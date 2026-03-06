import 'package:hive/hive.dart';

part 'tag.g.dart';

@HiveType(typeId: 0)
class Tag extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  Tag({
    required this.id,
    required this.name,
  });
}
