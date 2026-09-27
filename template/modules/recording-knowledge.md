## Recording Knowledge

Put information in the most durable, shared place its audience will actually inspect. Prefer committed, human-visible material over agent-only notes.

- **Transient active task state:** project scratch for one-project work; the task registry for cross-project work.
- **Cannot be committed:** private access details, host or network topology, and similar facts go in the resolver's `privatePath`. Keep credentials in their existing secret stores and reference only their location.
- **One specific change:** its rationale, trade-offs, and rejected alternatives go in the commit message or pull-request description.
- **One non-obvious local invariant:** a minimal inline comment where the code would otherwise mislead.
- **Durable repository guidance:** architecture, conventions, gotchas, build/test/deploy steps, accepted limits, and do-not-retry decisions go in repository `AGENTS.md` or its normal human-facing documentation.
- **Guidance across all projects:** this user-level file. Keep rules for one project in that project.

A one-off decision belongs in the commit. A durable accepted limitation or rejected approach that future agents would otherwise retry belongs in discoverable repository guidance, or in an inline comment when it concerns one precise location.

When a fact helps human maintainers, prefer normal documentation or code comments and have agent guidance link to it. Keep `AGENTS.md` lean enough for startup context; link rather than copy long references.
