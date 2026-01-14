import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:workpass/models/work_score_model.dart';
import 'package:workpass/theme/app_theme.dart';
import 'package:workpass/widgets/circular_score_gauge.dart';

class TrustScoreBreakdownScreen extends StatelessWidget {
  final WorkScoreModel workScore;

  const TrustScoreBreakdownScreen({
    super.key,
    required this.workScore,
  });

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel) {
      case 'Low Risk':
        return AppTheme.successGreen;
      case 'Medium Risk':
        return AppTheme.warningOrange;
      default:
        return AppTheme.errorRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final riskColor = _getRiskColor(workScore.riskLevel);

    // Calculate individual scores (normalized 0-100)
    final monthlyIncomeScore = (workScore.avgMonthlyIncome / 50000).clamp(0.0, 1.0) * 100;
    final stabilityScore = (workScore.monthsActive / 12.0).clamp(0.0, 1.0) * 100;
    final verificationScore = workScore.verifiedRatio * 100;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trust Center'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: AppTheme.gradientBackground(),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Premium Hero Section with Circular Gauge
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
                  decoration: AppTheme.gradientCard(),
                  child: Column(
                    children: [
                      Text(
                        'Your WorkScore',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                      ),
                      const SizedBox(height: 32),
                      CircularScoreGauge(
                        score: workScore.score,
                        size: 220,
                        strokeWidth: 24,
                      ),
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              workScore.riskLevel == 'Low Risk'
                                  ? Icons.check_circle
                                  : workScore.riskLevel == 'Medium Risk'
                                      ? Icons.warning
                                      : Icons.error,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              workScore.riskLevel,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      // Score Components
                      Text(
                        'Score Breakdown',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 20),
                      // Monthly Income Score
                      _buildPremiumScoreCard(
                        context,
                        'Monthly Income',
                        monthlyIncomeScore,
                        'Based on average monthly earnings',
                        Icons.currency_rupee,
                        AppTheme.accentBlue,
                      ),
                      const SizedBox(height: 16),
                      // Stability Score
                      _buildPremiumScoreCard(
                        context,
                        'Stability',
                        stabilityScore,
                        'Based on months of active work',
                        Icons.trending_up,
                        AppTheme.successGreen,
                      ),
                      const SizedBox(height: 16),
                      // Verification Score
                      _buildPremiumScoreCard(
                        context,
                        'Verification',
                        verificationScore,
                        'Based on verified work entries',
                        Icons.verified,
                        AppTheme.primaryBlue,
                      ),
                      const SizedBox(height: 32),
                      // Formula Section
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: AppTheme.glassmorphismCard(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.calculate, color: AppTheme.accentBlue),
                                const SizedBox(width: 12),
                                Text(
                                  'How your score is calculated',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppTheme.accentBlue.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTheme.accentBlue.withOpacity(0.2)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'WorkScore =',
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    '(0.4 × MonthlyIncomeScore) +',
                                    style: Theme.of(context).textTheme.bodyLarge,
                                  ),
                                  Text(
                                    '(0.3 × StabilityScore) +',
                                    style: Theme.of(context).textTheme.bodyLarge,
                                  ),
                                  Text(
                                    '(0.3 × VerificationScore)',
                                    style: Theme.of(context).textTheme.bodyLarge,
                                  ),
                                  const SizedBox(height: 20),
                                  Divider(color: AppTheme.mediumGray.withOpacity(0.3)),
                                  const SizedBox(height: 20),
                                  Text(
                                    '= (0.4 × ${monthlyIncomeScore.toStringAsFixed(1)}) +',
                                    style: Theme.of(context).textTheme.bodyLarge,
                                  ),
                                  Text(
                                    '  (0.3 × ${stabilityScore.toStringAsFixed(1)}) +',
                                    style: Theme.of(context).textTheme.bodyLarge,
                                  ),
                                  Text(
                                    '  (0.3 × ${verificationScore.toStringAsFixed(1)})',
                                    style: Theme.of(context).textTheme.bodyLarge,
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentBlue,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          '= ${workScore.score.toStringAsFixed(1)}',
                                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Metrics
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: AppTheme.glassmorphismCard(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your Metrics',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 24),
                            _buildPremiumMetricRow(
                              context,
                              'Average Monthly Income',
                              '₹${NumberFormat('#,##,###').format(workScore.avgMonthlyIncome)}',
                              Icons.currency_rupee,
                            ),
                            const SizedBox(height: 20),
                            Divider(color: AppTheme.mediumGray.withOpacity(0.3)),
                            const SizedBox(height: 20),
                            _buildPremiumMetricRow(
                              context,
                              'Months Active',
                              '${workScore.monthsActive} months',
                              Icons.calendar_today,
                            ),
                            const SizedBox(height: 20),
                            Divider(color: AppTheme.mediumGray.withOpacity(0.3)),
                            const SizedBox(height: 20),
                            _buildPremiumMetricRow(
                              context,
                              'Verification Ratio',
                              '${(workScore.verifiedRatio * 100).toStringAsFixed(1)}%',
                              Icons.verified,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumScoreCard(
    BuildContext context,
    String label,
    double score,
    String description,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassmorphismCard(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.darkGray,
                      ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: score / 100,
                    backgroundColor: AppTheme.mediumGray.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '${score.toStringAsFixed(1)}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumMetricRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.accentBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.accentBlue, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.deepBlue,
              ),
        ),
      ],
    );
  }
}
