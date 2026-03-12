import 'package:hive/hive.dart';

import '../models/quote.dart';
import '../models/tag.dart';

class DemoSeed {
  static Future<void> ensureSeeded() async {
    final tagsBox = Hive.box<Tag>('tags');
    final quotesBox = Hive.box<Quote>('quotes');

    if (tagsBox.isNotEmpty || quotesBox.isNotEmpty) {
      return;
    }

    final tags = <Tag>[
      Tag(id: 'tag-reading', name: 'чтение'),
      Tag(id: 'tag-writing', name: 'письмо'),
      Tag(id: 'tag-focus', name: 'фокус'),
      Tag(id: 'tag-product', name: 'продукт'),
      Tag(id: 'tag-reflection', name: 'рефлексия'),
      Tag(id: 'tag-ui', name: 'интерфейс'),
      Tag(id: 'tag-career', name: 'карьера'),
      Tag(id: 'tag-book', name: 'книга'),
      Tag(id: 'tag-idea', name: 'идея'),
      Tag(id: 'tag-discipline', name: 'дисциплина'),
    ];

    final quotes = <Quote>[
      Quote(
        id: 'entry-001',
        text:
            'Чтение нужно не только для сбора красивых фраз. Оно помогает точнее видеть мир и принимать более зрелые решения.',
        author: 'Шейн Пэрриш',
        tagIds: const ['tag-reading', 'tag-reflection', 'tag-book'],
        typeKey: QuoteType.quote.key,
        createdAt: DateTime(2025, 10, 11, 8, 30),
        updatedAt: DateTime(2026, 3, 10, 19, 40),
        isFavorite: true,
        sourceTitle: 'The Knowledge Project',
        sourceDetails: 'Конспект эпизода',
        note: 'Подходит как сильная цитата для главного экрана и избранного.',
      ),
      Quote(
        id: 'entry-002',
        text:
            'Если мысль действительно важна, ее нужно не просто сохранить, а переписать своими словами.',
        author: '',
        tagIds: const ['tag-writing', 'tag-reflection', 'tag-idea'],
        typeKey: QuoteType.thought.key,
        createdAt: DateTime(2026, 1, 14, 22, 5),
        updatedAt: DateTime(2026, 3, 8, 9, 12),
        isFavorite: true,
        sourceTitle: 'Вечерний обзор',
        sourceDetails: 'Личные заметки',
        note: 'Хороший пример типа Мысль без заполненного автора.',
      ),
      Quote(
        id: 'entry-003',
        text:
            'Продукт кажется спокойным, когда каждый экран хорошо отвечает на один вопрос, а не плохо пытается ответить сразу на десять.',
        author: 'Внутренняя сессия',
        tagIds: const ['tag-product', 'tag-ui', 'tag-focus'],
        typeKey: QuoteType.excerpt.key,
        createdAt: DateTime(2025, 12, 2, 13, 15),
        updatedAt: DateTime(2026, 3, 6, 21, 44),
        sourceTitle: 'Заметки UX-воркшопа',
        sourceDetails: 'Блок 3, страница 2',
        note: 'Удобный фрагмент для проверки длинного текста и метаданных.',
      ),
      Quote(
        id: 'entry-004',
        text:
            'Дисциплина — это уменьшение количества переговоров с самим собой.',
        author: 'Джеймс Клир',
        tagIds: const ['tag-discipline', 'tag-focus'],
        typeKey: QuoteType.quote.key,
        createdAt: DateTime(2025, 7, 19, 6, 45),
        updatedAt: DateTime(2026, 2, 28, 7, 0),
        isFavorite: true,
        sourceTitle: 'Atomic Habits',
        sourceDetails: 'Выделенный фрагмент',
        note: 'Короткая цитата для компактной карточки и скриншота списка.',
      ),
      Quote(
        id: 'entry-005',
        text:
            'Когда я сохраняю фрагмент, нужно сохранить и причину. Контекст превращает архив в память.',
        author: '',
        tagIds: const ['tag-idea', 'tag-reflection'],
        typeKey: QuoteType.thought.key,
        createdAt: DateTime(2026, 2, 9, 18, 22),
        updatedAt: DateTime(2026, 3, 9, 18, 22),
        sourceTitle: 'Дневник продукта',
        sourceDetails: 'Итерация 4',
        note: 'Показывает, зачем в приложении есть поле личной заметки.',
      ),
      Quote(
        id: 'entry-006',
        text:
            'Хороший интерфейсный текст всегда операционный: он объясняет, что произойдет дальше и почему это важно.',
        author: 'Сессия по UX-копирайтингу',
        tagIds: const ['tag-ui', 'tag-writing', 'tag-product'],
        typeKey: QuoteType.excerpt.key,
        createdAt: DateTime(2025, 11, 4, 11, 5),
        updatedAt: DateTime(2026, 3, 7, 16, 33),
        sourceTitle: 'Расшифровка воркшопа',
        sourceDetails: 'Таймкод 14:22',
        note: 'Полезно для проверки поиска по деталям источника.',
      ),
      Quote(
        id: 'entry-007',
        text:
            'Карьерные решения накапливаются как привычки: один ясный год часто важнее пяти шумных.',
        author: '',
        tagIds: const ['tag-career', 'tag-focus', 'tag-reflection'],
        typeKey: QuoteType.thought.key,
        createdAt: DateTime(2026, 1, 3, 7, 50),
        updatedAt: DateTime(2026, 3, 3, 20, 15),
        sourceTitle: 'Квартальное планирование',
        sourceDetails: 'Страница 1',
        note: 'Еще один пример личной мысли с сильным формулированием.',
      ),
      Quote(
        id: 'entry-008',
        text:
            'Лучшие выделенные фразы можно вынести из книги и применить к реальному решению уже сегодня.',
        author: 'Энни Дьюк',
        tagIds: const ['tag-book', 'tag-reading', 'tag-product'],
        typeKey: QuoteType.quote.key,
        createdAt: DateTime(2025, 8, 27, 9, 0),
        updatedAt: DateTime(2026, 3, 1, 12, 48),
        sourceTitle: 'Thinking in Bets',
        sourceDetails: 'Глава 6',
        note: 'Подходит для показа автора, источника и нескольких тегов.',
      ),
      Quote(
        id: 'entry-009',
        text:
            'Дизайн-система должна убирать повторяющиеся решения, а не убирать характер продукта.',
        author: 'Ретроспектива команды',
        tagIds: const ['tag-ui', 'tag-product'],
        typeKey: QuoteType.excerpt.key,
        createdAt: DateTime(2025, 9, 15, 17, 10),
        updatedAt: DateTime(2026, 3, 5, 14, 9),
        sourceTitle: 'Итоги ретро',
        sourceDetails: 'Экспорт доски',
        note: 'Удобный фрагмент для скриншота с типом Фрагмент.',
      ),
      Quote(
        id: 'entry-010',
        text:
            'Если я не могу найти сохраненную идею меньше чем за десять секунд, значит я ее по-настоящему не сохранил.',
        author: '',
        tagIds: const ['tag-focus', 'tag-idea', 'tag-writing'],
        typeKey: QuoteType.thought.key,
        createdAt: DateTime(2026, 2, 20, 10, 40),
        updatedAt: DateTime(2026, 3, 11, 8, 2),
        sourceTitle: 'Концепция Memryth',
        sourceDetails: 'Базовый принцип',
        note: 'Хорошо отражает основную идею приложения.',
      ),
    ];

    await tagsBox.putAll({for (final tag in tags) tag.id: tag});
    await quotesBox.putAll({for (final quote in quotes) quote.id: quote});
  }
}
