---
name: solution-review
description: Audit of how a completed, uncommitted plan stage or single-file plan was solved — challenges implementation decisions, including developer-approved ones, and may reject the whole approach. Independent of code-review.
disable-model-invocation: true
argument-hint: "[plan file]"
---

# Solution Review

Read-only: do not edit files, apply fixes, or commit. Report in Russian.

Scope is implementation decisions (how the task was solved and whether it can be solved better), not line-level bugs: the built-in `code-review` covers those and runs as a separate, independent process (before or after this one). Do not invoke it, rely on its results, or duplicate its job.

## 1. Scope
Argument: optional plan path.
- `plan/<name>.md` → single-file plan; scope = the whole file.
- `plan/<name>/stage_N.md` → stage; read `plan/<name>/README.md` and that file only.
- No path → the file under `plan/` (excluding `plan/done/`) modified in `git status --short`. Zero or several candidates → ask.

## 2. Context
- Changes: `git diff HEAD` plus untracked files in full. Read touched files and their direct callers as needed.
- Searches narrowed by directory or file type for existing helpers, project code or libraries that could replace new code are allowed.
- Open the report with one sentence: the **problem** the plan/stage solves (from its goal, not its steps). Judge the solution against that problem, not against the plan.

## 3. Audit
- A decision recorded as approved by the developer is not evidence of correctness: approval preceded the code. Re-evaluate it like any other.
- Sunk cost has zero weight: compare the diff with what you would write from scratch today, knowing what is known now. The amount of code, tests and docs already written is never an argument to keep them.
- Look for: incorrect or unsafe decisions; needless abstractions, layers or config; reimplementing stdlib, libraries or existing project code; workarounds compensating for earlier decisions; duplicated state; logic in the wrong layer; hot-path performance costs; fragile assumptions; docs or plan not matching the code.
- Flag only alternatives that are materially better in a nameable way (removes a bug class, fewer components, measurable performance, simpler invariant). Taste and equivalent alternatives are not findings. Before criticizing, state why the decision was likely made and why that reason does not hold.
- Dead-end test, answered explicitly in every report: (a) is most of the complexity caused by the chosen concept rather than the problem itself? (b) would a clean rewrite be clearly simpler than patching? Both yes → 🛑.

## 4. Templates
Single decision:
> **Проектное решение:** При реализации плана было принято решение <…>, но оно не самое оптимальное, потому что <…>.
> **Наиболее правильное решение:** <…>
> **Выигрыш:** <…>. **Цена перехода:** <…>.

Dead end:
> 🛑 **Архитектурный тупик этапа:** Выбранный подход нерационален, потому что <корневая причина>. Признаки: <цепочка обходных решений, file:line>. Локальные правки не устранят причину.
> **Концептуально правильный подход:** <…>
> **Что сохранить:** <…>. **Что откатить:** <…>.
> **Как переписать этап плана:** <…>

## 5. Verdict
Exactly one; the worst applies (🛑 > 🔴 > 🟡 > 🟢):
- 🟢 **Решения оптимальны** — существенных замечаний нет.
- 🟡 **Рекомендуются локальные улучшения** — концепция верна, отдельные решения можно упростить.
- 🔴 **Требуется пересмотр решений** — отдельные решения некорректны или небезопасны, концепция при этом жизнеспособна.
- 🛑 **Архитектурный тупик** — рекомендуется откат и переработка концепции этапа.

Recommendations are proposals; plan changes require the developer's approval (global CLAUDE.md, section 2).
