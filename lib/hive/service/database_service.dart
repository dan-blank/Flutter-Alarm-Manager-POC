import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter_alarm_manager_poc/hive/models/alarm_action.dart';
import 'package:flutter_alarm_manager_poc/hive/models/alarm_action_type.dart';
import 'package:hive_flutter/hive_flutter.dart';

class DatabaseService {
  // Private constructor
  DatabaseService._();

  static final DatabaseService _instance = DatabaseService._();

  static DatabaseService get instance => _instance;

  static const String alarmBoxName = 'alarm_actions';
  late Box<AlarmAction> _alarmBox;

  ValueListenable<Box<AlarmAction>> get alarmBoxListenable =>
      _alarmBox.listenable();

  // Initialize Hive and open the alarm actions box
  Future<void> initializeHive() async {
    try {
      await Hive.initFlutter();
      Hive
        ..registerAdapter(AlarmActionAdapter())
        ..registerAdapter(AlarmActionTypeAdapter());
      _alarmBox = await Hive.openBox<AlarmAction>(alarmBoxName);
      log('Hive initialized and box opened successfully.');
    } on Exception catch (e) {
      log('Failed to initialize Hive or open box: $e');
    }
  }

  // Add an alarm action to the Hive box
  Future<void> storeAlarmAction(AlarmActionType actionType,
      {Map<String, dynamic>? answers}) async {
    try {
      await _alarmBox.add(
        AlarmAction(
          actionType,
          DateTime.now().millisecondsSinceEpoch,
          answers,
        ),
      );
      log('Stored alarm action: ${actionType.name} with answers: $answers');

      final actions = getAllAlarmActions();
      log('Retrieved ${actions.length} alarm actions.');
    } on Exception catch (e) {
      log('Failed to store alarm action: $e');
    }
  }

  // Retrieve all alarm actions from the Hive box
  List<AlarmAction> getAllAlarmActions() {
    try {
      final actions = _alarmBox.values;
      log('Retrieved ${actions.length} alarm actions.');
      return actions.toList();
    } on Exception catch (e) {
      log('Failed to retrieve alarm actions: $e');
      return [];
    }
  }

  Map<dynamic, AlarmAction> getAllAlarmActionsMap() {
    try {
      final actionsMap = _alarmBox.toMap();
      log('Retrieved ${actionsMap.length} alarm actions as a map.');
      return actionsMap;
    } on Exception catch (e) {
      log('Failed to retrieve alarm actions map: $e');
      return {};
    }
  }

  // Clear all alarm actions (if needed)
  Future<void> clearAllAlarmActions() async {
    try {
      await _alarmBox.clear();
      log('All alarm actions cleared.');
    } on Exception catch (e) {
      log('Failed to clear alarm actions: $e');
    }
  }
}
