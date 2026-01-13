import 'package:flutter/material.dart';
import 'package:workpass/theme/app_theme.dart';
import 'package:workpass/screens/worker/work_score_screen.dart';
import 'package:workpass/screens/worker/transparency_screen.dart';
import 'package:workpass/screens/worker/add_work_entry_screen.dart';
import 'package:workpass/screens/worker/work_history_screen.dart';

class WorkPassAssistant extends StatefulWidget {
  final String userId;

  const WorkPassAssistant({super.key, required this.userId});

  @override
  State<WorkPassAssistant> createState() => _WorkPassAssistantState();
}

class _WorkPassAssistantState extends State<WorkPassAssistant> {
  bool _isExpanded = false;

  final List<AssistantIntent> _intents = [
    AssistantIntent(
      question: 'What is WorkScore?',
      answer: 'WorkScore is your creditworthiness metric based on work history, income stability, and verification.',
      action: 'navigate_to_score',
    ),
    AssistantIntent(
      question: 'How does verification work?',
      answer: 'When you add work entries with proof (screenshots, receipts), they are marked as verified and improve your score.',
      action: 'navigate_to_transparency',
    ),
    AssistantIntent(
      question: 'Where can I find my income?',
      answer: 'Your income is displayed on the dashboard and in the Work History section.',
      action: 'navigate_to_history',
    ),
    AssistantIntent(
      question: 'How do I add work?',
      answer: 'Tap the "Add Work" button on your dashboard, fill in the details, and optionally upload proof.',
      action: 'navigate_to_add_work',
    ),
    AssistantIntent(
      question: 'What does risk level mean?',
      answer: 'Risk level indicates your creditworthiness: Low Risk (70-100), Medium Risk (40-69), High Risk (<40).',
      action: 'navigate_to_score',
    ),
  ];

  void _handleIntent(AssistantIntent intent, BuildContext context) {
    setState(() {
      _isExpanded = false;
    });

    switch (intent.action) {
      case 'navigate_to_score':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => WorkScoreScreen(userId: widget.userId),
          ),
        );
        break;
      case 'navigate_to_transparency':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const TransparencyScreen(),
          ),
        );
        break;
      case 'navigate_to_history':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => WorkHistoryScreen(userId: widget.userId),
          ),
        );
        break;
      case 'navigate_to_add_work':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AddWorkEntryScreen(userId: widget.userId),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 80,
      right: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_isExpanded)
            Container(
              width: 300,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: AppTheme.glassmorphismCard(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.smart_toy, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'WorkPass Assistant',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 20),
                          onPressed: () {
                            setState(() {
                              _isExpanded = false;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: _intents.length,
                    itemBuilder: (context, index) {
                      final intent = _intents[index];
                      return InkWell(
                        onTap: () => _handleIntent(intent, context),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                intent.question,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                intent.answer,
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          FloatingActionButton(
            onPressed: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            backgroundColor: AppTheme.primaryBlue,
            child: Icon(
              _isExpanded ? Icons.close : Icons.chat_bubble_outline,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class AssistantIntent {
  final String question;
  final String answer;
  final String action;

  AssistantIntent({
    required this.question,
    required this.answer,
    required this.action,
  });
}

