import 'package:flutter/material.dart';

import '../settings/app_settings.dart';
import '../settings/app_settings_controller.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.controller});

  final AppSettingsController controller;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = _OnboardingText(widget.controller.settings.language);
    final pages = text.pages;
    final isLast = _page == pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: _finish, child: Text(text.skip)),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (value) => setState(() => _page = value),
                  itemCount: pages.length,
                  itemBuilder: (context, index) {
                    return _OnboardingPage(data: pages[index]);
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var index = 0; index < pages.length; index++)
                    _PageDot(active: index == _page),
                ],
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isLast ? _finish : _next,
                  icon: Icon(
                    isLast ? Icons.check_rounded : Icons.arrow_forward_rounded,
                  ),
                  label: Text(isLast ? text.start : text.next),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _next() async {
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish() async {
    await widget.controller.completeOnboarding();
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data});

  final _OnboardingPageData data;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withAlpha(28),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(
                data.icon,
                size: 44,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              data.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                height: 1.12,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              data.body,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).hintColor,
                fontSize: 16,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageDot extends StatelessWidget {
  const _PageDot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: active ? 22 : 8,
      height: 8,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: active
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).dividerColor,
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}

class _OnboardingText {
  const _OnboardingText(this.language);

  final AppLanguage language;

  bool get isRu => language == AppLanguage.ru;

  String get skip => isRu ? 'Пропустить' : 'Skip';
  String get next => isRu ? 'Дальше' : 'Next';
  String get start => isRu ? 'Начать' : 'Start';

  List<_OnboardingPageData> get pages {
    if (isRu) {
      return const [
        _OnboardingPageData(
          icon: Icons.edit_note_rounded,
          title: 'Сохраняйте мысли, цитаты и фрагменты',
          body:
              'MEMRYTH помогает быстро собрать важные текстовые записи в личной офлайн-библиотеке.',
        ),
        _OnboardingPageData(
          icon: Icons.sell_rounded,
          title: 'Добавляйте контекст',
          body:
              'Темы, источник, автор и личная заметка помогают понять, зачем запись была сохранена.',
        ),
        _OnboardingPageData(
          icon: Icons.manage_search_rounded,
          title: 'Возвращайтесь к нужному быстрее',
          body:
              'Поиск, темы, типы записей и избранное помогают находить сохранённое без лишнего шума.',
        ),
      ];
    }

    return const [
      _OnboardingPageData(
        icon: Icons.edit_note_rounded,
        title: 'Save thoughts, quotes and excerpts',
        body:
            'MEMRYTH keeps meaningful text in a private offline library on your device.',
      ),
      _OnboardingPageData(
        icon: Icons.sell_rounded,
        title: 'Keep the context',
        body:
            'Topics, source, author and personal notes explain why each entry matters.',
      ),
      _OnboardingPageData(
        icon: Icons.manage_search_rounded,
        title: 'Return quickly',
        body:
            'Search, topics, entry types and favorites help you find saved meaning fast.',
      ),
    ];
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}
