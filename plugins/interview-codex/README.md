# Interview Codex

Portable Socratic interview extraction from Ouroboros.

## What is included

- `skills/interview/SKILL.md`
  - A Codex-facing portable interview skill with no Ouroboros-specific MCP boot flow.
- `src/interview_plugin_core/`
  - A reusable Python core for interview state, question generation, prompt loading, brownfield detection, and ambiguity scoring.
- `tests/`
  - Ported unit coverage for the extracted portable subset.

## What is intentionally excluded from v1

- Ouroboros plugin version checks and self-update flow
- Deferred-tool loading and MCP handler glue
- Seed generation pipeline coupling
- PM interview variant

## Runtime model

The package keeps the original `LLMAdapter` protocol so other runtimes can wrap their own model client. The default model string is read from `INTERVIEW_CODEX_MODEL` and otherwise falls back to `"default"`.

Prompt overrides are supported through `INTERVIEW_CODEX_PROMPTS_DIR`. State persistence defaults to `~/.interview-codex/data` and can be overridden with `INTERVIEW_CODEX_STATE_DIR`.

## Runtime integration

### 1. Implement the `LLMAdapter` protocol

`LLMAdapter` is a thin async protocol with one method: `complete(config, messages) -> CompletionResponse`. Wrap your preferred model client (litellm, OpenAI SDK, Anthropic SDK, etc.) into something that matches this shape.

```python
from interview_plugin_core import (
    CompletionConfig,
    CompletionResponse,
    LLMAdapter,
    Message,
    MessageRole,
)

class MyAdapter:
    async def complete(
        self,
        config: CompletionConfig,
        messages: list[Message],
    ) -> CompletionResponse:
        # Translate `messages` + `config` into your provider's call,
        # return a CompletionResponse(content=..., model=..., usage=...).
        ...
```

The core package uses structural typing — any object with a matching `complete()` coroutine satisfies `LLMAdapter`.

### 2. Construct the engine

```python
from pathlib import Path
from interview_plugin_core import InterviewEngine

engine = InterviewEngine(
    llm_adapter=MyAdapter(),
    state_dir=Path.home() / ".interview-codex" / "data",
)
```

`state_dir` and `model` default to `INTERVIEW_CODEX_STATE_DIR` / `INTERVIEW_CODEX_MODEL` env vars. `state_dir` is created automatically on `__post_init__`.

### 3. Drive rounds

```python
result = await engine.start_interview(
    initial_context="I want to build a CLI tool for task management",
    cwd="/path/to/existing/repo",  # optional — enables brownfield detection
)
state = result.value

while not state.is_complete:
    question = (await engine.ask_next_question(state)).value
    user_response = input(question)
    await engine.record_response(state, user_response)
```

When `cwd` is supplied, the engine detects brownfield projects and records the path under `state.codebase_paths`. It does NOT auto-explore the codebase — the calling runtime is responsible for reading files and feeding facts back via enriched answer prefixes.

### 4. Enriched answer prefixes

User responses can be annotated with source prefixes so downstream scoring understands provenance:

- `[from-code]` — fact extracted from the calling runtime's codebase inspection.
- `[from-user]` — direct human decision.
- `[from-research]` — fact retrieved from external sources (docs, specs, APIs).

### 5. State persistence

`save_state(state)` / `load_state(interview_id)` / `list_interviews()` use file-locked writes under `state_dir`. Safe for concurrent access within a single process.

## Running tests

```bash
cd plugins/interview-codex
uv run python -m pytest -q
```

> Note: direct `.venv/bin/pytest` may fail if the virtualenv script points at a stale interpreter path from another checkout. Use `uv run` — it resolves the correct interpreter from `pyproject.toml` + `uv.lock`.
