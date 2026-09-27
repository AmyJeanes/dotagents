# dotagents

A shared home for **Claude Code** and **Codex** so they can work on the same projects, pick up each other's unfinished work, and keep knowledge where both of them (and you) can see it.

## Why

Each agent keeps its own instructions, memory, and skills. Switch agents, or just start a new session, and context is lost or has to be copied by hand. This kit gives both agents:

- **One set of guidance.** `~/.agents/AGENTS.md` is canonical. `~/.claude/CLAUDE.md` and `~/.codex/AGENTS.md` become thin adapters that point at it.
- **One skills folder.** Skills live in `~/.agents/skills`. Codex reads it natively, and Claude sees each skill through a link.
- **Per-project handoff space** outside your repositories, so unfinished work, notes, and private context never end up in commits.
- **Cross-project tasks** for work that spans several repositories. Each task has one canonical directory that every participating project can discover.
- **A memory migration** that moves what each agent has privately remembered into the shared places.

## How it works

```
~/.agents/
├── AGENTS.md                      shared guidance (managed blocks + your own additions)
├── scripts/Resolve-AgentProject.ps1
├── skills/
│   ├── handoff/                   write a handoff another session can continue
│   ├── migrate-memories/          move built-in memories into shared homes
│   └── tidy-agent-home/           retire stale handoffs, tasks and notes
├── tasks/                         cross-project handoffs (task.json + TASK.md)
└── projects/<project-id>/         created on demand per project
    ├── project.json
    ├── scratch/INDEX.md           active handoffs for this project
    └── private/INDEX.md           non-committable notes (hosts, local quirks)
```

Agents never guess where a project's state lives. They ask the resolver:

```
pwsh -NoProfile -File ~/.agents/scripts/Resolve-AgentProject.ps1 -Path . -Json
```

It maps a path, or its git worktree root, to a stable project ID, then returns `scratchPath`, `privatePath`, and any `relatedTasks` that list the project as a participant. It needs [PowerShell 7+](https://learn.microsoft.com/powershell/scripting/install/installing-powershell) and runs on Windows, macOS, and Linux.

The lifecycle is simple. Active work lives in scratch or a task. When the work finishes, durable knowledge is promoted into the repository (code, docs, `AGENTS.md`, commit messages) and the scratch entry is deleted. Nothing in the shared space is meant to be permanent memory.

## Setup

Paste this into Claude Code or Codex:

```text
Set up the shared agent home from https://github.com/AmyJeanes/dotagents.
Clone it to a temporary directory, read SETUP.md, and follow it exactly.
Inspect my current setup and ask me the questions it lists before changing
anything, show me the full plan, and only install after I approve it.
Do not modify any of my repositories.
```

The agent will check prerequisites, look at your existing configuration, and ask you:

- which agents to configure;
- which optional guidance modules to enable;
- whether to migrate existing memories now;
- how to fold any hand-written instructions you already have into the new layout.

It always installs to `~/.agents`, because that's where Codex looks for user skills. It also disables Claude auto memory and Codex memories, so knowledge lives only in places both agents can see. Everything it changes is backed up to `~/.agents/.backups/` first.

Setting up both agents? Run the prompt in either one. It configures both.

### WSL

If you also run agents inside WSL, set up Windows first, then paste the same prompt into your WSL agent. It detects WSL and links to the Windows install instead of creating a second one:

- WSL adapters import the Windows `AGENTS.md` through `/mnt/c/...`, and translate `C:\...` paths.
- Shared skills are symlinked into WSL `~/.claude/skills` and `~/.agents/skills`, so both WSL agents find them.
- Checkouts on the Linux filesystem get their own project homes. Cross-project tasks can mix Windows and Linux participants.
- File links come back as Windows-clickable `\\wsl.localhost\...` paths.

### Optional guidance modules

| Module | What it adds |
| --- | --- |
| `recording-knowledge` | Where each kind of fact belongs: commit message, comment, `AGENTS.md`, or private notes |
| `code-comments` | Minimal comments that explain *why*, never history |
| `code-style` | Match surrounding code and use plain, familiar identifiers |
| `git-safety` | Fetch before reasoning, confirm before pushing shared branches, no upstream PRs without approval |
| `autonomy` | Behaviour during unattended hand-offs |
| `machine-power` | Never shut down or sleep machines without explicit authorization |

Modules are installed between `<!-- agent-kit:begin ... -->` markers. Anything you write outside the markers is yours, and updates never touch it. If you want a kit rule worded differently, put your version in the `## Overrides To The Kit Guidance` section below the managed blocks rather than editing inside them. Overrides take precedence and survive updates.

Existing skills in `~/.claude/skills` can be moved into the shared folder with links back. Skills managed by other installers, and claude.ai synced skills, are left alone.

## Updating

```text
Update my shared agent home from https://github.com/AmyJeanes/dotagents.
Clone it to a temporary directory and follow the "Update mode" section of SETUP.md.
Show me what changed and ask before replacing anything I've edited.
```

## Migrating memories later

Skipped migration during setup, or found memories that were missed? Ask either agent:

```text
Use the migrate-memories skill to move my Claude and Codex memories into the shared agent home.
```

It shows a plan (source → destination, including anything it will drop and any secrets it found) and waits for your approval. Secrets are never copied.

## Day to day

- Say "hand this off" or run the `handoff` skill before switching agents or ending a session mid-task.
- Run `tidy-agent-home` now and then, or on a schedule. It checks scratch entries, tasks and private notes against merged PRs, deleted branches and age, then proposes what to retire or promote.
- Start work in a repository and the agent checks that project's scratch index and related tasks.
- Put repository guidance in the repository's `AGENTS.md`. Give it a one-line `CLAUDE.md` containing `@AGENTS.md` so Claude reads the same file.

## Licence

MIT. The `handoff` skill is adapted from [mattpocock/skills](https://github.com/mattpocock/skills) (MIT).
