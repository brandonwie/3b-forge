#!/usr/bin/env python3
"""Stop hook: session-end verification checklist.

Checks for uncommitted changes, buffer entries, and open todos.
Outputs reminders so nothing is forgotten before ending a session.
"""

import subprocess
import os
import sys

# 3B is opt-in via env var. Unset → buffer/3B checks skipped silently.
THREE_B_PATH = os.environ.get("FORGE_3B_ROOT") or None
BUFFER_PATH = (
    os.path.join(THREE_B_PATH, ".claude", "buffer.md") if THREE_B_PATH else None
)

warnings = []


def check_git_status():
    """Check for uncommitted changes in current repo."""
    try:
        result = subprocess.run(
            ["git", "status", "--porcelain"],
            capture_output=True, text=True, timeout=5
        )
        if result.stdout.strip():
            lines = result.stdout.strip().split("\n")
            count = len(lines)
            warnings.append(
                f"Uncommitted changes: {count} file(s) in current repo"
            )
    except Exception:
        pass


def check_buffer():
    """Check if buffer.md has unprocessed entries."""
    if not BUFFER_PATH:
        return
    try:
        if os.path.exists(BUFFER_PATH):
            with open(BUFFER_PATH, "r") as f:
                content = f.read().strip()
            # Skip if buffer is empty or only has header
            lines = [
                l for l in content.split("\n")
                if l.strip() and not l.startswith("#")
            ]
            if len(lines) > 0:
                warnings.append(
                    "Buffer has unprocessed entries (run /wrap before ending)"
                )
    except Exception:
        pass


def check_3b_uncommitted():
    """Check if 3B repo has uncommitted changes."""
    if not THREE_B_PATH:
        return
    try:
        result = subprocess.run(
            ["git", "-C", THREE_B_PATH, "status", "--porcelain"],
            capture_output=True, text=True, timeout=5
        )
        if result.stdout.strip():
            lines = result.stdout.strip().split("\n")
            count = len(lines)
            warnings.append(
                f"3B repo has {count} uncommitted file(s)"
            )
    except Exception:
        pass


def check_friction_reminder():
    """Soft reminder to tag friction entries if session had errors."""
    if not BUFFER_PATH:
        return
    try:
        if os.path.exists(BUFFER_PATH):
            with open(BUFFER_PATH, "r") as f:
                content = f.read()
            has_friction = "[FRICTION]" in content
            # If there are already warnings (errors/uncommitted changes)
            # but no friction entries, nudge the user
            if not has_friction and len(warnings) > 0:
                warnings.append(
                    "Consider tagging [FRICTION] entries in the "
                    "buffer if any errors traced to config issues"
                )
    except Exception:
        pass


def main():
    check_git_status()
    check_buffer()
    check_3b_uncommitted()
    check_friction_reminder()

    if warnings:
        print("Session verification:")
        for w in warnings:
            print(f"  - {w}")
    # No output if everything is clean (silent success)


if __name__ == "__main__":
    main()
