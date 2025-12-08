---
name: javascript
description: Use when developing or debugging Vite+React+TanStack Query frontends with Cloudflare Workers + Bun + shadcn + Tailwind and you need an agent-ready dev environment with a frontend-to-backend console log bridge, tmux panes for logs/servers, mobile-responsive dense UI defaults, and no-animation square styling.
---

# JavaScript (Vite/React/TanStack/Workers/Bun)

## Overview
One-stop playbook for agent-friendly local development on the preferred stack: Vite + React + TanStack Query + Tailwind/shadcn UI on Bun, with a Cloudflare Worker backend. Core pieces: (1) development-only console bridge piping frontend logs to the backend log stream, (2) tmux layout that auto-runs servers and tails logs, (3) opinionated UI defaults (no animations, square corners, dense layout, mobile-responsive), and (4) verification steps so agents and humans see the same signals fast.

**Doc-first, no guessing:** Consult official sources before answering or coding—Vite, React, TanStack Query, Tailwind/shadcn, Bun, Cloudflare Workers. If a flag/API isn’t explicitly documented or version is unclear, stop and ask for the correct docs link instead of inferring.

## When to Use
- Building or debugging this stack in dev mode and need frontend logs without opening a browser console.
- Spinning up a fresh env for an agent to drive (server + wrangler + log tails) in one tmux session.
- UI should be information-dense, square, no animations, mobile-friendly by default.
- You want predictable commands for Bun, Vite, Wrangler, and log tails ready in panes.

**Do NOT use** the bridge in production or when logs may contain PII/secrets unless scrubbed.

## Core Pattern

### 1) Justfile as the entrypoint (required)
- Add a root `Justfile` so `just` works after clone. Suggested recipes:
  - `default` → `just test` (run something meaningful, never a no-op)
  - `just install` → `pnpm install --frozen-lockfile`
  - `just lint` → `pnpm lint`
  - `just test` → `pnpm test -- --runInBand` (or `pnpm test:e2e`)
  - `just fmt` → `pnpm format:check`
  - `just check` → chain fmt + lint + test
  - `just dev` → `pnpm dev`
  - `just build` → `pnpm build`
  - `just preview` → `pnpm preview` or Vercel preview trigger
- Mirror CI to these targets; keep env vars consistent (`VITE_*`, `NEXT_PUBLIC_*`).

### 2) Frontend console bridge (dev-only, wevm TS style)
```ts
// src/dev/console-bridge.ts
type Level = 'log' | 'info' | 'warn' | 'error'
const ENDPOINT = '/__dev/fe-logs'
const original: Record<Level, (...args: unknown[]) => void> = {
  log: console.log,
  info: console.info,
  warn: console.warn,
  error: console.error,
}
let sending = false

function send(level: Level, args: unknown[]) {
  if (sending || typeof fetch === 'undefined' || !navigator.onLine) return
  sending = true
  const body = JSON.stringify({
    level,
    ts: Date.now(),
    msg: args.map(String).join(' '),
  })
  fetch(ENDPOINT, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body,
    keepalive: true,
  })
    .catch(() => {})
    .finally(() => {
      sending = false
    })
}

;(['log', 'info', 'warn', 'error'] satisfies Level[]).forEach((level) => {
  console[level] = (...args) => {
    original[level](...args)
    if (import.meta.env.DEV) send(level, args)
  }
})
```
- Guard with `import.meta.env.DEV`; bail if offline; prevent recursion via `sending`.
- Avoid sending its own network failures; drop silently instead of looping.

### 3) Backend receiver (Cloudflare Worker)
```ts
// src/worker.ts excerpt
export default {
  async fetch(req: Request, env, ctx): Promise<Response> {
    const url = new URL(req.url)
    if (url.pathname === '/__dev/fe-logs' && req.method === 'POST') {
      const { level, ts, msg } = await req.json().catch(() => ({}))
      const prefix = `[FE ${new Date(ts ?? Date.now()).toISOString()}]`
      if (level === 'error') console.error(prefix, msg)
      else if (level === 'warn') console.warn(prefix, msg)
      else console.log(prefix, msg)
      return new Response('ok')
    }
    // ...rest of worker...
  },
}
```
- Worker logs show alongside backend logs; keep endpoint dev-only via route gating or build flag.

