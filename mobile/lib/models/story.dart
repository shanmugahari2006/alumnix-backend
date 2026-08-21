class Story {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final String authorName;
  final int authorGradYear;
  final String? authorDesignation;
  final String? imageUrl;
  final int likesCount;
  final bool isLiked;
  final DateTime createdAt;

  const Story({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    this.authorGradYear = 2018,
    this.authorDesignation,
    this.imageUrl,
    this.likesCount = 0,
    this.isLiked = false,
    required this.createdAt,
  });

  String get excerpt {
    final clean = content.replaceAll('\n', ' ').trim();
    if (clean.length <= 130) return clean;
    return '${clean.substring(0, 130).trim()}...';
  }

  int get readingTimeMinutes {
    final words = content.split(RegExp(r'\s+')).length;
    final mins = (words / 180).ceil();
    return mins < 1 ? 1 : mins;
  }

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? 'Untitled Story',
      content: json['content'] as String? ?? '',
      authorId: json['author_id']?.toString() ?? '',
      authorName: json['author_name'] as String? ?? 'Distinguished Alumnus',
      authorGradYear: (json['author_grad_year'] as num?)?.toInt() ?? 2018,
      authorDesignation: json['author_designation'] as String?,
      imageUrl: json['image_url'] as String?,
      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
      isLiked: json['is_liked'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'author_id': authorId,
      'author_name': authorName,
      'author_grad_year': authorGradYear,
      'author_designation': authorDesignation,
      'image_url': imageUrl,
      'likes_count': likesCount,
      'is_liked': isLiked,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Story copyWith({
    String? id,
    String? title,
    String? content,
    String? authorId,
    String? authorName,
    int? authorGradYear,
    String? authorDesignation,
    String? imageUrl,
    int? likesCount,
    bool? isLiked,
    DateTime? createdAt,
  }) {
    return Story(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorGradYear: authorGradYear ?? this.authorGradYear,
      authorDesignation: authorDesignation ?? this.authorDesignation,
      imageUrl: imageUrl ?? this.imageUrl,
      likesCount: likesCount ?? this.likesCount,
      isLiked: isLiked ?? this.isLiked,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class LikeToggleResult {
  final String storyId;
  final bool isLiked;
  final int likesCount;

  const LikeToggleResult({
    required this.storyId,
    required this.isLiked,
    required this.likesCount,
  });

  factory LikeToggleResult.fromJson(Map<String, dynamic> json) {
    return LikeToggleResult(
      storyId: json['story_id']?.toString() ?? '',
      isLiked: json['liked'] as bool? ?? true,
      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
    );
  }
}
