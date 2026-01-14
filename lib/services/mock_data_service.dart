import 'package:workpass/models/user_model.dart';
import 'package:workpass/models/work_entry_model.dart';
import 'package:workpass/models/work_score_model.dart';

/// MockDataService provides placeholder data for development and demo purposes.
/// This will be replaced by SupabaseService when the backend is fully wired.
class MockDataService {
  static UserModel getMockUser() {
    return UserModel(
      id: 'mock_user_ravi_kumar',
      name: 'Ravi Kumar',
      phone: '+91 9876543210',
      city: 'Bangalore',
      workType: 'Delivery + Ride Share',
      createdAt: DateTime.now().subtract(const Duration(days: 180)),
    );
  }

  static List<WorkEntryModel> getMockWorkEntries() {
    final now = DateTime.now();
    final entries = <WorkEntryModel>[];

    // Generate 10 entries spread across different platforms and dates
    final platforms = ['Swiggy', 'Zomato', 'Ola', 'Zepto', 'OYO', 'Uber', 'Rapido'];
    final dates = [
      now.subtract(const Duration(days: 5)),
      now.subtract(const Duration(days: 8)),
      now.subtract(const Duration(days: 12)),
      now.subtract(const Duration(days: 15)),
      now.subtract(const Duration(days: 20)),
      now.subtract(const Duration(days: 25)),
      now.subtract(const Duration(days: 30)),
      now.subtract(const Duration(days: 35)),
      now.subtract(const Duration(days: 45)),
      now.subtract(const Duration(days: 50)),
    ];

    final hours = [4.5, 6.0, 5.5, 7.0, 8.0, 5.0, 6.5, 4.0, 7.5, 5.5];
    final amounts = [850.0, 1200.0, 1100.0, 1400.0, 1600.0, 950.0, 1300.0, 750.0, 1500.0, 1050.0];
    final verificationTypes = [
      'verified',
      'verified',
      'unverified',
      'verified',
      'verified',
      'unverified',
      'verified',
      'verified',
      'verified',
      'unverified',
    ];

    for (int i = 0; i < 10; i++) {
      entries.add(
        WorkEntryModel(
          id: 'mock_entry_$i',
          userId: 'mock_user_ravi_kumar',
          platform: platforms[i % platforms.length],
          date: dates[i],
          hoursWorked: hours[i],
          amountEarned: amounts[i],
          verificationType: verificationTypes[i],
          trustWeight: verificationTypes[i] == 'verified' ? 1.0 : 0.5,
          createdAt: dates[i],
        ),
      );
    }

    return entries;
  }

  static WorkScoreModel calculateMockWorkScore() {
    final entries = getMockWorkEntries();
    final now = DateTime.now();

    // Calculate monthly income
    final monthlyIncomes = <double>[];
    final monthMap = <String, double>{};

    for (var entry in entries) {
      final monthKey = '${entry.date.year}-${entry.date.month.toString().padLeft(2, '0')}';
      monthMap[monthKey] = (monthMap[monthKey] ?? 0) + entry.amountEarned;
    }

    monthlyIncomes.addAll(monthMap.values);
    final avgMonthlyIncome = monthlyIncomes.isEmpty
        ? 0.0
        : monthlyIncomes.reduce((a, b) => a + b) / monthlyIncomes.length;

    // Calculate months active
    final firstEntry = entries.reduce((a, b) => a.date.isBefore(b.date) ? a : b);
    final monthsActive = ((now.difference(firstEntry.date).inDays) / 30).ceil().clamp(0, 12);

    // Calculate verification ratio
    final verifiedEntries = entries.where((e) => e.verificationType != 'unverified').length;
    final verifiedRatio = entries.isEmpty ? 0.0 : verifiedEntries / entries.length;

    // Calculate scores (normalized 0-100)
    final monthlyIncomeScore = (avgMonthlyIncome / 50000).clamp(0.0, 1.0) * 100;
    final stabilityScore = (monthsActive / 12.0).clamp(0.0, 1.0) * 100;
    final verificationScore = verifiedRatio * 100;

    // Final WorkScore
    final workScore = 0.4 * monthlyIncomeScore + 0.3 * stabilityScore + 0.3 * verificationScore;

    // Risk level
    String riskLevel;
    if (workScore >= 70) {
      riskLevel = 'Low Risk';
    } else if (workScore >= 40) {
      riskLevel = 'Medium Risk';
    } else {
      riskLevel = 'High Risk';
    }

    return WorkScoreModel(
      userId: 'mock_user_ravi_kumar',
      avgMonthlyIncome: avgMonthlyIncome,
      monthsActive: monthsActive,
      verifiedRatio: verifiedRatio,
      score: workScore,
      riskLevel: riskLevel,
      updatedAt: DateTime.now(),
    );
  }

  static bool shouldUseMockData(String userId) {
    // Use mock data if userId is the mock user or if Supabase returns null
    return userId == 'mock_user_ravi_kumar' || userId.isEmpty;
  }
}
