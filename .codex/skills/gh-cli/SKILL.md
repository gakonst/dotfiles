---
name: gh-cli
description: Use when interacting with GitHub—prefer `gh` for cloning, PRs, issues, reviews, and quick data pulls; if scripting/data work needs raw JSON, use `gh api` with the auth token from `gh auth status`/`gh auth token` instead of unauthenticated curl.
---

# GitHub via gh CLI

## Overview
Default to the GitHub CLI for all repo interactions: clone, fork, check out PRs, open/close issues, comment, review, and fetch metadata. For data/ETL scripts, use `gh api` authenticated with your existing session rather than ad-hoc curl tokens.

## When to Use
- Cloning or checking out repos/PRs (`gh repo clone`, `gh pr checkout`).
- Opening PRs, drafting release notes, managing issues/discussions.
- Gathering repo/org data for analytics (contributors, labels, workflow runs).
- Need authenticated API calls in scripts/notebooks without storing tokens in files.

## Core Pattern
1) **Auth once**  
   `gh auth status` → if missing, `gh auth login` (device or SSH).  
   Get token on demand: `gh auth token`.

2) **Clone / checkout**  
   - Default clone root: `~/github/<owner>/<repo>`. Ensure parent exists: `dir=~/github/<owner>/<repo>; mkdir -p "$(dirname "$dir")"; gh repo clone <owner>/<repo> "$dir"` (add `-- --depth 1` if shallow).  
   - `gh pr checkout 123` to fetch a PR branch.

3) **PR flow**  
   - Create: `gh pr create --fill` or `--title --body`.  
   - View: `gh pr view --web` or `--json headRefName,baseRefName,mergeableState`.  
   - Comment/review: `gh pr review --approve|--request-changes -b "..."`.

4) **Issues / discussions**  
   - `gh issue list --label bug`  
   - `gh issue create --title ... --body ...`  
   - `gh discussion create ...`

5) **Data projects (use API via gh)**  
   - `gh api repos/{owner}/{repo}/contributors`  
   - Paginate: `gh api -H "Accept: application/vnd.github+json" --paginate ...`  
   - Filter: pipe to `jq` instead of storing tokens in env files.  
   - If scripting, wrap: `token=$(gh auth token)` and export `GITHUB_TOKEN` for tools that read it.

6) **Workflows and deployments**  
   - List runs: `gh run list --limit 20`  
   - Rerun: `gh run rerun <id> --failed`  
   - Deploy previews (Vercel/GHA): prefer existing workflows; trigger via `gh workflow run`.

## Quick Reference
| Task | Command |
| --- | --- |
| Check auth | `gh auth status` |
| Clone repo (standard path) | `dir=~/github/owner/repo; mkdir -p "$(dirname "$dir")"; gh repo clone owner/repo "$dir"` |
| Checkout PR | `gh pr checkout <num>` |
| Create PR | `gh pr create --fill` |
| Review PR | `gh pr review --approve -b "Looks good"` |
| List issues | `gh issue list --state open` |
| API GET | `gh api repos/{owner}/{repo}` |
| Paginate | `gh api --paginate /repos/{owner}/{repo}/pulls` |
| Export token | `gh auth token` |

## Common Mistakes
- Using `git clone` without auth → prompts/denials; use `gh repo clone` to reuse stored credentials.
- Storing PATs in scripts/notebooks → prefer `gh auth token` at runtime.
- Unauthenticated `curl` to api.github.com hitting rate limits; use `gh api`.
- Forgetting `--paginate` and missing results.
- Mixing SSH/HTTPS remotes manually; `gh` respects your chosen protocol.
- Cloning into the current directory or `~/github/<repo>` and skipping the org folder, breaking the standard layout.

## Red Flags
- Copy-pasted PATs in shell history or notebooks.
- `curl https://api.github.com/...` in data scripts without auth header.
- Manual PR URL creation instead of `gh pr create`.
- Cloning private repos with `git clone` and failing auth.
- Running `gh repo clone owner/repo` in the current directory because “it’s faster” instead of targeting `~/github/<owner>/<repo>`.

## Verification
- Run `gh auth status` (should show logged-in host).  
- `gh repo clone tempoxyz/tempo` succeeds without further prompts.  
- `gh api user` returns your account JSON.  
- `gh pr list` works in a repo without extra auth steps.
