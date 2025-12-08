---
name: github-workflows
description: Use when setting up GitHub Actions for Rust, Python, or TypeScript (including monorepos) to run formatters, linters, tests on pull requests, gate Vercel preview builds, and scope jobs with path filters so cross-language docs/examples don’t trigger unrelated pipelines.
---

# GitHub Workflows (Rust / Python / TypeScript)

## Overview
Opinionated GitHub Actions patterns for language-specific fmt/lint/test plus Vercel previews, designed for monorepos: jobs only run when relevant paths change, caches stay warm, and docs for another language don’t fan out the whole CI.

**Doc-first, no guessing:** Rely on official docs for Actions syntax and marketplace actions (docs.github.com/actions, action README). If uncertain about a key, permission, or input, check the action docs or ask for the URL instead of inferring.

## When to Use
- You need reliable PR checks for Rust, Python (uv), or TypeScript projects.
- Monorepo contains multiple stacks (e.g., Rust core + JS docs) and must avoid cross-triggering.
- PRs should automatically build Vercel previews for web apps, but only when frontend paths change.

## Core Patterns
1) **Trigger + path scoping**
```yaml
on:
  pull_request:
    paths:
      - "rust/**"
      - ".github/workflows/**"
      - "!docs/js/**" # exclude if desired
  push:
    branches: [main]
```
- Per-job guard: `if: contains(github.event.pull_request.head.sha, '') || github.event_name == 'push'` is redundant; instead use `if: needs.changes.outputs.rust == 'true'`.

2) **Detect changes once**
```yaml
jobs:
  changes:
    runs-on: ubuntu-latest
    outputs:
      rust: ${{ steps.filter.outputs.rust }}
      py: ${{ steps.filter.outputs.py }}
      ts: ${{ steps.filter.outputs.ts }}
    steps:
      - uses: actions/checkout@v4
      - id: filter
        uses: dorny/paths-filter@v3
        with:
          filters: |
            rust:
              - 'rust/**'
            py:
              - 'python/**'
            ts:
              - 'js/**'
```
- Downstream jobs use `needs: [changes]` and `if: needs.changes.outputs.rust == 'true'`.

3) **Rust job (fast + deterministic)**
```yaml
  rust:
    needs: changes
    if: needs.changes.outputs.rust == 'true'
    runs-on: depot-ubuntu-latest-4 # or ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
        with: { toolchain: stable, components: rustfmt, clippy }
      - uses: rui314/setup-mold@v1
      - uses: mozilla-actions/sccache-action@v0.0.9
      - uses: Swatinem/rust-cache@v2
      - run: cargo fmt --all -- --check
      - run: cargo clippy --all-targets --all-features -- -D warnings
      - uses: taiki-e/install-action@nextest
      - run: cargo nextest run --no-fail-fast -j num-cpus
```

4) **Python (uv) job**
```yaml
  python:
    needs: changes
    if: needs.changes.outputs.py == 'true'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v3
      - run: uv venv .venv && source .venv/bin/activate && uv sync --frozen
      - run: uv run ruff check .
      - run: uv run mypy .
      - run: uv run pytest
```

5) **TypeScript job**
```yaml
  ts:
    needs: changes
    if: needs.changes.outputs.ts == 'true'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 20, cache: "pnpm" }
      - uses: pnpm/action-setup@v4
        with: { run_install: true }
      - run: pnpm lint
      - run: pnpm test -- --runInBand
      - run: pnpm format:check
      - name: Cache Playwright
        uses: actions/cache@v4
        id: playwright-cache
        with:
          path: ~/.cache/ms-playwright
          key: ${{ runner.os }}-playwright-1.56.1
      - name: Install Playwright
        if: steps.playwright-cache.outputs.cache-hit != 'true'
        run: pnpx playwright@1.56.1 install --with-deps
```

6) **Vercel preview (guarded)**
```yaml
  vercel-preview:
    needs: changes
    if: needs.changes.outputs.ts == 'true' # only frontend paths trigger
    runs-on: ubuntu-latest
    permissions: { contents: read, deployments: write, id-token: write }
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 20 }
      - run: pnpm install --frozen-lockfile
      - name: Vercel Deploy
        run: npx vercel --token=${{ secrets.VERCEL_TOKEN }} --scope=${{ secrets.VERCEL_SCOPE }} --yes --confirm
```
- Set `VERCEL_PROJECT_ID`, `VERCEL_ORG_ID`, `VERCEL_TOKEN`, `VERCEL_SCOPE` secrets.
- For monorepo, pass `--project` or `--prod` flags and `--env`/`--build-env` as needed.

