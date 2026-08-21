class Event {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String location;
  final String creatorId;
  final DateTime createdAt;
  final bool isRegistered;
  final int attendeesCount;
  final String? bannerImageUrl;
  final String? category; // Reunion, Workshop, Convocation, Networking

  const Event({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.location,
    required this.creatorId,
    required this.createdAt,
    this.isRegistered = false,
    this.attendeesCount = 0,
    this.bannerImageUrl,
    this.category,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? 'Untitled Event',
      description: json['description'] as String? ?? '',
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      location: json['location'] as String? ?? 'Campus Auditorium',
      creatorId: json['creator_id']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isRegistered: json['is_registered'] as bool? ?? false,
      attendeesCount: (json['attendees_count'] as num?)?.toInt() ?? 0,
      bannerImageUrl: json['banner_image_url'] as String?,
      category: json['category'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'location': location,
      'creator_id': creatorId,
      'created_at': createdAt.toIso8601String(),
      'is_registered': isRegistered,
      'attendees_count': attendeesCount,
      'banner_image_url': bannerImageUrl,
      'category': category,
    };
  }

  Event copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    String? location,
    String? creatorId,
    DateTime? createdAt,
    bool? isRegistered,
    int? attendeesCount,
    String? bannerImageUrl,
    String? category,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      location: location ?? this.location,
      creatorId: creatorId ?? this.creatorId,
      createdAt: createdAt ?? this.createdAt,
      isRegistered: isRegistered ?? this.isRegistered,
      attendeesCount: attendeesCount ?? this.attendeesCount,
      bannerImageUrl: bannerImageUrl ?? this.bannerImageUrl,
      category: category ?? this.category,
    );
  }
}
