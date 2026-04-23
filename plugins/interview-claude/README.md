# 3b (a.k.a. interview-claude)

Socratic-interview plugin for the 3b-harness, built from analysis of
the upstream [Ouroboros](https://github.com/Q00/ouroboros) `interview`
skill.

> **Status:** `v0.0.1` — **not-for-use snapshot**. Held side-by-side
> with [`../interview-codex/`](../interview-codex/) as a deliberate
> design-axis experiment (prompt-heavy vs engine-heavy — see
> [../../consolidated-plan.md](../../consolidated-plan.md) §3).
> Do not install yet.

## Graduation criterion (0.0.1 → 0.1.0)

We bump to `0.1.0` when this plugin is **ready-to-use-out-of-the-box
as a harness library** — meaning:

1. All P1+P2 items in [`../../consolidated-plan.md`](../../consolidated-plan.md)
   Workstream B have landed (perspective-rotation decision table is
   explicit, seed-closer 6-dim rubric is codified, session-continuity
   transcript convention is in place).
2. The slash command (`/3b:interview`) works end-to-end on a fresh
   Claude Code install with no manual file shuffling.
3. `docs/interview-skill/10-variant-comparison.md` exists so users
   understand why both plugins ship.
4. At least 2 golden transcript fixtures demonstrate the playbook on
   greenfield and brownfield inputs.

Until all four are true, the version stays at `0.0.1` and the keyword
list keeps `not-for-use` as an install guard.

## Snapshot intent

This folder captures one interpretation of "how to extract and port the
interview skill":

- Claude-session-authored, analysis-driven.
- Cross-agent (Claude Code / Codex / Gemini CLI) skill format from day
  one.
- Pure-markdown primary workflow — no MCP dependency, no Python
  runtime. (The earlier dual-path design with a deferred MCP mode has
  been dropped; a future numerical-scoring variant is the separate
  [`../interview-codex/`](../interview-codex/) plugin.)
- Seven agent prompts: six inherited (socratic-interviewer,
  seed-closer, researcher, simplifier, architect, breadth-keeper) plus
  the ontologist (added beyond upstream's default five).

The alternate in [`../interview-codex/`](../interview-codex/) is a
Codex-generated portable extraction that ships a Python scoring core
and its own skill. The two are deliberately different in scope — see
[../../consolidated-plan.md](../../consolidated-plan.md) §3 for the
design-axis thesis.

## Current gaps (v0.1.0 blockers)

1. Perspective rotation decision table needs expansion (SKILL.md §B.6
   has the table; integration tests via golden transcripts pending).
2. `seed-closer.md` 6-dim rubric not yet codified as per-dimension
   observable signals.
3. No session-continuity convention (transcript path under
   `projects/*/actives/` not yet documented).

Full backlog in [`../../consolidated-plan.md`](../../consolidated-plan.md)
Workstream B.

## How to read this snapshot

- [`.claude-plugin/plugin.json`](./.claude-plugin/plugin.json) —
  manifest (plugin `name: 3b`, `v0.0.1`; `not-for-use` keyword as
  install guard).
- [`skills/interview/SKILL.md`](./skills/interview/SKILL.md) — primary
  workflow playbook. Start here for how the skill actually behaves.
- [`agents/`](./agents/) — the seven role prompts loaded per round.
- [`commands/interview.md`](./commands/interview.md) — slash-command
  entry stub for `/3b:interview`.

## Design reference

The full analysis that informed this snapshot is in
[`../../docs/interview-skill/`](../../docs/interview-skill/). Start with
[`README.md`](../../docs/interview-skill/README.md) and the fork
decision tree.

Key decision doc:
[`09-plugin-build-decisions.md`](../../docs/interview-skill/09-plugin-build-decisions.md)
(English) or
[`09-plugin-build-decisions.ko.md`](../../docs/interview-skill/09-plugin-build-decisions.ko.md)
(Korean).

Note: the docs were written when the plugin name was `ask-socratic`,
then `interview`, then `interview-claude`. The plugin's **manifest
name** is now `3b` (so the slash command is `/3b:interview`); the
**directory name** remains `interview-claude` to preserve its pair
with `interview-codex`.

## File layout

```
plugins/interview-claude/
├── .claude-plugin/plugin.json       # manifest (name: 3b, v0.0.1)
├── commands/interview.md            # /3b:interview entry stub
├── skills/interview/
│   ├── SKILL.md                     # primary workflow
│   └── references/
│       ├── codex-tools.md           # Claude→Codex tool mapping
│       └── gemini-tools.md          # Claude→Gemini tool mapping
├── agents/                          # 7 role prompts
│   ├── socratic-interviewer.md
│   ├── seed-closer.md
│   ├── researcher.md
│   ├── simplifier.md
│   ├── architect.md
│   ├── breadth-keeper.md
│   └── ontologist.md
└── README.md                        # this file
```

## Upstream

Forked from the `interview` skill in
[Q00/ouroboros](https://github.com/Q00/ouroboros). Upstream carries the
original Socratic methodology, five-perspective model, and numerical
ambiguity-scoring design.

## Changelog

See the root [CHANGELOG.md](../../CHANGELOG.md) for both harness-level
and plugin-level entries.

## License

MIT. See [LICENSE](../../LICENSE).
