# Setup Procedure (for agents)

You are Claude Code or Codex installing this kit for the user. Follow these steps in order. Steps 1 and 2 are read-only. Do not write anything until the user has approved the plan in step 3. Never modify, commit to, or push the user's repositories.

`<kit>` means the directory you cloned this repository into. `<home>` means `~/.agents`. The location is fixed: Codex discovers user skills only in `~/.agents/skills`, and Claude's adapter imports `../.agents/AGENTS.md` relative to `~/.claude`.

## 1. Check prerequisites

- **PowerShell 7+** (`pwsh`): the resolver needs it on every OS. If it is missing, offer the platform install command (`winget install Microsoft.PowerShell`, `brew install powershell`, or Microsoft's Linux package instructions) and wait for the user.
- **Agents present:** Claude Code if `~/.claude` exists; Codex if `$CODEX_HOME` or `~/.codex` exists. Configure only the agents the user actually uses.
- **Environment:** if you are running inside WSL (`WSL_DISTRO_NAME` is set, or `/proc/version` mentions Microsoft), use **WSL companion mode** below instead of steps 3 to 5. On Windows, if `wsl.exe -l -q` lists distros, tell the user they can run the same prompt in their WSL agent afterwards to share this install with it.

## 2. Inspect existing state

Report, without changing anything:

- whether `<home>` exists, and whether `<home>/.install.json` shows an earlier install from this kit (if so, use **Update mode** below);
- existing `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`, and `<home>/AGENTS.md`, summarising any hand-written content;
- existing skills in `<home>/skills` and `~/.claude/skills`, including any name clash with `handoff` or `migrate-memories`;
- how much built-in memory exists: the number of Claude `~/.claude/projects/*/memory/` directories with content, and whether Codex `memories/` has any files;
- whether built-in memory is currently enabled: `autoMemoryEnabled` in `~/.claude/settings.json`, and `[features] memories` in Codex `config.toml`. The install always disables both, because agent-private memory is invisible to the other agent.

## 3. Ask, then plan

Ask all of these in one batch, giving your recommendation for each:

1. **Which agents to configure.**
2. **Guidance modules.** The core (`template/AGENTS.md`) is always installed. Show each module's heading and a one-line summary, and let the user pick:
   - `recording-knowledge`: where each kind of fact belongs (commit message, comment, `AGENTS.md`, private notes). Recommended.
   - `code-comments`: minimal comments that explain *why*, never history. Recommended.
   - `code-style`: match surrounding code and use plain, familiar identifiers. Recommended.
   - `git-safety`: fetch before reasoning, confirm before pushing shared branches, no upstream PRs or issues without approval.
   - `autonomy`: how to behave during unattended hand-offs.
   - `machine-power`: never shut down or sleep machines without explicit authorization.
   Offer to adjust any module's wording to the user's taste before installing it.
3. **Migrate existing memories now?** (only if step 2 found some). Recommend yes: built-in memory is disabled by the install, so unmigrated memories stop being read (they stay in the backup). It runs the `migrate-memories` skill after the install.
4. **Existing hand-written guidance.** For content found in step 2, offer to move shared rules into `<home>/AGENTS.md`, keep agent-specific parts in the adapter, and drop duplicates. Show the proposed split.

Then present the full plan: every file created or changed, every link, every settings edit, and the backup location. Wait for explicit approval.

## 4. Install

1. **Back up** every existing file you are about to change to `<home>/.backups/setup-<UTC timestamp>/`, preserving relative paths.
2. **Copy** from `<kit>/template` into `<home>`: `scripts/Resolve-AgentProject.ps1`, `tasks/README.md`, and `skills/*`. Create `<home>/projects/` and `<home>/tasks/`. Never overwrite an existing skill with the same name without the user's say-so.
3. **Substitute placeholders** in every copied or composed file:
   - `{{AGENT_HOME}}`: the absolute path of `~/.agents` in the OS's native form, e.g. `C:\Users\name\.agents` or `/home/name/.agents`.
   - `{{WINDOWS_AGENT_HOME}}` and `{{WSL_DISTRO}}`: only in WSL adapters; see **WSL companion mode**.
   Afterwards, grep the installed files for `{{`. None may remain.
4. **Compose `<home>/AGENTS.md`** from managed blocks: the core first, then each chosen module in the order listed above. Wrap each block in markers:

   ```
   <!-- agent-kit:begin core -->
   ...template content...
   <!-- agent-kit:end core -->
   ```

   Use the module's file name as the block name. Keep the user's own content outside the markers, below the managed blocks. Nothing outside the markers is ever rewritten by this kit.
5. **Adapters**, also wrapped in an `adapter` managed block, preserving any user content outside it:
   - Claude: `~/.claude/CLAUDE.md` from `template/adapters/claude/CLAUDE.md`. The `@` import line must stay the file's first line.
   - Codex: `$CODEX_HOME/AGENTS.md` (default `~/.codex/AGENTS.md`) from `template/adapters/codex/AGENTS.md`.
6. **Expose skills to Claude:** for each installed skill, create `~/.claude/skills/<name>` as a link to `<home>/skills/<name>`. On Windows use a directory junction (`New-Item -ItemType Junction`, which needs no admin rights); elsewhere use a symlink. Codex reads `~/.agents/skills` directly and needs no link.
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
     "skills": ["handoff", "migrate-memories"]
   }
   ```

## 5. Migrate memories

If the user chose it, follow the installed `<home>/skills/migrate-memories/SKILL.md` now.

## 6. Verify and report

- Run `pwsh -NoProfile -File <home>/scripts/Resolve-AgentProject.ps1 -Path <any existing directory> -Json` and confirm it prints JSON with `scratchPath`, `privatePath`, and `relatedTasks`. Do not pass `-Ensure` here.
- Confirm each Claude skill link resolves to `<home>/skills/<name>`.
- Confirm no `{{` placeholders remain.
- Report what was installed, the backup location, and anything skipped. Tell the user to start a fresh Claude Code or Codex session so the new guidance and skills load, and suggest trying the `handoff` skill in a repository.

## Update mode

When `<home>/.install.json` exists:

1. Fetch the latest kit and show `git log --oneline <recorded commit>..HEAD` as a summary of what changed.
2. Diff each installed script and skill against the new template, after substituting placeholders. If an installed file differs from what the recorded commit would have produced, the user has edited it locally: show the diff and ask before replacing it.
3. Replace only the content inside `agent-kit` markers, keeping the recorded modules. Offer any modules that are new since the recorded commit.
4. Update `.install.json` and run the step 6 verification.

## WSL companion mode

WSL agents share the Windows install instead of getting their own, so one set of guidance, handoffs, and tasks serves both sides. The resolver already matches Windows and Linux paths in cross-project tasks.

1. **Find the Windows install.** Look for `/mnt/c/Users/*/.agents/.install.json`, and ask the user which Windows profile is theirs if there is more than one. If none exists, ask the user to run the setup prompt on Windows first. If they only use WSL, fall back to the normal install in the Linux `~/.agents`.
2. **Inspect** as in step 2, on the Linux side: existing `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`, `~/.claude/skills`, `~/.agents/skills`, WSL built-in memories, and memory settings. Check that `pwsh` is on the `PATH`.
3. **Ask:** which WSL agents to configure; whether to migrate WSL memories now (recommend yes); and how to fold in any existing hand-written instructions. Present the plan and wait for approval.
4. **Install**, with the same backups and managed `adapter` block as step 4, but copy nothing into a Linux store:
   - Claude `~/.claude/CLAUDE.md` from `template/adapters/claude/CLAUDE.wsl.md`, and Codex `~/.codex/AGENTS.md` from `template/adapters/codex/AGENTS.wsl.md`. Fill `{{AGENT_HOME}}` with the Windows home's `/mnt/c/...` path, `{{WINDOWS_AGENT_HOME}}` with its `C:\...` form, and `{{WSL_DISTRO}}` with `$WSL_DISTRO_NAME`.
   - For each skill in the shared `skills/`, create symlinks `~/.claude/skills/<name>` and `~/.agents/skills/<name>` pointing at `/mnt/c/.../.agents/skills/<name>`. The second link is how Codex in WSL discovers shared skills. Leave existing Linux-only skills in place.
   - Disable built-in memory in the WSL `~/.claude/settings.json` and `~/.codex/config.toml`, as in step 4.7.
   - Add `"wsl": ["<distro>"]` to the Windows `.install.json`.
5. **Migrate** WSL memories with the shared `migrate-memories` skill, if chosen. Its resolver calls use the Linux path.
6. **Verify:** run the resolver by its `/mnt/c/...` path against a Linux directory, confirm every skill link resolves, and confirm no `{{` placeholders remain in the WSL adapters.

In **Update mode**, when `.install.json` lists WSL distros, remind the user to run the update prompt in each WSL agent too, so new shared skills get linked there.
