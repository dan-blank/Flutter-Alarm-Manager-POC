import 'package:flutter/material.dart';
import 'package:flutter_alarm_manager_poc/alarm_actions_screen.dart';
import 'package:flutter_alarm_manager_poc/hive/service/settings_service.dart';
import 'package:flutter_alarm_manager_poc/services/export_service.dart';
import 'package:flutter_alarm_manager_poc/state/alarm_state_manager.dart';
import 'package:flutter_alarm_manager_poc/state/notification_behavior.dart';
import 'package:permission_handler/permission_handler.dart';

class AlarmManagerScreen extends StatefulWidget {
  const AlarmManagerScreen({super.key});

  @override
  State<AlarmManagerScreen> createState() => _AlarmManagerScreenState();
}

class _AlarmManagerScreenState extends State<AlarmManagerScreen> {
  final _exportService = ExportService();
  final AlarmStateManager alarmStateManager = AlarmStateManager.instance;
  late NotificationBehavior _currentBehavior;

  @override
  void initState() {
    super.initState();
    _currentBehavior = SettingsService.instance.getNotificationBehavior();
  }

  Future<bool> _requestNotificationPermission() async {
    final status = await Permission.notification.request();
    if (!mounted) return false;

    if (status.isGranted) {
      return true;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Notification permission is required to schedule alarms.'),
        ),
      );
      return false;
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _changeExportPath() async {
    final result = await _exportService.changeExportPath();
    _showSnackBar(result.message);
  }

  Future<void> _exportData() async {
    final result = await _exportService.exportData();
    _showSnackBar(result.message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alarm Manager POC'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'View Stored Data',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<AlarmActionsScreen>(
                    builder: (_) => const AlarmActionsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.folder_open),
            tooltip: 'Change Export Path',
            onPressed: _changeExportPath,
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Export Data',
            onPressed: _exportData,
          )
        ],
      ),
      body: StreamBuilder<AlarmState>(
        stream: alarmStateManager.state,
        initialData: alarmStateManager.currentState,
        builder: (context, snapshot) {
          final state = snapshot.data;

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- Notification Behavior Dropdown (always visible) ---
                  DropdownButtonFormField<NotificationBehavior>(
                    value: _currentBehavior,
                    decoration: const InputDecoration(
                      labelText: 'Notification Type',
                      border: OutlineInputBorder(),
                    ),
                    items: NotificationBehavior.values
                        .map((behavior) => DropdownMenuItem(
                              value: behavior,
                              child: Text(behavior.name),
                            ))
                        .toList(),
                    onChanged: (newValue) async {
                      if (newValue != null) {
                        // 1. Persist the new setting
                        await SettingsService.instance
                            .setNotificationBehavior(newValue);
                        // 2. Update the local UI state
                        setState(() {
                          _currentBehavior = newValue;
                        });
                        // 3. If a cycle is active, dispatch an event to update it
                        if (alarmStateManager.currentState is AlarmActive) {
                          alarmStateManager
                              .dispatch(NotificationBehaviorChanged(newValue));
                        }
                        _showSnackBar(
                            'Notification type set to ${newValue.name}');
                      }
                    },
                  ),
                  const SizedBox(height: 20),

                  // --- UI for AlarmIdle state ---
                  if (state is AlarmIdle) ...[
                    const Text('Alarm cycle is not running.'),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        final granted = await _requestNotificationPermission();
                        if (granted) {
                          alarmStateManager.dispatch(CycleStarted());
                        }
                      },
                      child: const Text('Start Alarm Cycle'),
                    ),
                  ],

                  // --- UI for AlarmActive state ---
                  if (state is AlarmActive) ...[
                    Text(
                      'Alarm cycle is active.',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 10),
                    Text('Next alarm at: ${state.scheduledAt.toLocal()}'),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () {
                        alarmStateManager.dispatch(CycleCancelled());
                      },
                      child: const Text('Cancel Alarm Cycle'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange),
                      onPressed: () {
                        alarmStateManager.dispatch(DebugScheduleRequested());
                      },
                      child: const Text('Schedule debug alarm in 10 sec'),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
