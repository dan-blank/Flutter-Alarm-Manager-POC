import 'package:flutter/material.dart';
import 'package:flutter_alarm_manager_poc/alarm_manager_screen.dart';
import 'package:flutter_alarm_manager_poc/hive/service/database_service.dart';
import 'package:flutter_alarm_manager_poc/hive/service/settings_service.dart';
import 'package:flutter_alarm_manager_poc/state/alarm_state_manager.dart';
import 'package:flutter_alarm_manager_poc/utils/alarm_method_channel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.instance.initializeHive();
  await SettingsService.instance.initializeHive();
  AlarmMethodChannel.initialize();

  // --- The "Interpreter" ---
  // This logic listens to state changes from the central "brain" and
  // performs side-effects, like calling native code. This cleanly separates
  // state management from platform-specific actions.
  final alarmStateManager = AlarmStateManager.instance;

  alarmStateManager.state.listen((state) async {
    switch (state) {
      case AlarmActive(scheduledAt: final time, behavior: final behavior):
        // When the state becomes active, get the current notification setting
        // and schedule the alarm on the native side.
        await AlarmMethodChannel.schedule(time, behavior);
      case AlarmIdle():
        // When the state becomes idle, cancel any existing native alarm.
        await AlarmMethodChannel.cancel();
    }
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Demo',
        themeMode: ThemeMode.dark,
        darkTheme: ThemeData(
          brightness: Brightness.dark,
        ),
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const AlarmManagerScreen());
  }
}
