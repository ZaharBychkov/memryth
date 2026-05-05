import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:memryth_dart_project/models/quote.dart';
import 'package:memryth_dart_project/models/tag.dart';
import 'package:memryth_dart_project/repositories/quote_repository.dart';
import 'package:memryth_dart_project/repositories/tag_repository.dart';
import 'package:memryth_dart_project/services/export_import_service.dart';

void main() {
  group('ExportImportService', () {
    test('exports schema v1 with tags and quotes', () {
      final service = ExportImportService(
        quoteRepository: _MemoryQuoteRepository([
          _quote(id: 'q1', text: 'Text', tagIds: ['t1']),
        ]),
        tagRepository: _MemoryTagRepository([Tag(id: 't1', name: 'Topic')]),
        now: () => DateTime.utc(2026, 5, 1, 12),
      );

      final json =
          jsonDecode(service.buildExportJson()) as Map<String, Object?>;
      final tags = json['tags'] as List<Object?>;
      final quotes = json['quotes'] as List<Object?>;
      final quote = quotes.single as Map<String, Object?>;

      expect(json['app'], 'MEMRYTH');
      expect(json['schemaVersion'], 1);
      expect(json['exportedAt'], '2026-05-01T12:00:00.000Z');
      expect(tags.single, {'id': 't1', 'name': 'Topic'});
      expect(quote['id'], 'q1');
      expect(quote['text'], 'Text');
      expect(quote['tagIds'], ['t1']);
      expect(quote['typeKey'], 'quote');
      expect(quote['createdAt'], '2026-01-01T00:00:00.000Z');
      expect(quote['updatedAt'], '2026-01-01T00:00:00.000Z');
    });

    test('exports selected quotes with only referenced tags', () {
      final selected = _quote(id: 'q1', text: 'Selected', tagIds: ['t1']);
      final service = ExportImportService(
        quoteRepository: _MemoryQuoteRepository([
          selected,
          _quote(id: 'q2', text: 'Not selected', tagIds: ['t2']),
        ]),
        tagRepository: _MemoryTagRepository([
          Tag(id: 't1', name: 'Selected topic'),
          Tag(id: 't2', name: 'Other topic'),
        ]),
        now: () => DateTime.utc(2026, 5, 1, 12),
      );

      final json =
          jsonDecode(service.buildExportJson(quotes: [selected]))
              as Map<String, Object?>;
      final tags = json['tags'] as List<Object?>;
      final quotes = json['quotes'] as List<Object?>;

      expect(tags.single, {'id': 't1', 'name': 'Selected topic'});
      expect((quotes.single as Map<String, Object?>)['id'], 'q1');
    });

    test(
      'merge import reuses existing tags by name and skips quote id conflicts',
      () async {
        final quotes = _MemoryQuoteRepository([
          _quote(id: 'existing', text: 'Already here', tagIds: ['local-topic']),
        ]);
        final tags = _MemoryTagRepository([
          Tag(id: 'local-topic', name: 'Topic'),
        ]);
        final service = ExportImportService(
          quoteRepository: quotes,
          tagRepository: tags,
        );

        final result = await service.importJsonMerge(
          jsonEncode({
            'app': 'MEMRYTH',
            'schemaVersion': 1,
            'exportedAt': '2026-05-01T12:00:00.000Z',
            'tags': [
              {'id': 'imported-topic', 'name': ' topic '},
              {'id': 'new-topic', 'name': 'New'},
            ],
            'quotes': [
              _quoteJson(
                id: 'new-quote',
                text: 'Imported',
                tagIds: ['imported-topic', 'new-topic'],
              ),
              _quoteJson(
                id: 'existing',
                text: 'Must not overwrite',
                tagIds: ['new-topic'],
              ),
            ],
          }),
        );

        expect(result.addedTags, 1);
        expect(result.reusedTags, 1);
        expect(result.addedQuotes, 1);
        expect(result.skippedQuotes, 1);
        expect(tags.getAll().map((tag) => tag.name), ['Topic', 'New']);
        expect(quotes.getAll().map((quote) => quote.id), [
          'existing',
          'new-quote',
        ]);
        expect(quotes.getAll().last.tagIds, ['local-topic', 'new-topic']);
        expect(quotes.getAll().first.text, 'Already here');
      },
    );

    test('rejects unsupported schema versions', () {
      final service = ExportImportService(
        quoteRepository: _MemoryQuoteRepository(const []),
        tagRepository: _MemoryTagRepository(const []),
      );

      expect(
        () => service.previewImportJson(
          jsonEncode({
            'app': 'MEMRYTH',
            'schemaVersion': 999,
            'exportedAt': '2026-05-01T12:00:00.000Z',
            'tags': [],
            'quotes': [],
          }),
        ),
        throwsA(isA<ImportFormatException>()),
      );
    });
  });
}

Quote _quote({
  required String id,
  required String text,
  required List<String> tagIds,
}) {
  final date = DateTime.utc(2026);
  return Quote(
    id: id,
    text: text,
    author: 'Author',
    tagIds: tagIds,
    typeKey: QuoteType.quote.key,
    createdAt: date,
    updatedAt: date,
    isFavorite: true,
    sourceTitle: 'Source',
    note: 'Note',
  );
}

Map<String, Object?> _quoteJson({
  required String id,
  required String text,
  required List<String> tagIds,
}) {
  return {
    'id': id,
    'text': text,
    'author': '',
    'tagIds': tagIds,
    'typeKey': 'thought',
    'createdAt': '2026-02-01T00:00:00.000Z',
    'updatedAt': '2026-02-02T00:00:00.000Z',
    'isFavorite': false,
    'sourceTitle': '',
    'note': '',
  };
}

class _MemoryQuoteRepository implements QuoteRepository {
  _MemoryQuoteRepository(List<Quote> quotes) : _quotes = [...quotes];

  final List<Quote> _quotes;

  @override
  List<Quote> getAll() => [..._quotes];

  @override
  Future<void> save(Quote quote) async {
    _quotes.removeWhere((item) => item.id == quote.id);
    _quotes.add(quote);
  }

  @override
  Future<void> deleteById(String id) async {
    _quotes.removeWhere((quote) => quote.id == id);
  }

  @override
  Stream<BoxEvent> watch() => const Stream<BoxEvent>.empty();
}

class _MemoryTagRepository implements TagRepository {
  _MemoryTagRepository(List<Tag> tags) : _tags = [...tags];

  final List<Tag> _tags;

  @override
  List<Tag> getAll() => [..._tags];

  @override
  Future<void> save(Tag tag) async {
    _tags.removeWhere((item) => item.id == tag.id);
    _tags.add(tag);
  }

  @override
  Stream<BoxEvent> watch() => const Stream<BoxEvent>.empty();
}
