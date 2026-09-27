---
name: tidy-agent-home
description: Sweep the shared agent home for stale handoffs, finished cross-project tasks, outdated private notes, and skill lines that narrate history, then retire or promote them after user approval. Use periodically, or when scratch indexes and tasks look cluttered.
---

Handoffs and notes pile up whenever a session finishes work without retiring its records. This skill checks each record against its source of truth and proposes what to do with it. It writes nothing before the user approves.

## 1. Collect (read-only)

- Every `{{AGENT_HOME}}/projects/*/scratch/INDEX.md` row and scratch file, including files missing from the index and index rows whose file is gone.
- Every task in `{{AGENT_HOME}}/tasks/*/task.json` with its entrypoint.
- Every `{{AGENT_HOME}}/projects/*/private/INDEX.md` entry and file.
- Every skill under `{{AGENT_HOME}}/skills`.

Read each project's `project.json` for its `canonicalPath`. If nothing has changed since the last sweep (no file newer than `{{AGENT_HOME}}/.last-tidy`), report "nothing to do" and stop.

## 2. Check against sources of truth

For each scratch entry and task:

- Does the project path still exist? Do the branches it names still exist locally or on the remote?
- Are the pull requests or issues it references merged or closed (`gh pr view`, `gh issue view`, or the equivalent for the host)? Are referenced tickets done, where a tool to check them is available?
- Has the work landed in the default branch? Search the git log for its commits or subject.
- How old is the last update? Treat anything untouched for more than 30 days as a candidate, not an automatic retire.
- Does every task participant still resolve, and is its `status` still accurate?

For private notes: does the note duplicate something now committed to the repository? Does it refer to hosts, paths, or tools that no longer exist?

For skills: flag lines that narrate an episode ("we found that…", ticket-by-ticket history), corrections appended after older guidance instead of replacing it, and references to retired memory files.

## 3. Propose

Present one table per area with each item, the evidence, and a proposed action:

- **retire:** delete the file or directory and its index row;
- **promote, then retire:** move durable knowledge into the repository (proposed edit only, never committed), a skill, or `{{AGENT_HOME}}/AGENTS.md`;
- **update:** fix its status, index row, or wording;
- **keep:** still active.

Wait for the user to approve or edit the plan.

## 4. Apply and report

Back up everything you will delete or change to `{{AGENT_HOME}}/.backups/tidy-<UTC timestamp>/`, apply the approved actions, re-resolve any project or task participant you touched, and update `{{AGENT_HOME}}/.last-tidy` with the current UTC time. Report what changed and where the backup is.

## Running periodically

When run from a recurring schedule, do steps 1 and 2 only. If nothing needs action, finish with a one-line "nothing to do". Otherwise leave the proposal for the user rather than applying it unattended.
