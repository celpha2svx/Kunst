import 'package:flutter/material.dart';
import '../services/database_service.dart';

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
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Theme'),
            subtitle: const Text('Dark mode is the current default.'),
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
