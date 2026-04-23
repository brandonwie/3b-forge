# Review: `interview-claude` (v0.0.1) vs `interview-codex` (v0.1.0)

**Reviewer:** Claude (Opus 4.7, 1M)
**Date:** 2026-04-23
**Scope:** Full cross-audit of `plugins/interview-claude/` against `plugins/interview-codex/` as reference variant.
**Mandate:** Produce analysis; produce improvement plan only if material gaps exist.

---

## TL;DR

`interview-claude` is **architecturally coherent for Claude Code native** and deliberately avoids Python coupling. It is **not "done"** — three gaps warrant closure before it graduates from v0.0.1 to v0.1.0:

1. **No closure quantification** (subjective exit vs codex's 0–1 scored gate).
2. **No perspective rotation protocol** (7 agents exist; only 1 is explicitly loaded in the playbook).
3. **No session continuity** (conversation-only; can't resume).

Recommendation: **Option B — integrate best-of in-prompt** (keep prompt-heavy architecture; add the three missing pieces as markdown-native mechanisms, not by porting Python). Do not pursue Python parity with codex — that would duplicate codex's scope and defeat the harness experiment.

---

## 1. Structural comparison

| Axis | `interview-claude` v0.0.1 | `interview-codex` v0.1.0 |
|---|---|---|
| Manifest | `.claude-plugin/plugin.json` | `.codex-plugin/plugin.json` |
| Status | `not-for-use snapshot` | extracted, portable core |
| Runtime deps | **zero** (markdown only) | Python 3.12+, pydantic, structlog |
| Core implementation | SKILL.md dual-path playbook | `src/interview_plugin_core/` (12 modules) |
| Scoring | qualitative, agent-reasoned | `AmbiguityScorer` 0–1, 40/30/30 weights |
| Closure gate | `seed-closer.md` 6-dim audit | threshold ≤0.2 + `seed-closer.md` |
| State | none (conversation-only) | `InterviewState` dataclass, file-locked persistence |
| LLM coupling | implicit (host conversation) | `LLMAdapter` Protocol (swappable) |
| Security | none | `InputValidator` sanitizer |
| Tests | none | 26+ pytest-asyncio tests across 4 files |
| Perspectives | **7** (incl. `ontologist`) | **6** (no `ontologist`) |
| Cross-agent story | `references/{codex,gemini}-tools.md` aspirational mapping | portable by Python runtime, not tool mapping |
| Install footprint | drop-in markdown | `pyproject.toml` + `uv.lock` install |

## 2. `interview-claude` — what it does well

### 2.1 Prompt-heavy architecture fits the host

Claude Code is a conversational agent host. Asking it to spawn a Python subprocess to score ambiguity is a layer already handled by the surrounding conversation. `interview-claude` correctly pushes the "engine" into prompt semantics and role files. Nothing installed. Nothing to break. Auditable as prose.

### 2.2 The `ontologist` agent is a genuine contribution

`ontologist.md` (absent from codex) asks four foundational questions: *What IS it? Root cause or symptom? Prerequisites? Hidden assumptions?* This maps to the global Scientific Thinking principle in `~/.claude/CLAUDE.md` §7 (hypothesis + falsifiability) and addresses a failure mode the codex variant doesn't name: symptom-treating interviews that converge on a plausible-but-shallow requirement. **Keep this; promote it.**

### 2.3 Rhythm tracking in B.4 is a real design insight

> *non-user rounds (auto-confirm, code-confirmation) don't reset counter; human-judgment rounds reset to 0.*

This is a subtle user-attention model: don't burn the user's interview budget on confirmations the codebase can answer. The codex variant doesn't articulate this. **Preserve explicitly in any refactor.**

### 2.4 Closure gate in `seed-closer.md` is more structured than codex's

Six dimensions — ownership, protocol/API, lifecycle, migration, cross-client impact, verification. Codex's version is similar in content but embeds it in the Python scoring pipeline. The claude variant's version is directly readable and extendable. **Good.**

### 2.5 Dual-path architecture (A: MCP future / B: agent-now) documents a migration story

`SKILL.md` clearly says Path A is tombstoned for v0.1.0-alpha pending the `interview-ai` PyPI package. This is honest about what's aspirational vs what ships. **Clarity > pretense.**

## 3. `interview-claude` — material gaps

### 3.1 Closure decision is fully subjective

`seed-closer.md` gives dimensions but no scoring guidance. Two interviewer-agent runs on the same transcript could disagree on readiness. Codex solves this with a 0–1 scalar; claude solves it with narrative. For many users, narrative is fine — but there is no published rubric.

**Impact:** medium. Closure quality depends on the LLM's calibration.

### 3.2 Perspective rotation is underspecified

`SKILL.md §B.1` loads `socratic-interviewer.md`. The other six agents exist but no rule says **when** they activate. Compare codex's `_select_perspectives()` which deterministically picks which persona speaks this round. In claude-land, this should still be deterministic — encoded as a markdown decision table, not Python.

**Impact:** high. Seven well-written role files are mostly dead weight if the playbook never reaches them.

**Example trigger rules that should exist:**

| Signal | Activate |
|---|---|
| User gives vague goal, no domain terms | `ontologist` (essence analysis) |
| User describes implementation before requirements | `simplifier` (YAGNI pushback) |
| Brownfield repo; user proposes change | `architect` (structural impact) |
| Unknown domain / external API mentioned | `researcher` (evidence gathering) |
| Conversation narrows to one thread early | `breadth-keeper` (zoom-out) |
| Closure signals appear | `seed-closer` (6-dim audit) |

These rules don't need Python — they need a table in `SKILL.md §B.3`.

### 3.3 No session continuity

Codex writes state to `~/.interview-codex/data` with file locking. Claude has nothing. For long or multi-session interviews (which the 3B knowledge flow routinely produces — see `projects/*/actives/`), this is a usability gap.

The fix is **not** a Python state store. It is a markdown transcript convention: `projects/{project}/actives/interview-YYYY-MM-DD-{slug}/transcript.md` with frontmatter (round count, open tracks, last perspective, closure-dim status). Claude Code already reads/writes such files naturally.

**Impact:** medium-high for real use; low for demo.

### 3.4 v0.0.1 `not-for-use snapshot` status is load-bearing ambiguity

The manifest declares the plugin unusable; the skill is fully operational. Either the skill ships under a clearer gate, or the manifest lies. Fix whichever is wrong.

### 3.5 Path A (MCP) tombstone is dead weight

`SKILL.md` references `interview-ai` PyPI package + MCP persistence as the v0.1.0 target. That package does not exist in this repo. Either:
- (a) Delete Path A until `interview-ai` exists, or
- (b) Commit to a stub + timeline.

Keeping a referenced-but-absent package in docs erodes trust.

### 3.6 Slash command name is placeholder

`/interview-claude:interview` is called out in the plugin's own README as non-final. Before v0.1.0 graduation, lock this — renames after release leak into user muscle memory.

### 3.7 Zero tests

`interview-codex` ships 26+ async tests covering state transitions, brownfield detection, LLM error paths, and prompt filtering. `interview-claude` has none — and it is arguably impossible to unit-test prompt-heavy code the same way. But it IS possible to ship **transcript fixtures**: golden-path example interviews in `docs/interview-skill/fixtures/` that reviewers read to confirm the playbook behaves sensibly. Codex-style coverage is not achievable; reproducibility via fixture is.

## 4. Philosophical question: is claude "enough"?

Yes for the current phase, no for v0.1.0.

- **For the harness comparison (CA1/CA2/CA3):** claude is sufficient as-is. The snapshot exists specifically to be audited against codex. That's this document.
- **For shipping as a useful plugin:** claude needs §3.1–§3.3 closed. §3.4–§3.6 are cleanup.
- **Do not pursue §3.7-style Python parity.** That path exists; it is the codex variant. Harness's point is divergence, not duplication.

## 5. Improvement plan

### Option A — minimal cleanup (ship snapshot faster)
- Resolve Path A tombstone (delete or commit to timeline).
- Lock slash command name.
- Graduate manifest to `pre-release` (not `not-for-use`) once §3.2 lands.
- Add `ontologist` + codex-absent perspectives to a README feature-comparison table.
- **Effort:** ~1 session. **Value:** removes friction; does not raise quality.

### Option B — integrate best-of, prompt-heavy (recommended)
- Keep zero-Python architecture.
- `SKILL.md §B.3`: add perspective-rotation decision table (see §3.2 example).
- `seed-closer.md`: add qualitative 6-dim rubric (explicit criteria + observable signals per dim; no numeric score, **reasoned** verdict per dim).
- `SKILL.md §B.6` (new): session continuity convention — transcript path, frontmatter schema, resume instructions.
- `docs/interview-skill/fixtures/`: 2–3 golden transcripts (greenfield, brownfield, single-track-collapse) proving the playbook.
- Execute Option A cleanups alongside.
- **Effort:** ~2–3 sessions. **Value:** closes the three material gaps without defeating the experiment.

### Option C — Python parity
- Not recommended. Duplicates codex; defeats harness intent.

### Recommendation
**Option B.** Claude's prompt-heavy architecture is the right choice for a Claude Code native plugin. Regressing to Python would forfeit the divergence the harness was built to test. Close the three gaps in-markdown.

## 6. Cross-variant decision input (for CA1/CA2/CA3)

Based on this review, inputs to the upcoming cross-variant decision:

- **If CA1 picks one winner:** `interview-claude` + Option B improvements is the right winner **for Claude Code users**. `interview-codex` is the right winner **for users building agent pipelines in Python**. They are not competitors; they are variants for different deploy targets.
- **If CA1 merges:** keep claude as the user-facing playbook; reuse codex's `AmbiguityScorer` only if a Python runtime is guaranteed in the host environment. Otherwise scoring belongs in prompt.
- **Harness-level learning:** prompt-heavy vs engine-heavy is a **real axis** worth keeping as a design dimension in `docs/interview-skill/10-variant-comparison.md`. Neither is universally right.

## 7. Appendix: verification for the improvement plan

If Option B is approved, verification:

1. `/interview-claude:interview` → load playbook → confirm B.1 loads `socratic-interviewer` and B.3 table triggers a non-default agent on a seeded brownfield repo.
2. Run a greenfield interview against a throwaway idea; inspect transcript file under `projects/*/actives/`.
3. Reach closure; confirm `seed-closer.md` rubric produces per-dim verdicts, not just a gut call.
4. Compare against codex fixtures to confirm behavioral coverage is comparable modulo scoring scalar.

## 8. Files reviewed

- `plugins/interview-claude/.claude-plugin/plugin.json`
- `plugins/interview-claude/skills/interview/SKILL.md`
- `plugins/interview-claude/skills/interview/references/{codex,gemini}-tools.md`
- `plugins/interview-claude/commands/interview.md`
- `plugins/interview-claude/agents/{socratic-interviewer,seed-closer,researcher,simplifier,architect,breadth-keeper,ontologist}.md`
- `plugins/interview-claude/README.md`
- `plugins/interview-codex/.codex-plugin/plugin.json`
- `plugins/interview-codex/src/interview_plugin_core/*.py` (architectural)
- `plugins/interview-codex/skills/interview/SKILL.md`
- `plugins/interview-codex/tests/*.py` (coverage map)
- `plugins/interview-codex/pyproject.toml`
- `README.md`, `todos.md`
