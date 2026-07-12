import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../services/database_service.dart';
import '../widgets/theme_selector.dart';

class SettingsScreen extends StatelessWidget {
  SettingsScreen({super.key});

  final DatabaseService _databaseService = DatabaseService();

  Future<void> _resetData(BuildContext context) async {
    await _databaseService.resetDatabase();
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
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Focus Hours'),
            subtitle: const Text('Morning planning and evening review are enabled.'),
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
