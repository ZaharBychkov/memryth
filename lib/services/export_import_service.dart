import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/quote.dart';
import '../models/tag.dart';
import '../repositories/quote_repository.dart';
import '../repositories/tag_repository.dart';

class ExportImportService {
  ExportImportService({
    required QuoteRepository quoteRepository,
    required TagRepository tagRepository,
    DateTime Function()? now,
  }) : _quoteRepository = quoteRepository,
       _tagRepository = tagRepository,
       _now = now ?? DateTime.now;

  static const appName = 'MEMRYTH';
  static const schemaVersion = 1;

  final QuoteRepository _quoteRepository;
  final TagRepository _tagRepository;
  final DateTime Function() _now;

  Map<String, Object?> buildExportMap({Iterable<Quote>? quotes}) {
    final exportedAt = _now().toUtc();
    final selectedQuotes = (quotes ?? _quoteRepository.getAll()).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final selectedTagIds = selectedQuotes
        .expand((quote) => quote.tagIds)
        .toSet();
    final tags =
        _tagRepository
            .getAll()
            .where((tag) => quotes == null || selectedTagIds.contains(tag.id))
            .toList()
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );

    return {
      'app': appName,
      'schemaVersion': schemaVersion,
      'exportedAt': exportedAt.toIso8601String(),
      'tags': [for (final tag in tags) _tagToJson(tag)],
      'quotes': [for (final quote in selectedQuotes) _quoteToJson(quote)],
    };
  }

  String buildExportJson({Iterable<Quote>? quotes}) {
    return const JsonEncoder.withIndent(
      '  ',
    ).convert(buildExportMap(quotes: quotes));
  }

  Future<File> writeExportFile({
    Iterable<Quote>? quotes,
    String? fileNamePrefix,
  }) async {
    final directory = await getTemporaryDirectory();
    final file = File(
      '${directory.path}/${_exportFileName(fileNamePrefix ?? 'memryth-backup')}',
    );
    return file.writeAsString(buildExportJson(quotes: quotes), flush: true);
  }

  String get exportFileName => _exportFileName('memryth-backup');

  String _exportFileName(String prefix) {
    final local = _now();
    String two(int value) => value.toString().padLeft(2, '0');
    return '$prefix-'
        '${local.year}-${two(local.month)}-${two(local.day)}-'
        '${two(local.hour)}-${two(local.minute)}.json';
  }

  ImportPreview previewImportJson(String source) {
    final backup = _parseBackup(source);
    return ImportPreview(
      exportedAt: backup.exportedAt,
      tagCount: backup.tags.length,
      quoteCount: backup.quotes.length,
    );
  }

  Future<ImportResult> importJsonMerge(String source) async {
    final backup = _parseBackup(source);
    final existingTags = _tagRepository.getAll();
    final existingQuotes = _quoteRepository.getAll();
    final tagNameToId = <String, String>{
      for (final tag in existingTags) _normalizeName(tag.name): tag.id,
    };
    final existingTagIds = existingTags.map((tag) => tag.id).toSet();
    final existingQuoteIds = existingQuotes.map((quote) => quote.id).toSet();
    final importedTagIdToFinalId = <String, String>{};

    var addedTags = 0;
    var reusedTags = 0;
    var skippedTags = 0;

    for (final tag in backup.tags) {
      final name = tag.name.trim();
      if (name.isEmpty) {
        skippedTags++;
        continue;
      }

      final normalized = _normalizeName(name);
      final existingId = tagNameToId[normalized];
      if (existingId != null) {
        importedTagIdToFinalId[tag.id] = existingId;
        reusedTags++;
        continue;
      }

      final id = _uniqueId(tag.id, existingTagIds);
      await _tagRepository.save(Tag(id: id, name: name));
      existingTagIds.add(id);
      tagNameToId[normalized] = id;
      importedTagIdToFinalId[tag.id] = id;
      addedTags++;
    }

    var addedQuotes = 0;
    var skippedQuotes = 0;

    for (final quote in backup.quotes) {
      if (quote.text.trim().isEmpty || existingQuoteIds.contains(quote.id)) {
        skippedQuotes++;
        continue;
      }

      final tagIds = <String>[
        for (final tagId in quote.tagIds)
          if (importedTagIdToFinalId[tagId] != null)
            importedTagIdToFinalId[tagId]!,
      ];
      await _quoteRepository.save(
        Quote(
          id: quote.id,
          text: quote.text,
          author: quote.author,
          tagIds: tagIds,
          typeKey: QuoteType.fromKey(quote.typeKey).key,
          createdAt: quote.createdAt,
          updatedAt: quote.updatedAt,
          isFavorite: quote.isFavorite,
          sourceTitle: quote.sourceTitle,
          note: quote.note,
        ),
      );
      existingQuoteIds.add(quote.id);
      addedQuotes++;
    }

    return ImportResult(
      addedTags: addedTags,
      reusedTags: reusedTags,
      skippedTags: skippedTags,
      addedQuotes: addedQuotes,
      skippedQuotes: skippedQuotes,
    );
  }

  static Map<String, Object?> _tagToJson(Tag tag) {
    return {'id': tag.id, 'name': tag.name};
  }

  static Map<String, Object?> _quoteToJson(Quote quote) {
    return {
      'id': quote.id,
      'text': quote.text,
      'author': quote.author,
      'tagIds': quote.tagIds,
      'typeKey': quote.typeKey,
      'createdAt': quote.createdAt.toUtc().toIso8601String(),
      'updatedAt': quote.updatedAt.toUtc().toIso8601String(),
      'isFavorite': quote.isFavorite,
      'sourceTitle': quote.sourceTitle,
      'note': quote.note,
    };
  }

  static _Backup _parseBackup(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException catch (error) {
      throw ImportFormatException('File is not valid JSON.', error);
    }

    if (decoded is! Map<String, Object?>) {
      throw const ImportFormatException('Backup root must be a JSON object.');
    }

    if (decoded['app'] != appName) {
      throw const ImportFormatException('Backup app marker is not supported.');
    }

    if (decoded['schemaVersion'] != schemaVersion) {
      throw const ImportFormatException(
        'Backup schema version is not supported.',
      );
    }

    final exportedAt = _readDate(decoded['exportedAt'], 'exportedAt');
    final tagsRaw = decoded['tags'];
    final quotesRaw = decoded['quotes'];

    if (tagsRaw is! List || quotesRaw is! List) {
      throw const ImportFormatException('Backup must contain tags and quotes.');
    }

    return _Backup(
      exportedAt: exportedAt,
      tags: [
        for (final item in tagsRaw)
          if (item is Map<String, Object?>) _ImportedTag.fromJson(item),
      ],
      quotes: [
        for (final item in quotesRaw)
          if (item is Map<String, Object?>) _ImportedQuote.fromJson(item),
      ],
    );
  }

  static DateTime _readDate(Object? value, String field) {
    if (value is! String) {
      throw ImportFormatException('$field must be an ISO date string.');
    }

    try {
      return DateTime.parse(value);
    } on FormatException catch (error) {
      throw ImportFormatException('$field is not a valid date.', error);
    }
  }

  static String _readString(
    Map<String, Object?> json,
    String field, {
    bool required = false,
  }) {
    final value = json[field];
    if (value == null && !required) {
      return '';
    }
    if (value is String) {
      return value;
    }
    throw ImportFormatException('$field must be a string.');
  }

  static List<String> _readStringList(Map<String, Object?> json, String field) {
    final value = json[field];
    if (value == null) {
      return const [];
    }
    if (value is! List) {
      throw ImportFormatException('$field must be a list.');
    }
    return [
      for (final item in value)
        if (item is String) item,
    ];
  }

  static bool _readBool(Map<String, Object?> json, String field) {
    final value = json[field];
    if (value == null) {
      return false;
    }
    if (value is bool) {
      return value;
    }
    throw ImportFormatException('$field must be a boolean.');
  }

  static String _normalizeName(String value) {
    return value.trim().toLowerCase();
  }

  static String _uniqueId(String preferredId, Set<String> existingIds) {
    final base = preferredId.trim().isEmpty
        ? 'imported-tag'
        : preferredId.trim();
    if (!existingIds.contains(base)) {
      return base;
    }

    var index = 2;
    while (existingIds.contains('$base-$index')) {
      index++;
    }
    return '$base-$index';
  }
}

