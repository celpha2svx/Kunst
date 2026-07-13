import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/settings_provider.dart';
import '../services/database_service.dart';
import '../services/calendar_service.dart';

class NightPlanningScreen extends StatefulWidget {
  const NightPlanningScreen({super.key});

  @override
  State<NightPlanningScreen> createState() => _NightPlanningScreenState();
}

class _NightPlanningScreenState extends State<NightPlanningScreen> {
  final TextEditingController _noteController = TextEditingController();
  final DatabaseService _databaseService = DatabaseService();
  final CalendarService _calendarService = CalendarService();
  String _selectedWorld = 'Future';
  List<String> _worldNames = const ['Inner', 'Outside', 'Future'];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadWorlds();
  }

  Future<void> _loadWorlds() async {
    final worlds = await _databaseService.getWorlds();
    if (!mounted) {
      return;
    }
    setState(() {
      _worldNames = worlds
          .map((world) => world['name']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .toList();
      if (_worldNames.isNotEmpty && !_worldNames.contains(_selectedWorld)) {
        _selectedWorld = _worldNames.first;
      }
    });
  }

  Future<void> _savePlan() async {
    setState(() => _saving = true);
    final calendarIdRaw = context.read<SettingsProvider>().calendarId;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final date = DateFormat('yyyy-MM-dd').format(tomorrow);
    final taskId = await _databaseService.insertTask({
      'name': 'Night plan saved',
      'description': _noteController.text.trim(),
      'world': _selectedWorld,
      'time_state': 'present',
      'type': 'project',
      'apps_needed': '[]',
      'date': date,
      'start_time': '08:00',
      'end_time': '09:00',
      'priority': 3,
      'status': 'pending',
    });
    final task = Task(
      id: taskId,
      name: 'Night plan saved',
      description: _noteController.text.trim(),
      world: _selectedWorld,
      timeState: 'present',
      type: 'project',
      appsNeeded: const [],
      date: date,
      startTime: '08:00',
      endTime: '09:00',
      priority: 3,
      status: 'pending',
    );
    final eventId = await _calendarService.syncTask(
      task,
      calendarId: int.tryParse(calendarIdRaw),
    );
    if (eventId > 0) {
      await _databaseService.updateTask(taskId, {'calendar_event_id': eventId.toString()});
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Plan saved for tomorrow and calendar sync attempted.')),
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
              DropdownButtonFormField<String>(
                value: _selectedWorld,
                items: _worldNames
                    .map((world) => DropdownMenuItem<String>(
                          value: world,
                          child: Text(world),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _selectedWorld = value;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'World',
                  border: OutlineInputBorder(),
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
