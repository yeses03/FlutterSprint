class UserModel {
  final String id;
  final String name;
  final String phone;
  final String city;
  final String workType;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.city,
    required this.workType,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      city: json['city'] as String,
      workType: json['work_type'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'city': city,
      'work_type': workType,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

