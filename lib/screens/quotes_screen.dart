import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../contollers/quote_contoller.dart';
import '../models/quote.dart';
import '../repositories/quote_repository.dart';
import '../repositories/tag_repository.dart';
import '../settings/app_settings_scope.dart';
import '../settings/app_strings.dart';
import '../widgets/quote_card.dart';
import '../widgets/search_bar.dart';
import '../widgets/settings_drawer.dart';
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _itemKeys = <int, GlobalKey>{};

  QuoteController? _controller;
  StreamSubscription<dynamic>? _quotesSub;
  StreamSubscription<dynamic>? _tagsSub;
  int _centeredIndex = 0;

  @override
  void initState() {
    super.initState();
    _quotesSub = _quoteRepository.watch().listen((_) => _onStorageChanged());
    _tagsSub = _tagRepository.watch().listen((_) => _onStorageChanged());
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = AppSettingsScope.of(context).settings;
    _controller ??= QuoteController(
      quoteRepository: _quoteRepository,
      tagRepository: _tagRepository,
      initialSortMode: settings.defaultSortMode,
    )..loadInitial();

    if (_controller!.sortMode != settings.defaultSortMode) {
      _controller!.setSortMode(settings.defaultSortMode);
    }
  }

  @override
  void dispose() {
    _quotesSub?.cancel();
    _tagsSub?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsController = AppSettingsScope.of(context);
    final strings = AppStrings(settingsController.settings.language);
    final controller = _controller;
    if (controller == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerBg = isDark ? const Color(0xFF1A1E24) : const Color(0xFFF5F0E6);

    return AnimatedBuilder(
      animation: Listenable.merge([controller, settingsController]),
      builder: (context, _) {
        final filtered = controller.filteredQuotes;
        if (_centeredIndex >= filtered.length && filtered.isNotEmpty) {
          _centeredIndex = filtered.length - 1;
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _updateCenteredIndex(filtered.length);
        });

        return Scaffold(
          key: _scaffoldKey,
          endDrawer: SettingsDrawer(controller: settingsController),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openCreate,
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: Text(strings.newEntry),
          ),
          appBar: AppBar(
            centerTitle: true,
            leadingWidth: 104,
            leading: Row(
              children: [
                const SizedBox(width: 8),
                PopupMenuButton<QuoteSortMode>(
                  tooltip: strings.sortTooltip,
                  initialValue: controller.sortMode,
                  onSelected: controller.setSortMode,
                  color: isDark
                      ? const Color(0xFF232830)
                      : const Color(0xFFF5EEE7),
                  surfaceTintColor: Colors.transparent,
                  elevation: 10,
                  position: PopupMenuPosition.under,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(
                      color: Theme.of(context).dividerColor,
                      width: 1.2,
                    ),
                  ),
                  itemBuilder: (context) => [
                    for (final mode in QuoteSortMode.values)
                      PopupMenuItem(
                        value: mode,
                        child: _SortMenuItem(
                          label: strings.sortModeLabel(mode),
                          selected: mode == controller.sortMode,
                        ),
                      ),
                  ],
                  child: _HeaderIconShell(
                    child: Icon(
                      Icons.sort_rounded,
                      color: isDark
                          ? const Color(0xFFEAE4DB)
                          : const Color(0xFF2C2C2C),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _HeaderIconButton(
                  onPressed: () => settingsController.toggleTheme(),
                  child: Icon(
                    settingsController.settings.isDarkMode
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                    color: isDark
                        ? const Color(0xFFEAE4DB)
                        : const Color(0xFF2C2C2C),
                  ),
                ),
              ],
            ),
            title: Text(
              strings.appTitle,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            actions: [
              SizedBox(
                width: 104,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _HeaderIconButton(
                      onPressed: () =>
                          _scaffoldKey.currentState?.openEndDrawer(),
                      child: Icon(
                        Icons.tune_rounded,
                        color: isDark
                            ? const Color(0xFFEAE4DB)
                            : const Color(0xFF2C2C2C),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  color: headerBg,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Column(
                    children: [
                      QuoteSearchBar(
                        controller: _searchController,
                        hintText: strings.searchHint,
                        onChanged: controller.setSearchQuery,
                        onClear: () {
                          _searchController.clear();
                          controller.setSearchQuery('');
                        },
                      ),
                      const SizedBox(height: 10),
                      _buildTypeFiltersRow(controller, strings, isDark),
                    ],
                  ),
                ),
                if (filtered.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 2),
                    child: Text(
                      '${_centeredIndex + 1} / ${filtered.length}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                Expanded(
                  child: filtered.isEmpty
                      ? _buildEmptyState(controller, strings)
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
                              padding: EdgeInsets.only(
                                bottom: settingsController
                                    .settings
                                    .cardDensity
                                    .cardSpacing,
                              ),
                              child: QuoteCard(
                                quote: quote,
                                tags: controller.tagsForQuote(quote),
                                query: controller.searchQuery,
                                activeTagFilters: controller.activeTagFilters,
                                onTagTap: controller.toggleTagFilter,
                                onTap: () => _openDetails(quote),
                                onFavoriteToggle: () =>
                                    controller.toggleFavorite(quote),
                                onLongPressStart: (details) =>
                                    _showQuoteMenu(quote, details, strings),
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

  Widget _buildTypeFiltersRow(
    QuoteController controller,
    AppStrings strings,
    bool isDark,
  ) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              for (var index = 0; index < QuoteType.values.length; index++) ...[
                Expanded(
                  child: _TypeFilterButton(
                    label: strings.quoteTypeLabel(QuoteType.values[index]),
                    selected: controller.activeTypeFilters.contains(
                      QuoteType.values[index],
                    ),
                    onTap: () =>
                        controller.toggleTypeFilter(QuoteType.values[index]),
                  ),
                ),
                if (index < QuoteType.values.length - 1)
                  const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        _FavoriteFilterButton(
          selected: controller.favoritesOnly,
          onTap: controller.toggleFavoritesOnly,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildEmptyState(QuoteController controller, AppStrings strings) {
    if (controller.totalCount == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(strings.emptyList, textAlign: TextAlign.center),
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(strings.emptyFilter, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () {
              _searchController.clear();
              controller.clearFilters();
            },
            child: Text(strings.resetFilters),
          ),
        ],
      ),
    );
  }

  Future<void> _showQuoteMenu(
    Quote quote,
    LongPressStartDetails details,
    AppStrings strings,
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
          strings: strings,
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
    if (action == 'read') {
      await _openDetails(quote);
      return;
    }
    if (action == 'edit') {
      await _openEdit(quote);
      return;
    }
    if (action == 'copy') {
      await _copyQuoteToClipboard(quote, strings);
      return;
    }
    if (action == 'delete') {
      await _deleteQuote(quote.id, strings);
    }
  }

  Future<void> _copyQuoteToClipboard(Quote quote, AppStrings strings) async {
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
        SnackBar(
          content: Text(strings.copied),
          duration: const Duration(seconds: 2),
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
          tags: _controller!.tagsForQuote(quote),
          quoteRepository: _quoteRepository,
          tagRepository: _tagRepository,
        ),
      ),
    );
  }

  Future<void> _deleteQuote(String quoteId, AppStrings strings) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(strings.deleteEntry),
          content: Text(strings.deleteWarning),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(strings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB84A3A),
                foregroundColor: Colors.white,
              ),
              child: Text(strings.delete),
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
    _controller?.refreshFromStorage();
    _itemKeys.clear();
  }

  void _onScroll() {
    final controller = _controller;
    if (controller == null) return;
    _updateCenteredIndex(controller.filteredQuotes.length);
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

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.onPressed, required this.child});

  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(14),
      child: _HeaderIconShell(child: child),
    );
  }
}

class _HeaderIconShell extends StatelessWidget {
  const _HeaderIconShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? const Color(0xFF262B33) : const Color(0xFFF5EEE7),
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(width: 42, height: 42, child: Center(child: child)),
    );
  }
}

class _TypeFilterButton extends StatelessWidget {
  const _TypeFilterButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(
                  context,
                ).colorScheme.primary.withAlpha(isDark ? 56 : 36)
              : (isDark ? const Color(0xFF262B33) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).dividerColor,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FavoriteFilterButton extends StatelessWidget {
  const _FavoriteFilterButton({
    required this.selected,
    required this.onTap,
    required this.isDark,
  });

  final bool selected;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final inactiveColor = isDark
        ? const Color(0xFFD7CEC3)
        : const Color(0xFF6E6258);
    final activeColor = isDark
        ? const Color(0xFFEAE4DB)
        : const Color(0xFF4E4035);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF262B33) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? activeColor : Theme.of(context).dividerColor,
          ),
        ),
        child: Icon(
          selected ? Icons.star_rounded : Icons.star_border_rounded,
          size: 20,
          color: selected ? activeColor : inactiveColor,
        ),
      ),
    );
  }
}

