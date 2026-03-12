# Contributing

Thank you for contributing to MEMRYTH.

## Workflow

1. Fork the repository or create a feature branch if you have access.
2. Create a branch from `main`:
   - `feature/<short-description>` for new features
   - `fix/<short-description>` for bug fixes
3. Make focused changes with clear commit messages.
4. Run local checks before opening a pull request.

## Local Checks

```bash
flutter pub get
flutter analyze
flutter test
dart format lib test
```

## Pull Request Requirements

- Clear title and description of the change
- Screenshots for UI changes
- Small and focused scope
- Related issue link if available

## Coding Notes

- Follow Dart style and lints from `analysis_options.yaml`
- Avoid committing generated build artifacts
- Never commit secrets such as `.env`, keys, or keystores

---

# Вклад в проект

Спасибо за вклад в MEMRYTH.

## Рабочий процесс

1. Сделайте форк репозитория или создайте feature-ветку, если у вас есть доступ.
2. Создайте ветку от `main`:
   - `feature/<краткое-описание>` для новых возможностей
   - `fix/<краткое-описание>` для исправлений
3. Вносите небольшие и сфокусированные изменения с понятными сообщениями коммитов.
4. Перед Pull Request запускайте локальные проверки.

## Локальные проверки

```bash
flutter pub get
flutter analyze
flutter test
dart format lib test
```

## Требования к Pull Request

- Понятный заголовок и описание изменений
- Скриншоты для изменений интерфейса
- Небольшой и сфокусированный объем изменений
- Ссылка на связанный issue, если он есть

## Заметки по коду

- Следуйте стилю Dart и правилам из `analysis_options.yaml`
- Не коммитьте артефакты сборки
- Никогда не коммитьте секреты: `.env`, ключи, keystore
