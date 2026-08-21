class FacultyProfile {
  final String id;
  final String employeeId;
  final String department;
  final String designation;
  final bool isApproved;

  const FacultyProfile({
    required this.id,
    required this.employeeId,
    required this.department,
    required this.designation,
    this.isApproved = false,
  });

  factory FacultyProfile.fromJson(Map<String, dynamic> json) {
    return FacultyProfile(
      id: json['id']?.toString() ?? '',
      employeeId: json['employee_id'] as String? ?? '',
      department: json['department'] as String? ?? '',
      designation: json['designation'] as String? ?? '',
      isApproved: json['is_approved'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      'department': department,
      'designation': designation,
      'is_approved': isApproved,
    };
  }

  FacultyProfile copyWith({
    String? id,
    String? employeeId,
    String? department,
    String? designation,
    bool? isApproved,
  }) {
    return FacultyProfile(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      department: department ?? this.department,
      designation: designation ?? this.designation,
      isApproved: isApproved ?? this.isApproved,
    );
  }
}
