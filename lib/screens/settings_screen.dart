import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../services/database_service.dart';
import '../services/calendar_service.dart';
import '../widgets/theme_selector.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final CalendarService _calendarService = CalendarService();
  late Future<List<Map<String, Object?>>> _worldsFuture;
  late Future<List<Map<String, Object?>>> _calendarsFuture;

  @override
  void initState() {
    super.initState();
    _worldsFuture = _databaseService.getWorlds();
    _calendarsFuture = _calendarService.listWritableCalendars();
  }

  void _reloadWorlds() {
    setState(() {
      _worldsFuture = _databaseService.getWorlds();
    });
  }

  void _reloadCalendars() {
    setState(() {
      _calendarsFuture = _calendarService.listWritableCalendars();
    });
  }

  Future<void> _addWorld() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add world'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (shouldSave != true) {
      return;
    }

    final name = nameController.text.trim();
    if (name.isEmpty) {
      return;
    }

    await _databaseService.insertWorld({
      'name': name,
      'description': descriptionController.text.trim(),
      'color': '#1e1e1e',
      'icon': 'category',
      'sort_order': 99,
      'is_active': 1,
    });
    _reloadWorlds();
  }

  Future<void> _resetData(BuildContext context) async {
    await _databaseService.resetDatabase();
    _reloadWorlds();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Launcher data reset.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ThemeSelector(),
                const SizedBox(height: 16),
                Text(
                  'Focus Hours',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Start: ${context.watch<SettingsProvider>().focusStartTime}   End: ${context.watch<SettingsProvider>().focusEndTime}',
                ),
                const SizedBox(height: 16),
                Text(
                  'Sleep Hours',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Start: ${context.watch<SettingsProvider>().sleepStartTime}   End: ${context.watch<SettingsProvider>().sleepEndTime}',
                ),
                const SizedBox(height: 16),
                Text(
                  'Worlds',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                FutureBuilder<List<Map<String, Object?>>>(
                  future: _worldsFuture,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: CircularProgressIndicator(),
                      );
                    }

                    final worlds = snapshot.data!;
                    return Column(
                      children: worlds
                          .map(
                            (world) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.circle_outlined),
                              title: Text(world['name']?.toString() ?? ''),
                              subtitle: Text(world['description']?.toString() ?? ''),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _addWorld,
                    icon: const Icon(Icons.add),
                    label: const Text('Add world'),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Calendar Sync',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                FutureBuilder<List<Map<String, Object?>>>(
                  future: _calendarsFuture,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: CircularProgressIndicator(),
                      );
                    }

                    final calendars = snapshot.data!;
                    final settings = context.watch<SettingsProvider>();
                    return DropdownButtonFormField<String>(
                      value: settings.calendarId.isEmpty ? null : settings.calendarId,
                      items: calendars
                          .map(
                            (calendar) => DropdownMenuItem<String>(
                              value: calendar['id']?.toString(),
                              child: Text(calendar['name']?.toString() ?? 'Calendar'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        context.read<SettingsProvider>().setCalendarId(value);
                      },
                      decoration: const InputDecoration(
                        labelText: 'Choose calendar',
                        border: OutlineInputBorder(),
                      ),
                    );
                  },
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _reloadCalendars,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh calendars'),
                  ),
                ),
              ],
            ),
          ),
          const ListTile(
            leading: Icon(Icons.access_time),
            title: Text('Focus Hours'),
            subtitle: Text('Morning planning and evening review are enabled.'),
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('Reset data'),
            subtitle: const Text('Clear local tasks and settings'),
            onTap: () => _resetData(context),
          ),
        ],
      ),
    );
  }
}
