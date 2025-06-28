import 'dart:async';
import 'dart:developer';

// --- STATES ---
// Using a sealed class ensures that we can only be in one of the defined states.
sealed class AlarmState {}

// The app is idle. No alarm is scheduled.
final class AlarmIdle extends AlarmState {}

// The cycle is running. An alarm is ALWAYS scheduled for a specific time.
final class AlarmActive extends AlarmState {
  AlarmActive({required this.scheduledAt});
  final DateTime scheduledAt;
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

// Helper enum to make the code more readable and type-safe.
enum QuestionnaireResult { answered, declined, snoozed }

// --- THE STATE MACHINE ("BRAIN") ---
class AlarmStateManager {
  // Singleton pattern for easy global access.
  AlarmStateManager._();
  static final AlarmStateManager instance = AlarmStateManager._();

  // The initial state of the application.
  AlarmState _state = AlarmIdle();

  // A broadcast stream controller allows multiple parts of the app (e.g., UI, interpreter)
  // to listen to state changes.
  final _controller = StreamController<AlarmState>.broadcast();

  // Public stream for widgets and services to listen to.
  Stream<AlarmState> get state => _controller.stream;

  // A way to get the current state synchronously if needed.
  AlarmState get currentState => _state;

  void dispatch(AlarmEvent event) {
    log('Dispatching event: ${event.runtimeType} from state: ${_state.runtimeType}');

    // The new state is calculated based on the current state and the incoming event.
    final newState = _reduce(_state, event);

    // If the state has changed, update it and notify all listeners.
    if (newState.runtimeType != _state.runtimeType ||
        (newState is AlarmActive &&
            _state is AlarmActive &&
            newState.scheduledAt != (_state as AlarmActive).scheduledAt)) {
      _state = newState;
      _controller.add(_state);
    }
  }

  // The "reducer" function contains all the transition logic.
  // It's a pure function: given a state and an event, it returns a new state.
  AlarmState _reduce(AlarmState currentState, AlarmEvent event) {
    switch (event) {
      case CycleStarted():
        // Can only start a cycle if we are currently idle.
        if (currentState is AlarmIdle) {
          return AlarmActive(scheduledAt: _calculateNextWholeIntervalTime());
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
            return AlarmActive(scheduledAt: _calculateNextWholeIntervalTime());
          case QuestionnaireResult.declined:
            return AlarmActive(scheduledAt: _calculateNextWholeIntervalTime());
          case QuestionnaireResult.snoozed:
            return AlarmActive(scheduledAt: _calculateSnoozeTime());
        }
      case DebugScheduleRequested():
        // A special event for testing that schedules an alarm 10 minutes from now.
        return AlarmActive(
            scheduledAt: DateTime.now().add(const Duration(seconds: 10)));
    }
    // If the event doesn't cause a state change, return the current state.
    return currentState;
  }

  // --- TIME CALCULATION LOGIC (moved from AlarmMethodChannel) ---
  DateTime _calculateNextWholeIntervalTime() {
    final now = DateTime.now();
    DateTime nextAlarmTime;

    if (now.hour >= 20) {
      // Changed from 23 to 20 as per original logic
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
