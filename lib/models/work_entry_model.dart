class WorkEntryModel {
  final String id;
  final String userId;
  final String platform;
  final DateTime date;
  final double hoursWorked;
  final double amountEarned;
  final String verificationType;
  final double trustWeight;
  final String? proofImageUrl;
  final DateTime createdAt;

  WorkEntryModel({
    required this.id,
    required this.userId,
    required this.platform,
    required this.date,
    required this.hoursWorked,
    required this.amountEarned,
    required this.verificationType,
    required this.trustWeight,
    this.proofImageUrl,
    required this.createdAt,
  });

  factory WorkEntryModel.fromJson(Map<String, dynamic> json) {
    return WorkEntryModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      platform: json['platform'] as String,
      date: DateTime.parse(json['date'] as String),
      hoursWorked: (json['hours_worked'] as num).toDouble(),
      amountEarned: (json['amount_earned'] as num).toDouble(),
      verificationType: json['verification_type'] as String,
      trustWeight: (json['trust_weight'] as num).toDouble(),
      proofImageUrl: json['proof_image_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'platform': platform,
      'date': date.toIso8601String().split('T')[0],
      'hours_worked': hoursWorked,
      'amount_earned': amountEarned,
      'verification_type': verificationType,
      'trust_weight': trustWeight,
      'proof_image_url': proofImageUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

