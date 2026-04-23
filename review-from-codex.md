# Review From Codex: `interview-codex` vs `interview-claude`

Date: 2026-04-23

## Executive Verdict

`plugins/interview-codex` is a strong portable v1 implementation. It is not just a thin prompt copy of `plugins/interview-claude`: it adds a reusable Python core for interview state, prompt loading, ambiguity scoring, brownfield detection, validation, file locking, and async-safe persistence. Its unit suite is also healthy: `uv run python -m pytest -q` passes with 60 tests.

I would not call it "done" as a distributable plugin yet. The implementation is good enough to keep as the primary Codex version, but it still needs a polish pass before it can be considered fully aligned with the `interview-claude` snapshot and safe for broader reuse. The main gaps are documentation and plugin packaging quality, one missing agent prompt, weaker skill-level behavioral guidance, and a stale brownfield docstring.

Recommended direction: keep the current portable architecture, do not reintroduce Ouroboros-specific MCP or Seed coupling, and close the small parity and distribution gaps listed below.

## Review Scope

Reference implementation:

- `plugins/interview-claude`
- Especially `skills/interview/SKILL.md`, `agents/`, `README.md`, and `.claude-plugin/plugin.json`

Reviewed implementation:

- `plugins/interview-codex`
- Especially `skills/interview/SKILL.md`, `src/interview_plugin_core/`, tests, README, and `.codex-plugin/plugin.json`

Verification performed:

- `uv run python -m pytest -q`
- Result: `60 passed in 0.15s`

Note: direct `.venv/bin/pytest -q` currently fails because the checked-in or local virtualenv script points at an old absolute interpreter path under `/Users/brandonwie/dev/personal/ouroboros/...`. The `uv` path works and should be the documented path.

## What `interview-claude` Provides

`interview-claude` is explicitly marked as a snapshot, not a production-ready plugin. Its README says it is pending cross-analysis against `interview-codex`, and its manifest keywords include `snapshot` and `not-for-use`.

The Claude version is mostly an operational prompt specification:

- A cross-agent skill contract for Claude Code, Codex, and Gemini CLI.
- Path A for future MCP mode, explicitly tombstoned/deferred in the current snapshot.
- Path B as the active agent fallback workflow.
- Detailed interview behavior:
  - pre-scan codebase when relevant;
  - route questions through auto-confirmation, code confirmation, direct user decision, hybrid code plus user, or external research;
  - maintain an ambiguity ledger;
  - enforce a dialectic rhythm guard;
  - rotate perspectives;
  - run a seed-ready acceptance guard before closure.
- Seven agent prompts:
  - `socratic-interviewer`
  - `researcher`
  - `simplifier`
  - `architect`
  - `breadth-keeper`
  - `seed-closer`
  - `ontologist`

This makes `interview-claude` useful as a detailed behavioral reference, but it is not itself a robust implementation.

## What `interview-codex` Provides

`interview-codex` is materially more implemented than `interview-claude`.

Core package:

- `interview.py`
  - `InterviewState`, `InterviewRound`, `InterviewStatus`
  - start, ask, record, save, load, complete, and list workflows
  - prompt construction
  - perspective selection
  - brownfield flag injection
  - ambiguity snapshot injection
- `ambiguity.py`
  - scoring dimensions and milestones
  - seed readiness thresholds
  - clarification question generation
- `prompt_loader.py`
  - packaged prompt loading
  - environment override via `INTERVIEW_CODEX_PROMPTS_DIR`
  - section parsing and persona prompt extraction
- `brownfield.py`
  - portable brownfield detection
- `security.py`
  - input validation, path containment, LLM response validation, and secret masking
- `file_lock.py`
  - lockfile-based persistence protection
- `provider.py`
  - `LLMAdapter` protocol and completion data types

Plugin skill:

- A compact Codex-facing `/interview` skill.
- Intentionally excludes Ouroboros MCP boot flow, deferred tool loading, and Seed generation commands.
- Supports enriched answer prefixes:
  - `[from-code]`
  - `[from-user]`
  - `[from-research]`

