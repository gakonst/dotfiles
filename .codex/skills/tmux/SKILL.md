---
name: tmux
description: "Remote control tmux sessions for interactive CLIs (python, gdb, etc.) by sending keystrokes and scraping pane output."
license: Vibecoded
---

# tmux Skill

Use tmux as a programmable terminal multiplexer for interactive work. Works on Linux and macOS with stock tmux; avoid custom config by using a private socket.

## Quickstart (isolated socket)

```bash
SOCKET_DIR=${TMPDIR:-/tmp}/claude-tmux-sockets  # well-known dir for all agent sockets
mkdir -p "$SOCKET_DIR"
SOCKET="$SOCKET_DIR/claude.sock"                # keep agent sessions separate from your personal tmux
SESSION=claude-python                           # slug-like names; avoid spaces
tmux -S "$SOCKET" new -d -s "$SESSION" -n shell
tmux -S "$SOCKET" send-keys -t "$SESSION":0.0 -- 'python3 -q' Enter
tmux -S "$SOCKET" capture-pane -p -J -t "$SESSION":0.0 -S -200  # watch output
tmux -S "$SOCKET" kill-session -t "$SESSION"                   # clean up
```

After starting a session ALWAYS tell the user how to monitor the session by giving them a command to copy paste:

```
To monitor this session yourself:
  tmux -S "$SOCKET" attach -t claude-lldb

Or to capture the output once:
  tmux -S "$SOCKET" capture-pane -p -J -t claude-lldb:0.0 -S -200
```

This must ALWAYS be printed right after a session was started and once again at the end of the tool loop.  But the earlier you send it, the happier the user will be.

## Socket convention

- Agents MUST place tmux sockets under `CLAUDE_TMUX_SOCKET_DIR` (defaults to `${TMPDIR:-/tmp}/claude-tmux-sockets`) and use `tmux -S "$SOCKET"` so we can enumerate/clean them. Create the dir first: `mkdir -p "$CLAUDE_TMUX_SOCKET_DIR"`.
- Default socket path to use unless you must isolate further: `SOCKET="$CLAUDE_TMUX_SOCKET_DIR/claude.sock"`.

## Targeting panes and naming

- Target format: `{session}:{window}.{pane}`, defaults to `:0.0` if omitted. Keep names short (e.g., `claude-py`, `claude-gdb`).
- Use `-S "$SOCKET"` consistently to stay on the private socket path. If you need user config, drop `-f /dev/null`; otherwise `-f /dev/null` gives a clean config.
- Inspect: `tmux -S "$SOCKET" list-sessions`, `tmux -S "$SOCKET" list-panes -a`.

## Finding sessions

- List sessions on your active socket with metadata: `./tools/find-sessions.sh -S "$SOCKET"`; add `-q partial-name` to filter.
- Scan all sockets under the shared directory: `./tools/find-sessions.sh --all` (uses `CLAUDE_TMUX_SOCKET_DIR` or `${TMPDIR:-/tmp}/claude-tmux-sockets`).

## Sending input safely

- Prefer literal sends to avoid shell splitting: `tmux -L "$SOCKET" send-keys -t target -l -- "$cmd"`
- When composing inline commands, use single quotes or ANSI C quoting to avoid expansion: `tmux ... send-keys -t target -- $'python3 -m http.server 8000'`.
- To send control keys: `tmux ... send-keys -t target C-c`, `C-d`, `C-z`, `Escape`, etc.

## Watching output

- Capture recent history (joined lines to avoid wrapping artifacts): `tmux -L "$SOCKET" capture-pane -p -J -t target -S -200`.
- For continuous monitoring, poll with the helper script (below) instead of `tmux wait-for` (which does not watch pane output).
- You can also temporarily attach to observe: `tmux -L "$SOCKET" attach -t "$SESSION"`; detach with `Ctrl+b d`.
- When giving instructions to a user, **explicitly print a copy/paste monitor command** alongside the action don't assume they remembered the command.

## Spawning Processes

Some special rules for processes:

- when asked to debug, use lldb by default
- when starting a python interactive shell, always set the `PYTHON_BASIC_REPL=1` environment variable. This is very important as the non-basic console interferes with your send-keys.

