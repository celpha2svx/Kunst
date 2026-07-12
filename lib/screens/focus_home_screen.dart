import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
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
  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  List<Task> _tasks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
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
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await _databaseService.insertTask({
      'name': name,
      'description': _descriptionController.text.trim(),
      'world': 'Inner',
      'time_state': 'present',
      'type': 'immediate',
      'apps_needed': '[]',
      'date': today,
      'start_time': '09:00',
      'end_time': '10:00',
      'priority': 2,
      'status': 'pending',
    });
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
