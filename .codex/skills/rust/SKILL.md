---
name: rust
description: Use when developing Rust projects in the tempoxyz org—standardizes fmt/clippy/nextest, sccache+mold, feature-powerset checks, MSRV builds, docsrs flags, and xtask patterns so local and CI behavior match.
---

# Rust (tempoxyz conventions)

## Overview
Fast, reproducible Rust workflows aligned with tempoxyz repos: cached toolchains, mold + sccache, clippy-as-error, nextest, feature-matrix checks, docsrs parity, and xtask utilities.

**Doc-first, no guessing:** Always consult official docs (rust-lang.org/edition-guide, doc.rust-lang.org/std, crate docs on docs.rs). If the exact flag/API/version isn’t in docs or you’re unsure, pause and ask for the correct link instead of inferring.

## When to Use
- Working on Rust crates (tempo, reth-commonware, tempo-commonware, dex-kv, tempo-std, etc.).
- Adding CI steps or local scripts to match repo expectations.
- Verifying docs/build across MSRV and nightly.

## Core Pattern
1) **Toolchain + components**
   - Default: stable; lint: nightly with `clippy` / `rustfmt` when required.
   - MSRV guard: pin (e.g., `toolchain: "1.88"`) and run `cargo build --bin <name>`.

2) **Standard commands (keep consistent with CI)**
   - Setup tools: install toolchains, sccache, mold, nextest, cargo-hack, typos, deny.
   - Format: `cargo fmt --all --check`.
   - Lint: `cargo clippy --all-targets --all-features --locked -- -D warnings`.
   - Test: `cargo nextest run --no-fail-fast -j num-cpus`.
   - Features: `cargo hack check --feature-powerset --depth 1`.
   - Docs: `cargo doc --workspace --all-features --no-deps` with docsrs flags.
   - MSRV: pinned-toolchain build (e.g., `cargo +1.88 build --bin <name>`).

3) **Performance**
   - Use `mold` linker (`rui314/setup-mold@v1` or `-Zshare-generics` not needed).
   - Enable `sccache` (`mozilla-actions/sccache-action@v0.0.9`); set `RUSTC_WRAPPER=sccache`.

4) **Checks**
   - Format: `cargo fmt --all --check`.
   - Lint: `cargo clippy --all-targets --all-features --locked -- -D warnings`.
   - Tests: `cargo nextest run --no-fail-fast -j num-cpus` (install via `taiki-e/install-action@nextest`).
   - Feature surface: `cargo hack check --feature-powerset --depth 1` for broad combos.
   - Licenses/Deps: `cargo deny check` (reuse workflow), `cargo vet` if present.
   - Typos: `typos` (`crate-ci/typos@v1`).
   - Custom sanity: `zepter run check` (from `tempo`).

5) **Docs parity**
   - `cargo doc --workspace --all-features --no-deps --document-private-items`.
   - `RUSTDOCFLAGS: --cfg docsrs -D warnings --show-type-layout --generate-link-to-definition --enable-index-page -Zunstable-options`.

6) **Xtask utilities**
   - Use existing `cargo xtask` commands (e.g., `cargo xtask generate-genesis ...`) instead of ad-hoc scripts.
   - Keep generated artifacts compared into repo fixtures (diff & fail if drift).

7) **Env defaults**
   - `CARGO_TERM_COLOR=always`, `RUST_BACKTRACE=full`, `RUSTFLAGS="-D warnings"` for builds where appropriate.

8) **Caching**
   - Combine `sccache` with `Swatinem/rust-cache@v2` in CI; keep lockfiles pinned.

## Quick Reference
| Task | Command |
| --- | --- |
| Format | `cargo fmt --all --check` |
| Lint | `cargo clippy --all-targets --all-features --locked -- -D warnings` |
| Test | `cargo nextest run --no-fail-fast -j num-cpus` |
| Feature sweep | `cargo hack check --feature-powerset --depth 1` |
| Docs | `cargo doc --workspace --all-features --no-deps` (+ docsrs flags) |
| MSRV | `cargo build --bin tempo` with pinned toolchain |
| Typos | `typos` |
| Zepter | `zepter run check` |

## Common Mistakes
- Running `cargo test` without nextest → slower/less parallel.
- Skipping `--locked` causing feature drift.
- Forgetting `mold`/`sccache` → slow CI.
- Leaving RUSTFLAGS unset → warnings slip through.
- Not updating docs when public API changes; docs job will fail in CI.
- Missing `Justfile` or targets drift from CI steps → contributors can’t run parity commands locally.

## Red Flags
- No clippy `-D warnings`.
- Feature-powerset not checked in multi-feature crates.
- MSRV not validated when adding new dependencies.
- Generated fixtures updated manually instead of via `xtask`.
- Docsrs flags missing; doc build passes locally but fails on docs.rs.

## Verification
- `cargo fmt && cargo clippy ... && cargo nextest ...` passes locally with sccache/mold configured.
- `cargo hack check --feature-powerset --depth 1` passes or is consciously scoped.
- MSRV build succeeds on pinned toolchain.
- Docs build with docsrs flags succeeds.

## Rationalizations Countered
| Excuse | Counter |
| --- | --- |
| "Nextest is optional" | It’s the default in CI and faster; keeps parity. |
| "mold/sccache not worth it" | Significant speedups; trivial to add. |
| "Warnings are fine" | CI treats warnings as errors; fix locally first. |
| "Feature matrix is too big" | `cargo hack --depth 1` limits blast radius while catching combos. |
