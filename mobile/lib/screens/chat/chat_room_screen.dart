import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/chat.dart';
import '../../models/user.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../widgets/loading_skeleton.dart';

class ChatRoomScreen extends ConsumerStatefulWidget {
  final String conversationId;

  const ChatRoomScreen({
    super.key,
    required this.conversationId,
  });

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _handleSend() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    final success = await ref
        .read(chatMessagesProvider(widget.conversationId).notifier)
        .sendMessage(text);

    if (success) {
      _scrollToBottom();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send message. Network error.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesProvider(widget.conversationId));
    final conversations = ref.watch(conversationsProvider).value ?? [];
    final currentUserId = ref.watch(authStateProvider).user?.id;

    // Find the partner summary details from cached conversations if possible
    final activeConv = conversations.firstWhere(
      (c) => c.id == widget.conversationId,
      orElse: () => Conversation(
        id: widget.conversationId,
        partner: ChatUserSummary(
          id: '',
          fullName: 'Alumni Partner',
          role: UserRole.student,
        ),
        unreadCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    // Scroll to bottom when data finishes loading or message count changes
    ref.listen(chatMessagesProvider(widget.conversationId), (prev, next) {
      if (next.hasValue) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.goldLight,
              child: Text(
                _getInitials(activeConv.partner.fullName),
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            AppSpacing.gapH12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activeConv.partner.fullName,
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    activeConv.partner.role.toString().split('.').last.toUpperCase(),
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam_outlined),
            onPressed: () {
              // Initiate WebRTC Call
              context.push('/calls/video?partnerId=${activeConv.partner.id}&partnerName=${Uri.encodeComponent(activeConv.partner.fullName)}');
            },
          ),
          AppSpacing.gapH8,
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => ListView.builder(
                padding: AppSpacing.pagePadding,
                itemCount: 4,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: LoadingSkeleton.card(height: 50),
                ),
              ),
              error: (err, _) => Center(
                child: Text('Failed to load message history: $err'),
              ),
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 40,
                          color: AppColors.textSecondary,
                        ),
                        AppSpacing.gapV12,
                        Text(
                          'No messages yet',
                          style: GoogleFonts.ibmPlexSans(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Send a message to start the conversation.',
                          style: GoogleFonts.ibmPlexSans(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16.0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isSelf = msg.senderId == currentUserId;

                    return Align(
                      alignment: isSelf ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12.0),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                        decoration: BoxDecoration(
                          color: isSelf ? AppColors.primary : AppColors.surface,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(12),
                            topRight: const Radius.circular(12),
                            bottomLeft: Radius.circular(isSelf ? 12 : 0),
                            bottomRight: Radius.circular(isSelf ? 0 : 12),
                          ),
                          border: isSelf
                              ? null
                              : Border.all(color: AppColors.border, width: 1.0),
                        ),
                        child: Column(
                          crossAxisAlignment:
                              isSelf ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg.content,
                              style: GoogleFonts.ibmPlexSans(
                                color: isSelf ? Colors.white : AppColors.textPrimary,
                                fontSize: 14.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  DateFormat('jm').format(msg.createdAt),
                                  style: GoogleFonts.ibmPlexSans(
                                    color: isSelf
                                        ? Colors.white.withOpacity(0.7)
                                        : AppColors.textSecondary,
                                    fontSize: 10.0,
                                  ),
                                ),
                                if (isSelf) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    msg.isRead
                                        ? Icons.done_all_rounded
                                        : Icons.done_rounded,
                                    size: 14,
                                    color: msg.isRead
                                        ? AppColors.secondary
                                        : Colors.white.withOpacity(0.7),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Message Input Field Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(color: AppColors.border, width: 1.0),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14.0),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(24.0),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: TextField(
                        controller: _messageController,
                        maxLines: 4,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 10.0),
                        ),
                        onSubmitted: (_) => _handleSend(),
                      ),
                    ),
                  ),
                  AppSpacing.gapH8,
                  GestureDetector(
                    onTap: _handleSend,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.send_rounded,
                          color: AppColors.secondary,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
