# Setup Procedure (for agents)

You are Claude Code or Codex installing this kit for the user. Follow these steps in order. Steps 1 and 2 are read-only. Do not write anything until the user has approved the plan in step 3. Never modify, commit to, or push the user's repositories.

`<kit>` means the directory you cloned this repository into. `<home>` means `~/.agents`. The location is fixed: Codex discovers user skills only in `~/.agents/skills`, and Claude's adapter imports `../.agents/AGENTS.md` relative to `~/.claude`.

## 1. Check prerequisites

- **PowerShell 7+** (`pwsh`): the resolver needs it on every OS. If it is missing, offer the platform install command (`winget install Microsoft.PowerShell`, `brew install powershell`, or Microsoft's Linux package instructions) and wait for the user.
- **Agents present:** Claude Code if `~/.claude` exists; Codex if `$CODEX_HOME` or `~/.codex` exists. Configure only the agents the user actually uses.
- **Environment:** if you are running inside WSL (`WSL_DISTRO_NAME` is set, or `/proc/version` mentions Microsoft), use **WSL companion mode** below instead of steps 3 to 5. On Windows, if `wsl.exe -l -q` lists distros, tell the user they can run the same prompt in their WSL agent afterwards to share this install with it.

## 2. Inspect existing state

Report, without changing anything:

- **Earlier install:** whether `<home>` exists, and whether `<home>/.install.json` shows an earlier install from this kit. If it does, use **Update mode** below.
- **Hand-written guidance:** existing `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`, and `<home>/AGENTS.md`, summarising their content. Flag any instruction that tells an agent to write to or rely on built-in memory (for example a "memory vs this file" section). The install disables built-in memory, so those instructions would contradict the new setup.
- **Skills:** classify every entry in `~/.claude/skills`, `<home>/skills`, and `$CODEX_HOME/skills`:
  - a link into `<home>/skills`: already shared, so leave it alone;
  - a link anywhere else: managed by another installer, so leave it alone;
  - a real directory with a `SKILL.md`: a user skill that could move into the shared home;
  - agent-managed folders such as `~/.claude/skills/synced/` (skills synced from claude.ai) and `$CODEX_HOME/skills/.system`: never touch.
  If `<home>/.skill-lock.json` exists, another skill installer manages the skills it lists; leave those in place. Note any name clash with the kit's skills (`handoff`, `migrate-memories`, `tidy-agent-home`).
- **Built-in memory:** the number of Claude `~/.claude/projects/*/memory/` directories with content, any files in Codex `memories/`, and the row counts in Codex `memories_*.sqlite` databases (an empty `memories/` folder does not mean there are no memories).
- **Memory settings:** `autoMemoryEnabled` in `~/.claude/settings.json`, and `[features] memories` in Codex `config.toml`. The install always disables both, because agent-private memory is invisible to the other agent.

## 3. Ask, then plan

Ask all of these in one batch, giving your recommendation for each:

1. **Which agents to configure.**
2. **Guidance modules.** The core (`template/AGENTS.md`) is always installed. Offer the modules as two groups, and let the user drop individual modules from a group:
   - **Writing:** `recording-knowledge` (where each kind of fact belongs), `code-comments` (minimal comments that explain *why*), and `code-style` (match surrounding code; plain identifiers). Recommended.
   - **Safety:** `git-safety` (check freshness before reasoning, confirm before pushing shared branches, no upstream actions outside the user's or their organisation's repositories without approval), `autonomy` (behaviour during unattended hand-offs), and `machine-power` (never shut down or sleep machines without authorization).
   If your question tool caps the number of options, ask about the two groups rather than each module separately.
3. **Existing user skills** (only if step 2 found some real directories). Recommend moving them into `<home>/skills` with links back, so both agents share them.
4. **Migrate existing memories now?** (only if step 2 found some). Recommend yes: the install disables built-in memory, so unmigrated memories stop being read (they stay in the backup). This runs the `migrate-memories` skill after the install.
5. **Existing hand-written guidance.** Propose how to split the content found in step 2: shared rules go in `<home>/AGENTS.md`, agent-specific parts stay in the adapter, and duplicates or memory instructions that would now contradict the setup are dropped or rewritten. Show the proposed split.

The user may want different wording for a kit rule. Never edit it inside the managed blocks. Record it in the overrides section instead (step 4.4).

Then present the full plan: every file created or changed, every skill moved or linked, every settings edit, and the backup location. Wait for explicit approval.

## 4. Install

1. **Back up** every existing file or skill directory you are about to change or move to `<home>/.backups/setup-<UTC timestamp>/`, preserving relative paths.
2. **Copy** from `<kit>/template` into `<home>`: `scripts/Resolve-AgentProject.ps1`, `tasks/README.md`, and `skills/*`. Create `<home>/projects/` and `<home>/tasks/`. Never overwrite an existing skill with the same name without the user's say-so.
3. **Substitute placeholders** in the files you copied or composed:
   - `{{AGENT_HOME}}`: the absolute path of `~/.agents` with forward slashes on every OS, e.g. `C:/Users/name/.agents` or `/home/name/.agents`. Windows tools accept forward slashes, and this keeps appended paths consistent.
   - `{{WINDOWS_AGENT_HOME}}` and `{{WSL_DISTRO}}`: only in WSL adapters; see **WSL companion mode**.
4. **Compose `<home>/AGENTS.md`**: first the managed blocks (the core, then each chosen module in the order listed in step 3), then the user's own content. Wrap each block in markers, using the module's file name as the block name:

   ```
   <!-- agent-kit:begin core -->
   ...template content...
   <!-- agent-kit:end core -->
   ```

   Nothing outside the markers is ever rewritten by this kit. Below the managed blocks, create a `## Overrides To The Kit Guidance` section if the user wants any kit rule worded differently. It states each replacement and which rule it supersedes, and it takes precedence over the managed blocks. Put the user's other shared rules after it.
5. **Adapters:** keep any user content outside the managed `adapter` block.
   - Claude: `~/.claude/CLAUDE.md` from `template/adapters/claude/CLAUDE.md`. Its `@` import line goes on the file's first line, **above** the `<!-- agent-kit:begin adapter -->` marker and outside the block; the rest of the template goes inside the block.
   - Codex: `$CODEX_HOME/AGENTS.md` (default `~/.codex/AGENTS.md`) from `template/adapters/codex/AGENTS.md`, entirely inside the block.
6. **Skills:**
   - If the user approved it, move each existing user skill directory into `<home>/skills/<name>` and replace the original with a link to it.
   - For each skill in `<home>/skills` that `~/.claude/skills` doesn't already have, create a link at `~/.claude/skills/<name>`. On Windows use a directory junction (`New-Item -ItemType Junction`, which needs no admin rights); elsewhere use a symlink. Codex reads `~/.agents/skills` directly and needs no link.
   - Never move or re-link skills that step 2 marked as belonging to another installer or to the agent itself.
7. **Disable built-in memory:** set `"autoMemoryEnabled": false` in `~/.claude/settings.json`, and `memories = false` under `[features]` in Codex `config.toml`. Edit these files in place and preserve every other setting.
8. **Write `<home>/.install.json`**:

   ```json
   {
     "schemaVersion": 1,
     "source": "<repository URL>",
     "commit": "<kit commit SHA>",
     "installedAt": "<UTC ISO timestamp>",
     "agents": ["claude", "codex"],
     "modules": ["recording-knowledge", "code-comments"],
     "skills": ["handoff", "migrate-memories", "tidy-agent-home"]
   }
   ```

## 5. Migrate memories

If the user chose it, follow the installed `<home>/skills/migrate-memories/SKILL.md` now.

## 6. Verify and report

- Run `pwsh -NoProfile -File <home>/scripts/Resolve-AgentProject.ps1 -Path <any existing directory> -Json` and confirm it prints JSON with `scratchPath`, `privatePath`, and `relatedTasks`. Do not pass `-Ensure` here.
- Confirm each Claude skill link resolves to `<home>/skills/<name>`.
- Search only the files this kit installed or composed (`<home>/AGENTS.md`, the adapters, the kit's skills, and `tasks/README.md`) for the kit's own tokens (`{{AGENT_HOME}}`, `{{WINDOWS_AGENT_HOME}}`, `{{WSL_DISTRO}}`). None may remain. Other `{{...}}` syntax in user skills, such as Helm or Go templates, is legitimate.
- Report what was installed, the backup location, and anything skipped. Tell the user to start a fresh Claude Code or Codex session so the new guidance and skills load. Suggest trying the `handoff` skill in a repository, and running `tidy-agent-home` now and then.

## Update mode

When `<home>/.install.json` exists:

1. Fetch the latest kit and show `git log --oneline <recorded commit>..HEAD` as a summary of what changed.
2. Diff each installed script and kit skill against what the recorded commit would have produced after placeholder substitution. If they differ, the user edited the file locally: show the diff and ask before replacing it.
3. Do the same check on each managed block in `<home>/AGENTS.md` and the adapters. If the user edited text inside the markers, show the diff and offer to move the edit into the overrides section before replacing the block.
4. Replace the managed blocks with the new template content, keeping the recorded modules. Offer any modules and kit skills that are new since the recorded commit.
5. Update `.install.json` and run the step 6 verification.

## WSL companion mode

WSL agents share the Windows install instead of getting their own, so one set of guidance, handoffs, and tasks serves both sides. The resolver already matches Windows and Linux paths in cross-project tasks.

1. **Find the Windows install.** Look for `/mnt/c/Users/*/.agents/.install.json`, and ask the user which Windows profile is theirs if there is more than one. If none exists, ask the user to run the setup prompt on Windows first. If they only use WSL, fall back to the normal install in the Linux `~/.agents`.
2. **Inspect** as in step 2, on the Linux side: existing `~/.claude/CLAUDE.md` and `~/.codex/AGENTS.md`, the skill directories, WSL built-in memories, and memory settings. Check that `pwsh` is on the `PATH`.
3. **Ask:** which WSL agents to configure; whether to move Linux-side user skills into the shared home (recommend it only for skills that also work on Windows); whether to migrate WSL memories now (recommend yes); and how to fold in any existing hand-written instructions. Present the plan and wait for approval.
4. **Install**, with the same backups, managed `adapter` block, and `@` import placement as step 4, but copy nothing into a Linux store:
   - Claude `~/.claude/CLAUDE.md` from `template/adapters/claude/CLAUDE.wsl.md`, and Codex `~/.codex/AGENTS.md` from `template/adapters/codex/AGENTS.wsl.md`. Fill `{{AGENT_HOME}}` with the Windows home's `/mnt/c/...` path, `{{WINDOWS_AGENT_HOME}}` with the same `C:/...` value the Windows install used, and `{{WSL_DISTRO}}` with `$WSL_DISTRO_NAME`.
   - For each shared skill that works on Linux, create symlinks `~/.claude/skills/<name>` and `~/.agents/skills/<name>` pointing at `/mnt/c/.../.agents/skills/<name>`. The second link is how Codex in WSL discovers shared skills. Apply the step 2 skill classification: leave Linux-only skills, other installers' links, and agent-managed folders in place.
   - Disable built-in memory in the WSL `~/.claude/settings.json` and `~/.codex/config.toml`, as in step 4.7.
   - Add `"wsl": ["<distro>"]` to the Windows `.install.json`.
5. **Migrate** WSL memories with the shared `migrate-memories` skill, if chosen. Its resolver calls use the Linux path.
6. **Verify:** run the resolver by its `/mnt/c/...` path against a Linux directory, confirm every skill link resolves, and confirm none of the kit's own placeholder tokens remain in the WSL adapters.

In **Update mode**, when `.install.json` lists WSL distros, remind the user to run the update prompt in each WSL agent too, so new shared skills get linked there.
