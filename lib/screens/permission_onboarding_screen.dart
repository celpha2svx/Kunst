import 'package:flutter/material.dart';
import '../services/platform_channel_service.dart';
import '../services/database_service.dart';
import 'focus_home_screen.dart';

class PermissionOnboardingScreen extends StatefulWidget {
  const PermissionOnboardingScreen({super.key});

  @override
  State<PermissionOnboardingScreen> createState() => _PermissionOnboardingScreenState();
}

class _PermissionOnboardingScreenState extends State<PermissionOnboardingScreen> with WidgetsBindingObserver {
  final PlatformChannelService _platformChannelService = PlatformChannelService();
  bool _saving = false;
  bool _loadingStatus = true;

  final Map<String, bool> _status = {
    'Device admin': false,
    'Calendar': false,
    'Notifications': false,
    'Usage access': false,
    'Exact alarms': false,
    'Battery optimization': false,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshStatus();
    }
  }

  Future<void> _refreshStatus() async {
    if (!mounted) return;
    setState(() => _loadingStatus = true);
    final deviceAdmin = await _platformChannelService.isDeviceAdminActive();
    final calendar = await _platformChannelService.hasCalendarPermissions();
    final notifications = await _platformChannelService.isNotificationListenerEnabled();
    final usage = await _platformChannelService.isUsageAccessGranted();
    final exactAlarms = await _platformChannelService.canScheduleExactAlarms();
    final battery = await _platformChannelService.isIgnoringBatteryOptimizations();
    if (!mounted) return;
    setState(() {
      _status['Device admin'] = deviceAdmin;
      _status['Calendar'] = calendar;
      _status['Notifications'] = notifications;
      _status['Usage access'] = usage;
      _status['Exact alarms'] = exactAlarms;
      _status['Battery optimization'] = battery;
      _loadingStatus = false;
    });
  }

  Future<void> _completePermissions(BuildContext context) async {
    setState(() => _saving = true);
    await _refreshStatus();
    final missing = _status.entries.where((e) => !e.value).map((e) => e.key).toList();
    setState(() => _saving = false);

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
              Expanded(
                child: _loadingStatus
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        children: [
                          _PermissionCard(
                            title: 'Device admin',
                            description: 'Needed for app blocking and focus enforcement.',
                            actionLabel: 'Enable',
                            granted: _status['Device admin'] ?? false,
                            onAction: () async {
                              await _platformChannelService.requestDeviceAdmin();
                            },
                          ),
                          _PermissionCard(
                            title: 'Calendar',
                            description: 'Needed for syncing tasks with your calendar.',
                            actionLabel: 'Allow',
                            granted: _status['Calendar'] ?? false,
                            onAction: () async {
                              await _platformChannelService.requestCalendarPermissions();
                              await _refreshStatus();
                            },
                          ),
                          _PermissionCard(
                            title: 'Notifications',
                            description: 'Needed to filter social distractions.',
                            actionLabel: 'Open',
                            granted: _status['Notifications'] ?? false,
                            onAction: () async {
                              await _platformChannelService.openNotificationListenerSettings();
                            },
                          ),
                          _PermissionCard(
                            title: 'Usage access',
                            description: 'Needed to detect app usage for timer enforcement.',
                            actionLabel: 'Open',
                            granted: _status['Usage access'] ?? false,
                            onAction: () async {
                              await _platformChannelService.openUsageAccessSettings();
                            },
                          ),
                          _PermissionCard(
                            title: 'Exact alarms',
                            description: 'Needed to wake the device for planned tasks.',
                            actionLabel: 'Open',
                            granted: _status['Exact alarms'] ?? false,
                            onAction: () async {
                              await _platformChannelService.requestExactAlarmSettings();
                            },
                          ),
                          _PermissionCard(
                            title: 'Battery optimization',
                            description: 'Needed so Samsung does not kill background services.',
                            actionLabel: 'Open',
                            granted: _status['Battery optimization'] ?? false,
                            onAction: () async {
                              await _platformChannelService.requestIgnoreBatteryOptimizations();
                            },
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _saving ? null : () => _completePermissions(context),
                icon: const Icon(Icons.check_circle_outline),
                label: Text(_saving ? 'Checking...' : 'Continue'),
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
  final bool granted;
  final Future<void> Function() onAction;

  const _PermissionCard({
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.granted,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          granted ? Icons.check_circle : Icons.security,
          color: granted ? Colors.green : null,
        ),
        title: Text(title),
        subtitle: Text(description),
        trailing: granted
            ? const Text('Granted', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
            : TextButton(
                onPressed: () => onAction(),
                child: Text(actionLabel),
              ),
      ),
    );
  }
}
