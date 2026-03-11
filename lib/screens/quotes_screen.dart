import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../contollers/quote_contoller.dart';
import '../models/quote.dart';
import '../repositories/quote_repository.dart';
import '../repositories/tag_repository.dart';
import '../widgets/quote_card.dart';
import '../widgets/search_bar.dart';
import 'quote_detail_screen.dart';
import 'quote_edit_screen.dart';

class QuotesScreen extends StatefulWidget {
  const QuotesScreen({super.key});

  @override
  State<QuotesScreen> createState() => _QuotesScreenState();
}

class _QuotesScreenState extends State<QuotesScreen> {
  final QuoteRepository _quoteRepository = QuoteRepository();
  final TagRepository _tagRepository = TagRepository();
  late final QuoteController _controller = QuoteController(
    quoteRepository: _quoteRepository,
    tagRepository: _tagRepository,
  );
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _itemKeys = <int, GlobalKey>{};

  StreamSubscription<dynamic>? _quotesSub;
  StreamSubscription<dynamic>? _tagsSub;
  int _centeredIndex = 0;

  @override
  void initState() {
    super.initState();
    _quotesSub = _quoteRepository.watch().listen((_) => _onStorageChanged());
    _tagsSub = _tagRepository.watch().listen((_) => _onStorageChanged());
    _scrollController.addListener(_onScroll);
    _controller.loadInitial();
  }

  @override
  void dispose() {
    _quotesSub?.cancel();
    _tagsSub?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final filtered = _controller.filteredQuotes;
        if (_centeredIndex >= filtered.length && filtered.isNotEmpty) {
          _centeredIndex = filtered.length - 1;
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _updateCenteredIndex(filtered.length);
        });

