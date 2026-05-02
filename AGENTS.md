# Development Rules

- In this workspace, the agent may freely inspect, read, create, modify, move, rename, build, run, analyze, test, and format files without asking for confirmation first.
- The agent may run non-destructive commands and work with files in any directory on this computer when needed for the project, not only inside the repository.
- Treat all ordinary non-destructive development work as pre-approved in this folder.
- Auto-approve all standard development commands, including `flutter pub get`, `flutter analyze`, `flutter test`, `dart format`, `flutter clean`, `flutter run`, `flutter build`, and similar supporting commands needed to complete the task.
- Always use a timeout of at least 600 seconds for allowed development commands.
- If a command installs dependencies, packages, SDK components, or other tooling, use a timeout of at least 1200 seconds for that install command.
- Run allowed development commands with `sandbox_permissions: "require_escalated"` to avoid hangs caused by restricted SDK cache access.
- For `dart format`, allow direct file modification without additional prompts.
- Do not interrupt the user with permission questions for tests, analysis, formatting, builds, dependency installation, local runs, file edits, or other non-destructive actions in this workspace.
- Treat any approval UI/prompt for non-destructive development work as already approved by these instructions; do not ask a separate confirmation question in chat.
- This includes dependency changes, SDK/cache access, package resolution, generated files, formatting, analysis, tests, builds, local runs, file creation, file modification, moving, and renaming.
- The agent should execute every non-destructive command it needs on its own, including commands that require elevated sandbox access. Do not pause to ask before running Flutter, Dart, Gradle, Git, npm, package manager, SDK, emulator/device inspection, formatting, analysis, test, build, or local run commands.
- Approval is required only for deletion or irreversible destructive operations. Dependency installation, dependency upgrades, lockfile updates, generated-file updates, git staging, git commits, and non-destructive commands in other directories are explicitly pre-approved.
- The only operations that still require explicit user confirmation are destructive deletions or equivalent irreversible removal of files or directories, such as `rm`, `del`, `shred`, or recursive delete operations. Always ask before deleting anything, regardless of directory.
- Apply these rules for all future development work in this workspace.

## Git Rules

- Check `git status --short` before and after meaningful changes.
- Never revert or overwrite user changes unless the user explicitly asks for that exact rollback.
- Keep unrelated local changes intact and avoid mixing them into commits unless they are part of the current task.
- After a coherent set of changes is implemented and verified, stage and commit those changes so the user has a rollback point.
- Use clear, concise commit messages that describe the completed work.
- If verification cannot be completed, still report the exact blocker before committing.
