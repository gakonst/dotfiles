---
name: agent
description: Use to run Codex as a control panel that drives multiple tmux-backed sub-agents with automated monitoring; includes watcher loop, per-task git worktrees, and the same tmux helper conventions.
---

# Agent Control Panel (tmux + monitor)

## Overview
Use your current Codex window as the operator console. From here, create a dedicated tmux socket/session that hosts sub-agent panes. You stay outside tmux as the driver—only the sub-agents run inside tmux windows—and you poll their output to know when to step in.

## When to Use
- You need parallel sub-agents (e.g., multiple tasks/PRs) managed from one Codex session.
- Long-running interactive tools (debuggers, REPLs) where you want passive monitoring.
- Any scenario where Codex should only step in when a pane is stuck or asks a question.

## Core Pattern
1) **Socket + session (private, driven from THIS Codex window):**
   ```bash
   SOCKET_DIR=${TMPDIR:-/tmp}/agent-tmux-sockets; mkdir -p "$SOCKET_DIR"
   SOCKET="$SOCKET_DIR/agent.sock"; SESSION=control
   tmux -S "$SOCKET" new -d -s "$SESSION" -n hub
   ```
2) **Create a per-task git worktree (keeps tasks isolated):**
   ```bash
   task=feat-xyz
   git worktree add .worktrees/$task -b $task   # or checkout existing: git worktree add .worktrees/$task origin/$task
   ```
3) **Launch a sub-agent window (one task each; you remain outside):**
   ```bash
   tmux -S "$SOCKET" new-window -t "$SESSION" -n task-a
   tmux -S "$SOCKET" send-keys -t "$SESSION:task-a" -- 'cd .worktrees/task-a' Enter
   tmux -S "$SOCKET" send-keys -t "$SESSION:task-a" -- 'codex --dangerously-bypass-approvals-and-sandbox' Enter
   tmux -S "$SOCKET" send-keys -t "$SESSION:task-a" -- 'Worktree is .worktrees/task-a. Do not ask. Create update_plan with TDD steps, then <task>; run cargo fmt && cargo clippy && cargo test.' Enter
   ```
4) **Monitor loop (flag panes needing input; run from this control panel):**
   ```bash
   monitor_once() {
     for tgt in $(tmux -S "$SOCKET" list-panes -a -F '#{session_name}:#{window_name}.#{pane_index}'); do
       OUT=$(tmux -S "$SOCKET" capture-pane -p -J -t "$tgt" -S -120)
       NEED=$(printf "%s\n\nIs this pane waiting for operator input? Reply YES or NO only." "$OUT" \
         | codex exec --system "You are a detector. Reply YES if the pane asks a question/choice or is stalled; NO otherwise.")
       [ "$NEED" = "YES" ] && echo "$tgt"
     done
   }
   while true; do
     NEEDS=$(monitor_once); [ -n "$NEEDS" ] && { echo "Input needed: $NEEDS"; break; }
     sleep 10
   done
   ```
5) **Intervene minimally (from this Codex pane):** map the flagged pane to its tmux target (e.g., `control:task-a.0`) and send exactly one concise answer with `tmux -S "$SOCKET" send-keys -t <target> -- '...response...' Enter`; then restart the monitor loop.
6) **Tell the user how to attach/monitor** right after creating sessions and again when wrapping up:
   ```
   tmux -S "$SOCKET" attach -t control
   tmux -S "$SOCKET" capture-pane -p -J -t control:hub.0 -S -200
   ```
7) **Cleanup:** `tmux -S "$SOCKET" kill-session -t "$SESSION"` or `tmux -S "$SOCKET" kill-server`. Remove worktrees when done: `git worktree remove .worktrees/task-a`.

## Socket Convention
- Use private sockets under `${TMPDIR:-/tmp}/agent-tmux-sockets`; default `SOCKET="$SOCKET_DIR/agent.sock"`.
- Always pass `-S "$SOCKET"` to tmux. Create the socket dir first (`mkdir -p`).
- Keep session/window names short and slug-like (`task-a`, `debug`, `ci`).

