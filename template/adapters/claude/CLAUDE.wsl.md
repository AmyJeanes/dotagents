@{{AGENT_HOME}}/AGENTS.md

# Claude Code WSL Adapter

You are running inside WSL on a Windows machine. The imported file is the canonical guidance shared with Codex and with the Windows-side agents. Put shared changes there, not here, and keep this adapter to WSL- and Claude-specific behaviour.

- There is one shared agent home. Where shared guidance or skills say `{{WINDOWS_AGENT_HOME}}`, use `{{AGENT_HOME}}`: they are the same location. Never create a second, Linux-local store.
- Run the resolver by its Linux path: `pwsh -NoProfile -File {{AGENT_HOME}}/scripts/Resolve-AgentProject.ps1 -Path <linux-path> -Json`. Linux-filesystem checkouts get their own project homes. Cross-project tasks may list both Windows and Linux participants; each session matches its own.
- When giving the user a file link, use a Windows-clickable path: `/mnt/c/...` becomes `C:\...`, and any other Linux path becomes `\\wsl.localhost\{{WSL_DISTRO}}\...`.
- Skip skills and guidance that only make sense on Windows.
- Claude auto memory is disabled. Do not create or depend on agent-private memory; route knowledge through the shared locations in the shared guidance.
