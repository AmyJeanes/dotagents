---
name: migrate-memories
description: Move existing Claude Code and Codex built-in memories into the shared agent home (shared guidance, project private notes, scratch handoffs, or repository docs) so both agents see the same knowledge. Use during setup or whenever agent-private memory has accumulated.
---

Agent-private memory is invisible to the other agent. This skill sorts each remembered fact into the shared home it belongs in, with the user approving the plan before anything is written.

## 1. Inventory (read-only)

Find every memory source that exists on this machine:

- **Claude Code:** `~/.claude/projects/<encoded-path>/memory/`, holding a `MEMORY.md` index plus topic files. The directory name encodes the project path lossily (every non-alphanumeric character becomes `-`), so recover the real path from the `"cwd"` field of any `*.jsonl` session transcript in the same `<encoded-path>` directory. If `~/.claude/settings.json` sets a custom memory directory, use that too.
- **Codex:** `$CODEX_HOME/memories/` (default `~/.codex/memories/`). Memory files are usually global rather than per-project, so infer each entry's project from its content. Treat `rollout_summaries/` as session history: skim it for durable facts only and never migrate it wholesale. Anything under `memories/skills/` is a candidate shared skill.
- **User-level instruction files:** content in `~/.claude/CLAUDE.md` or `~/.codex/AGENTS.md` outside the installer's managed blocks.

Report counts per source and skip empty or routing-only files.

## 2. Classify

Split each source into individual facts and give each exactly one destination:

| Kind of fact | Destination |
| --- | --- |
| A preference or rule for every project | `{{AGENT_HOME}}/AGENTS.md`, outside managed blocks |
| Durable, non-secret repository knowledge | That repository's `AGENTS.md` or docs, **proposed only**: list the edit and never commit it |
| Private operational context for one project (hosts, device access, local quirks) | That project's `privatePath/<topic>.md`, indexed in `privatePath/INDEX.md` |
| Active, unfinished work | That project's `scratchPath/<task-slug>.md` plus its `INDEX.md` row, or a task in `{{AGENT_HOME}}/tasks` if it spans projects |
| A reusable procedure | A skill in `{{AGENT_HOME}}/skills` |
| Agent-specific behaviour | The matching adapter file |
| Stale, completed, duplicated, or already committed | Drop |
| Credentials, tokens, keys | **Never copy.** Record only where the secret lives, and flag it to the user |

Get each project's paths from `pwsh -NoProfile -File {{AGENT_HOME}}/scripts/Resolve-AgentProject.ps1 -Path <project-path> -Json`. If a remembered project path no longer exists, ask whether to drop its facts or file them under a project that does exist.

## 3. Confirm

Present the plan as a table (source → fact summary → destination) grouped by destination, with every drop and every flagged secret listed explicitly. Wait for the user to approve or edit it. Nothing is written before approval.

## 4. Apply

1. Back up every source first: copy the memory directories and instruction files to `{{AGENT_HOME}}/.backups/memories-<UTC timestamp>/`, preserving relative paths.
2. Resolve with `-Ensure` for each destination project, then write the files. Merge into existing files rather than overwriting them, rewriting facts as concise, present-tense statements without session narration.
3. Keep every `INDEX.md` a one-line-per-file list: `- [topic](topic.md): one-line summary`.
4. Leave repository edits as a proposed list, or as uncommitted changes if the user asked for them to be applied.
5. Retire the migrated sources so stale copies cannot resurface: replace each Claude `MEMORY.md` with a short routing note pointing to the resolver, remove its topic files, and clear the migrated Codex memory files. The originals remain in the backup.

## 5. Verify

Re-run the resolver for each touched project and confirm the new files are under its `privatePath` or `scratchPath`. Report what went where, what was dropped, the proposed repository edits, and the backup location.
