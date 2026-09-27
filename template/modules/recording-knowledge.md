## Recording Knowledge

Put information in the most durable, shared place its audience will actually inspect. Prefer committed, human-visible material over agent-only notes.

- **Transient active task state:** project scratch for one-project work; the task registry for cross-project work.
- **Cannot be committed:** private access details, host or network topology, and similar facts go in the resolver's `privatePath`. Keep credentials in their existing secret stores and reference only their location.
- **One specific change:** its rationale, trade-offs, and rejected alternatives go in the commit message or pull-request description.
- **One non-obvious local invariant:** a minimal inline comment where the code would otherwise mislead.
- **Durable repository guidance:** architecture, conventions, gotchas, build/test/deploy steps, accepted limits, and do-not-retry decisions go in repository `AGENTS.md` or its normal human-facing documentation.
- **Guidance across all projects:** this user-level file. Keep rules for one project in that project.

When a fact helps human maintainers, prefer normal documentation or code comments and have agent guidance link to it. Keep `AGENTS.md` lean enough for startup context; link rather than copy long references.
