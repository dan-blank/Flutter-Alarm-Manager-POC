import 'package:hive/hive.dart';

part 'alarm_action.g.dart';

@HiveType(typeId: 0) //typeId should be unique for each model
class AlarmAction {
  AlarmAction(this.actionType, this.timestamp, [this.answers]);

  @HiveField(0)
  final String actionType;
  @HiveField(1)
  final DateTime timestamp;

  @HiveField(2)
  final Map<String, int>? answers;
}
