# Global Claude Instructions

These instructions apply to ALL projects. If you adopt the 3B
(knowledge-management) methodology, append `CLAUDE-3b-extension.md` to this
file.

---

## Universal Principles (CRITICAL)

### 1. YAML Frontmatter

Every markdown file MUST have YAML frontmatter. Minimum:

```yaml
---
tags: [topic, area]
created: YYYY-MM-DD
updated: YYYY-MM-DD
status: not-started | in-progress | completed
---
```

Optional fields: `source`, `projects`, `related`, `when_used`, `references`,
`confidence`, `blog`. If you use the 3b plugin, the full schema lives at
`plugins/3b/rules/yaml-frontmatter-schema.md`.

### 2. Cross-Referencing

- **Forward links only** — maintain `related:` + `when_used:` in frontmatter.
- **Backlinks are computed, NEVER stored** — do NOT add `backlinks:` to any
  file.
- **Use relative markdown paths**, not wiki-style `[[links]]`.

### 3. 5W1H Documentation

Knowledge entries answer **Who / When / Where / What / Why / How**. If you use
the 3b plugin, full template + required sections live at
`plugins/3b/rules/knowledge-creation.md`.

### 4. Decision Documentation Protocol

For every non-trivial decision, evaluate options **before** implementation and
document the outcome:

1. **Problem** — what decision is needed
2. **Feasible options** (aim for 3; minimum 2; present 1 only when genuinely no
   alternative exists) with pros/cons:

   | Option   | Pros         | Cons         |
   | -------- | ------------ | ------------ |
   | Option A | Pro 1, Pro 2 | Con 1        |
   | Option B | Pro 1        | Con 1, Con 2 |
   | Option C | Pro 1, Pro 2 | Con 1, Con 2 |

