import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_alarm_manager_poc/hive/service/settings_service.dart';
import 'package:flutter_alarm_manager_poc/state/notification_behavior.dart';

// --- STATES ---
sealed class AlarmState {}

final class AlarmIdle extends AlarmState {}

@immutable
final class AlarmActive extends AlarmState {
  AlarmActive({required this.scheduledAt, required this.behavior});
  final DateTime scheduledAt;
  final NotificationBehavior behavior;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlarmActive &&
          runtimeType == other.runtimeType &&
          scheduledAt == other.scheduledAt &&
          behavior == other.behavior;

  @override
  int get hashCode => scheduledAt.hashCode ^ behavior.hashCode;
}

// --- EVENTS ---
// These are all the possible actions that can trigger a state change.
sealed class AlarmEvent {}

final class CycleStarted extends AlarmEvent {}

final class CycleCancelled extends AlarmEvent {}

final class QuestionnaireFinished extends AlarmEvent {
  QuestionnaireFinished(this.result);
  final QuestionnaireResult result;
}

final class DebugScheduleRequested extends AlarmEvent {}

// New event to handle behavior changes.
final class NotificationBehaviorChanged extends AlarmEvent {
  NotificationBehaviorChanged(this.newBehavior);
  final NotificationBehavior newBehavior;
}

enum QuestionnaireResult { answered, declined, snoozed }

// --- THE STATE MACHINE ("BRAIN") ---
class AlarmStateManager {
  // Singleton pattern for easy global access.
  AlarmStateManager._();
  static final AlarmStateManager instance = AlarmStateManager._();

  // The initial state of the application.
  AlarmState _state = AlarmIdle();
  final _controller = StreamController<AlarmState>.broadcast();

  Stream<AlarmState> get state => _controller.stream;
  AlarmState get currentState => _state;

  void dispatch(AlarmEvent event) {
    log('Dispatching event: ${event.runtimeType} from state: ${_state.runtimeType}');
    final newState = _reduce(_state, event);

    if (newState != _state) {
      _state = newState;
      _controller.add(_state);
    }
  }

  // The "reducer" function contains all the transition logic.
  // It's a pure function: given a state and an event, it returns a new state.
  AlarmState _reduce(AlarmState currentState, AlarmEvent event) {
    // Helper to get the current notification setting.
    NotificationBehavior getCurrentBehavior() {
      return SettingsService.instance.getNotificationBehavior();
    }

    switch (event) {
      case CycleStarted():
        // Can only start a cycle if we are currently idle.
        if (currentState is AlarmIdle) {
          return AlarmActive(
            scheduledAt: _calculateNextWholeIntervalTime(),
            behavior: getCurrentBehavior(),
          );
        }
      case CycleCancelled():
        // Can only cancel a cycle if one is active.
        if (currentState is AlarmActive) {
          return AlarmIdle();
        }
      case QuestionnaireFinished():
        // After the questionnaire, we always schedule a new alarm.
        // The type of alarm depends on the user's answer.
        switch (event.result) {
          case QuestionnaireResult.answered:
          case QuestionnaireResult.declined:
            return AlarmActive(
              scheduledAt: _calculateNextWholeIntervalTime(),
              behavior: getCurrentBehavior(),
            );
          case QuestionnaireResult.snoozed:
            return AlarmActive(
              scheduledAt: _calculateSnoozeTime(),
              behavior: getCurrentBehavior(),
            );
        }
      case DebugScheduleRequested():
        // A special event for testing that schedules an alarm 10 seconds from now.
        return AlarmActive(
          scheduledAt: DateTime.now().add(const Duration(seconds: 10)),
          behavior: getCurrentBehavior(),
        );
      // Handle the new event to update the behavior of an active alarm.
      case NotificationBehaviorChanged(newBehavior: final behavior):
        if (currentState is AlarmActive) {
          // Create a new state with the same time but new behavior.
          return AlarmActive(
            scheduledAt: currentState.scheduledAt,
            behavior: behavior,
          );
        }
    }
    return currentState;
  }

  DateTime _calculateNextWholeIntervalTime() {
    final now = DateTime.now();
    DateTime nextAlarmTime;

    if (now.hour >= 20) {
      nextAlarmTime = DateTime(now.year, now.month, now.day + 1, 8);
    } else if (now.hour < 8) {
      nextAlarmTime = DateTime(now.year, now.month, now.day, 8);
    } else {
      nextAlarmTime = DateTime(now.year, now.month, now.day, now.hour + 1);
    }

    return DateTime(nextAlarmTime.year, nextAlarmTime.month, nextAlarmTime.day,
        nextAlarmTime.hour);
  }

  DateTime _calculateSnoozeTime() {
    return DateTime.now().add(const Duration(minutes: 15));
  }

  // It's good practice to close the stream controller when it's no longer needed.
  void dispose() {
    _controller.close();
  }
}
