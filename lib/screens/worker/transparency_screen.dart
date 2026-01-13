import 'package:flutter/material.dart';
import 'package:workpass/theme/app_theme.dart';

class TransparencyScreen extends StatelessWidget {
  const TransparencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transparency'),
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
                Text(
                  'How WorkScore Works',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 32),
                _buildSection(
                  context,
                  'What is WorkScore?',
                  'WorkScore is a creditworthiness metric calculated from your work history. It helps financial institutions understand your earning stability and reliability.',
                  Icons.assessment,
                ),
                const SizedBox(height: 24),
                _buildSection(
                  context,
                  'How is it Calculated?',
                  'WorkScore = 0.4 × MonthlyIncomeScore + 0.3 × StabilityScore + 0.3 × VerificationScore',
                  Icons.calculate,
                ),
                const SizedBox(height: 24),
                _buildSection(
                  context,
                  'Monthly Income Score',
                  'Based on your average monthly earnings. Higher consistent income leads to a better score.',
                  Icons.currency_rupee,
                ),
                const SizedBox(height: 24),
                _buildSection(
                  context,
                  'Stability Score',
                  'Measured by how many months you\'ve been actively working. Longer work history indicates stability.',
                  Icons.trending_up,
                ),
                const SizedBox(height: 24),
                _buildSection(
                  context,
                  'Verification Score',
                  'Percentage of your work entries that are verified with proof. Verified entries carry more weight.',
                  Icons.verified,
                ),
                const SizedBox(height: 24),
                _buildSection(
                  context,
                  'Risk Levels',
                  'Low Risk (70-100): Excellent creditworthiness\nMedium Risk (40-69): Moderate creditworthiness\nHigh Risk (<40): Needs improvement',
                  Icons.warning,
                ),
                const SizedBox(height: 24),
                _buildSection(
                  context,
                  'How Verification Works',
                  'When you add a work entry with proof (screenshot, receipt, etc.), it gets marked as "verified". Verified entries are more trusted and improve your score.',
                  Icons.verified_user,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    String content,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassmorphismCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.lightBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.primaryBlue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.displaySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