### 4) Dev bootstrap (tmux + servers + tails)
```bash
tmux new-session -d -s appdev
tmux rename-window -t appdev:0 'dev'
tmux send-keys   -t appdev:0 'cd /Users/georgios/tempo/rust-skill && bun install' C-m
tmux split-window -h -t appdev:0
tmux send-keys   -t appdev:0.0 'bun run dev --host 0.0.0.0 --port 5173' C-m
tmux split-window -v -t appdev:0.0
tmux send-keys   -t appdev:0.1 'bunx wrangler dev --local' C-m
tmux send-keys   -t appdev:0.2 'tail -f logs/backend.log' C-m
tmux select-pane -t appdev:0.1
tmux split-window -v
tmux send-keys   -t appdev:0.3 'tail -f logs/frontend.log' C-m
tmux select-window -t appdev:0
tmux attach -t appdev
```
- Adjust log paths; ensure `bun run dev` writes frontend logs to file (e.g., `vite --logFile logs/frontend.log`).
- Session delivers four panes: Vite, Wrangler, backend log tail, frontend log tail (with bridge output).

### 5) UI defaults (dense, square, no motion)
- Tailwind base in `src/index.css`:
  ```css
  * { border-radius: 0 !important; }
  * { animation: none !important; transition: none !important; }
  :root { color-scheme: light; }
  ```
- shadcn config: set `radius: 0`, prefer `md`/`sm` sizes, keep spacing tight (`gap-2`, `px-3`).
- Layout: use CSS grid/flex with min 320px columns; keep mobile first; avoid hidden menus; prefer visible panels.

### 6) TypeScript style (wevm-inspired, deep dive)
- Imports
  - Split type/value imports; always use `.js` extension for local modules.
  - Group standard, third-party, local; keep deterministic order.
  - Example:
    ```ts
    import type { Chain } from './types/chain.js'
    import { defineChain } from './utils/chain/defineChain.js'
    ```
- Functions
  - Data-first: `(client, params)` not class methods. Keep generics narrow and ordered by dependence (`transport`, `chain`, `account`).
  - Destructure inputs up front; compute helper consts; return explicit typed objects.
  - Prefer `satisfies` for shape checks; only `as` when unavoidable.
  - Example:
    ```ts
    export function makeRequest<const chain extends Chain>(
      client: Client<Transport, chain>,
      params: RequestParams<chain>,
    ): Request {
      const { blockNumber, blockTag, ...rest } = params
      const block = blockNumber ? numberToHex(blockNumber) : blockTag
      return {
        ...rest,
        block,
      } satisfies Request
    }
    ```
- Types
  - Reuse utility types (`Assign`, `Prettify`, `Filter`, `NoInfer`, `Branded`) to keep return types readable.
  - Use `const T extends` in generics to preserve literal inference.
  - Export types next to values; prefer `type` exports over interfaces for shapes.
- Errors
  - Throw typed errors (extending BaseError) with contextual meta; wrap unknowns.
  - Pattern:
    ```ts
    try {
      return await client.request(args)
    } catch (err) {
      throw getCallError(err as BaseError, { ...args, chain: client.chain })
    }
    ```
- Docs
  - TSDoc on exports: short description, `@param`, `@returns`, and one `@example` using actual API imports.
  - Keep examples minimal but runnable.
- Tests
  - Co-locate `*.test.ts` near code; use `vitest` with `describe/test/expect/vi`.
  - Spy on functions instead of mocking modules; assert exact calls and shapes.
- Formatting/lint
  - No semicolons; single quotes; trailing commas on multiline.
  - Prefer immutability; avoid mutation unless necessary.
  - Run `pnpm biome check` / `pnpm biome format` (biome.json is present).

