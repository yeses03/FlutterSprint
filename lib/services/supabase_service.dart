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

  // Authentication and role operations
  static String? getCurrentUserId() {
    return _client.auth.currentUser?.id;
  }

  static Future<String?> getUserRole() async {
    final userId = getCurrentUserId();
    if (userId == null) return null;

    try {
      final response = await _client
          .from('user_roles')
          .select('role')
          .eq('user_id', userId)
          .maybeSingle();

      return response?['role'] as String?;
    } catch (e) {
      return null;
    }
  }

  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // Employer operations (using RLS with auth.uid())
  static Future<Map<String, dynamic>?> getEmployerProfile() async {
    final userId = getCurrentUserId();
    if (userId == null) {
      print('Employer tab → getEmployerProfile: No authenticated user');
      return null;
    }

    try {
      print('Employer tab → querying employers table (user_id: $userId)');
      final response = await _client
          .from('employers')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        print('Employer tab → employers result: null (RLS may be filtering or no record exists)');
      } else {
        print('Employer tab → employers result: ${response.keys}');
      }
      return response;
    } catch (e) {
      print('Employer tab → ERROR querying employers table: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getWorkHistoryForEmployer({
    String? workerId,
  }) async {
    try {
      print('Employer tab → querying work_history table${workerId != null ? ' (worker_id: $workerId)' : ''}');
      var query = _client.from('work_history').select('*, employers(name)');

      if (workerId != null) {
        query = query.eq('worker_id', workerId);
      }

      // RLS will filter based on employer access
      final response = await query.order('date', ascending: false);
      final result = List<Map<String, dynamic>>.from(response);
      
      print('Employer tab → work_history result: ${result.length} entries');
      if (result.isEmpty) {
        print('Employer tab → work_history result: empty (RLS may be filtering or no records exist)');
      }
      return result;
    } catch (e) {
      print('Employer tab → ERROR querying work_history table: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> searchWorkersForEmployer({
    String? searchQuery,
  }) async {
    try {
      print('Employer tab → querying work_history table (with workers join)${searchQuery != null ? ' (search: $searchQuery)' : ''}');
      // Query work_history with joins to get worker info
      // RLS will filter based on employer access
      var query = _client
          .from('work_history')
          .select('worker_id, workers:worker_id(id, name, phone, city, work_type)')
          .order('date', ascending: false);

      final response = await query;
      final workerMap = <String, Map<String, dynamic>>{};

      for (var item in response) {
        final worker = item['workers'];
        if (worker != null && worker['id'] != null) {
          final workerId = worker['id'] as String;
          if (!workerMap.containsKey(workerId)) {
            workerMap[workerId] = worker;
          }
        }
      }

      var workers = workerMap.values.toList();

      // Filter by search query if provided
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final queryLower = searchQuery.toLowerCase();
        workers = workers.where((worker) {
          final name = (worker['name'] as String? ?? '').toLowerCase();
          final phone = (worker['phone'] as String? ?? '').toLowerCase();
          final city = (worker['city'] as String? ?? '').toLowerCase();
          return name.contains(queryLower) ||
              phone.contains(queryLower) ||
              city.contains(queryLower);
        }).toList();
      }

      print('Employer tab → work_history (workers join) result: ${workers.length} unique workers');
      if (workers.isEmpty) {
        print('Employer tab → work_history (workers join) result: empty (RLS may be filtering or no records exist)');
      }
      return workers;
    } catch (e) {
      print('Employer tab → ERROR querying work_history table (workers join): $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getWorkerWorkHistory(String workerId) async {
    try {
      print('Employer tab → querying work_history table (worker_id: $workerId)');
      // RLS will filter based on employer access
      final response = await _client
          .from('work_history')
          .select()
          .eq('worker_id', workerId)
          .order('date', ascending: false);

      final result = List<Map<String, dynamic>>.from(response);
      print('Employer tab → work_history (worker_id: $workerId) result: ${result.length} entries');
      if (result.isEmpty) {
        print('Employer tab → work_history (worker_id: $workerId) result: empty (RLS may be filtering or no records exist)');
      }
      return result;
    } catch (e) {
      print('Employer tab → ERROR querying work_history table (worker_id: $workerId): $e');
      return [];
    }
  }

  static Future<void> verifyWorkHistoryEntry({
    required String entryId,
    required String verificationStatus,
    String? rejectionReason,
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      print('Employer tab → verifyWorkHistoryEntry: Not authenticated');
      throw Exception('Not authenticated');
    }

    try {
      print('Employer tab → updating work_history table (entry_id: $entryId, status: $verificationStatus)');
      // Update verification status in work_history (RLS will ensure access)
      await _client
          .from('work_history')
          .update({
            'verification_status': verificationStatus,
            'verified_at': DateTime.now().toIso8601String(),
          })
          .eq('id', entryId);

      print('Employer tab → inserting into verification_actions table (work_history_id: $entryId)');
      // Insert audit record into verification_actions
      await _client.from('verification_actions').insert({
        'work_history_id': entryId,
        'employer_id': userId,
        'action': verificationStatus,
        'reason': rejectionReason,
        'created_at': DateTime.now().toIso8601String(),
      });
      print('Employer tab → verification_actions insert successful');
    } catch (e) {
      print('Employer tab → ERROR in verifyWorkHistoryEntry (work_history/verification_actions): $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getVerificationRequests() async {
    final userId = getCurrentUserId();
    if (userId == null) {
      print('Employer tab → getVerificationRequests: No authenticated user');
      return [];
    }

    try {
      // Get employer_id from employers table
      final employerProfile = await getEmployerProfile();
      final employerId = employerProfile?['id'] as String?;

      if (employerId == null) {
        print('Employer tab → getVerificationRequests: No employer profile found');
        return [];
      }

      print('Employer tab → querying verification_requests table (employer_id: $employerId)');
      // RLS will filter by employer_id
      final response = await _client
          .from('verification_requests')
          .select()
          .eq('employer_id', employerId)
          .order('created_at', ascending: false);

      final result = List<Map<String, dynamic>>.from(response);
      print('Employer tab → verification_requests result: ${result.length} requests');
      if (result.isEmpty) {
        print('Employer tab → verification_requests result: empty (RLS may be filtering or no records exist)');
      }
      return result;
    } catch (e) {
      print('Employer tab → ERROR querying verification_requests table: $e');
      return [];
    }
  }

  static Future<void> createEmployerRating({
    required String workerId,
    required int rating,
    String? comment,
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      print('Employer tab → createEmployerRating: Not authenticated');
      throw Exception('Not authenticated');
    }

    try {
      // Get employer_id from employers table
      final employerProfile = await getEmployerProfile();
      final employerId = employerProfile?['id'] as String?;

      if (employerId == null) {
        print('Employer tab → createEmployerRating: No employer profile found');
        throw Exception('Employer profile not found');
      }

      print('Employer tab → inserting into employer_ratings table (employer_id: $employerId, worker_id: $workerId)');
      await _client.from('employer_ratings').insert({
        'employer_id': employerId,
        'worker_id': workerId,
        'rating': rating,
        'comment': comment,
        'created_at': DateTime.now().toIso8601String(),
      });
      print('Employer tab → employer_ratings insert successful');
    } catch (e) {
      print('Employer tab → ERROR inserting into employer_ratings table: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getAiVerificationLogs() async {
    try {
      print('Employer tab → querying ai_verification_logs table');
      // Read-only access to ai_verification_logs (RLS will filter)
      final response = await _client
          .from('ai_verification_logs')
          .select()
          .order('created_at', ascending: false)
          .limit(50);

      final result = List<Map<String, dynamic>>.from(response);
      print('Employer tab → ai_verification_logs result: ${result.length} logs');
      if (result.isEmpty) {
        print('Employer tab → ai_verification_logs result: empty (RLS may be filtering or no records exist)');
      }
      return result;
    } catch (e) {
      print('Employer tab → ERROR querying ai_verification_logs table: $e');
      return [];
    }
  }
}

