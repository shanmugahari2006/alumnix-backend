import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/services/chat_service.dart';
import '../api/api_config.dart';
import '../models/chat.dart';
import 'auth_provider.dart';

/// Chat Service Provider
final chatServiceProvider = Provider<ChatService>((ref) {
  final client = ref.watch(dioClientProvider);
  return ChatService(client);
});

/// Unread Messages Count Provider
final unreadCountProvider = StateNotifierProvider<UnreadCountNotifier, int>((ref) {
  final chatService = ref.watch(chatServiceProvider);
  final isAuthenticated = ref.watch(authStateProvider.select((s) => s.isAuthenticated));
  return UnreadCountNotifier(chatService, isAuthenticated);
});

class UnreadCountNotifier extends StateNotifier<int> {
  final ChatService _chatService;
  final bool _isAuthenticated;
  Timer? _pollingTimer;

  UnreadCountNotifier(this._chatService, this._isAuthenticated) : super(0) {
    if (_isAuthenticated) {
      loadUnreadCount();
      // Periodically refresh unread count as fallback
      _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) => loadUnreadCount());
    }
  }

  Future<void> loadUnreadCount() async {
    if (!_isAuthenticated) return;
    try {
      final count = await _chatService.getUnreadCount();
      state = count;
    } catch (_) {}
  }

  void setUnreadCount(int count) {
    state = count;
  }

  void decrementBy(int count) {
    state = (state - count).clamp(0, 9999);
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}

/// Active Conversations List Provider
final conversationsProvider =
    StateNotifierProvider<ConversationsNotifier, AsyncValue<List<Conversation>>>((ref) {
  final chatService = ref.watch(chatServiceProvider);
  final isAuthenticated = ref.watch(authStateProvider.select((s) => s.isAuthenticated));
  return ConversationsNotifier(chatService, isAuthenticated, ref);
});

class ConversationsNotifier extends StateNotifier<AsyncValue<List<Conversation>>> {
  final ChatService _chatService;
  final bool _isAuthenticated;
  final Ref _ref;

  ConversationsNotifier(this._chatService, this._isAuthenticated, this._ref)
      : super(const AsyncValue.loading()) {
    if (_isAuthenticated) {
      loadConversations();
    } else {
      state = const AsyncValue.data([]);
    }
  }

