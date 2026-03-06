import 'package:hive/hive.dart';

import '../models/tag.dart';

class TagRepository {
  Box<Tag> get _box => Hive.box<Tag>('tags');

  List<Tag> getAll() => _box.values.toList(growable: false);

  Future<void> save(Tag tag) => _box.put(tag.id, tag);

  Stream<BoxEvent> watch() => _box.watch();
}