Tests:

- 60 passing tests across interview state, prompt behavior, brownfield detection, research prefix guidance, no-web-search prompt behavior, async file IO, persistence, provider errors, validation, and closure behavior.

## Parity Matrix

| Area | `interview-claude` | `interview-codex` | Assessment |
| --- | --- | --- | --- |
| Usability intent | Snapshot, not for direct use | Portable Codex plugin plus Python core | Codex is stronger |
| MCP mode | Deferred/tombstoned | Intentionally excluded from v1 | Acceptable divergence |
| Agent fallback | Detailed prompt workflow | Implemented via Python prompt engine and skill | Strong, but skill docs are thinner |
| Ambiguity ledger | Prompt-level instruction | Numeric ambiguity scoring plus prompt snapshot | Codex is stronger |
| Dialectic rhythm guard | Explicit 3-question rhythm rule | Partially covered by breadth/perspective logic | Needs clearer implementation or documentation |
| Perspective rotation | Seven agents, including ontologist | Six packaged assets, missing ontologist | Gap |
| Seed closure guard | Prompt-level seed-ready acceptance guard | Numeric thresholds plus seed-closer activation | Strong, but should document how it maps |
| Brownfield support | Pre-scan and confirmation-style questions | Detects brownfield and records path; caller explores | Good architecture, stale docstring |
| External research routing | Prompt-level Path 4 | `[from-research]` prefix, no web-search hint | Good portable substitute |
| Persistence | None | State directory, save/load/list, file lock | Codex is stronger |
| Validation/security | Prompt discipline only | Dedicated validator module | Codex is stronger |
| Packaging metadata | Claude metadata mostly filled | Codex manifest has TODO metadata | Gap |
| Test coverage | None observed | 60 passing tests | Codex is stronger |

## Strengths

### 1. The Python Core Is Real, Not Decorative

The Codex plugin contains an actual reusable core instead of relying only on skill prose. This is the biggest improvement over the Claude snapshot. The engine has explicit state transitions, persistence, provider abstraction, prompt building, and scoring integration.

### 2. Ambiguity Scoring Is a Meaningful Upgrade

The Claude snapshot describes an ambiguity ledger in prose. Codex operationalizes this with scoring thresholds, readiness checks, milestones, and clarification generation. That is the right direction for Codex because it gives the caller a stable control surface instead of relying only on conversational discipline.

Observed thresholds include:

- `AMBIGUITY_THRESHOLD = 0.2`
- `SEED_CLOSER_ACTIVATION_THRESHOLD = 0.25`
- `AUTO_COMPLETE_STREAK_REQUIRED = 2`

### 3. Portable Runtime Boundary Is Correct

`LLMAdapter` is the right abstraction. It avoids binding the core package to one model client, one CLI runtime, or one MCP implementation. This preserves the ability to run the same interview engine from a Codex skill, CLI, MCP server, or tests.

### 4. Brownfield Handling Avoids Context Stuffing

The current Codex behavior detects brownfield projects and records the path, but does not automatically stuff codebase exploration into the engine. Tests confirm this is intentional. This is the right design for Codex: the main session should inspect code with its own tools and feed facts back using `[from-code]`.

### 5. Test Coverage Is Broad for a v1 Plugin

The tests cover many practical failure points:

- state initialization and serialization;
- question generation;
- recording responses;
- provider errors;
- save/load/list;
- async IO offloading;
- concurrent save/load;
- prompt construction;
- brownfield detection;
- closure mode;
- research prefix behavior;
- no implicit web-search instruction.

That is enough coverage to trust the current architecture while making targeted improvements.

## Gaps And Risks

### 1. Plugin Manifest Still Has TODO Metadata

`plugins/interview-codex/.codex-plugin/plugin.json` contains placeholder metadata:

- author name and URL
- homepage
- repository
- developer name
- website URL
- privacy policy URL
- terms of service URL

This makes the plugin look unfinished even though the core implementation is credible. It should be fixed before treating `interview-codex` as publishable or stable.

