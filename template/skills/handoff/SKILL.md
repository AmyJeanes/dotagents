---
name: handoff
description: Compact active project work into shared local or cross-project coordination space so Claude Code or Codex can continue it in another session.
---

First identify every project whose working tree or decisions are part of the active task. Resolve each project with:

```
pwsh -NoProfile -File {{AGENT_HOME}}/scripts/Resolve-AgentProject.ps1 -Path <project-path> -Ensure -Json
```

Never derive project IDs or shared paths by hand.

For a task confined to one project, use the returned `scratchPath`. Choose a stable lowercase hyphenated task slug and write `scratch/<task-slug>.md`. Update an existing file only when it represents the same task; do not overwrite another active handoff.

Maintain one row for the task in `scratch/INDEX.md` with its slug, agent or session owner, branch or worktree, status, and UTC update time. Keep the index limited to active work.

For a task spanning multiple projects, create or update one `{{AGENT_HOME}}/tasks/<task-slug>` directory instead. Follow `{{AGENT_HOME}}/tasks/README.md`: write a valid `task.json`, use `TASK.md` as its entrypoint, and list every participant by the `canonicalPath` from its resolver result. Keep detailed project-specific material in subdirectories within that task. Do not copy the same handoff into participant scratch directories.

After creating or changing a cross-project task, resolve every participant again and confirm the task appears in each result's `relatedTasks` with the intended role.

The task file must capture:

- objective and success criteria;
- current status;
- important decisions and rejected approaches;
- changed files and uncommitted work;
- commands and tests already run, including outcomes;
- blockers, external state, and live processes;
- exact next steps;
- suggested skills for the receiving agent.

If arguments were supplied, use them as the receiving session's intended focus.

Do not duplicate content already captured in other artifacts (plans, ADRs, issues, commits, diffs). Reference them by path or URL instead.

Do not store credentials, tokens, private raw data, or large logs. Summarize or redact sensitive information and point to its approved private source only when needed.

When the task is complete, promote durable knowledge to committed code, documentation, `AGENTS.md`, an ADR, or the commit message as appropriate. Then remove its index row and task file, or remove the cross-project task directory. Shared coordination state is not permanent memory.
