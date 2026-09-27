## Code Comments

Default to one line or no comment. Multi-line explanatory comments are exceptional.

Comment the unexplained **why**, not the visible **what**. Skip behaviour that is clear from the code, idiomatic patterns, and rationale better kept in the commit message. Keep necessary comments self-contained and useful without access to agent guidance or private notes.

Describe the live invariant, not historical behaviour: phrase a useful why-not forwards instead of narrating what the code used to do. Explain specialist concepts plainly for the maintainer.

Bias toward removing borderline comments, but keep a compact explanation of hard-won constraints, platform limits, or obvious-but-wrong alternatives a maintainer might otherwise retry.
