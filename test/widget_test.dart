import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:memryth_dart_project/contollers/quote_contoller.dart';
import 'package:memryth_dart_project/models/quote.dart';
import 'package:memryth_dart_project/models/tag.dart';
import 'package:memryth_dart_project/repositories/quote_repository.dart';
import 'package:memryth_dart_project/repositories/tag_repository.dart';
import 'package:memryth_dart_project/viewmodels/topic_index.dart';

void main() {
  group('QuoteController search', () {
    test('finds entries by topic when the text does not contain the query', () {
      final controller = _controller(
        quotes: [
          _quote(id: 'q1', text: 'Важный разговор', tagIds: ['family']),
          _quote(id: 'q2', text: 'Рабочая идея', tagIds: ['work']),
        ],
        tags: [
          Tag(id: 'family', name: 'семья'),
          Tag(id: 'work', name: 'работа'),
        ],
      );

      controller.setSearchQuery('семья');

      expect(controller.filteredQuotes.map((quote) => quote.id), ['q1']);
    });

    test('hash query searches topics only', () {
      final controller = _controller(
        quotes: [
          _quote(id: 'q1', text: 'Важный разговор', tagIds: ['family']),
          _quote(id: 'q2', text: 'семья в тексте', tagIds: ['work']),
        ],
        tags: [
          Tag(id: 'family', name: 'семья'),
          Tag(id: 'work', name: 'работа'),
        ],
      );

      controller.setSearchQuery('#семья');

      expect(controller.filteredQuotes.map((quote) => quote.id), ['q1']);
    });
  });

  group('topic index', () {
    test('builds a nested tree and aggregates note counts', () {
      final topics = buildTopicIndex(
        quotes: [
          _quote(id: 'q1', text: 'one', tagIds: ['familyKids']),
          _quote(id: 'q2', text: 'two', tagIds: ['familyBudget']),
          _quote(id: 'q3', text: 'three', tagIds: ['familyKids']),
        ],
        tags: [
          Tag(id: 'familyKids', name: 'семья/дети'),
          Tag(id: 'familyBudget', name: 'семья/бюджет'),
        ],
        sortMode: TopicSortMode.alphabetic,
      );

      expect(topics.single.path, 'семья');
      expect(topics.single.count, 3);
      expect(topics.single.children.map((topic) => topic.path), [
        'семья/бюджет',
        'семья/дети',
      ]);
      expect(topics.single.children.map((topic) => topic.count), [1, 2]);
    });

    test('sorts popular topics by frequency', () {
      final topics = buildTopicIndex(
        quotes: [
          _quote(id: 'q1', text: 'one', tagIds: ['work']),
          _quote(id: 'q2', text: 'two', tagIds: ['family']),
          _quote(id: 'q3', text: 'three', tagIds: ['family']),
        ],
        tags: [
          Tag(id: 'work', name: 'работа'),
          Tag(id: 'family', name: 'семья'),
        ],
        sortMode: TopicSortMode.frequency,
      );

      expect(topics.map((topic) => topic.path), ['семья', 'работа']);
    });
  });
}

QuoteController _controller({
  required List<Quote> quotes,
  required List<Tag> tags,
}) {
  final controller = QuoteController(
    quoteRepository: _MemoryQuoteRepository(quotes),
    tagRepository: _MemoryTagRepository(tags),
  );
  controller.loadInitial();
  return controller;
}

Quote _quote({
  required String id,
  required String text,
  required List<String> tagIds,
}) {
  final date = DateTime(2026);
  return Quote(
    id: id,
    text: text,
    author: '',
    tagIds: tagIds,
    createdAt: date,
    updatedAt: date,
  );
}

class _MemoryQuoteRepository implements QuoteRepository {
  _MemoryQuoteRepository(this._quotes);

  final List<Quote> _quotes;

  @override
  List<Quote> getAll() => _quotes;

  @override
  Future<void> save(Quote quote) async {}

  @override
  Future<void> deleteById(String id) async {}

  @override
  Stream<BoxEvent> watch() => const Stream<BoxEvent>.empty();
}

class _MemoryTagRepository implements TagRepository {
  _MemoryTagRepository(this._tags);

  final List<Tag> _tags;

  @override
  List<Tag> getAll() => _tags;

  @override
  Future<void> save(Tag tag) async {}

  @override
  Stream<BoxEvent> watch() => const Stream<BoxEvent>.empty();
}
