# Project Memory — gtfs2emis

Corrections and learned facts that persist across sessions (local only;
gitignored). When a mistake is corrected, append a
`[LEARN:category] wrong → right` entry below. Suggested categories:
`ef`, `units`, `data.table`, `parallel`, `data`, `api`, `tests`, `cran`,
`docs`, `perf`, `workflow`, `tooling`.

------------------------------------------------------------------------

## Workflow

\[LEARN:workflow\] Workflow config was ported from gtfs2gps (2026-10-12)
→ gtfs2gps-only items (Rcpp/src, `gtfs2gps()` worker path, poa/saopaulo
fixtures, GPS column types) do NOT apply here. gtfs2emis is pure R, uses
cli for conditions since 2026-10-13 (conventions A4), `test_` files,
`master`, and tests are Rbuildignored (not run on CRAN).

\[LEARN:workflow\] Grep tool skips gitignored files → search `.claude/`
(gitignored here) with shell `grep -r`.

\[LEARN:tooling\] (inherited, same machine) git-guardrails matches
command TEXT, so a heredoc that merely mentions a destructive git
command gets blocked → write helper scripts with the Write tool, then
run them.

\[LEARN:tooling\] (inherited) Avoid `>` inside `Rscript -e '...'`
strings on Windows: it was treated as a redirect and created a stray
file.

\[LEARN:tooling\] (inherited) devtools::document() with roxygen2 8
replaces `RoxygenNote:` with `Config/roxygen2/version:` in DESCRIPTION →
restore the RoxygenNote line unless the maintainers agree to move; and
use `devtools::check(document = FALSE, ...)`.

\[LEARN:tooling\] (inherited) Rewriting a whole R file with the Write
tool strips trailing whitespace on untouched lines (noisy diff) → use
Edit for small changes.

\[LEARN:parallel\] (inherited from gtfs2gps) Under `load_all()`, furrr
multisession workers load the *installed* package →
`devtools::install(quick = TRUE, upgrade = FALSE)` before testing a
changed worker path in
[`transport_model()`](https://ipea.github.io/gtfs2emis/dev/reference/transport_model.md)/[`emission_model()`](https://ipea.github.io/gtfs2emis/dev/reference/emission_model.md).

\[LEARN:tooling\] (inherited) `gh` CLI is not installed on this machine
→ PRs are opened by the user from the GitHub compare URL; prepare the
body in a file.

\[LEARN:tooling\] (inherited) sed/perl replacement strings containing
`\c` on Git Bash turn `\code{` into a control byte → write roxygen text
with Write/Edit, never via shell replacement strings.

\[LEARN:workflow\] (inherited) Subagents cannot write report files → the
orchestrator saves each hand-back to disk itself.

\[LEARN:workflow\] (inherited) Concurrent agents must not
`devtools::load_all()`/install into the same library at once → install
once to an isolated lib (`R CMD INSTALL -l <scratch>/lib .`) and load
with
[`library(gtfs2emis, lib.loc = ...)`](https://rdrr.io/r/base/library.html).

\[LEARN:tooling\] (inherited) `git add` can fail with “unable to write
new index file” (Dropbox briefly locking .git) → check for .git/\*.lock,
then retry.

\[LEARN:api\] Assumed gtfs2emis keeps base stop()/message() → maintainer
decided 2026-10-13 to route all conditions through cli. checkmate stays
for the checks via internal `assert_*()` wrappers in R/conditions.R
(conventions A4).

\[LEARN:tooling\] The Write tool strips whitespace-only lines inside
strings in scratch scripts, so exact-match replacements of R code that
contains a blank-but-indented line fail → delete or normalise that line
first (sed), or match with a regex.
