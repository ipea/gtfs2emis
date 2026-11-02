#!/usr/bin/env python3
"""
Session-Log Auto-Writer Hook (Stop)

A Stop hook that **writes** the session log instead of nagging about it.
The previous version (v1.x) only emitted stderr advisories — "consider
updating the log" — and left the writing to the human/agent. The modern
posture is: the system does the bookkeeping, you do the research.

On each Stop, when the working tree has changed since the last auto-entry,
it appends a structured entry to today's session log
(quality_reports/session_logs/auto/YYYY-MM-DD_auto.md, created if absent;
kept in a subfolder so tools that read "the most recent session log" get
the narrative log, not this mechanical one):

  - timestamp
  - changed files (git status --porcelain, capped)
  - active plan + status (most recent non-completed plan)
  - stale-render note: README.Rmd newer than README.md. Non-blocking by default; set
    CLAUDE_COMPILE_GATE=block to turn the note into a Stop-block that asks
    Claude to re-render before stopping.

Throttling: writes only when `git status --porcelain` changed since the
last entry (hashed in state), so a quiet turn does not spam the log.

Fail-open: any error → exit 0, never blocks Claude on a hook bug.

Usage (.claude/settings.json):
    "Stop": [{ "hooks": [{ "type": "command",
      "command": "python3 \"$CLAUDE_PROJECT_DIR\"/.claude/hooks/log-reminder.py" }] }]
"""

from __future__ import annotations

import json
import os
import sys
import hashlib
import re
import subprocess
from pathlib import Path
from datetime import datetime


def get_state_dir() -> Path:
    project_dir = os.environ.get("CLAUDE_PROJECT_DIR", "")
    if not project_dir:
        d = Path.home() / ".claude" / "sessions" / "default"
    else:
        h = hashlib.md5(project_dir.encode()).hexdigest()[:8]
        d = Path.home() / ".claude" / "sessions" / h
    d.mkdir(parents=True, exist_ok=True)
    return d


def _git(project_dir: str, *args: str) -> str:
    try:
        out = subprocess.run(
            ["git", "-C", project_dir, *args],
            capture_output=True, text=True, timeout=5,
        )
        return out.stdout if out.returncode == 0 else ""
    except Exception:
        return ""


def active_plan(project_dir: str) -> str | None:
    plans = Path(project_dir) / "quality_reports" / "plans"
    if not plans.is_dir():
        return None
    files = sorted(plans.glob("*.md"), key=lambda f: f.stat().st_mtime, reverse=True)
    for p in files[:3]:
        try:
            text = p.read_text(encoding="utf-8", errors="replace")
        except Exception:
            continue
        # Parse the Status FIELD, not a whole-file substring — a DRAFT plan that
        # merely mentions "APPROVED"/"COMPLETED" must not be mis-labelled.
        m = re.search(r"^\s*\**\s*status\s*\**\s*:\s*\**\s*"
                      r"(draft|approved|completed|implemented|in[ -]?progress)",
                      text, re.IGNORECASE | re.MULTILINE)
        v = m.group(1).lower() if m else "in-progress"
        if v.startswith(("completed", "implemented")):
            continue
        status = "APPROVED" if v.startswith("approved") else ("DRAFT" if v.startswith("draft") else "in-progress")
        return f"{p.name} ({status})"
    return None


def uncompiled(project_dir: str) -> list[str]:
    """README.Rmd newer than its rendered README.md."""
    flagged: list[str] = []
    root = Path(project_dir)
    src, out = root / "README.Rmd", root / "README.md"
    try:
        if src.exists() and (not out.exists() or src.stat().st_mtime > out.stat().st_mtime):
            flagged.append("README.Rmd -> README.md not re-rendered")
    except Exception:
        pass
    return flagged


def main() -> int:
    try:
        hook_input = json.load(sys.stdin)
    except (json.JSONDecodeError, EOFError):
        hook_input = {}

    # Avoid Stop-hook loops.
    if hook_input.get("stop_hook_active", False):
        return 0

    project_dir = os.environ.get("CLAUDE_PROJECT_DIR", "") or hook_input.get("cwd", "")
    if not project_dir or not Path(project_dir).is_dir():
        return 0

    status = _git(project_dir, "status", "--porcelain")
    if not status.strip():
        return 0  # nothing changed — nothing to log

    state_path = get_state_dir() / "g2e-session-log-state.json"
    status_hash = hashlib.md5(status.encode()).hexdigest()
    try:
        prev = json.loads(state_path.read_text()).get("last_hash")
    except Exception:
        prev = None
    if status_hash == prev:
        return 0  # already logged this exact change-set

    logs = Path(project_dir) / "quality_reports" / "session_logs" / "auto"
    logs.mkdir(parents=True, exist_ok=True)
    today = datetime.now().strftime("%Y-%m-%d")
    log_file = logs / f"{today}_auto.md"
    new_file = not log_file.exists()

    changed = [ln for ln in status.splitlines() if ln.strip()][:30]
    plan = active_plan(project_dir)
    flagged = uncompiled(project_dir)

    lines = []
    if new_file:
        lines.append(f"# Session Log — {today} (auto)\n")
        lines.append("_Auto-written by the Stop hook on each meaningful change-set. "
                     "Narrative notes welcome alongside._\n")
    lines.append(f"\n## {datetime.now().strftime('%H:%M')} — {len(changed)} file(s) touched")
    if plan:
        lines.append(f"\n**Active plan:** {plan}")
    lines.append("\n**Changed:**")
    lines.extend(f"- `{ln.strip()}`" for ln in changed)
    if flagged:
        lines.append("\n**Stale renders:**")
        lines.extend(f"- {x}" for x in flagged)
    lines.append("")

    try:
        with open(log_file, "a", encoding="utf-8") as f:
            f.write("\n".join(lines) + "\n")
    except Exception:
        return 0

    try:
        state_path.write_text(json.dumps({"last_hash": status_hash}))
    except Exception:
        pass

    sys.stderr.write(f"[session-log] appended {len(changed)} change(s) to {log_file.name}\n")

    # Opt-in compile gate: turn the uncompiled note into a Stop-block.
    if flagged and os.environ.get("CLAUDE_COMPILE_GATE", "") == "block":
        reason = ("Stale renders before stop: " + "; ".join(flagged) +
                  ". Run rmarkdown::render('README.Rmd'), or set CLAUDE_COMPILE_GATE= to disable this gate.")
        json.dump({"decision": "block", "reason": reason}, sys.stdout)

    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception:
        sys.exit(0)  # fail open
