---
tags: [todos, 3b-forge]
created: 2026-04-23
updated: 2026-04-23
status: in-progress
---

# 3b-forge — TODOs

Near-term action backlog for the harness. Tracked here (not in GitHub
Issues) because this is a personal workspace.

Status markers: `[ ]` open, `[~]` in-progress, `[x]` done, `[-]` skipped,
`[!]` blocker.

## Adjudication — resolved 2026-04-23

Cross-variant review cycle (CA1 + CA3) closed. Direction chosen:
**merge best-of-both into single [`plugins/3b/`](./plugins/3b/)** with
two **layers** (conversational SKILL + optional Python `engine/`).

- [x] **CA1** — cross-analyzed both snapshots across 8 design axes.
- [x] **CA3** — direction decided; consolidation shipped.
- [-] **CA2** — standalone variant-comparison doc dropped; the
      two-layer rationale now lives in `plugins/3b/README.md` + root
      `README.md` "Why ONE plugin with two layers" section.
- [-] **CA3 formal ADR** — dropped; decision captured in CHANGELOG +
      plugin README. No separate ADR needed.

Internal adjudication artifacts (cross-reviews, consolidated plan)
and upstream-Ouroboros analysis moved to `tmp/` (gitignored) as
internal design-journey material.

## Post-comparison roadmap (blocked on CA3)

After CA3 picks a direction, these tasks apply to whichever plugin
wins. Versioning restarts at `v0.1.0` once the winner is chosen — the
`-claude` v0.0.1 and `-codex` v0.1.0 numbers are frozen snapshot labels
and will not continue.

- [ ] **v0.1.0** — first usable cross-agent release (Path B working on
  Claude Code / Codex / Gemini CLI). Includes proper versioned tag,
  per-agent install instructions with tested commands, release notes
  in CHANGELOG.
- [ ] **v0.2.0** — Path A (MCP) via `interview-ai` PyPI package.
  (See internal build-decisions doc under `tmp/interview-skill/` Phase 2.)
  - [ ] Port core utilities (types, errors, file_lock, security,
        initial_context, seed dataclass)
  - [ ] Port providers (LLMAdapter + litellm impl)
  - [ ] Port simplified config
  - [ ] Port agents/loader
  - [ ] Port InterviewEngine + state + scorer + events
  - [ ] Port event_store
  - [ ] Port MCP types + errors
  - [ ] Port InterviewHandler (drop plugin-mode per D13b)
  - [ ] MCP server registration + CLI entry
  - [ ] Un-tombstone SKILL.md Step 0.5
  - [ ] Fresh tests (property / integration / contract)
  - [ ] PyPI publish dry-run + docs update
- [ ] **v0.3.0** — Phase 3 (see same build-decisions doc Phase 3).
  - [ ] Port brownfield detection + codebase explorer
  - [ ] Port PM variant (pm_interview.py, pm_handler.py, pm_seed,
        pm_document, pm_completion, question_classifier)
  - [ ] Add ontologist as 6th `InterviewPerspective`
  - [ ] Register PM MCP tool
  - [ ] Fresh PM + brownfield tests
  - [ ] End-to-end smoke on all 3 agents
  - [ ] Claude marketplace submission + PyPI publish

## Harness infrastructure (run in parallel to CA1–CA3 when slack time)

### 3B integration — **priority** (do early; pays off every session after)

Without this, every `/wrap` that touches 3b-forge has to manually
scope which changes go where and can't auto-populate the ACTIVE-STATUS
"Work" table with 3b-forge tasks. With proper 3B wiring, all of that
becomes automatic.

