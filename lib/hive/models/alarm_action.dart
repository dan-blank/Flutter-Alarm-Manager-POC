import 'package:flutter_alarm_manager_poc/hive/models/alarm_action_type.dart';
import 'package:hive/hive.dart';

part 'alarm_action.g.dart';

@HiveType(typeId: 0) //typeId should be unique for each model
class AlarmAction {
  AlarmAction(this.actionType, this.timestamp, [this.answers]);

  @HiveField(0)
  final AlarmActionType actionType;
  @HiveField(1)
  final int timestamp;

  @HiveField(2)
  final Map<String, dynamic>? answers;
}