class ImportPreview {
  const ImportPreview({
    required this.exportedAt,
    required this.tagCount,
    required this.quoteCount,
  });

  final DateTime exportedAt;
  final int tagCount;
  final int quoteCount;
}

class ImportResult {
  const ImportResult({
    required this.addedTags,
    required this.reusedTags,
    required this.skippedTags,
    required this.addedQuotes,
    required this.skippedQuotes,
  });

  final int addedTags;
  final int reusedTags;
  final int skippedTags;
  final int addedQuotes;
  final int skippedQuotes;
}

class ImportFormatException implements Exception {
  const ImportFormatException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

class _Backup {
  const _Backup({
    required this.exportedAt,
    required this.tags,
    required this.quotes,
  });

  final DateTime exportedAt;
  final List<_ImportedTag> tags;
  final List<_ImportedQuote> quotes;
}

class _ImportedTag {
  const _ImportedTag({required this.id, required this.name});

  factory _ImportedTag.fromJson(Map<String, Object?> json) {
    return _ImportedTag(
      id: ExportImportService._readString(json, 'id', required: true),
      name: ExportImportService._readString(json, 'name', required: true),
    );
  }

  final String id;
  final String name;
}

class _ImportedQuote {
  const _ImportedQuote({
    required this.id,
    required this.text,
    required this.author,
    required this.tagIds,
    required this.typeKey,
    required this.createdAt,
    required this.updatedAt,
    required this.isFavorite,
    required this.sourceTitle,
    required this.note,
  });

  factory _ImportedQuote.fromJson(Map<String, Object?> json) {
    return _ImportedQuote(
      id: ExportImportService._readString(json, 'id', required: true),
      text: ExportImportService._readString(json, 'text', required: true),
      author: ExportImportService._readString(json, 'author'),
      tagIds: ExportImportService._readStringList(json, 'tagIds'),
      typeKey: ExportImportService._readString(json, 'typeKey'),
      createdAt: ExportImportService._readDate(json['createdAt'], 'createdAt'),
      updatedAt: ExportImportService._readDate(json['updatedAt'], 'updatedAt'),
      isFavorite: ExportImportService._readBool(json, 'isFavorite'),
      sourceTitle: ExportImportService._readString(json, 'sourceTitle'),
      note: ExportImportService._readString(json, 'note'),
    );
  }

  final String id;
  final String text;
  final String author;
  final List<String> tagIds;
  final String typeKey;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFavorite;
  final String sourceTitle;
  final String note;
}
