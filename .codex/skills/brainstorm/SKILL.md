---
name: brainstorm
description: Use when generating options or clarifying a build/fix request—pull constraints from the user, list varied approaches, then narrow with them to pick a plan. For code reviews, use briefly to confirm expectations, then hand off to the agent flow.
---

# Brainstorm

## Overview
Generate many concise options first, then converge with the user. Favor breadth, then prune to what fits scope, time, and constraints.

## When to Use
- Any build/fix request that lacks explicit constraints (scope, stack, perf, deadlines).
- User asks for ideas, approaches, pros/cons, or “what are my options?”
- Early in a task to choose direction or unblock.
- When stuck or tunneling on one solution.
- **Before a code/PR review:** confirm expectations (depth, checks to run) then proceed with the agent default review flow.

## Core Pattern (Diverge → Converge)
1) Clarify must-haves/constraints in 1–3 bullets (time, stack, budget, risk).  
2) Diverge: list 5–10 varied options (mix quick wins, bold bets, hybrids). One line each.  
3) Cluster and trim: group similar items, drop weak/out-of-scope ones.  
4) Select 1–3 candidates with rationale (impact vs effort vs risk).  
5) Ask for a pick or permission to detail the top choice.  
6) If chosen, expand into a concrete next-step plan (3–6 steps, timeboxed).

## Tips
- Keep options short; avoid over-detailing during divergence.
- Include at least one low-risk/fast path and one higher-upside path.
- Call out key trade-offs (time, complexity, reliability).
- If info is missing, state assumptions and invite corrections.
- Avoid anchoring: shuffle or avoid numbering during divergence; number only when converging.

## Quick Reference
- Start: “What constraints or must-haves should I respect? (time/budget/stack/risk)”
- Diverge: bullet 5–10 options, 1 line each.
- Converge: pick 1–3 best with why; ask which to pursue.
- Expand: provide next steps for the chosen option.

## Red Flags
- Only one idea offered (no divergence).
- Options are near-identical or all high-risk.
- Deep detail before the user chooses a direction.
- Ignoring stated constraints or assumptions. 