Also review whether the declared capability `"Write"` is accurate. The skill can produce summaries/specs and the core persists state, but if plugin capability declarations are user-facing permissions, it should be intentionally chosen and documented.

### 2. `ontologist.md` Is Missing From Codex Assets

Claude has seven agent prompts. Codex packages six:

- present:
  - `architect.md`
  - `breadth-keeper.md`
  - `researcher.md`
  - `seed-closer.md`
  - `simplifier.md`
  - `socratic-interviewer.md`
- missing:
  - `ontologist.md`

The six shared prompts are mostly exact copies. `socratic-interviewer.md` differs by one line but preserves section parity.

The missing ontologist matters because the Claude workflow uses it when the user's stated problem appears symptomatic rather than root-cause. That is a real interview mode, not just a cosmetic prompt.

Decision needed: either add `ontologist.md` to Codex and include it in perspective selection, or explicitly document that v1 excludes root-cause ontology questioning.

### 3. Codex Skill Instructions Are Too Thin Compared With Claude

`plugins/interview-codex/skills/interview/SKILL.md` is intentionally portable and concise, but it omits several high-value behavioral controls from the Claude skill:

- explicit ambiguity ledger categories;
- question routing rules;
- confirmation-style handling for code facts;
- dialectic rhythm guard;
- seed-ready acceptance guard;
- perspective rotation guidance;
- closure audit checklist.

Some of this exists in the Python core, but the skill file is what Codex reads at runtime when the user invokes the skill. If the skill is too generic, Codex may behave like a normal clarifying assistant instead of using the stronger interview protocol.

Recommendation: keep it shorter than the Claude version, but add the missing behavioral invariants.

### 4. Brownfield Startup Docstring Is Stale

`InterviewEngine.start_interview()` documents that when `cwd` is provided it "auto-detects brownfield projects and runs codebase exploration before the first question."

The implementation does not run exploration. It intentionally detects brownfield and records:

- `state.is_brownfield = True`
- `state.codebase_paths = [{"path": cwd, "role": "primary"}]`

Tests explicitly say the new architecture does not trigger exploration and the main session handles code reading.

This is a small but important correctness issue. The docstring should be updated so future maintainers do not accidentally reintroduce automatic codebase stuffing.

### 5. README Test Command Is Less Reliable Than The Working Command

The README says:

```bash
python -m pytest -q
```

In this environment, the reliable command is:

```bash
uv run python -m pytest -q
```

Direct `.venv/bin/pytest` fails due to an absolute interpreter path from another checkout. The README should prefer the `uv run` command and optionally mention recreating `.venv` if direct venv commands fail.

### 6. Public Runtime Story Needs More Detail

The README says the default model string comes from `INTERVIEW_CODEX_MODEL` and falls back to `"default"`, and that callers wrap their own model client with `LLMAdapter`. That is technically fine, but thin for an implementer.

Needed additions:

- minimal adapter example;
- state directory behavior;
- prompt override behavior;
- how `[from-code]`, `[from-user]`, and `[from-research]` are expected to be supplied;
- how ambiguity scoring and closure should be invoked in an actual runtime.

### 7. Packaging Includes Local Cache Artifacts In The Tree

The file listing shows local `.venv/`, `.pytest_cache/`, and `__pycache__/` content under `plugins/interview-codex`. Some are probably ignored or untracked, but they are present in the working tree.

Risk:

- stale absolute paths;
- noisy plugin distribution;
- confusing test behavior;
- accidental packaging or archive inclusion if plugin publishing tooling does not respect `.gitignore`.

Recommendation: confirm these are untracked and ignored, then remove local cache artifacts from the plugin folder when cleaning the workspace.

## Improvement Plan

### Priority 1: Make The Plugin Look Finished

1. Fill `plugins/interview-codex/.codex-plugin/plugin.json`.
   - Replace all `[TODO: ...]` values.
   - Confirm homepage and repository point to the plugin path.
   - Confirm `developerName`.
   - Decide whether privacy and terms URLs are required or should be omitted if plugin schema permits omission.
   - Review `"capabilities": ["Write"]` and keep only if accurate.

