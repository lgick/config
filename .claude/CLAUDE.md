# Global Instructions & Constraints

## 1. Language Split & Token Optimization
- **Internal Reasoning**: You must conduct all your internal reasoning, chain of thought (CoT), planning, and intermediate analysis STRICTLY in English. This is critical to prevent Russian text from flooding the JSONL logs and wasting output tokens.
- **User-Facing Communication**: All explanations, answers, inline code comments, documentation, user messages, **and especially all interactive prompts, questions, consent requests, and choice menus** must be written EXCLUSIVELY in Russian.
- **Task Summarization**: Upon completing any task, provide a highly concise summary of your accomplishments in Russian. Avoid long, verbose explanations unless specifically requested.
- **Token Conservation & Consent**: Be extremely mindful of token consumption. You must ask the user for explicit consent **strictly in Russian** before executing any high-token or high-risk operations, which include:
  1. Reading exceptionally large files (more than 1000 lines of code, huge JSON data files, or raw log/build outputs).
  2. Initiating broad, recursive directory-wide searches (like massive `grep` or `find_files` sweeps across the entire repository).
  3. Spawning new autonomous sub-agents (Explore/Plan/Task) if the task context is already heavy.
  4. Proceeding with a multi-step task if the initial search shows that the code scope is too wide.

## 2. Planning, Modularization & Progress Tracking
- **Plan Format**: All detailed planning must be written in Russian.
- **Modular Directory**: Store all detailed plans inside the `plan/` directory. Break down the plan into separate, detailed Markdown files for each stage/milestone (e.g., `plan/stage_1.md`, `plan/stage_2.md`).
- **Heavy Stages**: If a stage is complex or heavy, it must be subdivided into sub-stages or sub-steps within its respective stage file.
- **Master Index**: Maintain a master plan file at `plan/README.md`. This file must act as an index containing a high-level summary of all stages and their completion status.
- **Token Saving**: When asked to execute a specific stage (e.g., "Сделай 5-й этап плана"), first inspect `plan/README.md` and then open ONLY the specific stage file (e.g., `plan/stage_5.md`). Do not read or load other stage files unless explicitly instructed, to save context tokens.
- **Progress Verification**: When working on a task defined by a plan (whether it is a multi-file plan in `plan/` or a single `PLAN.md` file), you must mark completed stages with a "✅ выполнен" tag next to the stage header. The plan must always accurately reflect the current progress of the work.

## 3. Command Execution & Noise Reduction
- **Silent Commands**: When running tests, builds, linting, or compilations, always use flags that minimize console output to prevent bloated logs from polluting the session context (e.g., use `npm test -- --silent`, `vitest --reporter=terse`, `--quiet`, or respective quiet flags).

## 4. Project-level CLAUDE.md Hygiene
- **Language & Size Limit**: The project-level `CLAUDE.md` file must be written strictly in English and must never exceed 1000 tokens (ideally kept highly compact, between 300 and 600 tokens).
- **Allowed Content**: Include only invariants: the core tech stack, commands to run tests/linting, and essential style rules.
- **Forbidden Content**: Never store temporary notes, task histories, verbose feature requirements, or command outputs in `CLAUDE.md`.

## 5. Definition of Done
Before completing any task, evaluate and execute the following if required:
- Update the project-level `CLAUDE.md` if any dependencies, build tools, or test commands have changed.
- Update or add relevant tests to verify the implemented changes.
- Update the project documentation to align with the changes made.

## 6. Git Workflow Constraints
- **No Automatic Commits**: Never run `git commit` or execute automatic commit hooks. All code modifications must be left in the working tree (staged or unstaged) so that the user can review, verify, and commit them manually.
