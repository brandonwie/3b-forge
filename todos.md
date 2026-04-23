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

- [ ] **Run `/init-3b` inside 3b-forge** to wire it into the 3B
  knowledge system. This creates:
  - `3b/.claude/project-claude/3b-forge.md` (project CLAUDE.md
    source; the repo's `CLAUDE.md` becomes a symlink to this)
  - `3b/.claude/prompts/3b-forge/PROJECT-CONFIG.md` (tells skills
    where to find todos, PROGRESS, actives, docs paths)
  - `3b/projects/3b-forge/` (personal docs + task tracking —
    `todos.md`, `actives/`, `PROGRESS.md` live here)
  - Optional: `docs/` inside the repo as a symlink to
    `3b/projects/3b-forge/` (gitignored, personal-only). Decide up
    front: no `docs/` directory currently — prior Ouroboros analysis
    was moved to `tmp/` as internal material. If future public docs
    emerge, they go under `docs/` in-repo (NOT symlinked to 3B).
    The `/init-3b` wiring needs a variant: docs stay in-repo, but the
    3B project folder still holds task tracking (`todos.md` + `actives/`).
- [ ] **Reconcile `todos.md` locations.** Two options:
  - (a) Move this `todos.md` into `3b/projects/3b-forge/todos.md`
    (the 3B-canonical location, symlinked back OR gitignored). Keeps
    `/wrap`'s PROJECT_MODE path-reading working out of the box.
  - (b) Keep `todos.md` at 3b-forge root (public, committed — good
    for contributors to see backlog) AND also wire
    `3b/projects/3b-forge/todos.md` for personal planning that
    shouldn't be public. Dual-tracker.
  - Pick one before committing to layout.
- [ ] **Confirm `PROJECT-CONFIG.md` fields** — minimally needs
  `project: 3b-forge`, `domain: personal` (or `tools`?),
  `actives_path`, `todos_path`, `type: personal` (or the new
  `plugins-workspace` type if we introduce one).
- [ ] **Verify `/wrap` auto-detection.** After `/init-3b`, run `/wrap`
  from `3b-forge/` and confirm it:
  - detects PROJECT_MODE=true,
  - reads this `todos.md` (if option a above) or the 3b-personal one
    (option b),
  - includes 3b-forge tasks in the ACTIVE-STATUS Work table,
  - commits to both repos separately with correct scopes.
- [ ] **Add routing entry to global CLAUDE.md** if not auto-detected —
  `/wrap` should know `3b-forge` is a recognized project so it
  doesn't fall back to 3B-only mode.
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
