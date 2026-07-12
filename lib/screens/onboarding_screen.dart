import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import 'focus_home_screen.dart';
import 'permission_onboarding_screen.dart';
import 'settings_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final TextEditingController _nameController = TextEditingController();
  final DatabaseService _databaseService = DatabaseService();
  bool _isSaving = false;

  Future<void> _completeSetup() async {
    setState(() => _isSaving = true);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await _databaseService.insertTask({
      'name': 'Plan your day',
      'description': 'Start with a simple intention for today.',
      'world': 'Inner',
      'time_state': 'present',
      'type': 'immediate',
      'apps_needed': '[]',
      'date': today,
      'start_time': '08:00',
      'end_time': '09:00',
      'priority': 2,
      'status': 'pending',
    });
    await _databaseService.setSetting('first_launch_complete', '1');
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const PermissionOnboardingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text(
                'KUNST Launcher',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'A personal launcher for focus, planning, and intentional living.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Your name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _isSaving ? null : _completeSetup,
                icon: const Icon(Icons.arrow_forward),
                label: Text(_isSaving ? 'Preparing...' : 'Begin setup'),
              ),
              const Spacer(),
              Text(
                'This first step creates the local database and prepares the launcher for your daily flow.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomePlaceholder extends StatelessWidget {
  const _HomePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KUNST Home'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => SettingsScreen()),
              );
            },
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: Center(
        child: Text(
          'Launcher foundation is ready.',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}
