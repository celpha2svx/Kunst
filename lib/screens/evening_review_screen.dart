import 'package:flutter/material.dart';
import '../services/database_service.dart';

class EveningReviewScreen extends StatefulWidget {
  const EveningReviewScreen({super.key});

  @override
  State<EveningReviewScreen> createState() => _EveningReviewScreenState();
}

class _EveningReviewScreenState extends State<EveningReviewScreen> {
  final DatabaseService _databaseService = DatabaseService();
  String _summary = 'No review yet.';

  Future<void> _loadSummary() async {
    final settings = await _databaseService.getSetting('first_launch_complete', defaultValue: '0');
    setState(() {
      _summary = settings == '1' ? 'You have completed the day intentionally.' : 'Setup is still in progress.';
    });
  }

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Evening Review')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Review your day',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_summary),
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.home),
                label: const Text('Back to focus'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
