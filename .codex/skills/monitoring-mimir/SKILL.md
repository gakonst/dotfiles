---
name: monitoring-mimir
description: Use when managing Grafana Mimir alerting rules—validate rule files on PRs and sync to Grafana Cloud from main using mimirtool, with path filters to limit runs to rule changes.
---

# Monitoring: Mimir Alert Rules

## Overview
Keep alerting rules healthy and in sync: lint rules with `mimirtool rules lint` on every change, and sync to Grafana Cloud only on main pushes. Use path filters so unrelated changes don’t trigger the workflow.

**Doc-first, no guessing:** Use official Grafana Mimir docs and the `mimirtool` README/releases for flags and expected behavior. If a flag/path isn’t documented, ask for the correct doc link instead of inferring.

## When to Use
- Editing alerting rules under `contrib/infra/monitoring/mimir/`.
- Adding CI to validate or sync rules to Grafana Cloud.
- Reviewing PRs that touch Mimir rule files.

## Core Pattern (GitHub Actions)
```yaml
on:
  push:
    paths: ['contrib/infra/monitoring/mimir/**/*.y{a,}ml']
    branches: [main]
  pull_request:
    paths: ['contrib/infra/monitoring/mimir/**/*.y{a,}ml']
  workflow_dispatch:

jobs:
  validate-rules:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: |
          curl -fLo mimirtool https://github.com/grafana/mimir/releases/latest/download/mimirtool-linux-amd64
          chmod +x mimirtool && sudo mv mimirtool /usr/local/bin/
      - run: mimirtool rules lint contrib/infra/monitoring/mimir/*.yml

  sync-to-grafana-cloud:
    needs: validate-rules
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: |
          curl -fLo mimirtool https://github.com/grafana/mimir/releases/latest/download/mimirtool-linux-amd64
          chmod +x mimirtool && sudo mv mimirtool /usr/local/bin/
      - env:
          MIMIR_ADDRESS: ${{ secrets.MIMIR_PROMETHEUS_URL }}
          MIMIR_TENANT_ID: ${{ secrets.MIMIR_PROMETHEUS_USER }}
          MIMIR_API_USER: ${{ secrets.MIMIR_PROMETHEUS_USER }}
          MIMIR_API_KEY: ${{ secrets.MIMIR_PROMETHEUS_KEY }}
        run: mimirtool rules load contrib/infra/monitoring/mimir/*.yml
```

## Justfile Starter
- Add root `Justfile` entries so contributors can lint/sync locally (sync should require explicit opts):
  - `just mimir-lint` → `mimirtool rules lint contrib/infra/monitoring/mimir/*.yml`
  - `just mimir-sync` → guard on env vars; run `mimirtool rules load ...` (use for ops, not CI)
- Keep CI steps identical to `just mimir-*` commands.

## Quick Reference
- Lint: `mimirtool rules lint <path>`.
- Sync: `mimirtool rules load <path>` with cloud creds.
- Paths filter: `contrib/infra/monitoring/mimir/**/*.y{a,}ml`.

## Common Mistakes
- Running sync on PRs → avoid; gate to main pushes only.
- Forgetting to lint before sync; upload may accept bad rules.
- Missing secrets: `MIMIR_*` values must be configured.
- Using broad triggers → CI runs on unrelated changes.
- No `Justfile` helpers → operators run ad-hoc commands and drift from CI.

## Red Flags
- Workflow lacks `paths` filters.
- Sync job not conditioned on `main && push`.
- Curl download without `-f` or checksum; failures go unnoticed.

## Verification
- PR touching rules triggers lint job only.
- Merge to main triggers lint + sync; fails if rules invalid.
- `mimirtool rules lint` passes locally.