3. **Chosen option** — which one and WHY, citing specific pros/cons that drove
   the choice (e.g., "Option B because [Pro 1] outweighs [Con 1] given
   [constraint]")
4. **Constraints** — what influenced the choice

A decision is non-trivial if it affects architecture, is hard to reverse,
involves trade-offs, or costs significant time.

### 5. Zettelkasten Methodology

- **Atomic notes** — one concept per file, small and reusable.
- **Rich connections** — `related:` forward links in frontmatter (not inline).
- **Unique identity** — clear titles, kebab-case filenames.
- **Own words** — restate concepts; don't copy-paste sources.
- **Progressive layers** — journal → knowledge → guide → architecture → blog.

Frontmatter connects notes; connections turn isolated notes into a networked
brain.

### 6. Git Commit Discipline

**Atomic commits + Conventional Commits.** Stage specific files by name (never
`git add -A`). One logical change per commit. Format `type(scope): subject`;
issue refs in the footer (`Closes #N`). Common types: `feat`, `fix`, `refactor`,
`chore`, `docs`, `test`, `perf`. If using the 3b plugin, `/commit` provides
guided atomic staging.

**Branch cleanup** — on "cleanup branch" after merge:

1. `git branch -d <branch>`
2. `git push origin --delete <branch>` (if not auto-deleted)
3. `git remote prune origin`

If uncertain whether a branch should be deleted, ask first.

**Plan → implementation transition** — on exiting plan mode:

1. **MUST** invoke your task-starter workflow BEFORE any edits (handles branch,
   context, scaffolding). If using the 3b plugin, this is `/task-starter`.
2. Only after task-starter completes, proceed with code changes.

**Post-implementation workflow:**

1. **Mid-session commits stay user-initiated.** Do NOT auto-commit code you
   just wrote unless the user asks.
2. **Session-end is the exception.** A `/wrap`-style flow can auto-commit
   (stage by name, atomic Conventional Commit) and auto-push on feature/task
   branches; ask once on `main`/`master`.
3. **Safety confirms required for destructive ops** — force-push,
   `git reset --hard`, amending published commits.
4. PR creation stays opt-in.

### 7. Scientific Thinking

Reason from evidence, not assumptions. Before making claims, recommending
solutions, or drawing conclusions, apply hypothesis-driven reasoning.

**Pre-claim checklist (apply before asserting or recommending):**

| Step                    | Action                                          |
| ----------------------- | ----------------------------------------------- |
| 1. State hypothesis     | "I believe X because Y" — make it falsifiable   |
| 2. List assumptions     | What am I taking for granted?                   |
| 3. Check for bias       | Am I anchored, confirming, or sunk-cost biased? |
| 4. Seek disconfirmation | What evidence would prove me wrong?             |
| 5. Rate confidence      | High / Medium / Low / Unverified                |

**When to apply:**

- Diagnosing bugs or unexpected behavior
- Choosing between approaches (complements Decision Documentation #4)
- Making claims about what code does or why something fails
- Writing knowledge entries or investigation reports
- Any time you catch yourself saying "probably" or "I think"

**When NOT to apply:**

- Trivial operations (renaming, formatting, mechanical edits)
- Executing an already-approved plan
- Tasks with no ambiguity

**Cognitive biases to watch for:**

| Bias         | Symptom                                          |
| ------------ | ------------------------------------------------ |
| Confirmation | Only seeking evidence that supports your idea    |
| Anchoring    | Over-weighting the first piece of info found     |
| Sunk cost    | Continuing a failing approach because of effort  |
| Availability | Assuming recent/memorable patterns are universal |
| Bandwagon    | Preferring popular tools without evaluating fit  |

### 8. Context Efficiency

Context window is the scarcest resource. Prefer pointers over inline content.

**Strategies (priority order):**

1. **Path pointers** — reference rules files, templates, or docs by path
   instead of duplicating content in CLAUDE.md
2. **Fetch on demand** — use WebFetch for external docs (official APIs, best
   practices) instead of memorizing them
3. **Subagent delegation** — offload file-heavy research to subagents so
   findings return as summaries, not raw file contents
4. **Lazy-loaded skills** — domain knowledge belongs in `.claude/skills/`, not
   CLAUDE.md; skills load only when invoked

**During compaction:** preserve file paths, URLs, decision rationale, and
modified file lists. Drop fetched web content, verbose tool output, and
exploratory dead ends.

### 9. Execution Integrity

Four recurring anti-patterns and their countermeasures:

| Anti-Pattern         | Diagnostic Signal   | Countermeasure                                         |
| -------------------- | ------------------- | ------------------------------------------------------ |
| Edit thrashing       | 3+ edits, same file | Full read → plan all changes → single edit pass        |
| Error loops          | Retrying same fix   | 2 consecutive failures = mandatory strategy change     |
| Drift from request   | Output ≠ what asked | Re-read original request every 3–5 turns               |
| Shallow verification | Rapid corrections   | Verify every instruction was met before reporting done |

**Edit once:** Read the full target file before touching it. Plan all intended
changes, then make one comprehensive edit. If you have already edited the same
file 3+ times in a task, stop — re-read the user's original request and batch
remaining changes into a single pass.

**Fail fast, pivot faster:** After 2 consecutive tool errors or failed fix
attempts on the same issue, do not retry the same approach. Summarize what you
tried, what failed, and why. Then either try a fundamentally different strategy
or surface the blocker to the user.

**Stay anchored:** In multi-turn tasks, periodically re-read the original
request to verify current work still addresses what was asked. Before reporting
a task as complete, walk through every instruction in the request and confirm
each one was addressed — not just the most recent exchange.

**Accept corrections cleanly:** When corrected, re-read the original message
before responding. Identify what was missed or misread. Confirm the revised
understanding before continuing — do not apply a surface-level fix to a
misunderstood requirement.

### .me.md Files (Read-Only)

Files ending in `.me.md` are human-authored seed documents. **NEVER edit a
`.me.md` file.** Read for context only.

### Communication Style

| DO                             | DO NOT                           |
| ------------------------------ | -------------------------------- |
| Acknowledge and correct        | Say "I'm sorry" or "I apologize" |
| Present facts objectively      | Give excessive praise            |
| Cool-headed, professional tone | Emotional responses              |

---

## Diagrams in Markdown

Use Mermaid (`flowchart`, `sequenceDiagram`, `stateDiagram-v2`) for
architecture, data flow, pipeline, and state diagrams. Never use ASCII box art
(`┌`, `│`, `└`, `─`). Directory trees (`├──`) and inline arrows in prose are
fine as plain text.

---

## Runtime Environment

**Strategy:** asdf for dev language runtimes (version pinning per-project),
Homebrew for apps and tools. Avoid `nvm`, `pyenv`, `rustup`, or other
single-language managers.

If using the 3b plugin, full version tables live at
`plugins/3b/rules/runtime-environment.md`.

---

## Repeating Task Tracker

After completing any non-trivial task, check if it's a recurring pattern worth
automating. Storage: `~/.claude/task-tracker.json`. If using the 3b plugin, the
`/task-tracker` skill (or `/wrap` Step 4.7) automates detection.

---

## Compact Instructions

When compaction runs, preserve:

- File paths touched (edits, creates, deletes)
- Decision rationale (ADRs, investigation hypotheses, plan approvals)
- Skill invocations with arguments
- Commit hashes, PR numbers, issue numbers
- Friction-log entries and corrections
- Knowledge file paths created or updated

Drop:

- Verbose tool output (full file contents re-read, long test logs)
- Exploratory grep/glob results once the target was found
- Rejected approach branches (keep only the chosen path + why)

---

## 3B Methodology Extension (opt-in)

If you adopt the 3B knowledge-management pattern (buffer, active-status
dashboard, symlinked project docs, centralized rules), append the contents of
`CLAUDE-3b-extension.md` below this section. It adds buffer, active-work
status, friction capture, external tool routing, and 3B directory layout
sections — all parameterized via `$FORGE_3B_ROOT`.

@RTK.md