- [x] 2026-04-23 — **Ran `/init-3b` inside 3b-forge** (scaffold D,
  simple). Created:
  - `3b/.claude/project-claude/3b-forge.md` (CLAUDE.md SoT; repo
    `CLAUDE.md` symlinked)
  - `3b/.claude/prompts/3b-forge/PROJECT-CONFIG.md` (personal template)
  - `3b/projects/3b-forge/` (empty; task tracking will land here —
    separate from Brain's existing `projects/3b/`)
  - `docs/` symlink → `3b/projects/3b-forge/` (gitignored,
    personal-only). Public docs, if any, stay in-repo.
  - Registered in `3b/.claude/projects.md` (Registered + Sync Status).
- [~] **Reconcile `todos.md` locations.** De-facto option (b) in place:
  `todos.md` stays at repo root (public backlog), `3b/projects/3b-forge/`
  stands ready for personal planning. Revisit once 3B-side gains
  content and /wrap path-reading needs a canonical home.
- [x] 2026-04-23 — **Confirmed `PROJECT-CONFIG.md` fields** (personal
  template: `name`, `type: personal`, GitHub org/repo, `todos: todos.md`,
  `progress: PROGRESS.md`, status symbols). `actives_path` intentionally
  omitted for now — no actives folder pattern in use.
- [~] **Verify `/wrap` auto-detection.** This /wrap run is the test
  (running post `/init-3b` from `3b-forge/`). Confirms PROJECT_MODE=true
  and dual-repo commits. ACTIVE-STATUS Work-table inclusion depends on
  an actives folder layout, which is not set up (see reconcile task
  above).
- [ ] **Add routing entry to global CLAUDE.md** only if needed —
  PROJECT-CONFIG.md auto-detection handled it this run.
- [x] **Decide `docs/` symlink question.** Resolved 2026-04-23 —
  `docs/interview-skill/` was internal analysis, moved to `tmp/`
  (gitignored). No public `docs/` dir exists currently. Future public
  docs, if any, stay in-repo. Personal planning (`todos.md`,
  `actives/`) goes under 3B project folder when `/init-3b` runs.
- [ ] **Update harness README's file-layout diagram** after 3B wiring
  to document which files are in-repo vs in 3B.

### General harness infrastructure

- [ ] Add `.claude-plugin-marketplace.json` (or Claude's current
  marketplace manifest format) so
  `claude plugin marketplace add brandonwie/3b-forge` discovers
  individual plugins under `plugins/` correctly.
- [ ] Document per-agent install flow for non-Claude platforms in root
  README with concrete, tested commands (current instructions are best-
  guess; both Codex and Gemini install paths need verification).
- [ ] Decide: stay under `brandonwie/` user on GitHub, or migrate the
  harness to a GitHub org once a second "real" plugin arrives.
- [ ] Add CI (GitHub Actions) running: plugin.json schema validation,
  markdown lint on docs/, eventually Python tests for PyPI package
  side.

## Future plugin ideas (not yet committed)

Backlog — raw ideas, no roadmap slot yet. Candidates only:

- [ ] `/edit` workflow skill — refactor-focused guided edit
- [ ] `/simplify` post-PR review — removes accidental complexity
- [ ] `/codebase-summary` — summary for newcomer onboarding
- [ ] `/ralph` variant — persistent verify-until-green loop
- [ ] `/wrap` lite — end-of-session checklist without full 3B
  integration (for repos not 3B-connected)
- [ ] Custom MCP servers (TBD based on which plugins ship first)

## Closed / recent

- [x] 2026-04-23 — `ask-socratic` repo scaffolded, v0.1.0-alpha
      committed.
- [x] 2026-04-23 — Rename repo `ask-socratic` → `3b-harness` → `3b-forge`.
      First rename restructured single-plugin layout to harness layout with
      `plugins/<name>/`; second rename re-branded to 3B Forge (packaging
      layer under the 3B umbrella — see CHANGELOG).
- [x] 2026-04-23 — Move `plugins/interview-codex/` in from
      `ouroboros/plugins/`.
- [x] 2026-04-23 — Copy `docs/interview-skill/` (10 analysis files,
      EN + KO for #09) into harness.
- [x] 2026-04-23 — Rename `plugins/interview/` →
      `plugins/interview-claude/`; demote `v0.1.0-alpha` → `v0.0.1`
      (not-for-use snapshot).

## References

- Root [README.md](./README.md) — forge overview.
- [CHANGELOG.md](./CHANGELOG.md) — history of changes.
- Internal design-journey material (gitignored): `tmp/interview-skill/`,
  `tmp/archive/`, `tmp/review-from-claude.md`, `tmp/review-from-codex.md`,
  `tmp/consolidated-plan.md`.
- Upstream: [Q00/ouroboros](https://github.com/Q00/ouroboros).