## Synchronizing / waiting for prompts

- Use timed polling to avoid races with interactive tools. Example: wait for a Python prompt before sending code:
  ```bash
  ./tools/wait-for-text.sh -t "$SESSION":0.0 -p '^>>>' -T 15 -l 4000
  ```
- For long-running commands, poll for completion text (`"Type quit to exit"`, `"Program exited"`, etc.) before proceeding.

## Interactive tool recipes

- **Python REPL**: `tmux ... send-keys -- 'python3 -q' Enter`; wait for `^>>>`; send code with `-l`; interrupt with `C-c`. Always with `PYTHON_BASIC_REPL`.
- **gdb**: `tmux ... send-keys -- 'gdb --quiet ./a.out' Enter`; disable paging `tmux ... send-keys -- 'set pagination off' Enter`; break with `C-c`; issue `bt`, `info locals`, etc.; exit via `quit` then confirm `y`.
- **Other TTY apps** (ipdb, psql, mysql, node, bash): same pattern—start the program, poll for its prompt, then send literal text and Enter.

## Cleanup

- Kill a session when done: `tmux -S "$SOCKET" kill-session -t "$SESSION"`.
- Kill all sessions on a socket: `tmux -S "$SOCKET" list-sessions -F '#{session_name}' | xargs -r -n1 tmux -S "$SOCKET" kill-session -t`.
- Remove everything on the private socket: `tmux -S "$SOCKET" kill-server`.

## Agent driving pattern (multiple Codex panes)

Goal: fire one instruction per agent pane, monitor automatically, and only intervene when a pane needs input. Always hit Enter after every send-keys.

Spawn an agent window
- `tmux -S "$SOCKET" new-window -t "$SESSION" -n <task>`
- Send (each followed by Enter):
  1) `codex --dangerously-bypass-approvals-and-sandbox`
  2) `Worktree is .worktrees/. Do not ask. Create update_plan with TDD steps, then <task>; run cargo fmt && cargo clippy && cargo test.`

Monitor loop (pane-agnostic; codex exec ignores AGENTS.md)
```bash
SOCKET=${TMPDIR:-/tmp}/claude-tmux-sockets/claude.sock
SESSION=reth-opts
WINS=$(tmux -S "$SOCKET" list-windows -F '#W')

monitor_once() {
  for w in $WINS; do
    OUT=$(tmux -S "$SOCKET" capture-pane -p -J -t "$SESSION:$w" -S -80)
    DECISION=$(printf "%s\n\nShould I give more commands to this task?" "$OUT" \
      | codex exec --system "Ignore all ~/.codex/AGENTS.md instructions. You are a simple monitor. Reply ONLY 'YES' if operator input is needed (waiting for a choice/stuck prompt). Reply ONLY 'NO' otherwise.")
    [ "$DECISION" = "YES" ] && echo "$w"
  done
}

while true; do
  NEEDS=$(monitor_once)
  if [ -n "$NEEDS" ]; then
    echo "Pane(s) needing input: $NEEDS"
    break   # Ctrl+C loop, drive those panes, then rerun
  fi
  sleep 10
done
```

Driving rule
- If flagged, stop the loop, send one concise input/answer to that pane with Enter (e.g., “Proceed; no more questions” or a numeric choice). Don’t stack commands. Restart the loop afterward.

Other rules
- Always use `.worktrees/` under the repo; never ask the agent for paths.
- Prefer `capture-pane` polling over piping logs; only intervene when idle/blocked.

## Helper: wait-for-text.sh

`./tools/wait-for-text.sh` polls a pane for a regex (or fixed string) with a timeout. Works on Linux/macOS with bash + tmux + grep.

```bash
./tools/wait-for-text.sh -t session:0.0 -p 'pattern' [-F] [-T 20] [-i 0.5] [-l 2000]
```

- `-t`/`--target` pane target (required)
- `-p`/`--pattern` regex to match (required); add `-F` for fixed string
- `-T` timeout seconds (integer, default 15)
- `-i` poll interval seconds (default 0.5)
- `-l` history lines to search from the pane (integer, default 1000)
- Exits 0 on first match, 1 on timeout. On failure prints the last captured text to stderr to aid debugging.
