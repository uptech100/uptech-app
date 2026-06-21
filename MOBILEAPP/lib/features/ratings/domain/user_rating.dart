class RateableUser {
  final int id;
  final String name;
  final String employeeId;
  final String departmentName;

  RateableUser({
    required this.id,
    required this.name,
    required this.employeeId,
    required this.departmentName,
  });

  factory RateableUser.fromJson(Map<String, dynamic> json) {
    return RateableUser(
      id: json['id'],
      name: json['name'] ?? '',
      employeeId: json['employeeId'] ?? '',
      departmentName: json['department']?['name'] ?? '',
    );
  }
}

class AdminRatingSummary {
  final int id;
  final String name;
  final String employeeId;
  final String departmentName;
  final double averageRating;
  final int totalRatings;

  AdminRatingSummary({
    required this.id,
    required this.name,
    required this.employeeId,
    required this.departmentName,
    required this.averageRating,
    required this.totalRatings,
  });

  factory AdminRatingSummary.fromJson(Map<String, dynamic> json) {
    return AdminRatingSummary(
      id: json['id'],
      name: json['name'] ?? '',
      employeeId: json['employeeId'] ?? '',
      departmentName: json['departmentName'] ?? '',
      averageRating: double.tryParse(json['averageRating'].toString()) ?? 0.0,
      totalRatings: json['totalRatings'] ?? 0,
    );
  }
}
