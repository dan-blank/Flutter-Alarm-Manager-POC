import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:flutter_alarm_manager_poc/hive/service/database_service.dart';
import 'package:flutter_alarm_manager_poc/state/alarm_state_manager.dart';
import 'package:flutter_alarm_manager_poc/state/notification_behavior.dart';

class AlarmMethodChannel {
  static const name = 'Flutter';
  static const platform = MethodChannel('com.example/alarm_manager');

  static void initialize() {
    platform.setMethodCallHandler(_handleMethodCall);
  }

  // --- PUBLIC METHODS ---
  // These methods are now simple "bridges" to the native side.
  // They contain no business logic.

  /// Schedules a single alarm at the exact given time with the specified behavior.
  static Future<void> schedule(
      DateTime time, NotificationBehavior behavior) async {
    try {
      final timeInMillis = time.millisecondsSinceEpoch;
      log(
          name: name,
          'Scheduling alarm for $time with behavior ${behavior.name}');
      await platform.invokeMethod('scheduleAlarm',
          {'triggerTime': timeInMillis, 'behavior': behavior.name});
    } on PlatformException catch (e) {
      log(name: name, "Failed to schedule alarm: '${e.message}'.");
    }
  }

  /// Cancels the scheduled alarm.
  static Future<void> cancel() async {
    try {
      log(name: name, 'Cancelling alarm.');
      await platform.invokeMethod('cancelAlarm');
    } on PlatformException catch (e) {
      log(name: name, "Failed to cancel alarm: '${e.message}'.");
    }
  }

  // --- METHOD CALL HANDLER FROM NATIVE ---

  static Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'questionnaireFinished':
        final args = call.arguments as Map<dynamic, dynamic>;
        final status = args['status'] as String?;

        log(name: name, 'Questionnaire finished with status: $status');

        if (status != null) {
          // 1. Store the user's action (side-effect).
          final answerData = args['data'] as Map<dynamic, dynamic>?;
          final answers = answerData
              ?.map((key, value) => MapEntry(key.toString(), value as int));
          await DatabaseService.instance
              .storeAlarmAction(status, answers: answers);

          // 2. Convert the native string into our type-safe enum.
          final QuestionnaireResult result;
          switch (status) {
            case 'answered':
              result = QuestionnaireResult.answered;
            case 'declined':
              result = QuestionnaireResult.declined;
            case 'snoozed':
              result = QuestionnaireResult.snoozed;
            default:
              log(name: name, 'Unknown questionnaire status: $status');
              return; // Do nothing if status is unknown
          }

          // 3. Send an event to the state machine. The state machine decides what happens next.
          // This class no longer has any scheduling logic itself.
          AlarmStateManager.instance.dispatch(QuestionnaireFinished(result));
        } else {
          log(name: name, 'Questionnaire finished with null status.');
        }
      default:
        log('Unrecognized method ${call.method}');
    }
  }
}
