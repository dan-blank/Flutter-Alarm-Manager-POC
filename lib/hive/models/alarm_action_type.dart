import 'package:hive/hive.dart';

// This 'part' line is necessary for the build_runner to generate the adapter file.
part 'alarm_action_type.g.dart';

@HiveType(
    typeId:
        1) // IMPORTANT: Use a new typeId that is not used by other models (AlarmAction uses 0).
enum AlarmActionType {
  @HiveField(0)
  answered,

  @HiveField(1)
  declined,

  @HiveField(2)
  snoozed,
}
