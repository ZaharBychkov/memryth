import 'package:hive/hive.dart';

import '../models/tag.dart';

abstract class TagRepository {
  List<Tag> getAll();

  Future<void> save(Tag tag);

  Stream<BoxEvent> watch();
}

class HiveTagRepository implements TagRepository {
  Box<Tag> get _box => Hive.box<Tag>('tags');

  @override
  List<Tag> getAll() => _box.values.toList(growable: false);

  @override
  Future<void> save(Tag tag) => _box.put(tag.id, tag);

  @override
  Stream<BoxEvent> watch() => _box.watch();
}
