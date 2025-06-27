import 'package:flutter/material.dart';
import 'package:flutter_alarm_manager_poc/alarm_actions_screen.dart';
import 'package:flutter_alarm_manager_poc/services/export_service.dart';
import 'package:flutter_alarm_manager_poc/utils/alarm_method_channel.dart';
import 'package:permission_handler/permission_handler.dart';

class AlarmManagerScreen extends StatelessWidget {
  const AlarmManagerScreen({super.key});

  Future<void> _requestNotificationPermission(BuildContext context) async {
    // get a reference to the ScaffoldMessenger before calling async method
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final status = await Permission.notification.request();

    if (status.isGranted) {
      // This now correctly calculates the first alarm time and schedules it.
      final triggerTime =
          await AlarmMethodChannel.scheduleToNextWholeInterval();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Alarm cycle started, next alarm at $triggerTime'),
        ),
      );
    } else {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content:
              Text('Notification permission is required to schedule alarms.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Instantiate the service
    final exportService = ExportService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alarm Manager Screen'),
        centerTitle: true,
        actions: [
          // View saved data button
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
          // Change Export Path button
          IconButton(
            icon: const Icon(Icons.folder_open),
            tooltip: 'Change Export Path',
            onPressed: () {
              exportService.changeExportPath(context);
            },
          ),
          // Export button
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Export Data',
            onPressed: () {
              exportService.exportData(context);
            },
          )
        ],
      ),
      body: Center(
        child: ElevatedButton(
            onPressed: () async {
              // The _requestNotificationPermission should now call the method that
              // starts the entire alarm cycle.
              await _requestNotificationPermission(context);
            },
            child: const Text('Start Alarm Cycle')),
      ),
    );
  }
}
