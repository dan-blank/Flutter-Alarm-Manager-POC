// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alarm_action_type.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AlarmActionTypeAdapter extends TypeAdapter<AlarmActionType> {
  @override
  final int typeId = 1;

  @override
  AlarmActionType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AlarmActionType.answered;
      case 1:
        return AlarmActionType.declined;
      case 2:
        return AlarmActionType.snoozed;
      default:
        return AlarmActionType.answered;
    }
  }

  @override
  void write(BinaryWriter writer, AlarmActionType obj) {
    switch (obj) {
      case AlarmActionType.answered:
        writer.writeByte(0);
      case AlarmActionType.declined:
        writer.writeByte(1);
      case AlarmActionType.snoozed:
        writer.writeByte(2);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlarmActionTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
