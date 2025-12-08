---
name: conventional-commits
description: Use when preparing git commits, especially when multiple fixes/features are intermixed or unstaged — enforces Conventional Commits format, splitting changes with git add -p so each commit expresses one atomic behavior change and passes CI/release tooling.
---

# Conventional Commits

## Overview
Commit messages stay parseable for changelogs/semver. Core rule: one atomic behavior change per commit, titled `<type>[scope]: <imperative>`.

## When to Use
- Mixed changes in working tree (feature + bugfix + refactor) and you need clean history.
- Release tooling/CI expects semantic versions or auto-changelog.
- You feel tempted to "just commit everything as update" due to time pressure.
- You need to split work using `git add -p` before saving progress.

## Core Pattern (Split Then Commit)
1) **Group by behavior:** list intended behaviors (feature, bugfix, refactor).  
2) **Stage atomically:** for each behavior, stage only matching hunks with `git add -p`; skip unrelated hunks (`s`/`n`), edit mixed hunks (`e`). *Never stage plan docs (e.g., `docs/plans/*`) unless explicitly asked.*  
3) **Verify:** `git diff --cached` should read like the eventual title; otherwise `git reset -p` and restage.  
4) **Commit:** `<type>[scope]: <imperative>`; subject ≤72 chars; body = what/why, footer = issues.  
5) **Repeat** until `git status` is clean.

## Post-Commit & PR
- Push the branch after final commits.
- Open a PR with a concise title mirroring the main commit and a short description (what changed, why, how to test). Use repo templates if present.

## Quick Reference
| type | use for |
| --- | --- |
| feat | new behavior |
| fix | bug fix |
| refactor | internal-only |
| chore | tooling/config |
| test | tests only |
| docs | documentation |
| perf | performance |
| build | build system/deps |
| ci | CI pipeline |
| revert | revert prior commit |
Example: `feat(auth): add magic-link login`

## Rationalizations Countered
| Excuse | Reality |
| --- | --- |
| "No time, just one commit" | `git add -p` + message takes minutes; saves revert pain. |
| "It's all related" | Related ≠ same behavior; keep history searchable by outcome. |
| "I can't remember scopes" | Scope optional; omit it. |
| "I'll clean later" | Unlikely; tools need correct types now. |
| "git add -p is risky" | Reversible via `git reset -p` + `git diff --cached`. |

## Red Flags
- One commit mixes new behavior and bug fix.
- Subject is "update" / "misc" / past-tense ("added", "fixed").
- `git diff --cached` doesn't match the commit subject.
- You skip review of staged diff before committing.

## Common Mistakes
- Using past tense; subjects must be imperative ("add", "fix").
- Forgetting type → commit won't trigger semantic release.
- Letting unstaged changes leak; always zero-check `git status` after each commit.
- Using scope for tickets (`scope` is component; put tickets in body or footer).

## Stay Green (Self-Test Under Pressure)
- Deadline in 10 minutes, mixed fixes/features: can you stage two clean commits with `git add -p`, verify with `git diff --cached`, and write proper subjects? If not, restart at Core Pattern step 1.
