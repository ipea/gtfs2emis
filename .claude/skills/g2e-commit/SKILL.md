---
name: g2e-commit
description: Run the commit gate, then branch and commit for gtfs2emis; push and open a PR only when asked (after Gate 2). Use ONLY on explicit commit intent — user says "commit", "ship it", "push this", "open a PR", or prefixes with `/g2e-commit`. Do NOT auto-invoke on vague end-of-task phrases ("we're done", "wrap up"). Never merges unless the user explicitly asks; never force-pushes or skips hooks.
argument-hint: "[optional: commit message]"
allowed-tools: ["Bash", "Read", "Glob", "Grep", "Agent"]
---

# Commit and PR (gtfs2emis)

The repo is public and co-maintained, and the package is on CRAN. This skill
stops at a local commit by default; it pushes and opens a PR only when asked.
**Merging needs a separate, explicit request.**

## Step 0: Commit gate

Run Gate 1 from `.claude/rules/quality-gates.md` for the changed files:

```bash
Rscript -e "devtools::document()"
git diff --stat man/ NAMESPACE DESCRIPTION   # content drift must be intended (EOL-only changes: restore)
Rscript -e "devtools::test(filter = '<fn>')"   # each touched function (test_<fn>.R)
```

- If the `transport_model()` or `emission_model()` worker path changed,
  install the package first (workers load the installed gtfs2emis), then
  confirm `parallel = FALSE` and `parallel = TRUE, ncores = 2` give identical
  results.
- If EF or emission math changed, a hand-checked known value matches the
  source table/equation. If `data/*.rda` changed, it was rebuilt by its
  `data-raw/` script and `R/data.R` matches its columns.
- Confirm nothing staged is a build artefact or data dump
  (`git diff --cached --name-only | grep -E '\.(rds|RData|Rhistory)$'`
  returns nothing; `.zip`/`.tif` only under `inst/extdata/`; `.rda` only under `data/`).
- A user-facing change needs a `NEWS.md` bullet (conventions A9).
- If any check fails, stop and report. Override only on an explicit "commit
  anyway", and record the reason in the commit body.
- Before any push or PR, run **Gate 2 from `quality-gates.md` in full**:
  full `devtools::test()`, `devtools::check(args = "--as-cran")` (background),
  a converged review loop, `r-package-reviewer` with 0 CRITICAL/MAJOR, and
  `bench::mark` evidence if the change claims or risks a speed change.

## Step 1: State

```bash
git status
git diff --stat
git log --oneline -5
```

## Step 2: Branch

If on `master`, run `git checkout -b <short-descriptive-name>`. Never commit
directly to `master`.

## Step 3: Stage specific files

`git add <file> ...`. Never use `git add -A` / `git add .`.

**Only these workflow files may be staged:** `CLAUDE.md` and
`.claude/rules/*`, and only when the user has agreed to share them. Everything
else in the workflow (`.claude/` outside rules, `MEMORY.md`,
`quality_reports/`, `templates/`) is gitignored and stays local. Never stage
`.rds`, `.RData` or `.Rhistory`.
The scratch folders `tests/test_joao/` and `tests/tests_rafa/` belong to
the maintainers; don't stage changes there unless asked.

## Step 4: Commit

Use `$ARGUMENTS` as the message if given. Otherwise write one that explains
*why*, in the repo's style (short imperative subject). End with the attribution
lines from the system context.

```bash
git commit -m "$(cat <<'EOF'
<subject>

<body>
EOF
)"
```

**Never pass `--no-verify`.** If a hook fails, fix the cause and commit again
as a new commit attempt. Don't amend.

## Step 5: Push and open a PR (only if asked)

```bash
git push -u origin <branch>
gh pr create --title "<short title>" --body "$(cat <<'EOF'
## Summary
<1-3 bullets>

## Checks
- devtools::test(): <result>
- R CMD check --as-cran: <E/W/N>
- Review loop: <rounds; converged with 0 open CRITICAL/MAJOR>
- r-package-reviewer: <0 CRITICAL / 0 MAJOR / n MINOR>
- Benchmarks: <bench::mark summary / not applicable>
- NEWS.md: <updated / not needed>

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

## Step 6: Report

Report the branch, commit hash and PR URL, with gate results.

## Merging

Only when the user explicitly says "merge". Use `gh pr merge <n> --merge`, then
`git checkout master` and `git pull`. Confirm CI is green first
(`gh pr checks <n>`).
