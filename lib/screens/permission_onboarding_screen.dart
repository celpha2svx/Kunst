import 'package:flutter/material.dart';
import '../services/platform_channel_service.dart';
import '../services/database_service.dart';
import 'focus_home_screen.dart';

class PermissionOnboardingScreen extends StatefulWidget {
  const PermissionOnboardingScreen({super.key});

  @override
  State<PermissionOnboardingScreen> createState() => _PermissionOnboardingScreenState();
}

class _PermissionOnboardingScreenState extends State<PermissionOnboardingScreen> {
  final PlatformChannelService _platformChannelService = PlatformChannelService();
  bool _saving = false;

  Future<void> _completePermissions(BuildContext context) async {
    final databaseService = DatabaseService();
    await databaseService.setSetting('first_launch_complete', '1');
    if (!context.mounted) {
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const FocusHomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
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
              _PermissionCard(
                title: 'Device admin',
                description: 'Needed for app blocking and focus enforcement.',
                actionLabel: 'Enable',
                onAction: () => _platformChannelService.requestDeviceAdmin(),
              ),
              _PermissionCard(
                title: 'Calendar',
                description: 'Needed for syncing tasks with your calendar.',
                actionLabel: 'Allow',
                onAction: () => _platformChannelService.requestCalendarPermissions(),
              ),
              _PermissionCard(
                title: 'Notifications',
                description: 'Needed to filter social distractions.',
                actionLabel: 'Open',
                onAction: () => _platformChannelService.openNotificationListenerSettings(),
              ),
              _PermissionCard(
                title: 'Usage access',
                description: 'Needed to detect app usage for timer enforcement.',
                actionLabel: 'Open',
                onAction: () => _platformChannelService.openUsageAccessSettings(),
              ),
              _PermissionCard(
                title: 'Exact alarms',
                description: 'Needed to wake the device for planned tasks.',
                actionLabel: 'Open',
                onAction: () => _platformChannelService.requestExactAlarmSettings(),
              ),
              _PermissionCard(
                title: 'Battery optimization',
                description: 'Needed so Samsung does not kill background services.',
                actionLabel: 'Open',
                onAction: () => _platformChannelService.requestIgnoreBatteryOptimizations(),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _saving ? null : () => _completePermissions(context),
                icon: const Icon(Icons.check_circle_outline),
                label: Text(_saving ? 'Saving...' : 'Continue'),
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
  final String actionLabel;
  final Future<bool> Function() onAction;

  const _PermissionCard({
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.security),
        title: Text(title),
        subtitle: Text(description),
        trailing: TextButton(
          onPressed: () => onAction(),
          child: Text(actionLabel),
        ),
      ),
    );
  }
}
