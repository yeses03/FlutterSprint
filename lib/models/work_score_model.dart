class WorkScoreModel {
  final String userId;
  final double avgMonthlyIncome;
  final int monthsActive;
  final double verifiedRatio;
  final double score;
  final String riskLevel;
  final DateTime updatedAt;

  WorkScoreModel({
    required this.userId,
    required this.avgMonthlyIncome,
    required this.monthsActive,
    required this.verifiedRatio,
    required this.score,
    required this.riskLevel,
    required this.updatedAt,
  });

  factory WorkScoreModel.fromJson(Map<String, dynamic> json) {
    return WorkScoreModel(
      userId: json['user_id'] as String,
      avgMonthlyIncome: (json['avg_monthly_income'] as num).toDouble(),
      monthsActive: json['months_active'] as int,
      verifiedRatio: (json['verified_ratio'] as num).toDouble(),
      score: (json['score'] as num).toDouble(),
      riskLevel: json['risk_level'] as String,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'avg_monthly_income': avgMonthlyIncome,
      'months_active': monthsActive,
      'verified_ratio': verifiedRatio,
      'score': score,
      'risk_level': riskLevel,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

