import '../models/quote.dart';
import '../models/tag.dart';

enum TopicSortMode { alphabetic, frequency }

class TopicIndexNode {
  const TopicIndexNode({
    required this.name,
    required this.path,
    required this.count,
    required this.children,
  });

  final String name;
  final String path;
  final int count;
  final List<TopicIndexNode> children;
}

List<TopicIndexNode> buildTopicIndex({
  required List<Quote> quotes,
  required List<Tag> tags,
  required TopicSortMode sortMode,
}) {
  final tagsById = {for (final tag in tags) tag.id: tag};
  final roots = <String, _TopicBuilderNode>{};

  for (final quote in quotes) {
    for (final tagId in quote.tagIds.toSet()) {
      final tag = tagsById[tagId];
      if (tag == null) {
        continue;
      }

      final parts = tag.name
          .split('/')
          .map((part) => part.trim())
          .where((part) => part.isNotEmpty)
          .toList(growable: false);
      if (parts.isEmpty) {
        continue;
      }

      var children = roots;
      final pathParts = <String>[];
      for (final part in parts) {
        pathParts.add(part);
        final key = part.toLowerCase();
        final node = children.putIfAbsent(
          key,
          () => _TopicBuilderNode(name: part, path: pathParts.join('/')),
        );
        node.quoteIds.add(quote.id);
        children = node.children;
      }
    }
  }

  return _finalizeNodes(roots.values, sortMode);
}

List<TopicIndexNode> _finalizeNodes(
  Iterable<_TopicBuilderNode> nodes,
  TopicSortMode sortMode,
) {
  final finalized = [
    for (final node in nodes)
      TopicIndexNode(
        name: node.name,
        path: node.path,
        count: node.quoteIds.length,
        children: _finalizeNodes(node.children.values, sortMode),
      ),
  ];

  finalized.sort((a, b) {
    if (sortMode == TopicSortMode.frequency) {
      final countCompare = b.count.compareTo(a.count);
      if (countCompare != 0) {
        return countCompare;
      }
    }
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });

  return finalized;
}

class _TopicBuilderNode {
  _TopicBuilderNode({required this.name, required this.path});

  final String name;
  final String path;
  final Set<String> quoteIds = <String>{};
  final Map<String, _TopicBuilderNode> children = <String, _TopicBuilderNode>{};
}
