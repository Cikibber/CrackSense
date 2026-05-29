// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'detection_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DetectionRecordAdapter extends TypeAdapter<DetectionRecord> {
  @override
  final int typeId = 0;

  @override
  DetectionRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DetectionRecord(
      id: fields[0] as String,
      classification: fields[1] as String,
      confidence: fields[2] as double,
      timestamp: fields[3] as DateTime,
      imageBytes: fields[4] as Uint8List?,
      latitude: fields[5] as double?,
      longitude: fields[6] as double?,
      altitude: fields[7] as double?,
      inferenceTimeMs: fields[8] as int,
    );
  }

  @override
  void write(BinaryWriter writer, DetectionRecord obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.classification)
      ..writeByte(2)
      ..write(obj.confidence)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.imageBytes)
      ..writeByte(5)
      ..write(obj.latitude)
      ..writeByte(6)
      ..write(obj.longitude)
      ..writeByte(7)
      ..write(obj.altitude)
      ..writeByte(8)
      ..write(obj.inferenceTimeMs);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DetectionRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
