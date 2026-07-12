import 'package:flutter/material.dart';
import 'focus_home_screen.dart';

class PermissionOnboardingScreen extends StatelessWidget {
  const PermissionOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text(
                'Permission setup',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'KUNST Launcher needs explicit Android permissions to manage focus mode, alarms, and planned tasks.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              const _PermissionCard(title: 'Device admin', description: 'Needed for app blocking and focus enforcement.'),
              const _PermissionCard(title: 'Calendar', description: 'Needed for syncing tasks with your calendar.'),
              const _PermissionCard(title: 'Notifications', description: 'Needed to filter social distractions.'),
              const Spacer(),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const FocusHomeScreen()),
                  );
                },
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  final String title;
  final String description;

  const _PermissionCard({required this.title, required this.description, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.security),
        title: Text(title),
        subtitle: Text(description),
      ),
    );
  }
}