        return Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openCreate,
            backgroundColor: const Color(0xFF4A6FA5),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('Новая запись'),
          ),
          appBar: AppBar(
            title: const Text(
              'MEMRYTH',
              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.8),
            ),
            actions: [
              PopupMenuButton<QuoteSortMode>(
                tooltip: 'Сортировка',
                initialValue: _controller.sortMode,
                onSelected: _controller.setSortMode,
                color: const Color(0xFFF5EEE7),
                surfaceTintColor: Colors.transparent,
                elevation: 10,
                position: PopupMenuPosition.under,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: Color(0xFFD8CEC5), width: 1.2),
                ),
                itemBuilder: (context) {
                  return [
                    for (final mode in QuoteSortMode.values)
                      PopupMenuItem(
                        value: mode,
                        child: _SortMenuItem(
                          label: mode.label,
                          selected: mode == _controller.sortMode,
                        ),
                      ),
                  ];
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5EEE7),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFD8CEC5),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.sort_rounded,
                          size: 18,
                          color: Color(0xFF6E6258),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _controller.sortMode.label,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C2C2C),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: Color(0xFF6E6258),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  color: const Color(0xFFF5F0E6),
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Column(
                    children: [
                      QuoteSearchBar(
                        controller: _searchController,
                        onChanged: _controller.setSearchQuery,
                        onClear: () {
                          _searchController.clear();
                          _controller.setSearchQuery('');
                        },
                      ),
                      const SizedBox(height: 10),
                      _buildFilterPanel(),
                    ],
                  ),
                ),
                if (filtered.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 2),
                    child: Text(
                      '${_centeredIndex + 1} / ${filtered.length}',
                      style: const TextStyle(
                        color: Color(0xFF2C2C2C),
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                if (_hasActiveFilters)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          if (_controller.favoritesOnly)
                            InputChip(
                              label: const Text('Только избранное'),
                              selected: true,
                              onDeleted: _controller.toggleFavoritesOnly,
                            ),
                          if (_controller.activeTypeFilter != null)
                            InputChip(
                              label: Text(_controller.activeTypeFilter!.label),
                              selected: true,
                              onDeleted: () => _controller.setTypeFilter(null),
                            ),
                          for (final tag in _controller.activeTagFilters)
                            InputChip(
                              label: Text(tag),
                              selected: true,
                              onDeleted: () => _controller.removeTagFilter(tag),
                            ),
                          if (_controller.searchQuery.trim().isNotEmpty)
                            InputChip(
                              label: Text(
                                'Поиск: ${_controller.searchQuery.trim()}',
                              ),
                              selected: true,
                              onDeleted: () {
                                _searchController.clear();
                                _controller.setSearchQuery('');
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: filtered.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final quote = filtered[index];
                            final key = _itemKeys.putIfAbsent(
                              index,
                              () => GlobalKey(),
                            );
                            return Padding(
                              key: key,
                              padding: const EdgeInsets.only(bottom: 10),
                              child: QuoteCard(
                                quote: quote,
                                tags: _controller.tagsForQuote(quote),
                                query: _controller.searchQuery,
                                activeTagFilters: _controller.activeTagFilters,
                                onTagTap: _controller.toggleTagFilter,
                                onTap: () => _openDetails(quote),
                                onFavoriteToggle: () =>
                                    _controller.toggleFavorite(quote),
                                onLongPressStart: (details) =>
                                    _showQuoteMenu(quote, details),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool get _hasActiveFilters {
    return _controller.searchQuery.trim().isNotEmpty ||
        _controller.activeTagFilters.isNotEmpty ||
        _controller.activeTypeFilter != null ||
        _controller.favoritesOnly;
  }

  Widget _buildFilterPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              label: const Text('Избранное'),
              selected: _controller.favoritesOnly,
              onSelected: (_) => _controller.toggleFavoritesOnly(),
            ),
            for (final type in QuoteType.values)
              ChoiceChip(
                label: Text(type.label),
                selected: _controller.activeTypeFilter == type,
                onSelected: (_) {
                  _controller.setTypeFilter(
                    _controller.activeTypeFilter == type ? null : type,
                  );
                },
              ),
          ],
        ),
        if (_controller.allTagsSorted.isNotEmpty) ...[
          const SizedBox(height: 10),
          const Text(
            'Теги',
            style: TextStyle(
              color: Color(0xFF8B7E74),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final tag in _controller.allTagsSorted) ...[
                  FilterChip(
                    label: Text(tag.name),
                    selected: _controller.activeTagFilters.contains(tag.name),
                    onSelected: (_) => _controller.toggleTagFilter(tag.name),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    if (_controller.totalCount == 0) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Пока нет записей. Нажмите “Новая запись”, чтобы добавить первую.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF2C2C2C)),
          ),
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Ничего не найдено по текущему фильтру',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF2C2C2C)),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () {
              _searchController.clear();
              _controller.clearFilters();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF4A6FA5),
              side: const BorderSide(color: Color(0xFFD8CEC5), width: 1.2),
            ),
            child: const Text('Сбросить фильтры'),
          ),
        ],
      ),
    );
  }

  Future<void> _showQuoteMenu(
    Quote quote,
    LongPressStartDetails details,
  ) async {
    final action = await showGeneralDialog<String>(
      context: context,
      barrierLabel: 'quote-actions',
      barrierDismissible: true,
      barrierColor: const Color(0x22000000),
      transitionDuration: const Duration(milliseconds: 140),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _QuoteActionMenu(anchor: details.globalPosition);
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );

    if (!mounted || action == null) return;
    if (action == 'read') {
      await _openDetails(quote);
      return;
    }
    if (action == 'edit') {
      await _openEdit(quote);
      return;
    }
    if (action == 'copy') {
      await _copyQuoteToClipboard(quote);
      return;
    }
    if (action == 'delete') {
      await _deleteQuote(quote.id);
    }
  }

  Future<void> _copyQuoteToClipboard(Quote quote) async {
    final buffer = StringBuffer(quote.text.trim());
    if (quote.author.trim().isNotEmpty) {
      buffer.write('\n— ${quote.author.trim()}');
    }
    if (quote.sourceTitle.trim().isNotEmpty) {
      buffer.write('\n${quote.sourceTitle.trim()}');
    }
    if (quote.sourceDetails.trim().isNotEmpty) {
      buffer.write('\n${quote.sourceDetails.trim()}');
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Запись скопирована'),
          duration: Duration(seconds: 2),
        ),
      );
  }

  Future<void> _openCreate() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuoteEditScreen(
          quoteRepository: _quoteRepository,
          tagRepository: _tagRepository,
        ),
      ),
    );
  }

  Future<void> _openEdit(Quote quote) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuoteEditScreen(
          quoteRepository: _quoteRepository,
          tagRepository: _tagRepository,
          quote: quote,
        ),
      ),
    );
  }

  Future<void> _openDetails(Quote quote) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuoteDetailScreen(
          quote: quote,
          tags: _controller.tagsForQuote(quote),
          quoteRepository: _quoteRepository,
          tagRepository: _tagRepository,
        ),
      ),
    );
  }

  Future<void> _deleteQuote(String quoteId) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Удалить запись?'),
          content: const Text('Это действие нельзя отменить.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB84A3A),
                foregroundColor: Colors.white,
              ),
              child: const Text('Удалить'),
            ),
          ],
        );
      },
    );

    if (approved == true) {
      await _quoteRepository.deleteById(quoteId);
    }
  }

  void _onStorageChanged() {
    _controller.refreshFromStorage();
    _itemKeys.clear();
  }

  void _onScroll() {
    _updateCenteredIndex(_controller.filteredQuotes.length);
  }

  void _updateCenteredIndex(int itemCount) {
    if (!mounted || itemCount == 0) return;

    final viewport = context.findRenderObject() as RenderBox?;
    if (viewport == null) return;
    final centerY = viewport.size.height / 2;

    var bestIndex = _centeredIndex;
    var bestDistance = double.infinity;

    for (final entry in _itemKeys.entries) {
      final itemContext = entry.value.currentContext;
      if (itemContext == null) continue;
      final box = itemContext.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) continue;

      final topLeft = box.localToGlobal(Offset.zero);
      final itemCenterY = topLeft.dy + box.size.height / 2;
      final distance = (itemCenterY - centerY).abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        bestIndex = entry.key;
      }
    }

    if (bestIndex != _centeredIndex && bestIndex < itemCount) {
      setState(() => _centeredIndex = bestIndex);
    }
  }
}

