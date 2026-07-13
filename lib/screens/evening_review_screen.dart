import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../services/database_service.dart';
import '../services/notification_queue_service.dart';

class EveningReviewScreen extends StatefulWidget {
  const EveningReviewScreen({super.key});

  @override
  State<EveningReviewScreen> createState() => _EveningReviewScreenState();
}

class _EveningReviewScreenState extends State<EveningReviewScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final NotificationQueueService _notificationQueueService = NotificationQueueService();
  List<Task> _tasks = [];
  List<Map<String, Object?>> _queuedNotifications = [];
  bool _loading = true;
  bool _loadingQueuedNotifications = true;

  Future<void> _loadSummary() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final rows = await _databaseService.getTasksForDate(today);
    final queued = await _notificationQueueService.loadQueuedNotifications();
    setState(() {
      _tasks = rows.map(Task.fromMap).toList();
      _queuedNotifications = queued;
      _loading = false;
      _loadingQueuedNotifications = false;
    });
  }

  Future<void> _clearQueuedNotifications() async {
    await _notificationQueueService.clearQueuedNotifications();
    if (!mounted) {
      return;
    }
    setState(() {
      _queuedNotifications = [];
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
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Planned: ${_tasks.length} task${_tasks.length == 1 ? '' : 's'} today.',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Queued notifications',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (_loadingQueuedNotifications)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: LinearProgressIndicator(),
                  )
                else if (_queuedNotifications.isEmpty)
                  const Text('No queued notifications.'),
                if (_queuedNotifications.isNotEmpty)
                  Expanded(
                    child: ListView.builder(
                      itemCount: _queuedNotifications.length,
                      itemBuilder: (context, index) {
                        final item = _queuedNotifications[index];
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.notifications_off),
                            title: Text(item['title']?.toString() ?? 'Notification'),
                            subtitle: Text(item['text']?.toString() ?? item['packageName']?.toString() ?? ''),
                          ),
                        );
                      },
                    ),
                  ),
                if (_queuedNotifications.isNotEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _clearQueuedNotifications,
                      icon: const Icon(Icons.clear_all),
                      label: const Text('Clear queued notifications'),
                    ),
                  ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: _tasks.length,
                    itemBuilder: (context, index) {
                      final task = _tasks[index];
                      return Card(
                        child: ListTile(
                          leading: Icon(
                            task.status == 'completed' ? Icons.check_circle : Icons.radio_button_unchecked,
                          ),
                          title: Text(task.name),
                          subtitle: Text('${task.world} • ${task.status}'),
                        ),
                      );
                    },
                  ),
                ),
              ],
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
