---
name: python-uv
description: Use when creating or maintaining Python projects, installing packages, or running Python commands — enforces uv for packaging, environments, and execution so workflows stay reproducible, fast, and aligned with modern Python tooling.
---

# Python + uv Only

## Overview
Always use `uv` (the Rust-powered Python package manager) for env creation, dependency management, and command execution. Avoid `pip`, `virtualenv`, `venv`, `pip-tools`, and ad-hoc `python -m ...` so tooling stays consistent and cached.

**Doc-first, no guessing:** Use official docs (https://docs.astral.sh/uv/, https://docs.python.org/3/) and library docs (ruff, mypy, pytest). If an option or behavior isn’t clear in docs, stop and ask for the right link instead of speculating.

## When to Use
- Starting a new Python project or onboarding to an existing one without locked tooling.
- Installing/upgrading dependencies or adding dev tools.
- Running scripts, tests, linters, or REPLs locally or in CI.
- Replacing legacy `pip install -r requirements.txt` flows.

**Do NOT use** `pip`, `pipenv`, `poetry`, or `virtualenv` in these repos unless explicitly required by a third-party project you cannot change.

## Core Pattern
1) **Justfile first (required)**
   - Provide a root `Justfile` so clone + `just` works. Suggested targets:
     - `default` → `just test` (never a no-op).
     - `just setup` → `uv venv .venv && source .venv/bin/activate && uv sync`
     - `just fmt` → `uv run ruff format --check .`
     - `just lint` → `uv run ruff check .`
     - `just type` → `uv run mypy .`
     - `just test` → `uv run pytest`
     - `just lock` → `uv lock`
     - `just check` → `just fmt lint type test` (or a shell chain)
   - Keep CI steps identical to these recipes.

2) **Create env once**  
   `uv venv .venv`

3) **Activate**  
   `source .venv/bin/activate` (shell) or set `VIRTUAL_ENV` in CI. Prefer direnv/rc files to auto-activate.

4) **Pin and install**  
   - Add deps: `uv add fastapi pytest`  
   - Dev-only: `uv add --dev ruff mypy`  
   - Sync from lock: `uv sync`

5) **Run commands through uv**  
   - `uv run python script.py`  
   - `uv run pytest tests`  
   - `uv run ruff check .`  
   - `uv run python -m http.server 8000`

6) **Lock + cache**  
   `uv lock` generates `uv.lock`; commit lock + `pyproject.toml`.

7) **CI pattern**  
   ```bash
   uv sync --frozen
   uv run pytest
   ```

## Quick Reference
| task | uv command |
| --- | --- |
| New env | `uv venv .venv` |
| Install deps | `uv add <pkg>` / `uv add --dev <pkg>` |
| Sync from lock | `uv sync` |
| Run anything | `uv run <cmd>` |
| Update all | `uv lock --upgrade` |
| Export list | `uv export --format requirements.txt > requirements.txt` (only when another tool demands) |

## Common Mistakes
- Mixing `pip install` with `uv sync` → can corrupt env; recreate with `rm -rf .venv && uv venv && uv sync`.
- Forgetting to commit `uv.lock` → breaks reproducibility.
- Running `python script.py` directly → bypasses uv shims; use `uv run python script.py`.
- Using per-user site-packages (`pip install --user`) → conflicts with project env; always env-local via uv.

## Rationalizations Countered
| Excuse | Counter |
| --- | --- |
| "pip is already installed" | uv is faster, resolves locks, and keeps one tool chain; install uv once via `curl -LsSf https://astral.sh/uv/install.sh | sh`. |
| "I only need a quick script" | Quick scripts still deserve reproducibility; `uv run python - <<'PY' ...` costs almost nothing. |
| "CI images already have pip" | Add `uv` install step; caching and `--frozen` lock enforcement reduce flakes. |
| "Requirements.txt is enough" | Without a lock, resolves can drift; `uv lock` captures exact versions. |

## Red Flags
- Any command starts with `pip` or `python -m pip`.
- Missing `uv.lock` next to `pyproject.toml`.
- `python script.py` in docs/CI instead of `uv run`.
- Virtualenv created with `python -m venv` instead of `uv venv`.

## Verification (do this per repo)
- Fresh clone: `uv venv && uv sync --frozen && uv run pytest` completes without touching pip.
- `which pip` shows `.venv/bin/pip` symlinked by uv (not system). If not, recreate env via uv.

## Notes
- If upstream tooling hard-requires pip/virtualenv, isolate it in a throwaway env; do not mix with project envs. Document the exception in the repo’s CLAUDE.md.
