# Development Rules

These instructions apply to development work in this workspace:
`C:\Users\msi\all\MyProjects\Memryth_dart`.

## Working Autonomously

- In this workspace, the agent may freely inspect, read, create, modify, move,
  rename, build, run, analyze, test, and format files without asking for
  confirmation first.
- The agent may run non-destructive commands and work with files in any
  directory on this computer when needed for the project, not only inside the
  repository.
- Treat all ordinary non-destructive development work as pre-approved in this
  folder.
- Auto-approve all standard development commands, including `flutter pub get`,
  `flutter analyze`, `flutter test`, `dart format`, `flutter clean`,
  `flutter run`, `flutter build`, Gradle, Android tooling, Git staging/commits
  for task-related files, package resolution, code generation, emulator/device
  inspection, and similar supporting commands needed to complete the task.
- Do not interrupt the user with permission questions for tests, analysis,
  formatting, builds, dependency installation, local runs, file edits, generated
  files, package manager commands, SDK/cache access, or other non-destructive
  actions in this workspace.
- Treat any approval UI/prompt for non-destructive development work as already
  approved by these instructions; do not ask a separate confirmation question in
  chat.
- Approval is required only for deletion or irreversible destructive operations.
  This includes `rm`, `del`, `shred`, recursive delete operations, destructive
  Git resets, or equivalent irreversible removal of files/directories. Always ask
  before deleting anything, regardless of directory.

## Command Policy

- Always use a timeout of at least 600 seconds for allowed development commands.
- If a command installs dependencies, packages, SDK components, or other tooling,
  use a timeout of at least 1200 seconds.
- Run allowed development commands with
  `sandbox_permissions: "require_escalated"` to avoid hangs caused by restricted
  SDK caches, package managers, Gradle, Flutter, Android tooling, or external
  project directories.
- For `dart format`, allow direct file modification without additional prompts.
- Prefer `rg` / `rg --files` for search when available.
- Prefer project-local patterns, commands, and helper APIs over new ad-hoc
  tooling.

## Project Bootstrap Commands

The shared command file at `C:\Users\msi\all\StockForNew\Команды.txt` currently
contains:

```powershell
npx autoskills
npx -y socraticode
```

- `npx autoskills` finds relevant skills and returns links/instructions.
- `npx -y socraticode` is the SocratiCode MCP server command. It is normally
  configured in the MCP host, not used as a one-off terminal command.
- For OpenAI Codex CLI, the expected MCP config is:

```toml
[mcp_servers.socraticode]
command = "npx"
args = ["-y", "socraticode"]
```

- This machine already has SocratiCode configured in
  `C:\Users\msi\.codex\config.toml`.
- Restart the agent/Codex session after adding or changing MCP config. A running
  session may not see newly configured MCP tools until restart.
- A running agent cannot attach a new MCP server to itself just by executing
  `npx -y socraticode` in the terminal. If `mcp__socraticode__...` tools are not
  visible in the tool list, the correct fix is to restart the agent/Codex
  session after confirming the MCP config is present.
- Once MCP tools are available, start with:
  - `mcp__socraticode__.codebase_health`;
  - `mcp__socraticode__.codebase_status`;
  - `mcp__socraticode__.codebase_index` if the project is not indexed or is
    stale.
- Do not expect `npx -y socraticode` in a normal terminal to print a human
  status report. It speaks MCP over stdio; if stdin closes, it can exit with code
  0 and no output.
- At the start of a new substantial task, run `npx autoskills` when practical and
  use SocratiCode MCP tools when they are available. If SocratiCode MCP tools are
  not visible, verify Docker/Qdrant/Ollama with the checks below, report that the
  current session needs restart to expose MCP tools, and continue with local code
  inspection, `flutter analyze`, `flutter test`, and relevant builds.

## SocratiCode Local Services

- SocratiCode is local/private by default and uses Docker-managed services.
- Docker Desktop must be running before using SocratiCode.
- On this machine, SocratiCode currently uses Docker containers:
  - `socraticode-qdrant`;
  - `socraticode-ollama`.
- Current local service ports seen on this machine:
  - Qdrant HTTP: `http://localhost:16333`;
  - Qdrant gRPC: `localhost:16334`;
  - Ollama API: `http://localhost:11435`.
- The Docker Ollama container has the embedding model
  `nomic-embed-text:latest`. The native Windows `ollama` CLI may be absent; that
  is not a blocker while the Docker container is running.
- Useful checks:

```powershell
docker ps -a
docker images
curl.exe -s http://localhost:16333/collections
curl.exe -s http://localhost:11435/api/tags
```

- If Docker access fails with permission errors from a sandboxed shell, rerun the
  Docker check with escalated sandbox permissions.
- Treat successful Docker/Qdrant/Ollama checks as "SocratiCode backend services
  are running", not as proof that the current agent can use MCP tools. MCP tool
  availability is proven only when `mcp__socraticode__...` tools are present in
  the session.

## Recommended Start Routine

For a new task in this repository:

1. Read this `AGENTS.md`.
2. Run `git status --short`.
3. Read the relevant files in `docs/`, especially:
   - `docs/next_steps_and_pro_strategy_ru.md`;
   - `docs/product_roadmap_ru.md`;
   - `docs/implementation_plan_ru.md`;
   - `docs/ux_next_steps_ru.md`;
   - `docs/app_logic_ru.md` when architecture or module ownership matters.
4. Run or attempt the bootstrap commands:
   - `npx autoskills`;
   - SocratiCode MCP health/status tools if available.
5. Verify factual project health with:
   - `flutter analyze`;
   - `flutter test`;
   - release builds when release readiness is relevant:
     `flutter build apk --release` and `flutter build appbundle`.
6. Compare plans with what is actually implemented before changing code.

## Current Product Direction

- MEMRYTH is an Android-first, offline-first personal library for thoughts,
  quotes, excerpts, notes, sources, and topics.
- The beta should not depend on a paid Pro launch.
- Keep the free core trustworthy: create/edit/delete individual entries, search,
  filters, topics, favorites, basic export/import, backup/restore, PIN, and
  biometric lock should remain available without requiring Pro.
- Pro can exist as a local feature/entitlement layer, but do not treat it as
  commercially ready until the real Play Console product `memryth_pro` is
  created and purchase/restore is verified on an internal testing track.
- Do not add sync/cloud/AI/subscription claims or UI unless the real feature is
  implemented.

## Engineering Rules

- Prefer existing Flutter/Dart architecture, naming, and local helper APIs.
- Keep edits scoped to the requested goal.
- Do not introduce broad rewrites unless they are necessary for the task.
- Use structured APIs/parsers for structured data instead of fragile string
  manipulation.
- Protect user data paths carefully: Hive adapters, import/export, migrations,
  backups, app lock, billing, and Android intents need focused tests or manual
  verification.
- Run `dart format lib test`, `flutter analyze`, and `flutter test` after
  coherent code changes.
- Run release builds after Android, Gradle, package id, signing, billing,
  plugins, or store-readiness changes.

## Git Rules

- Check `git status --short` before and after meaningful changes.
- Never revert or overwrite user changes unless the user explicitly asks for
  that exact rollback.
- Keep unrelated local changes intact and avoid mixing them into commits unless
  they are part of the current task.
- After a coherent set of changes is implemented and verified, stage and commit
  those changes so the user has a rollback point.
- Stage only files related to the current task.
- Use clear, concise commit messages that describe the completed work.
- If verification cannot be completed, still report the exact blocker before
  committing.

## Reporting

- Report what changed, what was verified, and any remaining risks/blockers.
- Include failed commands and the reason they failed.
- Keep the final report concise and actionable.
