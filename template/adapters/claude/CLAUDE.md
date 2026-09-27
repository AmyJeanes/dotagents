@../.agents/AGENTS.md

# Claude Code Adapter

The imported file is the canonical guidance shared with Codex. Put shared changes there, not here. Keep this adapter limited to Claude Code behaviour.

- In repositories, treat `AGENTS.md` as canonical and `CLAUDE.md` as its thin adapter. When changing shared repository guidance, update `AGENTS.md` and preserve or update the `CLAUDE.md` import plus any genuinely Claude-specific notes.
- Claude auto memory is disabled. Do not create or depend on agent-private memory; route knowledge through the shared locations in the shared guidance.
- Claude settings such as model, permissions, hooks, and status line belong in `~/.claude/settings.json`, not shared guidance.
