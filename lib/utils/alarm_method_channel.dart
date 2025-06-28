import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:flutter_alarm_manager_poc/hive/service/database_service.dart';

class AlarmMethodChannel {
  static const name = 'Flutter';
  static const platform = MethodChannel('com.example/alarm_manager');

  static void initialize() {
    platform.setMethodCallHandler(_handleMethodCall);
  }

  // --- PRIVATE SCHEDULING METHOD ---
  // This is the single point of contact with the native side for scheduling.
  static Future<void> _scheduleAlarm(int timeInMillis) async {
    try {
      log(
          name: name,
          'Scheduling alarm for ${DateTime.fromMillisecondsSinceEpoch(timeInMillis)}');
      // Pass the exact time to the native method.
      await platform
          .invokeMethod('scheduleAlarm', {'triggerTime': timeInMillis});
    } on PlatformException catch (e) {
      log(name: name, "Failed to schedule alarm: '${e.message}'.");
    }
  }

  // --- PUBLIC LOGIC-BASED SCHEDULING METHODS ---

  /// Schedules the very first alarm or the next one after an answer/decline.
  /// This adheres to the 8-20h hourly constraint.
  static Future<int> scheduleToNextWholeInterval() async {
    final triggerTime = _calculateNextWholeIntervalTime();
    await _scheduleAlarm(triggerTime.millisecondsSinceEpoch);
    return triggerTime.millisecondsSinceEpoch;
  }

  /// Schedules an alarm 15 minutes from now.
  static Future<void> scheduleToNextSnoozeInterval() async {
    final triggerTime = _calculateSnoozeTime();
    await _scheduleAlarm(triggerTime.millisecondsSinceEpoch);
  }

  // --- TIME CALCULATION LOGIC ---

  /// Calculates the next valid hourly slot between 8:00 and 20:00.
  static DateTime _calculateNextWholeIntervalTime() {
    final now = DateTime.now();
    DateTime nextAlarmTime;

    // Case 1: It's 8 PM or later. Schedule for 8 AM tomorrow.
    if (now.hour >= 23) {
      nextAlarmTime = DateTime(now.year, now.month, now.day + 1, 8);
    }
    // Case 2: It's before 8 AM. Schedule for 8 AM today.
    else if (now.hour < 8) {
      nextAlarmTime = DateTime(now.year, now.month, now.day, 8);
    }
    // Case 3: It's during the active window (8:00 - 19:59). Schedule for the next hour.
    else {
      nextAlarmTime = DateTime(now.year, now.month, now.day, now.hour + 1);
    }

    // Return a time with 0 minutes, 0 seconds for precision.
    return DateTime(nextAlarmTime.year, nextAlarmTime.month, nextAlarmTime.day,
        nextAlarmTime.hour);
  }

  /// Calculates the snooze time (15 minutes from now).
  static DateTime _calculateSnoozeTime() {
    return DateTime.now().add(const Duration(minutes: 15));
  }

  // --- METHOD CALL HANDLER FROM NATIVE ---

  static Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'questionnaireFinished':
        final args = call.arguments as Map<dynamic, dynamic>;
        final status = args['status'] as String?;

        log(name: name, 'Questionnaire finished with status: $status');

        if (status != null) {
          // 1. Store the user's action
          switch (status) {
            case 'answered':
              final answerData = args['data'] as Map<dynamic, dynamic>?;
              // Safely cast to the expected type for Hive.
              final answers = answerData
                  ?.map((key, value) => MapEntry(key.toString(), value as int));
              await DatabaseService.instance
                  .storeAlarmAction(status, answers: answers);
              await scheduleToNextWholeInterval();
            case 'declined':
              await DatabaseService.instance.storeAlarmAction(status);
              await scheduleToNextWholeInterval();
            case 'snoozed':
              await DatabaseService.instance.storeAlarmAction(status);
              await scheduleToNextSnoozeInterval();
          }
        } else {
          log(name: name, 'Questionnaire finished with null status.');
        }
      default:
        log('Unrecognized method ${call.method}');
    }
  }
}