### 7) React + TanStack Query style (wagmi-inspired)
- Top-level `'use client'` for React hook modules when used in Next/SSR.
- Options-first hooks: accept an options bag with optional `query`/`mutation` config; default to `{}`.
- Pull shared config via `useConfig(parameters)`; derive connection state via dedicated hooks (`useConnection`, `useChainId`).
- Build query options from core helpers (e.g., `getWalletClientQueryOptions`) to reuse query keys and hashes; destructure `queryKey` from options so it can be returned.
- Compute `enabled` booleans explicitly; honor `query.enabled ?? true`; gate on connection status.
- Manage query cache manually when identity changes (e.g., address change) with `useQueryClient`, `removeQueries`, `invalidateQueries`; track prior value with `useRef`.
- Accept lint waivers intentionally: `// biome-ignore lint/correctness/useExhaustiveDependencies: queryKey not required`.
- Mutations: compose `sendTransactionMutationOptions` (or similar) with user overrides, return `mutate`/`mutateAsync` plus deprecated aliases; derive a `type Return = ...` to cast once.
- useQuery/useInfiniteQuery wrappers: pass `queryKeyHashFn: hashFn` for bigint support; surface `queryKey` on the return value for consumers.
- Type utilities: use `Compute`, `ExactPartial`, `UnionStrictOmit`, `Omit` to clean public types; keep `config extends Config = ResolvedRegister['config']` defaults for hooks.
- Tests: include runtime tests and `*.test-d.ts` type tests for hook signatures; prefer focused assertions and spy-based interaction checks.

### 8) Verification (per run)
- `curl -X POST http://localhost:8787/__dev/fe-logs -d '{"level":"info","ts":0,"msg":"hello"}' -H 'Content-Type: application/json'` -> appears in backend log pane.
- Trigger a frontend `console.error('boom')` in dev -> see `[FE ...] boom` in backend log tail.
- Resize viewport to 360px width -> layout remains readable, no overflow, no hidden menus.

## Quick Reference
- Frontend bridge file: `src/dev/console-bridge.ts` (import once in `main.tsx` in dev).
- Backend endpoint: `/__dev/fe-logs` in worker, dev-only.
- Start env: `just dev` (wrapping `bun run dev`) and `just wrangler` if separate; tmux script above.
- Logs: tail files in tmux panes; ensure Vite logs to file (`--logLevel info --logFile logs/frontend.log`).
- Design defaults: radius 0, animations off, dense spacing, mobile-first grid.

## Common Mistakes
- Bridge left enabled in production -> always gate on `import.meta.env.DEV` or a build flag.
- Recursive logging when endpoint unreachable -> guard with `sending` and `navigator.onLine`, drop failures.
- Missing CORS/route allowlist in worker -> allow only POST from same origin in dev.
- Logging secrets (tokens, cookies) -> redact before `JSON.stringify`.
- tmux panes pointing at wrong working directory -> set absolute paths in script.
- Missing `Justfile` or `just install` diverges from CI (`pnpm install --frozen-lockfile`).

## Rationalization Table (from baseline pressure tests)
| Excuse | Counter |
|--------|---------|
| "Opening browser console is faster than adding a bridge" | Bridge is <30 lines and saves MCP/browser hops; include it first run. |
| "I'll wire logs later after the bug shows" | Without bridge you debug blind; add it before reproducing. |
| "Wrangler dev is noisy; I'll tail later" | Noise is data; keep a dedicated pane; filter later, not now. |
| "UI polish later; animations/rounded defaults are fine" | Defaults hide density regressions; set square/no-motion baseline up front. |
| "Justfile is optional" | It’s the single entry point for contributors; mirror CI there for one-command setup. |

## Red Flags - Stop and Fix
- Starting Vite without the bridge imported.
- Running dev servers without tmux panes for both logs.
- Keeping animations/rounded corners because "library default".
- Bridge POSTs 4xx/5xx and you keep sending.

## Staying Green (apply skill)
- Import bridge only in dev entrypoint.
- Start tmux layout before debugging.
- Verify bridge by forcing a `console.error` and seeing backend log line.
- Keep UI base CSS enforcing square, no-motion, dense spacing.
