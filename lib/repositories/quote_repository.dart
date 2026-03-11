import 'package:hive/hive.dart';

import '../models/quote.dart';

abstract class QuoteRepository {
  List<Quote> getAll();

  Future<void> save(Quote quote);

  Future<void> deleteById(String id);

  Stream<BoxEvent> watch();
}

class HiveQuoteRepository implements QuoteRepository {
  Box<Quote> get _box => Hive.box<Quote>('quotes');

  @override
  List<Quote> getAll() => _box.values.toList(growable: false);

  @override
  Future<void> save(Quote quote) => _box.put(quote.id, quote);

  @override
  Future<void> deleteById(String id) => _box.delete(id);

  @override
  Stream<BoxEvent> watch() => _box.watch();
}