class _QuoteActionMenu extends StatelessWidget {
  const _QuoteActionMenu({required this.anchor, required this.strings});

  final Offset anchor;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    const menuWidth = 220.0;
    const menuHeight = 208.0;
    const margin = 12.0;
    const gapToAnchor = 14.0;
    const arrowSize = 12.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark
        ? const Color(0xFF232830)
        : const Color(0xFFF5EEE7);

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
                color: background,
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
                color: background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                  width: 1.2,
                ),
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
                    label: strings.open,
                    onTap: () => Navigator.of(context).pop('read'),
                    isTop: true,
                  ),
                  const _DividerLine(),
                  _MenuItem(
                    label: strings.edit,
                    onTap: () => Navigator.of(context).pop('edit'),
                  ),
                  const _DividerLine(),
                  _MenuItem(
                    label: strings.copy,
                    onTap: () => Navigator.of(context).pop('copy'),
                  ),
                  const _DividerLine(),
                  _MenuItem(
                    label: strings.delete,
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
    this.color,
    this.isTop = false,
    this.isBottom = false,
  });

  final String label;
  final VoidCallback onTap;
  final Color? color;
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
            style: TextStyle(
              color: color ?? Theme.of(context).textTheme.bodyLarge?.color,
              fontWeight: FontWeight.w600,
            ),
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
      color: Theme.of(context).dividerColor,
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
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
        if (selected)
          Icon(
            Icons.check_rounded,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
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