7) **Matrix for crates/packages (optional)**
```yaml
  rust:
    strategy:
      matrix: { crate: [core, cli] }
    steps:
      - run: cargo test -p ${{ matrix.crate }}
```
Use separate filters per package if paths-filter becomes too broad.

8) **Aggregating status + concurrency**
- Add `concurrency` to cancel superseded PR runs:
  ```yaml
  concurrency:
    group: ${{ github.workflow }}-${{ github.head_ref || github.run_id }}
    cancel-in-progress: ${{ github.event_name == 'pull_request' }}
  ```
- Use `re-actors/alls-green@release/v1` as a final job that depends on all others to produce a single required status even when some jobs are skipped:
  ```yaml
  final:
    if: always()
    needs: [rust, python, ts, vercel-preview]
    runs-on: ubuntu-latest
    steps:
      - uses: re-actors/alls-green@release/v1
        with: { jobs: ${{ toJSON(needs) }} }
  ```

9) **Rust extras seen in production repos**
- Feature-powerset checks: `cargo hack check --feature-powerset --depth 1`.
- MSRV guard: pin toolchain (e.g., `toolchain: "1.88"`) and run `cargo build --bin <name>`.
- Docs job with `RUSTDOCFLAGS` (docsrs parity) and optional Pages upload.
- Heavy integrity checks: snapshot re-execution or state replay can be separate long-runner jobs.
- Reusable workflows: `uses: owner/repo/.github/workflows/deny.yml@main` to share license/deny checks across repos.
- Private registry/login in CI: use `docker/login-action@v3` for ghcr.io before pulling images or running E2E that need them.

## Quick Reference
| Stack | Format | Lint | Test | Cache |
| --- | --- | --- | --- | --- |
| Rust | `cargo fmt -- --check` | `cargo clippy -D warnings` | `cargo nextest run --no-fail-fast` | `sccache` + `Swatinem/rust-cache` |
| Python | `uv run ruff format --check .` (or `ruff check .`) | `uv run ruff check .` | `uv run pytest` | `astral-sh/setup-uv@v3` caches wheel/venv |
| TypeScript | `pnpm format:check` | `pnpm lint` | `pnpm test` | `actions/setup-node` cache=pnpm |

## Common Mistakes
- Missing `needs: changes` leads to unconditional job runs.
- Forgetting `paths-filter` causes docs to trigger full CI.
- Running Vercel preview on every PR regardless of app paths.
- Using `pip install` instead of `uv sync --frozen` in Python jobs.
- Skipping Rust components (`rustfmt`, `clippy`, `nextest`) so jobs fail when invoked.
- No `concurrency` → parallel duplicate runs on stacked pushes.

## Red Flags
- Workflow lacks `paths` or `paths-filter`.
- No lockfiles committed (`uv.lock`, `pnpm-lock.yaml`, `Cargo.lock` when applicable).
- Vercel secrets not configured but job is always-on.
- Monorepo packages share one `pnpm install` without `--filter` when only one app changed.
- Long-running Rust jobs without sccache/mold → slow CI.
- Aggregator job missing while some jobs are optional → required status may stay “pending”.

## Verification
- PR touching only `docs/js/**` should skip Rust and Python jobs.
- PR touching `rust/` runs Rust job and skips TS/Vercel.
- PR touching `js/app/` runs TS + Vercel preview; caches hit.
- Push to `main` still runs language jobs for changed stacks.
- All required checks report a single final status even if some jobs are skipped.

## Rationalizations Countered
| Excuse | Counter |
| --- | --- |
| "Running all jobs is safer" | It slows feedback and burns minutes; scoped jobs keep signals relevant. |
| "Paths-filter is flaky" | dorny/paths-filter is battle-tested; add a changes job once and reuse outputs. |
| "Vercel should always run" | Previews are costly; gate on frontend paths and skip when unchanged. |
| "pip/venv is fine" | uv is faster and reproducible; mixing tools increases flakes. |
| "We don't need sccache/mold" | They cut Rust build times substantially; trivial to add and safe. |
| "nextest is overkill" | It’s faster and more reliable for Rust CI; drop-in via `taiki-e/install-action@nextest`. |
