// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quote.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QuoteAdapter extends TypeAdapter<Quote> {
  @override
  final int typeId = 1;

  @override
  Quote read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    final id = fields[0] as String;
    final fallbackDate = _inferDateFromId(id);
    return Quote(
      id: id,
      text: fields[1] as String,
      author: (fields[2] as String?) ?? '',
      tagIds: (fields[3] as List).cast<String>(),
      typeKey: (fields[4] as String?) ?? 'quote',
      createdAt: (fields[5] as DateTime?) ?? fallbackDate,
      updatedAt:
          (fields[6] as DateTime?) ?? (fields[5] as DateTime?) ?? fallbackDate,
      isFavorite: (fields[7] as bool?) ?? false,
      sourceTitle: (fields[8] as String?) ?? '',
      sourceDetails: (fields[9] as String?) ?? '',
      note: (fields[10] as String?) ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, Quote obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.text)
      ..writeByte(2)
      ..write(obj.author)
      ..writeByte(3)
      ..write(obj.tagIds)
      ..writeByte(4)
      ..write(obj.typeKey)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.updatedAt)
      ..writeByte(7)
      ..write(obj.isFavorite)
      ..writeByte(8)
      ..write(obj.sourceTitle)
      ..writeByte(9)
      ..write(obj.sourceDetails)
      ..writeByte(10)
      ..write(obj.note);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuoteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

DateTime _inferDateFromId(String id) {
  final microPrefix = RegExp(r'^\d{13,}').stringMatch(id);
  if (microPrefix == null) {
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  final microseconds = int.tryParse(microPrefix);
  if (microseconds == null) {
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  return DateTime.fromMicrosecondsSinceEpoch(microseconds);
}
