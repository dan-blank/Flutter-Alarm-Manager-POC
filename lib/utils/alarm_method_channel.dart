import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:flutter_alarm_manager_poc/hive/service/database_service.dart';

class AlarmMethodChannel {
  static const name = 'Flutter';
  static const platform = MethodChannel('com.example/alarm_manager');

  static Future<void> scheduleAlarm() async {
    try {
      await platform.invokeMethod('scheduleAlarm');
    } on PlatformException catch (e) {
      log("Failed to schedule alarm: '${e.message}'.");
    }
  }

  static void initialize() {
    platform.setMethodCallHandler(_handleMethodCall);
  }

  static Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'questionnaireFinished':
        // This single handler now manages all outcomes from the alarm screen.
        final args = call.arguments as Map<dynamic, dynamic>;
        final status = args['status'] as String?;

        log(name: name, 'Questionnaire finished with status: $status');

        if (status != null) {
          // The status string ("answered", "declined", "snoozed") is passed
          // directly to the database service for logging.
          await DatabaseService.instance.storeAlarmAction(status);
        } else {
          log(name: name, 'Questionnaire finished with null status.');
        }
      default:
        log('Unrecognized method ${call.method}');
    }
  }
}
