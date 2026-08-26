import 'package:dio/dio.dart';
import '../api_config.dart';
import '../dio_client.dart';
import '../../models/chat.dart';

class ChatService {
  final DioClient client;

  ChatService(this.client);

  /// Fetch all active conversations for the authenticated user
  /// GET /chat/conversations
  Future<List<Conversation>> listConversations() async {
    try {
      final response = await client.get('/chat/conversations');
      final list = response.data as List<dynamic>;
      return list.map((e) => Conversation.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  /// Retrieve full message history for a conversation
  /// GET /chat/conversations/{conversation_id}/messages
  Future<List<ChatMessage>> getMessages(String conversationId) async {
    try {
      final response = await client.get('/chat/conversations/$conversationId/messages');
      final list = response.data as List<dynamic>;
      return list.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  /// Start or retrieve an existing one-to-one conversation with another user
  /// POST /chat/conversations
  /// Body: { "recipient_id": string }
  Future<Conversation> startConversation(String recipientId) async {
    try {
      final response = await client.post(
        '/chat/conversations',
        data: {'recipient_id': recipientId},
      );
      return Conversation.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  /// Send a message in a conversation via REST API (fallback / backup)
  /// POST /chat/conversations/{conversation_id}/messages
  /// Body: { "content": string }
  Future<ChatMessage> sendMessage(String conversationId, String content) async {
    try {
      final response = await client.post(
        '/chat/conversations/$conversationId/messages',
        data: {'content': content},
      );
      return ChatMessage.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  /// Mark unread messages in a conversation as read by the current user
  /// PATCH /chat/conversations/{conversation_id}/read
  Future<int> markAsRead(String conversationId) async {
    try {
      final response = await client.patch('/chat/conversations/$conversationId/read');
      final data = response.data as Map<String, dynamic>;
      return data['updated_count'] as int? ?? 0;
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  /// Get aggregate total count of unread messages for current user
  /// GET /chat/unread-count
  Future<int> getUnreadCount() async {
    try {
      final response = await client.get('/chat/unread-count');
      final data = response.data as Map<String, dynamic>;
      return data['total_unread'] as int? ?? 0;
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  /// Search available users and alumni to initiate a new private chat
  /// GET /chat/users/search?query=...
  Future<List<ChatUserSummary>> searchUsers(String query) async {
    try {
      final response = await client.get(
        '/chat/users/search',
        queryParameters: {'query': query},
      );
      final list = response.data as List<dynamic>;
      return list.map((e) => ChatUserSummary.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  /// Helper to extract detail message from FastAPI error responses
  String _extractErrorMessage(DioException e) {
    if (e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic> && data['detail'] is String) {
        return data['detail'] as String;
      }
    }
    return e.message ?? 'Network error occurred.';
  }
}
