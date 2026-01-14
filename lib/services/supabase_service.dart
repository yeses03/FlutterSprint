import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/work_entry_model.dart';
import '../models/work_score_model.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  // User operations
  static Future<String> createUser({
    required String name,
    required String phone,
    required String city,
    required String workType,
  }) async {
    final response = await _client.from('users').insert({
      'name': name,
      'phone': phone,
      'city': city,
      'work_type': workType,
    }).select('id').single();

    return response['id'] as String;
  }

  static Future<UserModel?> getUser(String userId) async {
    final response = await _client
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return null;
    return UserModel.fromJson(response);
  }

  static Future<UserModel?> getUserByPhone(String phone) async {
    final response = await _client
        .from('users')
        .select()
        .eq('phone', phone)
        .maybeSingle();

    if (response == null) return null;
    return UserModel.fromJson(response);
  }

  // Work entry operations
  static Future<String> createWorkEntry({
    required String userId,
    required String platform,
    required DateTime date,
    required double hoursWorked,
    required double amountEarned,
    required String verificationType,
    required double trustWeight,
    String? proofImageUrl,
  }) async {
    // Build payload dynamically - only include proof_image_url if provided
    final data = <String, dynamic>{
      'user_id': userId,
      'platform': platform,
      'date': date.toIso8601String().split('T')[0],
      'hours_worked': hoursWorked,
      'amount_earned': amountEarned,
      'verification_type': verificationType,
      'trust_weight': trustWeight,
    };

    // Only include proof_image_url if it's not null and not empty
    if (proofImageUrl != null && proofImageUrl.isNotEmpty) {
      data['proof_image_url'] = proofImageUrl;
    }

    final response = await _client.from('work_entries').insert(data).select('id').single();

    return response['id'] as String;
  }

  static Future<List<WorkEntryModel>> getWorkEntries(String userId) async {
    final response = await _client
        .from('work_entries')
        .select()
        .eq('user_id', userId)
        .order('date', ascending: false);

    return (response as List)
        .map((json) => WorkEntryModel.fromJson(json))
        .toList();
  }

  static Future<void> updateWorkEntry(String entryId, Map<String, dynamic> updates) async {
    await _client.from('work_entries').update(updates).eq('id', entryId);
  }

  static Future<void> deleteWorkEntry(String entryId) async {
    await _client.from('work_entries').delete().eq('id', entryId);
  }

  // Work score operations
  static Future<void> upsertWorkScore(WorkScoreModel score) async {
    await _client.from('work_scores').upsert(score.toJson());
  }

  static Future<WorkScoreModel?> getWorkScore(String userId) async {
    final response = await _client
        .from('work_scores')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return null;
    return WorkScoreModel.fromJson(response);
  }

  static Future<List<WorkScoreModel>> getAllWorkScores() async {
    final response = await _client.from('work_scores').select();

    return (response as List)
        .map((json) => WorkScoreModel.fromJson(json))
        .toList();
  }

  // Calculate and update work score
  static Future<WorkScoreModel> calculateAndUpdateWorkScore(String userId) async {
    final entries = await getWorkEntries(userId);

    if (entries.isEmpty) {
      final defaultScore = WorkScoreModel(
        userId: userId,
        avgMonthlyIncome: 0,
        monthsActive: 0,
        verifiedRatio: 0,
        score: 0,
        riskLevel: 'High Risk',
        updatedAt: DateTime.now(),
      );
      await upsertWorkScore(defaultScore);
      return defaultScore;
    }

    // Calculate monthly income
    final now = DateTime.now();
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
    final monthlyIncomeScore = (avgMonthlyIncome / 50000).clamp(0.0, 1.0) * 100; // Normalize to 50k max
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

    final scoreModel = WorkScoreModel(
      userId: userId,
      avgMonthlyIncome: avgMonthlyIncome,
      monthsActive: monthsActive,
      verifiedRatio: verifiedRatio,
      score: workScore,
      riskLevel: riskLevel,
      updatedAt: DateTime.now(),
    );

    await upsertWorkScore(scoreModel);
    return scoreModel;
  }
}

