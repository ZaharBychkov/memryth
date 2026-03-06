import 'package:hive/hive.dart';

part 'quote.g.dart';

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

  Quote({
    required this.id,
    required this.text,
    required this.author,
    required this.tagIds,
  });

  Quote copyWith({
    String? text,
    String? author,
    List<String>? tagIds,
  }) {
    return Quote(
      id: id,
      text: text ?? this.text,
      author: author ?? this.author,
      tagIds: tagIds ?? this.tagIds,
    );
  }
}
