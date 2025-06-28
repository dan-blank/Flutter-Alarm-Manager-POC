import 'package:flutter_alarm_manager_poc/state/notification_behavior.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SettingsService {
  // Private constructor
  SettingsService._();

  static final SettingsService _instance = SettingsService._();
  static SettingsService get instance => _instance;

  static const String _settingsBoxName = 'settings';
  static const String _exportPathKey = 'exportPath';
  static const String _notificationBehaviorKey = 'notificationBehavior';

  late Box<String> _settingsBox;

  Future<void> initializeHive() async {
    _settingsBox = await Hive.openBox<String>(_settingsBoxName);
  }

  Future<void> setExportPath(String path) async {
    await _settingsBox.put(_exportPathKey, path);
  }

  String? getExportPath() {
    return _settingsBox.get(_exportPathKey);
  }

  Future<void> setNotificationBehavior(NotificationBehavior behavior) async {
    await _settingsBox.put(_notificationBehaviorKey, behavior.name);
  }

  NotificationBehavior getNotificationBehavior() {
    final behaviorName = _settingsBox.get(_notificationBehaviorKey);
    return NotificationBehavior.values.firstWhere(
      (e) => e.name == behaviorName,
      orElse: () => NotificationBehavior.vibrateAndSound, // Default value
    );
  }
}
