---
name: python
description: Use for Python work with uv—envs, deps, and commands run through uv; avoid pip/venv/pip-tools; keep Justfile/CI parity with ruff, mypy, pytest.
---

# Python (uv-only)

## Overview
Standardize Python workflows on `uv` for envs, dependency resolution, and execution. No `pip`, `venv`, or `pip-tools` unless forced by third-party tooling.

## When to Use
- Any Python install/run/test/lint/typecheck in this repo.
- Setting up new projects or maintaining existing ones.
- CI steps for Python.

## Core Pattern
- **Standard commands (keep CI aligned)**: `uv venv .venv && source .venv/bin/activate && uv sync`; `uv run ruff format --check .`; `uv run ruff check .`; `uv run mypy .`; `uv run pytest`; `uv lock`; combine as needed for CI.
- **Env**: `uv venv .venv`; activate shell or direnv; never use system/site-packages.
- **Deps**: `uv add <pkg>`; dev deps `uv add --dev ruff mypy pytest`; sync `uv sync`; commit `uv.lock` + `pyproject.toml`.
- **Run**: always `uv run <cmd>` (python, pytest, scripts).
- **CI**: `uv sync --frozen`; `uv run pytest` (plus ruff/mypy as needed).

## Quick Reference
| task | command |
| --- | --- |
| New env | `uv venv .venv` |
| Install | `uv add foo` / `uv add --dev ruff mypy` |
| Sync lock | `uv sync --frozen` |
| Run script | `uv run python script.py` |
| Tests | `uv run pytest` |
| Format | `uv run ruff format --check .` |
| Lint | `uv run ruff check .` |
| Types | `uv run mypy .` |
| Lock | `uv lock` |

## Red Flags
- Any `pip install`, `python -m venv`, or `pipenv/poetry` use.
- Missing `uv.lock` in repo.
- Running `python script.py` without `uv run`.
- Mixing global site-packages with project env.

## Verification
- Fresh clone: `uv venv && uv sync --frozen && uv run pytest` succeeds without pip.
- `which pip` points to `.venv/bin/pip` created by uv.
