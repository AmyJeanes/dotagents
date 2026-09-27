---
name: migrate-memories
description: Move existing Claude Code and Codex built-in memories into the shared agent home (shared guidance, project private notes, scratch handoffs, skills, or repository docs) so both agents see the same knowledge. Use during setup or whenever agent-private memory has accumulated.
---

Agent-private memory is invisible to the other agent. This skill sorts each remembered fact into the shared home it belongs in, with the user approving the plan before anything is written.

## 1. Inventory (read-only)

Find every memory source that exists on this machine:

- **Claude Code:** `~/.claude/projects/<encoded-path>/memory/`, holding a `MEMORY.md` index plus topic files. The directory name encodes the project path lossily (every non-alphanumeric character becomes `-`), so recover the real path from the `"cwd"` field of any `*.jsonl` session transcript in the same `<encoded-path>` directory. If `~/.claude/settings.json` sets a custom memory directory, use that too.
- **Codex files:** `$CODEX_HOME/memories/` (default `~/.codex/memories/`). Memory files are usually global rather than per-project, so infer each entry's project from its content. Treat `rollout_summaries/` as session history: skim it for durable facts only and never migrate it wholesale. Anything under `memories/skills/` is a candidate shared skill.
- **Codex database:** Codex also keeps memories in SQLite (`$CODEX_HOME/memories_*.sqlite`). An empty `memories/` folder does not mean there are no memories. List the tables, count the rows in each, and read the text columns of any non-empty memory tables, for example with Python's `sqlite3` module. Open the database read-only and never write to it.
- **User-level instruction files:** content in `~/.claude/CLAUDE.md` or `~/.codex/AGENTS.md` outside the installer's managed blocks.

Report counts per source and skip empty or routing-only files.

## 2. Classify

Split each source into individual facts and give each exactly one destination:

| Kind of fact | Destination |
| --- | --- |
| A preference or rule for every project | `{{AGENT_HOME}}/AGENTS.md`, below the managed blocks |
| Durable, non-secret repository knowledge | That repository's `AGENTS.md` or docs, **proposed only**: list the edit and never commit it |
| Private operational context for one project (hosts, device access, local quirks) | That project's `privatePath/<topic>.md`, indexed in `privatePath/INDEX.md` |
| Active work in one project | That project's `scratchPath/<task-slug>.md` plus its `INDEX.md` row |
| Active work spanning several repositories, including a ticket worked from a workspace folder of repositories | One task in `{{AGENT_HOME}}/tasks`, with each touched repository as a participant, plus the workspace folder if sessions start there |
| A reusable procedure or reference | A skill in `{{AGENT_HOME}}/skills` |
| Agent-specific behaviour | The matching adapter file, outside its managed block |
| Stale, completed, duplicated, or already committed | Drop |
| Credentials, tokens, keys | **Never copy.** Record only where the secret lives, and flag it to the user |

Get each project's paths from `pwsh -NoProfile -File {{AGENT_HOME}}/scripts/Resolve-AgentProject.ps1 -Path <project-path> -Json`. If a remembered project path no longer exists, ask whether to drop its facts or file them under a project that does exist.

For a large memory store, you may fan out per-source classification to subagents. Give them a cheaper, faster model, and keep the merged plan, and any source touching credentials or security tooling, on your own model.

## 3. Find references to the sources

Before planning any retirement, search for anything that points into the memory sources: paths under `~/.claude/projects/*/memory/`, `MEMORY.md`, memory-file names, and wiki-style links such as `[[topic-name]]`. Search `{{AGENT_HOME}}/AGENTS.md`, the adapters, every skill under `{{AGENT_HOME}}/skills` and `~/.claude/skills`, and the `AGENTS.md`, `CLAUDE.md`, and docs of affected repositories. Each hit must be rewritten to point at the fact's new home, or removed if that fact is being dropped.

## 4. Confirm

Present the plan as a table (source → fact summary → destination), grouped by destination. List explicitly every drop, every flagged secret, and every reference rewrite. Wait for the user to approve or edit it. Nothing is written before approval.

## 5. Apply

1. Back up every source first: copy the memory directories, Codex memory databases, and instruction files to `{{AGENT_HOME}}/.backups/memories-<UTC timestamp>/`, preserving relative paths.
2. Resolve with `-Ensure` for each destination project, then write the files. Merge into existing files rather than overwriting them, rewriting facts as concise, present-tense statements without session narration.
3. Keep every `INDEX.md` a one-line-per-file list: `- [topic](topic.md): one-line summary`.
4. Apply the reference rewrites from step 3. Repository files follow the same rule as repository knowledge: propose the edit, or leave it uncommitted if the user asked for it to be applied.
5. Retire the migrated file sources so stale copies cannot resurface: replace each Claude `MEMORY.md` with a short routing note pointing to the resolver, remove its topic files, and clear the migrated Codex memory files. Leave Codex databases in place, since built-in memory is disabled and they are backed up.

## 6. Verify

Re-run the resolver for each touched project and confirm the new files are under its `privatePath` or `scratchPath`. Search again for references to retired memory files and confirm none remain. Report what went where, what was dropped, the reference rewrites, the proposed repository edits, and the backup location.
