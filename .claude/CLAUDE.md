# Global Instructions & Constraints

## 1. Language Split & Token Optimization
- **Internal Reasoning**: You must conduct all your internal reasoning, chain of thought (CoT), internal planning, and intermediate analysis STRICTLY in English. This is critical to prevent Russian text from flooding the JSONL logs and wasting output tokens.
- **User-Facing Communication**: All explanations, answers, user messages, plans, inline code comments, **and especially all interactive prompts, questions, consent requests, and choice menus** must be written EXCLUSIVELY in Russian. The language of project documentation, changelogs, UI strings and the project-level `CLAUDE.md` is set by the project (its own rules and existing files), not by this rule.
- **Task Summarization**: Upon completing any task, provide a highly concise summary of your accomplishments in Russian. Avoid long, verbose explanations unless specifically requested.
- **Token Conservation & Consent**: Be extremely mindful of token consumption. You must ask the user for explicit consent **strictly in Russian** before:
  1. Reading a whole file of more than 1000 lines, a large JSON data file, or a raw log/build output. Reading such a file in targeted fragments (a line range, `grep` matches) is allowed without consent.
  2. Running a search that is not narrowed by directory or file type (e.g. `grep -r` from the repository root over all files).

## 2. Planning, Modularization & Progress Tracking
- **Plan Format**: All detailed planning must be written in Russian.
- **Plan Directory**: Store all detailed plans inside the `plan/` directory.
- **Splitting Is Conditional**: Do NOT split a plan into stages by default. A small plan stays in a single file (e.g., `plan/<name>.md`). Only when the plan is genuinely large (many independent milestones, wide code scope, or work that cannot be delivered in one pass) must you split it into separate stage files (e.g., `plan/<name>/stage_1.md`, `plan/<name>/stage_2.md`).
- **Heavy Stages**: If a stage is complex or heavy, it must be subdivided into sub-stages or sub-steps within its respective stage file.
- **Master Index**: For multi-stage plans only, maintain a master plan file at `plan/<name>/README.md`. This file must act as an index containing a high-level summary of all stages and their completion status. A single-file plan needs no index.
- **Token Saving**: When asked to execute a specific stage (e.g., "Сделай 5-й этап плана"), first inspect `plan/<name>/README.md` and then open ONLY the specific stage file (e.g., `plan/<name>/stage_5.md`). Do not read or load other stage files unless explicitly instructed, to save context tokens.
- **Progress Verification**: When working on a task defined by a plan (whether it is a multi-file plan or a single plan file), you must mark completed stages with a "✅ выполнен" tag next to the stage header. The plan must always accurately reflect the current progress of the work.
- **Strict Plan Adherence & Revision**: Follow the plan literally. Every decision with an observable effect that the plan does not explicitly fix — including choices *inside* a planned step, deviations from a pattern the plan names, defaults, thresholds, failure/edge-case behavior — requires approval BEFORE coding: stop and propose options (in Russian, recommended one marked). If you would justify a choice in the report, it needed approval first; reporting after the fact is not approval. Choices with no observable effect (naming, file layout, test structure) are free. The same applies when the plan contradicts itself or the code. Before working with code, update the plan to reflect the agreed solution.
- **Archiving**: When every stage of a plan in `plan/` is marked "✅ выполнен", move it unchanged into `plan/done/` (create it if missing): `plan/<name>.md` → `plan/done/<name>.md`, `plan/<name>/` → `plan/done/<name>/`. Use `git mv` for tracked files and `mv` for untracked ones.

## 3. Command Execution & Noise Reduction
- **Silent Commands**: When running tests, builds, linting, or compilations, always use flags that minimize console output to prevent bloated logs from polluting the session context (e.g., use `npm test -- --silent`, `vitest run --reporter=dot`, `--quiet`, or respective quiet flags).

## 4. Project-level CLAUDE.md Hygiene
- **Language & Size Limit**: The project-level `CLAUDE.md` file must be written strictly in English and must never exceed 2000 tokens (ideally kept highly compact, between 800 and 1500 tokens).
- **Allowed Content**: Include only invariants: the core tech stack, commands to run tests/linting, and essential style rules.
- **Forbidden Content**: Never store temporary notes, task histories, verbose feature requirements, or command outputs in `CLAUDE.md`.

## 5. Definition of Done
Before completing any task, evaluate and execute the following if required:
- Update the project-level `CLAUDE.md` if any dependencies, build tools, or test commands have changed.
- Update or add relevant tests to verify the implemented changes.
- Update the project documentation to align with the changes made.

## 6. Documentation & Comments
- **Accurate and complete**: Docs and docstrings describe only current live code, verified against it; cover all public behavior (purpose, parameters, defaults, errors, commands), nothing stale.
- **Clean slate**: Present tense, as if this implementation is the only version that ever existed. No history, migrations, or temporal words ("previously", "no longer", "now"). Exception: changelogs. Design rationale ("X, not Y, because …") is allowed without historical framing.
- **Code comments**: Describe only the current code; short, concise, no restating the code.
- **Compact**: Dense, zero filler or duplication; edit in place and delete outdated text instead of appending.

## 7. Git Workflow Constraints
- **No Automatic Commits**: Never run `git commit` or execute automatic commit hooks unless the user explicitly asks for a commit in the current message. All code modifications must be left in the working tree (staged or unstaged) so that the user can review, verify, and commit them manually.
