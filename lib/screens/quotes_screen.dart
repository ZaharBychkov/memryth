import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../contollers/quote_contoller.dart';
import '../models/quote.dart';
import '../repositories/quote_repository.dart';
import '../repositories/tag_repository.dart';
import '../widgets/quote_card.dart';
import '../widgets/search_bar.dart';
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
          floatingActionButton: FloatingActionButton(
            onPressed: _openCreate,
            backgroundColor: const Color(0xFF4A6FA5),
            foregroundColor: Colors.white,
            child: const Icon(Icons.add),
          ),
          appBar: AppBar(
            title: const Text(
              'MEMRYTH',
              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.8),
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  color: const Color(0xFFF5F0E6),
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: QuoteSearchBar(
                    controller: _searchController,
                    onChanged: _controller.setSearchQuery,
                    onClear: () {
                      _searchController.clear();
                      _controller.setSearchQuery('');
                    },
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
                if (_controller.activeTagFilters.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          for (final tag in _controller.activeTagFilters)
                            InputChip(
                              label: Text(tag),
                              selected: true,
                              side: const BorderSide(
                                color: Color(0xFFD8CEC5),
                                width: 1.2,
                              ),
                              backgroundColor: const Color(0xFFF5EEE7),
                              onDeleted: () => _controller.removeTagFilter(tag),
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
                            final key = _itemKeys.putIfAbsent(index, () => GlobalKey());
                            return Padding(
                              key: key,
                              padding: const EdgeInsets.only(bottom: 10),
                              child: QuoteCard(
                                quote: quote,
                                tags: _controller.tagsForQuote(quote),
                                query: _controller.searchQuery,
                                activeTagFilters: _controller.activeTagFilters,
                                onTagTap: _controller.toggleTagFilter,
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

  Widget _buildEmptyState() {
    if (_controller.totalCount == 0) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Пока нет цитат. Нажмите + чтобы добавить первую.',
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
              _controller.setSearchQuery('');
              for (final tag in _controller.activeTagFilters.toList()) {
                _controller.removeTagFilter(tag);
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF4A6FA5),
              side: const BorderSide(color: Color(0xFFD8CEC5), width: 1.2),
            ),
            child: const Text('Очистить фильтр'),
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
        return _QuoteActionMenu(
          anchor: details.globalPosition,
        );
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
    final text = quote.text.trim();
    final author = quote.author.trim();
    final formatted = author.isEmpty ? text : '$text\n- $author';

    await Clipboard.setData(ClipboardData(text: formatted));
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Цитата скопирована'),
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

  Future<void> _deleteQuote(String quoteId) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Удалить цитату?'),
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
  const _QuoteActionMenu({
    required this.anchor,
  });

  final Offset anchor;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    const menuWidth = 210.0;
    const menuHeight = 162.0;
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
                  Expanded(
                    child: InkWell(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      onTap: () => Navigator.of(context).pop('edit'),
                      child: const Center(
                        child: Text(
                          'Редактировать',
                          style: TextStyle(
                            color: Color(0xFF2C2C2C),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 22),
                    color: const Color(0xFFD8CEC5),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop('copy'),
                      child: const Center(
                        child: Text(
                          'Копировать',
                          style: TextStyle(
                            color: Color(0xFF2C2C2C),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 22),
                    color: const Color(0xFFD8CEC5),
                  ),
                  Expanded(
                    child: InkWell(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(16),
                      ),
                      onTap: () => Navigator.of(context).pop('delete'),
                      child: const Center(
                        child: Text(
                          'Удалить',
                          style: TextStyle(
                            color: Color(0xFFB84A3A),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
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

class _MenuArrowPainter extends CustomPainter {
  _MenuArrowPainter({
    required this.color,
    required this.pointLeft,
  });

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

