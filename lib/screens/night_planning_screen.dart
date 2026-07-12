import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';

class NightPlanningScreen extends StatefulWidget {
  const NightPlanningScreen({super.key});

  @override
  State<NightPlanningScreen> createState() => _NightPlanningScreenState();
}

class _NightPlanningScreenState extends State<NightPlanningScreen> {
  final TextEditingController _noteController = TextEditingController();
  final DatabaseService _databaseService = DatabaseService();
  bool _saving = false;

  Future<void> _savePlan() async {
    setState(() => _saving = true);
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final date = DateFormat('yyyy-MM-dd').format(tomorrow);
    await _databaseService.insertTask({
      'name': 'Night plan saved',
      'description': _noteController.text.trim(),
      'world': 'Future',
      'time_state': 'present',
      'type': 'project',
      'apps_needed': '[]',
      'date': date,
      'start_time': '08:00',
      'end_time': '09:00',
      'priority': 3,
      'status': 'pending',
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Plan saved for tomorrow.')),
    );
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Night Planning')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                'Plan tomorrow with intention.',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                maxLines: 8,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Write your plan, intention, or next actions...',
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _saving ? null : _savePlan,
                icon: const Icon(Icons.bedtime),
                label: Text(_saving ? 'Saving...' : 'Save plan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