2. Update `plugins/interview-codex/README.md`.
   - Use `uv run python -m pytest -q` as the primary test command.
   - Add a short "Runtime integration" section for `LLMAdapter`, state directory, prompt overrides, and enriched answer prefixes.
   - State clearly that v1 intentionally excludes Ouroboros MCP boot flow, deferred tool loading, Seed command coupling, and PM interview variant.

3. Fix stale docstrings in `interview.py`.
   - Replace the claim that brownfield startup runs codebase exploration.
   - Say it detects brownfield and records paths; the caller is responsible for inspection and feeding facts back with `[from-code]`.

### Priority 2: Close Prompt Parity Gaps

1. Decide the ontologist path.
   - Preferred: copy `plugins/interview-claude/agents/ontologist.md` into `plugins/interview-codex/src/interview_plugin_core/assets/ontologist.md`.
   - Add `ONTOLOGIST` to `InterviewPerspective`.
   - Include it in perspective selection when the request looks root-cause or symptom-oriented.
   - Add tests verifying prompt inclusion.

2. If not adding ontologist, document the exclusion.
   - README should say v1 excludes ontological/root-cause interview mode.
   - Skill should avoid claiming full parity with the Claude prompt panel.

3. Strengthen `skills/interview/SKILL.md`.
   - Add a compact ambiguity ledger:
     - goal
     - scope
     - constraints
     - success criteria
     - brownfield ownership and integration
     - non-goals
     - verification
   - Add a rhythm rule:
     - after several fact-confirmation rounds, ask for direct user judgment.
   - Add closure guard:
     - stop only when another question would not materially change implementation.
   - Keep the Codex skill portable and avoid Claude-specific `AskUserQuestion` language.

### Priority 3: Improve Runtime Confidence

1. Add tests for manifest and packaged prompt completeness.
   - Assert every `InterviewPerspective` has a loadable asset.
   - Assert plugin manifest has no `[TODO:` placeholders.
   - Assert skill file includes the key enriched answer prefixes.

2. Add tests for stale brownfield behavior.
   - Preserve current design: no automatic exploration in the engine.
   - Confirm prompt tells caller to use `[from-code]` facts for brownfield context.

3. Add a tiny adapter example test or doc snippet.
   - The goal is not to test a real provider.
   - The goal is to show the expected `LLMAdapter.complete()` contract.

### Priority 4: Workspace Hygiene

1. Confirm local artifacts are ignored.
   - `.venv/`
   - `.pytest_cache/`
   - `tests/__pycache__/`

2. Remove local cache artifacts from the plugin workspace when safe.
   - This should be a separate cleanup change.
   - Do not mix it with functional prompt or engine changes unless preparing a release.

## Suggested Acceptance Criteria

The next improvement pass is complete when:

- `plugin.json` has no TODO placeholders.
- README documents the working test command and runtime integration path.
- `interview.py` no longer claims automatic brownfield exploration.
- Codex either includes `ontologist.md` or explicitly documents its exclusion.
- Skill instructions preserve the key Claude behavioral controls in Codex-native language.
- `uv run python -m pytest -q` passes.
- New tests cover manifest metadata, packaged prompt completeness, and the brownfield no-auto-exploration contract.

## Final Recommendation

Keep `interview-codex` as the primary implementation. It is already better engineered than `interview-claude` for actual use because it has a testable runtime core and clean portability boundaries.

Do not rebuild it around the Claude snapshot. Instead, treat `interview-claude` as the behavioral source of truth and port only the missing high-signal pieces:

- ontologist perspective or an explicit exclusion;
- richer skill-level interview discipline;
- closure and rhythm guard language;
- package metadata and docs polish.

After those changes, `interview-codex` should be considered the canonical v1 plugin, while `interview-claude` can remain a reference snapshot or be archived once its useful behavior has been ported.
