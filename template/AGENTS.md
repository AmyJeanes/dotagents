# Shared Agent Guidance

Claude Code and Codex cooperate on the same projects on this machine. This file is the canonical user-level guidance shared by both agents.

## Where Guidance Lives

- Put guidance that applies to both agents here, not in an agent-specific adapter (`~/.claude/CLAUDE.md` or `~/.codex/AGENTS.md`). Adapters must stay concise and hold only genuinely agent-specific behaviour.
- In repositories, put shared guidance in `AGENTS.md`. Keep `CLAUDE.md` as a thin `@AGENTS.md` import plus genuinely Claude-specific notes; preserve or update that wrapper when changing repository guidance.
- Put shared user skills in `{{AGENT_HOME}}/skills` and repository skills in `<repo>/.agents/skills`. Expose them to Claude through matching links under the corresponding `.claude/skills` directory; never make duplicate copies.
- Keep plugin-bundled skills in their plugin repository and distribute them through each agent's plugin mechanism.
- When editing a skill mid-task, write general, reusable lessons: strip names specific to the current repository, branch, symbol, or path, and keep the diagnostic procedure rather than the instance.

## Shared Project State

- Resolve shared project state with `pwsh -NoProfile -File {{AGENT_HOME}}/scripts/Resolve-AgentProject.ps1 -Path <project-path> -Json`; never derive a project ID or shared path by hand. The result includes local `scratchPath` and `privatePath` locations plus any cross-project `relatedTasks`.
- At the start of non-trivial work, check the existing scratch `INDEX.md` and related task entrypoints, reading only what is relevant. Add `-Ensure` only when a project home must be created.
- Put active, non-secret handoffs confined to one project in the resolver's `scratchPath`, with its `INDEX.md` as the entrypoint.
- Put a handoff spanning multiple projects in one task directory under `{{AGENT_HOME}}/tasks`, following that registry's `README.md`. List every participating project in `task.json`; do not duplicate the handoff into each project's scratch space. The resolver surfaces these tasks to every participant through `relatedTasks`.
- Update local and cross-project handoffs before transferring work, planned compaction, or ending unfinished unattended work. The `handoff` skill does this.
- When a task finishes, promote durable knowledge to its proper committed home, then remove the completed scratch entry or task directory.
- When a deferred or planned item is later completed, by either agent, retire every record that still calls it pending: plan notes, status markers, and scratch or task entries. Finishing work the other agent planned includes clearing its stale "pending" or "do-not-touch" note.
- Treat scratch and the task registry as temporary coordination state, not permanent memory. Never store credentials, tokens, private raw data, or large logs there.
- Put durable project-specific private operational context that cannot be committed in the resolver's `privatePath`, with an `INDEX.md` as its entrypoint. Read it only when the task needs it. It is shared by both agents on this machine but is not source-controlled; never use it for facts that could safely live in the repository.
