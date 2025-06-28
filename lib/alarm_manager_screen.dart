import 'package:flutter/material.dart';
import 'package:flutter_alarm_manager_poc/alarm_actions_screen.dart';
import 'package:flutter_alarm_manager_poc/services/export_service.dart';
import 'package:flutter_alarm_manager_poc/state/alarm_state_manager.dart';
import 'package:permission_handler/permission_handler.dart';

class AlarmManagerScreen extends StatefulWidget {
  const AlarmManagerScreen({super.key});

  @override
  State<AlarmManagerScreen> createState() => _AlarmManagerScreenState();
}

class _AlarmManagerScreenState extends State<AlarmManagerScreen> {
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

  @override
  Widget build(BuildContext context) {
    final exportService = ExportService();
    final alarmStateManager = AlarmStateManager.instance;

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
                      builder: (_) => const AlarmActionsScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.folder_open),
            tooltip: 'Change Export Path',
            onPressed: () => exportService.changeExportPath(context),
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Export Data',
            onPressed: () => exportService.exportData(context),
          )
        ],
      ),
      // The UI is now driven entirely by the state from the AlarmStateManager.
      body: StreamBuilder<AlarmState>(
        // Listen to the state stream.
        stream: alarmStateManager.state,
        // Provide the initial state to avoid a null snapshot on the first build.
        initialData: alarmStateManager.currentState,
        builder: (context, snapshot) {
          final state = snapshot.data;

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- UI for AlarmIdle state ---
                  if (state is AlarmIdle) ...[
                    const Text('Alarm cycle is not running.'),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        // The UI's only job is to request permission and
                        // then send an event to the state machine.
                        final granted = await _requestNotificationPermission();
                        if (granted) {
                          alarmStateManager.dispatch(CycleStarted());
                        }
                      },
                      child: const Text('Start Alarm Cycle'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange),
                      onPressed: () {
                        // The debug button simply sends a different event.
                        // The state machine handles the logic.
                        alarmStateManager.dispatch(DebugScheduleRequested());
                      },
                      child: const Text('Schedule debug alarm in 10 min'),
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
                        // The cancel button sends the appropriate event.
                        alarmStateManager.dispatch(CycleCancelled());
                      },
                      child: const Text('Cancel Alarm Cycle'),
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
