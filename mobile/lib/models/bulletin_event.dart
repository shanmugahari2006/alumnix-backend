import 'package:intl/intl.dart';

class BulletinEvent {
  final String id;
  final String title;
  final String description;
  final DateTime eventDate;
  final DateTime registrationDeadline;
  final String location;
  final String creatorId;
  final String creatorName;
  final int registeredCount;
  final bool isRegistered;
  final String? bannerUrl;
  final DateTime createdAt;

  const BulletinEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.eventDate,
    required this.registrationDeadline,
    required this.location,
    required this.creatorId,
    this.creatorName = 'Faculty Convener',
    this.registeredCount = 0,
    this.isRegistered = false,
    this.bannerUrl,
    required this.createdAt,
  });

  bool get isRegistrationClosed {
    return DateTime.now().isAfter(registrationDeadline);
  }

  bool get isPastEvent {
    return DateTime.now().isAfter(eventDate);
  }

  String get formattedEventDate {
    // Format: "12 Sept 2026, 5:00 PM"
    final day = DateFormat('d').format(eventDate);
    final month = DateFormat('MMM').format(eventDate);
    final year = DateFormat('yyyy').format(eventDate);
    final time = DateFormat('h:mm a').format(eventDate);
    return '$day $month $year, $time';
  }

  String get formattedDeadline {
    final day = DateFormat('d').format(registrationDeadline);
    final month = DateFormat('MMM').format(registrationDeadline);
    final year = DateFormat('yyyy').format(registrationDeadline);
    final time = DateFormat('h:mm a').format(registrationDeadline);
    return '$day $month $year, $time';
  }

  String get countdownString {
    final now = DateTime.now();
    if (now.isAfter(registrationDeadline)) {
      return 'Registration Closed';
    }

    final diff = registrationDeadline.difference(now);
    if (diff.inDays > 0) {
      final hours = diff.inHours % 24;
      return 'Registration closes in ${diff.inDays}d ${hours}h';
    } else if (diff.inHours > 0) {
      final mins = diff.inMinutes % 60;
      return 'Registration closes in ${diff.inHours}h ${mins}m';
    } else if (diff.inMinutes > 0) {
      return 'Registration closes in ${diff.inMinutes}m';
    } else {
      return 'Registration closing soon';
    }
  }

  factory BulletinEvent.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now().add(const Duration(days: 7));
      return DateTime.tryParse(val.toString()) ??
          DateTime.now().add(const Duration(days: 7));
    }

    return BulletinEvent(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? 'Collegiate Event',
      description: json['description'] as String? ?? '',
      eventDate: parseDate(json['event_date']),
      registrationDeadline: json['registration_deadline'] != null
          ? parseDate(json['registration_deadline'])
          : parseDate(json['event_date']).subtract(const Duration(days: 1)),
      location: json['location'] as String? ?? 'Campus Auditorium',
      creatorId: json['creator_id']?.toString() ?? '',
      creatorName: json['creator_name'] as String? ?? 'Academic Council',
      registeredCount: (json['registered_count'] as num?)?.toInt() ?? 0,
      isRegistered: json['is_registered'] as bool? ?? false,
      bannerUrl: json['banner_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'event_date': eventDate.toIso8601String(),
      'registration_deadline': registrationDeadline.toIso8601String(),
      'location': location,
      'creator_id': creatorId,
      'creator_name': creatorName,
      'registered_count': registeredCount,
      'is_registered': isRegistered,
      'banner_url': bannerUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  BulletinEvent copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? eventDate,
    DateTime? registrationDeadline,
    String? location,
    String? creatorId,
    String? creatorName,
    int? registeredCount,
    bool? isRegistered,
    String? bannerUrl,
    DateTime? createdAt,
  }) {
    return BulletinEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      eventDate: eventDate ?? this.eventDate,
      registrationDeadline:
          registrationDeadline ?? this.registrationDeadline,
      location: location ?? this.location,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      registeredCount: registeredCount ?? this.registeredCount,
      isRegistered: isRegistered ?? this.isRegistered,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
