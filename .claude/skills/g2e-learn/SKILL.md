---
name: g2e-learn
description: |
  Extract reusable knowledge from the current session into a persistent skill.
  Use when you discover something non-obvious, create a workaround, or develop
  a multi-step workflow that future sessions would benefit from.
version: 1.0.0
argument-hint: "[skill-name (kebab-case)]"
allowed-tools: ["Read", "Write", "Bash", "Glob", "Grep"]
disable-model-invocation: true
---

# /g2e-learn — Skill Extraction Workflow

Extract non-obvious discoveries into reusable skills that persist across sessions.

## When to Use This Skill

Invoke `/g2e-learn` when you encounter:

- **Non-obvious debugging** — Investigation that took significant effort, not in docs
- **Misleading errors** — Error message was wrong, found the real cause
- **Workarounds** — Found a limitation with a creative solution
- **Tool integration** — Undocumented API usage or configuration
- **Trial-and-error** — Multiple attempts before success
- **Repeatable workflows** — Multi-step task you'd do again
- **User-facing automation** — Reports, checks, or processes users will request

## Workflow Phases

### PHASE 1: Evaluate (Self-Assessment)

Before creating a skill, answer these questions:

1. "What did I just learn that wasn't obvious before starting?"
2. "Would future-me benefit from this being documented?"
3. "Was the solution non-obvious from documentation alone?"
4. "Is this a multi-step workflow I'd repeat?"

**Continue only if YES to at least one question.**

### PHASE 2: Check Existing Skills

Search for related skills to avoid duplication:

```bash
# Check project skills
ls .claude/skills/ 2>/dev/null

# Search for keywords
grep -r -i "KEYWORD" .claude/skills/ 2>/dev/null
```

**Outcomes:**
- Nothing related → Create new skill (continue to Phase 3)
- Same trigger & fix → Update existing skill (bump version)
- Partial overlap → Update with new variant

### PHASE 3: Create Skill

Create the skill file at `.claude/skills/g2e-[skill-name]/SKILL.md` (project skills always carry the `g2e-` prefix):

```yaml
---
name: g2e-descriptive-kebab-case-name
description: |
  [CRITICAL: Include specific triggers in the description]
  - What the skill does
  - Specific trigger conditions (exact error messages, symptoms)
  - When to use it (contexts, scenarios)
version: 1.0.0
argument-hint: "[expected arguments]"  # Optional
---

# Skill Name

## Problem
[Clear problem description — what situation triggers this skill]

## Context / Trigger Conditions
[When to use — exact error messages, symptoms, scenarios]
[Be specific enough that you'd recognize it again]

## Solution
[Step-by-step solution]
[Include commands, code snippets, or workflows]

## Verification
[How to verify it worked]
[Expected output or state]

## Example
[Concrete example of the skill in action]

## References
[Documentation links, related files, or prior discussions]
```

### PHASE 4: Quality Gates

Before finalizing, verify:

- [ ] Description has specific trigger conditions (not vague)
- [ ] Solution was verified to work (tested)
- [ ] Content is specific enough to be actionable
- [ ] Content is general enough to be reusable
- [ ] No sensitive information (credentials, personal data)
- [ ] Skill name is descriptive and uses kebab-case

## Output

After creating the skill, report:

```
✓ Skill created: .claude/skills/g2e-[name]/SKILL.md
  Trigger: [when to use]
  Problem: [what it solves]
```

## Example: Creating a Skill

*(Illustrative: shows the format, not a recorded incident.)* A session finds
that an edit to `emission_model()` "works" with `parallel = FALSE` but not with
`parallel = TRUE`, because the workers ran the old installed gtfs2emis:

```markdown
---
name: g2e-parallel-workers-installed-package
description: |
  Explain parallel vs sequential divergence after editing gtfs2emis source.
  Use when: a change made under devtools::load_all() shows up with
  parallel = FALSE but not with parallel = TRUE in transport_model() or
  emission_model(), or results differ between the two modes after an edit.
version: 1.0.0
---

# Parallel workers run the installed package

## Problem
`transport_model()` and `emission_model()` use `future::plan("multisession")`
and `furrr::future_map()`. Each worker is a separate R process that loads the
**installed** gtfs2emis, not the `load_all()` copy, so edited worker code is
not what runs in parallel mode.

## Context / Trigger Conditions
- Results differ between `parallel = TRUE` and `parallel = FALSE` right after
  editing a function called inside the workers
- A fix "doesn't work" only in parallel mode

## Solution
Install the package (`devtools::install()` or `R CMD INSTALL .`) before
testing a changed worker path, then compare both modes.

## Verification
`parallel = FALSE` and `parallel = TRUE, ncores = 2` give identical results
(`all.equal()` is `TRUE`).

## References
- `.claude/rules/r-package-conventions.md` (A3, parallelism)
- `.claude/rules/quality-gates.md` (Gate 1, parallel parity)
```
