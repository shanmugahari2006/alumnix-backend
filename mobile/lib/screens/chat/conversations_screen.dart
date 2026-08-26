import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/chat_provider.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_skeleton.dart';

class ConversationsScreen extends ConsumerStatefulWidget {
  const ConversationsScreen({super.key});

  @override
  ConsumerState<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends ConsumerState<ConversationsScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  String _formatDateTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE').format(date); // e.g. Wednesday
    }
    return DateFormat('MMM d').format(date); // e.g. Aug 26
  }

  @override
  Widget build(BuildContext context) {
    final conversationsAsync = ref.watch(conversationsProvider);
    final searchAsync = ref.watch(chatSearchProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(conversationsProvider.notifier).loadConversations(),
          color: AppColors.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search Input Row
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) {
                      setState(() {
                        _isSearching = v.trim().isNotEmpty;
                      });
                      ref.read(chatSearchProvider.notifier).searchUsers(v);
                    },
                    decoration: InputDecoration(
                      hintText: 'Search people to chat...',
                      hintStyle: GoogleFonts.ibmPlexSans(color: AppColors.textSecondary),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                      suffixIcon: _isSearching
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, color: AppColors.textSecondary),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _isSearching = false);
                                ref.read(chatSearchProvider.notifier).searchUsers('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
                    ),
                  ),
                ),
              ),

              // Search Results vs Conversation List
              Expanded(
                child: _isSearching
                    ? _buildSearchResults(searchAsync)
                    : _buildConversationsList(conversationsAsync),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(AsyncValue searchAsync) {
    return searchAsync.when(
      loading: () => ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        itemCount: 3,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: LoadingSkeleton.card(height: 64),
        ),
      ),
      error: (err, _) => Center(child: Text('Search failed: $err')),
      data: (users) {
        final list = users as List;
        if (list.isEmpty) {
          return Center(
            child: Text(
              'No users match your query.',
              style: GoogleFonts.ibmPlexSans(color: AppColors.textSecondary),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          itemCount: list.length,
          separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.border),
          itemBuilder: (context, index) {
            final user = list[index];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
              leading: CircleAvatar(
                backgroundColor: AppColors.goldLight,
                child: Text(
                  _getInitials(user.fullName),
                  style: GoogleFonts.ibmPlexSans(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                user.fullName,
                style: GoogleFonts.ibmPlexSans(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              subtitle: Text(
                '${user.role.toString().split('.').last.toUpperCase()}'
                '${user.graduationYear != null ? ' · Class of ${user.graduationYear}' : ''}',
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
              onTap: () async {
                // Start or retrieve conversation
                final conv = await ref
                    .read(conversationsProvider.notifier)
                    .startConversation(user.id);
                if (conv != null && mounted) {
                  _searchController.clear();
                  setState(() => _isSearching = false);
                  ref.read(chatSearchProvider.notifier).searchUsers('');
                  context.push('/chat/${conv.id}');
                }
              },
            );
          },
        );
      },
    );
  }

  Widget _buildConversationsList(AsyncValue conversationsAsync) {
    return conversationsAsync.when(
      loading: () => ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        itemCount: 4,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: LoadingSkeleton.card(height: 80),
        ),
      ),
      error: (err, _) => EmptyState(
        icon: Icons.chat_bubble_outline_rounded,
        title: 'Unable to Load Chats',
        message: 'Failed to retrieve active messaging threads.',
        actionText: 'Retry',
        onAction: () => ref.read(conversationsProvider.notifier).loadConversations(),
      ),
      data: (conversations) {
        final list = conversations as List;
        if (list.isEmpty) {
          return EmptyState(
            icon: Icons.forum_outlined,
            title: 'No conversations yet',
            message: 'Search for graduates or collaborators to start messaging.',
            actionText: 'Find People',
            onAction: () {
              // Direct focus / switch tab programmatically to Directory if needed, 
              // or let them use the search input above
            },
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          itemCount: list.length,
          separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.border),
          itemBuilder: (context, index) {
            final conv = list[index];
            final hasUnread = conv.unreadCount > 0;

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: hasUnread ? AppColors.gold : AppColors.goldLight,
                child: Text(
                  _getInitials(conv.partner.fullName),
                  style: GoogleFonts.ibmPlexSans(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      conv.partner.fullName,
                      style: GoogleFonts.ibmPlexSans(
                        fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (conv.lastMessage != null)
                    Text(
                      _formatDateTime(conv.lastMessage!.createdAt),
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 11,
                        color: hasUnread ? AppColors.primary : AppColors.textSecondary,
                        fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        conv.lastMessage?.content ?? 'Conversation started',
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 13,
                          color: hasUnread ? AppColors.textPrimary : AppColors.textSecondary,
                          fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (hasUnread) ...[
                      AppSpacing.gapH8,
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.secondary, width: 0.5),
                        ),
                        child: Text(
                          '${conv.unreadCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ]
                  ],
                ),
              ),
              onTap: () {
                context.push('/chat/${conv.id}');
              },
            );
          },
        );
      },
    );
  }
}