  Future<void> loadConversations() async {
    state = const AsyncValue.loading();
    try {
      final conversations = await _chatService.listConversations();
      // Sort by last message time / updated_at desc
      conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      state = AsyncValue.data(conversations);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  Future<Conversation?> startConversation(String recipientId) async {
    try {
      final conv = await _chatService.startConversation(recipientId);
      final currentList = state.value ?? [];
      if (!currentList.any((c) => c.id == conv.id)) {
        state = AsyncValue.data([conv, ...currentList]);
      }
      return conv;
    } catch (_) {
      return null;
    }
  }

  void updateConversationWithNewMessage(ChatMessage msg) {
    final currentList = state.value ?? [];
    final index = currentList.indexWhere((c) => c.id == msg.conversationId);

    if (index != -1) {
      final oldConv = currentList[index];
      // Increment unread if message sender is NOT current user
      final currentUserId = _ref.read(authStateProvider).user?.id;
      final isNewUnread = msg.senderId != currentUserId;

      final updatedConv = Conversation(
        id: oldConv.id,
        partner: oldConv.partner,
        lastMessage: msg,
        unreadCount: isNewUnread ? oldConv.unreadCount + 1 : oldConv.unreadCount,
        createdAt: oldConv.createdAt,
        updatedAt: DateTime.now(),
      );

      final updatedList = List<Conversation>.from(currentList)..removeAt(index);
      updatedList.insert(0, updatedConv); // Move to top
      state = AsyncValue.data(updatedList);

      if (isNewUnread) {
        _ref.read(unreadCountProvider.notifier).decrementBy(-1); // Increment count
      }
    } else {
      // Refresh list to pull new conversations
      loadConversations();
    }
  }

  void markConversationAsRead(String conversationId) {
    final currentList = state.value ?? [];
    final index = currentList.indexWhere((c) => c.id == conversationId);

    if (index != -1) {
      final oldConv = currentList[index];
      final unreadCountRemoved = oldConv.unreadCount;

      if (unreadCountRemoved > 0) {
        final updatedConv = Conversation(
          id: oldConv.id,
          partner: oldConv.partner,
          lastMessage: oldConv.lastMessage,
          unreadCount: 0,
          createdAt: oldConv.createdAt,
          updatedAt: oldConv.updatedAt,
        );

        final updatedList = List<Conversation>.from(currentList)..[index] = updatedConv;
        state = AsyncValue.data(updatedList);
        _ref.read(unreadCountProvider.notifier).decrementBy(unreadCountRemoved);
      }
    }
  }
}

/// Chat Room Messages Provider (Stateful per Conversation ID)
final chatMessagesProvider = StateNotifierProvider.family.autoDispose<
    ChatMessagesNotifier, AsyncValue<List<ChatMessage>>, String>((ref, conversationId) {
  final chatService = ref.watch(chatServiceProvider);
  final token = ref.read(authStateProvider).accessToken;
  return ChatMessagesNotifier(chatService, conversationId, token, ref);
});

class ChatMessagesNotifier extends StateNotifier<AsyncValue<List<ChatMessage>>> {
  final ChatService _chatService;
  final String _conversationId;
  final String? _token;
  final Ref _ref;

  WebSocket? _webSocket;
  StreamSubscription? _wsSubscription;
  bool _isConnected = false;

  ChatMessagesNotifier(this._chatService, this._conversationId, this._token, this._ref)
      : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    await loadMessages();
    await _connectWebSocket();
    await markAsRead();
  }

  Future<void> loadMessages() async {
    try {
      final msgs = await _chatService.getMessages(_conversationId);
      // Sort oldest to newest for UI bubble ordering
      msgs.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      state = AsyncValue.data(msgs);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  Future<void> _connectWebSocket() async {
    if (_token == null || _token!.isEmpty) return;

    try {
      // Build Websocket URI replacing http/https with ws/wss
      final baseWsUrl = ApiConfig.baseUrl
          .replaceFirst('https://', 'wss://')
          .replaceFirst('http://', 'ws://')
          .replaceFirst('/api/v1', '/ws');

      final wsUrl = '$baseWsUrl/$_conversationId?token=$_token';
      
      _webSocket = await WebSocket.connect(wsUrl).timeout(const Duration(seconds: 5));
      _isConnected = true;

      _wsSubscription = _webSocket!.listen(
        (data) {
          _handleIncomingData(data as String);
        },
        onError: (err) {
          _isConnected = false;
        },
        onDone: () {
          _isConnected = false;
        },
      );
    } catch (_) {
      _isConnected = false;
    }
  }

  void _handleIncomingData(String rawData) {
    try {
      final json = jsonDecode(rawData) as Map<String, dynamic>;
      final type = json['type'] as String?;

      if (type == 'new_message') {
        final messageMap = json['message'] as Map<String, dynamic>;
        final message = ChatMessage.fromJson(messageMap);

        // Append message to state
        final currentMessages = state.value ?? [];
        if (!currentMessages.any((m) => m.id == message.id)) {
          state = AsyncValue.data([...currentMessages, message]);
        }

        // Notify conversations list provider to update preview & unread counts
        _ref.read(conversationsProvider.notifier).updateConversationWithNewMessage(message);

        // If this message belongs to the current room and we are in foreground, mark it as read immediately
        if (message.senderId != _ref.read(authStateProvider).user?.id) {
          markAsRead();
        }
      } else if (type == 'messages_read') {
        final readerId = json['reader_id'] as String?;
        final currentUserId = _ref.read(authStateProvider).user?.id;

        // If the other user read our messages, update our internal message list states
        if (readerId != currentUserId) {
          final currentMessages = state.value ?? [];
          final updated = currentMessages.map((m) {
            if (m.senderId == currentUserId && !m.isRead) {
              return ChatMessage(
                id: m.id,
                conversationId: m.conversationId,
                senderId: m.senderId,
                senderName: m.senderName,
                content: m.content,
                isRead: true,
                createdAt: m.createdAt,
              );
            }
            return m;
          }).toList();
          state = AsyncValue.data(updated);
        }
      }
    } catch (_) {}
  }

  /// Send message over WebSocket if connected, otherwise fallback to REST API
  Future<bool> sendMessage(String content) async {
    if (content.trim().isEmpty) return false;

    if (_isConnected && _webSocket != null) {
      try {
        _webSocket!.add(jsonEncode({
          'type': 'message',
          'content': content.trim(),
        }));
        return true;
      } catch (_) {
        // Fallback to REST below
      }
    }

    // Fallback: REST send
    try {
      final msg = await _chatService.sendMessage(_conversationId, content.trim());
      
      final currentMessages = state.value ?? [];
      state = AsyncValue.data([...currentMessages, msg]);
      
      _ref.read(conversationsProvider.notifier).updateConversationWithNewMessage(msg);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Mark all messages in room as read
  Future<void> markAsRead() async {
    try {
      await _chatService.markAsRead(_conversationId);
      
      // Update WebSocket channel so recipient knows we read them
      if (_isConnected && _webSocket != null) {
        _webSocket!.add(jsonEncode({'type': 'read'}));
      }

      // Sync local conversation unread indicators
      _ref.read(conversationsProvider.notifier).markConversationAsRead(_conversationId);
    } catch (_) {}
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    _webSocket?.close();
    super.dispose();
  }
}

/// Lookup directory for initiating new chats
final chatSearchProvider = StateNotifierProvider.autoDispose<
    ChatSearchNotifier, AsyncValue<List<ChatUserSummary>>>((ref) {
  final chatService = ref.watch(chatServiceProvider);
  return ChatSearchNotifier(chatService);
});

class ChatSearchNotifier extends StateNotifier<AsyncValue<List<ChatUserSummary>>> {
  final ChatService _chatService;
  Timer? _debounceTimer;

  ChatSearchNotifier(this._chatService) : super(const AsyncValue.data([]));

  void searchUsers(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        final list = await _chatService.searchUsers(query);
        state = AsyncValue.data(list);
      } catch (err, stack) {
        state = AsyncValue.error(err, stack);
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
