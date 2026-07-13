import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/settings_provider.dart';
import '../services/calendar_service.dart';
import '../services/database_service.dart';
import 'evening_review_screen.dart';
import 'night_planning_screen.dart';

class FocusHomeScreen extends StatefulWidget {
  const FocusHomeScreen({super.key});

  @override
  State<FocusHomeScreen> createState() => _FocusHomeScreenState();
}

class _FocusHomeScreenState extends State<FocusHomeScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final CalendarService _calendarService = CalendarService();
  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedWorld = 'Inner';
  List<String> _worldNames = const ['Inner', 'Outside', 'Future'];
  List<Task> _tasks = [];
  bool _loading = true;
  bool _loadingWorlds = true;

  @override
  void initState() {
    super.initState();
    _loadWorlds();
    _loadTasks();
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
      _loadingWorlds = false;
    });
  }

  Future<void> _loadTasks() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final rows = await _databaseService.getTasksForDate(today);
    setState(() {
      _tasks = rows.map(Task.fromMap).toList();
      _loading = false;
    });
  }

  Future<void> _addTask() async {
    final name = _taskController.text.trim();
    if (name.isEmpty) {
      return;
    }
    final calendarIdRaw = context.read<SettingsProvider>().calendarId;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final taskId = await _databaseService.insertTask({
      'name': name,
      'description': _descriptionController.text.trim(),
      'world': _selectedWorld,
      'time_state': 'present',
      'type': 'immediate',
      'apps_needed': '[]',
      'date': today,
      'start_time': '09:00',
      'end_time': '10:00',
      'priority': 2,
      'status': 'pending',
    });
    final task = Task(
      id: taskId,
      name: name,
      description: _descriptionController.text.trim(),
      world: _selectedWorld,
      timeState: 'present',
      type: 'immediate',
      appsNeeded: const [],
      date: today,
      startTime: '09:00',
      endTime: '10:00',
      priority: 2,
      status: 'pending',
    );
    final eventId = await _calendarService.syncTask(
      task,
      calendarId: int.tryParse(calendarIdRaw),
    );
    if (eventId > 0) {
      await _databaseService.updateTask(taskId, {'calendar_event_id': eventId.toString()});
    }
    _taskController.clear();
    _descriptionController.clear();
    await _loadTasks();
  }

  Future<void> _toggleTask(Task task) async {
    final newStatus = task.status == 'completed' ? 'pending' : 'completed';
    await _databaseService.updateTask(task.id!, {'status': newStatus});
    await _loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus Home'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NightPlanningScreen()),
              );
            },
            icon: const Icon(Icons.nights_stay),
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EveningReviewScreen()),
              );
            },
            icon: const Icon(Icons.rate_review),
          ),
          IconButton(
            onPressed: _loadTasks,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Today',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat('EEEE, MMMM d').format(DateTime.now()),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      TextField(
                        controller: _taskController,
                        decoration: const InputDecoration(
                          labelText: 'Add a task',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Notes',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedWorld,
                        items: _worldNames
                            .map((world) => DropdownMenuItem<String>(
                                  value: world,
                                  child: Text(world),
                                ))
                            .toList(),
                        onChanged: _loadingWorlds
                            ? null
                            : (value) {
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
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          onPressed: _addTask,
                          icon: const Icon(Icons.add),
                          label: const Text('Add'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: _tasks.length,
                        itemBuilder: (context, index) {
                          final task = _tasks[index];
                          return CheckboxListTile(
                            value: task.status == 'completed',
                            title: Text(task.name),
                            subtitle: task.description.isNotEmpty ? Text(task.description) : null,
                            secondary: const Icon(Icons.check_circle_outline),
                            onChanged: (_) => _toggleTask(task),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