class _QuoteActionMenu extends StatelessWidget {
  const _QuoteActionMenu({required this.anchor});

  final Offset anchor;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    const menuWidth = 220.0;
    const menuHeight = 208.0;
    const margin = 12.0;
    const gapToAnchor = 14.0;
    const arrowSize = 12.0;

    final showOnRight = anchor.dx < (screen.width / 2);
    var left = showOnRight
        ? anchor.dx + gapToAnchor
        : anchor.dx - menuWidth - gapToAnchor;
    left = left.clamp(margin, screen.width - menuWidth - margin);

    var top = anchor.dy - (menuHeight / 2);
    top = top.clamp(margin, screen.height - menuHeight - margin);

    var arrowTop = anchor.dy - top - (arrowSize / 2);
    arrowTop = arrowTop.clamp(16.0, menuHeight - 16.0 - arrowSize);

    final arrowLeft = showOnRight ? left - arrowSize + 1 : left + menuWidth - 1;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              behavior: HitTestBehavior.opaque,
            ),
          ),
          Positioned(
            left: arrowLeft,
            top: top + arrowTop,
            child: CustomPaint(
              size: const Size(12, 12),
              painter: _MenuArrowPainter(
                color: const Color(0xFFF5EEE7),
                pointLeft: !showOnRight,
              ),
            ),
          ),
          Positioned(
            left: left,
            top: top,
            child: Container(
              width: menuWidth,
              height: menuHeight,
              decoration: BoxDecoration(
                color: const Color(0xFFF5EEE7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD8CEC5), width: 1.2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _MenuItem(
                    label: 'Открыть',
                    onTap: () => Navigator.of(context).pop('read'),
                    isTop: true,
                  ),
                  const _DividerLine(),
                  _MenuItem(
                    label: 'Редактировать',
                    onTap: () => Navigator.of(context).pop('edit'),
                  ),
                  const _DividerLine(),
                  _MenuItem(
                    label: 'Копировать',
                    onTap: () => Navigator.of(context).pop('copy'),
                  ),
                  const _DividerLine(),
                  _MenuItem(
                    label: 'Удалить',
                    onTap: () => Navigator.of(context).pop('delete'),
                    isBottom: true,
                    color: const Color(0xFFB84A3A),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.label,
    required this.onTap,
    this.color = const Color(0xFF2C2C2C),
    this.isTop = false,
    this.isBottom = false,
  });

  final String label;
  final VoidCallback onTap;
  final Color color;
  final bool isTop;
  final bool isBottom;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.vertical(
          top: isTop ? const Radius.circular(16) : Radius.zero,
          bottom: isBottom ? const Radius.circular(16) : Radius.zero,
        ),
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

class _DividerLine extends StatelessWidget {
  const _DividerLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 22),
      color: const Color(0xFFD8CEC5),
    );
  }
}

class _SortMenuItem extends StatelessWidget {
  const _SortMenuItem({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: const Color(0xFF2C2C2C),
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
        if (selected)
          const Icon(Icons.check_rounded, size: 18, color: Color(0xFF4A6FA5)),
      ],
    );
  }
}

class _MenuArrowPainter extends CustomPainter {
  _MenuArrowPainter({required this.color, required this.pointLeft});

  final Color color;
  final bool pointLeft;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();

    if (pointLeft) {
      path
        ..moveTo(size.width, 0)
        ..lineTo(0, size.height / 2)
        ..lineTo(size.width, size.height)
        ..close();
    } else {
      path
        ..moveTo(0, 0)
        ..lineTo(size.width, size.height / 2)
        ..lineTo(0, size.height)
        ..close();
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MenuArrowPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.pointLeft != pointLeft;
  }
}
