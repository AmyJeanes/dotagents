# Repository Guidance

This is a public, generic template. Keep everything free of any individual's names, machines, paths, projects, or preferences.

- `template/` is what gets installed into a user's agent home. `SETUP.md` is the installer procedure an agent follows. `README.md` is for humans and holds the copy-paste prompts.
- Installed files use `{{PLACEHOLDER}}` tokens. Every token must be documented in `SETUP.md` step 4, and none may survive installation.
- Installed guidance is wrapped in `agent-kit` managed markers so updates can replace it without touching user content. Keep module files self-contained, each with a single `##` heading.
- When adding a module or skill, update the module list in `SETUP.md` step 3 and the table in `README.md`.
- Keep `template/scripts/Resolve-AgentProject.ps1` cross-platform on PowerShell 7+, and keep its manifest schemas backward compatible with existing installs.
