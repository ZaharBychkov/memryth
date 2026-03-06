import 'package:hive/hive.dart';

import '../models/quote.dart';

class QuoteRepository {
  Box<Quote> get _box => Hive.box<Quote>('quotes');

  List<Quote> getAll() => _box.values.toList(growable: false);

  Future<void> save(Quote quote) => _box.put(quote.id, quote);

  Future<void> deleteById(String id) => _box.delete(id);

  Stream<BoxEvent> watch() => _box.watch();
}
