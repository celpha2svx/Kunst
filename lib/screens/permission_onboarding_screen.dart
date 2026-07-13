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
  final bool _saving = false;

  Future<void> _completePermissions(BuildContext context) async {
    final missing = await _checkMissingPermissions();
    if (missing.isEmpty) {
      final databaseService = DatabaseService();
      await databaseService.setSetting('first_launch_complete', '1');
      if (!context.mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const FocusHomeScreen()),
      );
      return;
    }

    if (!context.mounted) return;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Missing permissions'),
        content: SingleChildScrollView(
          child: ListBody(
            children: missing.map((m) => Text('• $m')).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _openMissingSettings(missing);
            },
            child: const Text('Open settings'),
          ),
        ],
      ),
    );
  }

  Future<List<String>> _checkMissingPermissions() async {
    final missing = <String>[];
    final deviceAdmin = await _platformChannelService.isDeviceAdminActive();
    if (!deviceAdmin) missing.add('Device admin');
    final calendar = await _platformChannelService.hasCalendarPermissions();
    if (!calendar) missing.add('Calendar');
    final notifications = await _platformChannelService.isNotificationListenerEnabled();
    if (!notifications) missing.add('Notifications');
    final usage = await _platformChannelService.isUsageAccessGranted();
    if (!usage) missing.add('Usage access');
    final exactAlarms = await _platformChannelService.canScheduleExactAlarms();
    if (!exactAlarms) missing.add('Exact alarms');
    final battery = await _platformChannelService.isIgnoringBatteryOptimizations();
    if (!battery) missing.add('Battery optimization');
    return missing;
  }

  void _openMissingSettings(List<String> missing) {
    for (final item in missing) {
      switch (item) {
        case 'Device admin':
          _platformChannelService.requestDeviceAdmin();
          break;
        case 'Calendar':
          _platformChannelService.requestCalendarPermissions();
          break;
        case 'Notifications':
          _platformChannelService.openNotificationListenerSettings();
          break;
        case 'Usage access':
          _platformChannelService.openUsageAccessSettings();
          break;
        case 'Exact alarms':
          _platformChannelService.requestExactAlarmSettings();
          break;
        case 'Battery optimization':
          _platformChannelService.requestIgnoreBatteryOptimizations();
          break;
      }
    }
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