## Targeting & User Monitor Commands
- Pane target format `{session}:{window}.{pane}`, default `:0.0` if omitted.
- Keep a mapping of task → window name; set `TARGET="<session>:<window>.0"` before sends to avoid misrouting. Always include `-t "$TARGET"` on every `send-keys` and `capture-pane`.
- Immediately after starting any session/window, print both commands for the user:
  - Attach: `tmux -S "$SOCKET" attach -t control`
  - One-time capture: `tmux -S "$SOCKET" capture-pane -p -J -t control:hub.0 -S -200`

## Sending Input Safely
- Prefer literal sends to avoid shell splitting: `tmux -S "$SOCKET" send-keys -t target -l -- "$cmd"` then `Enter`.
- For inline commands use single quotes or ANSI C strings: `tmux ... send-keys -- $'python3 -m http.server 8000' Enter`.
- Control keys: `C-c`, `C-d`, `C-z`, `Escape`, etc.

## Watching Output
- Capture recent output: `tmux -S "$SOCKET" capture-pane -p -J -t target -S -200`.
- For continuous monitoring, rely on the monitor loop; avoid `tmux wait-for` (doesn’t watch pane text).

## Synchronizing / Waiting for Prompts
- Poll for prompts before sending commands, e.g.:
  ```bash
  ./tools/wait-for-text.sh -t "$SESSION":0.0 -p '^>>>' -T 15 -l 4000
  ```
- For long-running tasks, poll for completion strings (“Program exited”, etc.) before proceeding.

## Spawning Processes (defaults)
- Debugging: prefer `lldb` unless user requests otherwise.
- Python REPL: set `PYTHON_BASIC_REPL=1`; start with `python3 -q`; wait for `^>>>`; send code with `-l`; interrupt via `C-c`.

## Interactive Recipes
- **Python REPL:** `tmux ... send-keys -- 'PYTHON_BASIC_REPL=1 python3 -q' Enter`; wait for prompt; send code; `C-c` to interrupt.
- **gdb:** `tmux ... send-keys -- 'gdb --quiet ./a.out' Enter`; `set pagination off`; `C-c` to break; `bt`, `info locals`; exit `quit` then `y`.
- **Other TTY apps** (ipdb, psql, mysql, node, bash): start app, wait for prompt via `wait-for-text`, then send literal text + Enter.

## Cleanup
- Kill session: `tmux -S "$SOCKET" kill-session -t "$SESSION"`.
- Kill all sessions on socket: `tmux -S "$SOCKET" list-sessions -F '#{session_name}' | xargs -r -n1 tmux -S "$SOCKET" kill-session -t`.
- Remove socket server: `tmux -S "$SOCKET" kill-server`.
- Remove worktree when done: `git worktree remove .worktrees/<task>`.

## Tips
- Keep socket under `${TMPDIR:-/tmp}/agent-tmux-sockets`; names short (`task-a`, `task-b`).
- Use git worktrees under `.worktrees/<task>` so sub-agents never clash; point each Codex session at its worktree immediately.
- Use literal `send-keys -l`, `capture-pane -J`, `wait-for-text.sh`, and set `PYTHON_BASIC_REPL=1` before Python REPLs. Always print attach/capture commands for the user.
- Poll with `capture-pane -J` to avoid wrap artifacts; limit history to ~200 lines for speed.

## Quick Reference
- Start hub: `tmux -S "$SOCKET" new -d -s control -n hub`
- Launch agent window: `tmux ... new-window -n foo; tmux ... send-keys -- 'codex ...' Enter`
- Monitor: loop over panes → `codex exec` classifier YES/NO → intervene → resume
- User attach: `tmux -S "$SOCKET" attach -t control`
- Cleanup: `tmux -S "$SOCKET" kill-server`
- Helpers available: `tools/find-sessions.sh`, `tools/wait-for-text.sh` (copied locally). `find-sessions.sh` supports `-S SOCKET`, `-q filter`, or `--all` to scan socket dir; `wait-for-text.sh` supports `-t target -p regex [-F] [-T timeout] [-i interval] [-l lines]`.

## Red Flags
- Using the default user socket instead of private `${TMPDIR}/agent-tmux-sockets`.
- Not printing attach/capture commands for the user.
- Letting multiple tasks share one pane (one task per window).
- Spamming multiple inputs before re-running the monitor loop.
- Sending input without an explicit `-t <target>` (risk of driving the wrong sub-agent).
