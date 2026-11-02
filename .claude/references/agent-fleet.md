# Agent Fleet (gtfs2emis)

Which agent fills which role. Reviewers are read-only and return FINDINGs
(FINDING format in `.claude/rules/orchestrator-protocol.md`); the main session applies the fixes.

| Role | Agent | Model | Used by |
|---|---|---|---|
| Plan reviewer: Minimalist | `Plan` (built-in), fresh | inherit | `plan-first-workflow.md` adversarial review |
| Plan reviewer: Skeptic | `Plan` (built-in), fresh | inherit | `plan-first-workflow.md` adversarial review |
| Code review: correctness and emission math | `general-purpose`, fresh | inherit | `orchestrator-protocol.md` |
| Code review: performance and parallelism | `general-purpose`, fresh | inherit | `orchestrator-protocol.md` |
| Code review: package and CRAN | `r-package-reviewer` (`.claude/agents/`) | sonnet | `orchestrator-protocol.md`, `/g2e-package-check` |
| Codebase search | `Explore` (built-in) | inherit | plan mode exploration |

Keep this table in sync with `.claude/agents/*.md` when agents are added or
re-tiered.
