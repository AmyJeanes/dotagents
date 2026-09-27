# Codex Adapter

Before starting any task, read `{{AGENT_HOME}}/AGENTS.md` and treat it as the canonical user-level guidance shared with Claude Code. Put shared changes in that file, not here. Keep this adapter limited to Codex-specific behaviour.

- In repositories, treat `AGENTS.md` as canonical. A `CLAUDE.md` may be a thin import plus Claude-specific notes; when changing shared repository guidance, update `AGENTS.md` and preserve any existing `CLAUDE.md` wrapper rather than duplicating its prose.
- Codex memories are disabled. Do not create or depend on agent-private memory; route knowledge through the shared locations in the shared guidance.
- Codex-only user skills may live in `{{AGENT_HOME}}/skills` without a matching Claude link.
