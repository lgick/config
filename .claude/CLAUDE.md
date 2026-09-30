# Global Instructions & Constraints

## 1. Language Split & Token Optimization

- **Internal Reasoning**: Conduct all internal reasoning, chain of thought, and intermediate analysis STRICTLY in English. This keeps Russian text out of the session logs and saves output tokens.
- **User-Facing Communication**: Everything the user reads — answers, explanations, summaries, plan files, **and especially interactive prompts, questions, consent requests, and choice menus** — must be written EXCLUSIVELY in Russian.
- **Code Comments & Project Docs**: Write them in Russian by default. If the project's existing comments or docs are in English, follow the project's language.
- **Always English**: this file and project-level agent instruction files (see "Project-level CLAUDE.md Hygiene"). Identifiers, commands, and quoted tool output are never translated.
- **Task Summarization**: Upon completing any task, give a highly concise summary of what was done, in Russian. Avoid long explanations unless requested.
- **Token Conservation & Consent**: Be extremely mindful of token consumption. Ask the user for explicit consent, in Russian, before any of these high-token or high-risk operations:
  1. Reading exceptionally large files (more than 1000 lines of code, huge JSON data files, raw log/build outputs).
  2. Broad recursive searches over a whole repository or the home directory (e.g., an unscoped `grep -r` or `find`).
  3. Spawning sub-agents (e.g., Claude Code's Explore/Plan agents) when the context is already large (long session, many files already read).
  4. Continuing a multi-step task when the initial search shows the code scope is too wide; offer to write a plan first (see "Planning").
  5. Destructive or irreversible actions: deleting files or directories, `git reset --hard`, `git clean`, `git push --force`, dropping databases or data.

## 2. Planning, Modularization & Progress Tracking

- **When to Write a Plan File**: Only when the user explicitly asks for a plan. Built-in planning features of the tool (e.g., Claude Code plan mode files in `~/.claude/plans/`) are separate and are not copied into `plan/` unless the user asks.
- **Language & Location**: Plan files are written in Russian and stored in `plan/` at the project root (the git root, or the current working directory if there is no repository).
- **Single File vs. Split**: A small plan is one file, `plan/<name>.md`; a multi-stage plan is a directory, `plan/<name>/`.
  - Propose a split (in Russian) if the plan has more than 3 stages, covers a wide code scope (many modules or files), or clearly cannot be completed in one working session (one conversation without overflowing the context). Otherwise keep one file.
  - After consent, create `plan/<name>/` with an index `README.md` and stage files `stage_1.md`, `stage_2.md`, … If the user declines, keep one file.
  - After writing a split plan, stop and wait for the user's command to start a stage.
- **Heavy Stages**: Subdivide a complex stage into sub-steps inside its own stage file (or its own section of a single-file plan).
- **Master Index**: `plan/<name>/README.md` (multi-stage plans only) holds a short summary of every stage and its completion status.
- **Executing a Stage (Token Saving)**: When asked to execute a stage (e.g., "Сделай 5-й этап плана"), read `plan/<name>/README.md`, then open ONLY that stage file (`plan/<name>/stage_5.md`). Do not load other stage files unless instructed. If several active plans exist and the user did not name one, ask which one.
- **Progress Marking**: In any plan, append "✅ выполнен" to the header of each completed stage; in a split plan, mark it both in the stage file and in `README.md`. The plan must always reflect actual progress.
- **Archiving**: When every stage of a plan in `plan/` is marked "✅ выполнен", move it unchanged into `plan/done/` (create it if missing): `plan/<name>.md` → `plan/done/<name>.md`, `plan/<name>/` → `plan/done/<name>/`. Use `git mv` for tracked files and `mv` for untracked ones. Do not commit the move (see "Git Workflow Constraints").

## 3. Command Execution & Noise Reduction

- **Silent Commands**: Run tests, builds, linters, and compilers with flags that minimize output (e.g., `npm test -- --silent`, `vitest run --reporter=dot`, `--quiet`, `-q`). Never start watch modes.
- **Failure Details**: If a quiet run fails, re-run only the failing test or target with enough output to diagnose it, not the whole suite.

## 4. Project-level CLAUDE.md Hygiene

Applies to the project's agent instruction file (`CLAUDE.md`, or its equivalent for other agents, e.g. `AGENTS.md`).

- **Language & Size Limit**: English only; never more than 1000 tokens (ideally 300–600).
- **Allowed Content**: Only invariants: the core tech stack, commands to run tests/linting/formatting, and essential style rules.
- **Forbidden Content**: Temporary notes, task histories, verbose feature requirements, command outputs.

## 5. Definition of Done

Before reporting a task as complete, check each item and do the ones that apply:

- Update or add tests for the change, run the relevant tests/linters quietly, and report failures as they are.
- Update the project-level `CLAUDE.md` if dependencies, build tools, or test commands changed.
- Update the project documentation to match the change.
- If the task belongs to a plan, update its progress marks (see "Planning").

## 6. Code Formatting

- Write code that already follows the formatting rules; do not run formatters. The project's own formatter config (`.prettierrc*`, `stylua.toml`/`.stylua.toml`, `rustfmt.toml`, `.editorconfig`) takes precedence; without one, follow `~/.config/nvim/lua/plugins/conform.lua` (formatter per filetype) and `~/.prettierrc.mjs` (Prettier options).
- Do not reformat code you did not change.

## 7. Git Workflow Constraints

- **No Commits by Default**: Do not commit, amend, push, or otherwise create commits or change branch history (merge, rebase, cherry-pick), and do not set up automation (hooks, scripts) that commits on your behalf. Leave all changes in the working tree for the user to review and commit.
- **Allowed**: Staging and index operations such as `git add` and `git mv`.
- **Exception**: Commit or push only when the user explicitly asks for it in the current message; that permission does not carry over to later tasks.
