import 'package:hive/hive.dart';

part 'quote.g.dart';

enum QuoteType {
  quote,
  thought,
  excerpt;

  String get key => switch (this) {
    QuoteType.quote => 'quote',
    QuoteType.thought => 'thought',
    QuoteType.excerpt => 'excerpt',
  };

  String get label => switch (this) {
    QuoteType.quote => 'Цитата',
    QuoteType.thought => 'Мысль',
    QuoteType.excerpt => 'Фрагмент',
  };

  static QuoteType fromKey(String? value) {
    return QuoteType.values.firstWhere(
      (type) => type.key == value,
      orElse: () => QuoteType.quote,
    );
  }
}

@HiveType(typeId: 1)
class Quote extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String text;

  @HiveField(2)
  final String author;

  @HiveField(3)
  final List<String> tagIds;

  @HiveField(4)
  final String typeKey;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final DateTime updatedAt;

  @HiveField(7)
  final bool isFavorite;

  @HiveField(8)
  final String sourceTitle;

  @HiveField(9)
  final String sourceDetails;

  @HiveField(10)
  final String note;

  Quote({
    required this.id,
    required this.text,
    required this.author,
    required this.tagIds,
    this.typeKey = 'quote',
    required this.createdAt,
    required this.updatedAt,
    this.isFavorite = false,
    this.sourceTitle = '',
    this.sourceDetails = '',
    this.note = '',
  });

  QuoteType get type => QuoteType.fromKey(typeKey);

  Quote copyWith({
    String? text,
    String? author,
    List<String>? tagIds,
    String? typeKey,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFavorite,
    String? sourceTitle,
    String? sourceDetails,
    String? note,
  }) {
    return Quote(
      id: id,
      text: text ?? this.text,
      author: author ?? this.author,
      tagIds: tagIds ?? this.tagIds,
      typeKey: typeKey ?? this.typeKey,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      sourceTitle: sourceTitle ?? this.sourceTitle,
      sourceDetails: sourceDetails ?? this.sourceDetails,
      note: note ?? this.note,
    );
  }
}
