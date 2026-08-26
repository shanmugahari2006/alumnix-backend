import '../../models/user.dart';

class ChatUserSummary {
  final String id;
  final String fullName;
  final String? email;
  final UserRole role;
  final int? graduationYear;

  ChatUserSummary({
    required this.id,
    required this.fullName,
    this.email,
    required this.role,
    this.graduationYear,
  });

  factory ChatUserSummary.fromJson(Map<String, dynamic> json) {
    return ChatUserSummary(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? 'Alumnix User',
      email: json['email'] as String?,
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == (json['role'] as String? ?? 'student').toLowerCase(),
        orElse: () => UserRole.student,
      ),
      graduationYear: json['graduation_year'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'email': email,
        'role': role.toString().split('.').last,
        'graduation_year': graduationYear,
      };
}

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String content;
  final bool isRead;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.isRead,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      senderName: json['sender_name'] as String? ?? 'User',
      content: json['content'] as String? ?? '',
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversation_id': conversationId,
        'sender_id': senderId,
        'sender_name': senderName,
        'content': content,
        'is_read': isRead,
        'created_at': createdAt.toUtc().toIso8601String(),
      };
}

class Conversation {
  final String id;
  final ChatUserSummary partner;
  final ChatMessage? lastMessage;
  final int unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Conversation({
    required this.id,
    required this.partner,
    this.lastMessage,
    required this.unreadCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      partner: ChatUserSummary.fromJson(json['partner'] as Map<String, dynamic>),
      lastMessage: json['last_message'] != null
          ? ChatMessage.fromJson(json['last_message'] as Map<String, dynamic>)
          : null,
      unreadCount: json['unread_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'partner': partner.toJson(),
        'last_message': lastMessage?.toJson(),
        'unread_count': unreadCount,
        'created_at': createdAt.toUtc().toIso8601String(),
        'updated_at': updatedAt.toUtc().toIso8601String(),
      };
}
