import 'package:flutter/material.dart';
import 'package:workpass/models/work_score_model.dart';
import 'package:workpass/theme/app_theme.dart';

class RiskViewScreen extends StatelessWidget {
  final WorkScoreModel workScore;

  const RiskViewScreen({super.key, required this.workScore});

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

  String _getLendingSuitability(String riskLevel) {
    switch (riskLevel) {
      case 'Low Risk':
        return 'Highly suitable for lending. Low default risk.';
      case 'Medium Risk':
        return 'Moderately suitable. Standard lending terms apply.';
      default:
        return 'High risk. Requires additional assessment or collateral.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final riskColor = _getRiskColor(workScore.riskLevel);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Risk Assessment'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.lightBlue, Colors.white],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: AppTheme.gradientCard(),
                  child: Column(
                    children: [
                      Text(
                        'WorkScore',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        workScore.score.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              color: Colors.white,
                              fontSize: 64,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: AppTheme.glassmorphismCard(),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Risk Level',
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: riskColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: riskColor, width: 2),
                            ),
                            child: Text(
                              workScore.riskLevel,
                              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                    color: riskColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: riskColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: riskColor, width: 2),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              workScore.riskLevel == 'Low Risk'
                                  ? Icons.check_circle
                                  : workScore.riskLevel == 'Medium Risk'
                                      ? Icons.warning
                                      : Icons.error,
                              color: riskColor,
                              size: 32,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                _getLendingSuitability(workScore.riskLevel),
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: AppTheme.glassmorphismCard(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Score Breakdown',
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: 24),
                      _buildMetricRow(
                        'Average Monthly Income',
                        '₹${workScore.avgMonthlyIncome.toStringAsFixed(0)}',
                      ),
                      const Divider(),
                      _buildMetricRow(
                        'Months Active',
                        '${workScore.monthsActive} months',
                      ),
                      const Divider(),
                      _buildMetricRow(
                        'Verification Ratio',
                        '${(workScore.verifiedRatio * 100).toStringAsFixed(1)}%',
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

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                ),
          ),
        ],
      ),
    );
  }
}

