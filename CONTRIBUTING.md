# Contributing

Thank you for contributing to MEMRYTH.

## Workflow

1. Fork the repository (or create a feature branch if you have access).
2. Create a branch from `main`:
   - `feature/<short-description>` for new features
   - `fix/<short-description>` for bug fixes
3. Make focused changes with clear commit messages.
4. Run checks locally before opening a pull request.

## Local Checks

```bash
flutter pub get
flutter analyze
flutter test
dart format lib test
```

## Pull Request Requirements

- Clear title and description of the change.
- Include screenshots for UI changes.
- Keep PRs small and focused.
- Link related issues if available.

## Coding Notes

- Follow Dart style and lints from `analysis_options.yaml`.
- Avoid committing generated build artifacts.
- Never commit secrets (`.env`, keys, keystores).

---

# Вклад в проект (русская версия)

Спасибо за вклад в MEMRYTH.

## Рабочий процесс

1. Сделайте форк репозитория (или создайте feature-ветку, если есть доступ).
2. Создайте ветку от `main`:
   - `feature/<краткое-описание>` для новых фич
   - `fix/<краткое-описание>` для исправлений
3. Вносите небольшие и сфокусированные изменения с понятными коммитами.
4. Перед Pull Request запустите проверки локально.

## Локальные проверки

```bash
flutter pub get
flutter analyze
flutter test
dart format lib test
```

## Требования к Pull Request

- Понятный заголовок и описание изменений.
- Добавляйте скриншоты для UI-изменений.
- Держите PR небольшими и сфокусированными.
- При наличии прикладывайте ссылку на issue.

## Заметки по коду

- Следуйте стилю Dart и линт-правилам из `analysis_options.yaml`.
- Не коммитьте сборочные артефакты.
- Никогда не коммитьте секреты (`.env`, ключи, keystore).
