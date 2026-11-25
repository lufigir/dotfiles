#!/usr/bin/env python3
r"""PreToolUse guard shared by Claude Code and Antigravity CLI (agy).

Blocks, outside the model:
  1. `git push` with --force, -f or --force-with-lease (or a +refspec) to main or master,
     including a bare force-push while main or master is the checked-out branch.
  2. Anything that touches D:\Code\life-os\documentos\ from a working directory outside life-os.

Claude: reads {tool_name, tool_input, cwd}; denies with exit 2 and a message on stderr.
agy:    reads {toolCall: {name, args}, workspacePaths}; answers {"decision": "deny", "reason": ...}
        or {"decision": "allow"} on stdout with exit 0 (an empty {} denies on agy 1.5.13).
"""
import json
import os
import re
import shlex
import subprocess
import sys

PROTECTED = {"main", "master"}
LIFE_OS_DOCS = re.compile(r"life-os/documentos(/|$|\s|\"|')", re.IGNORECASE)
# Arguments that carry text being written, not a path being touched.
TEXT_KEYS = {
    "content", "new_string", "old_string",
    "CodeContent", "ReplacementContent", "TargetContent", "ReplacementChunks",
    "Content", "Replacement", "Target", "Prompt", "Message",
}


def strings(value):
    """Every string inside a tool's arguments, except the text it writes."""
    if isinstance(value, str):
        yield value
    elif isinstance(value, dict):
        for k, v in value.items():
            if k not in TEXT_KEYS:
                yield from strings(v)
    elif isinstance(value, list):
        for v in value:
            yield from strings(v)


def current_branch(cwd):
    try:
        out = subprocess.run(
            ["git", "-C", cwd or ".", "branch", "--show-current"],
            capture_output=True, text=True, timeout=5,
        )
        return out.stdout.strip()
    except Exception:
        return ""


def force_push_to_protected(command, cwd):
    """True when some `git ... push` in the command force-pushes main or master."""
    for segment in re.split(r"&&|\|\||[;|\n]", command):
        try:
            tokens = shlex.split(segment, posix=True)
        except ValueError:
            tokens = segment.split()
        if "push" not in tokens or "git" not in [os.path.basename(t) for t in tokens]:
            continue
        args = tokens[tokens.index("push") + 1:]
        flags = [a for a in args if a.startswith("-")]
        force = any(
            a in ("--force", "--force-with-lease", "--force-if-includes")
            or a.startswith("--force-with-lease=")
            or (not a.startswith("--") and "f" in a[1:])
            for a in flags
        )
        positional = [a for a in args if not a.startswith("-")]
        plus_refspec = any(a.startswith("+") for a in positional)
        if not (force or plus_refspec):
            continue
        # positional[0] is the remote; the rest are refspecs (src[:dst]).
        refspecs = positional[1:]
        targets = set()
        for r in refspecs:
            dst = r.lstrip("+").split(":")[-1]
            targets.add(dst.removeprefix("refs/heads/"))
        if targets & PROTECTED:
            return True
        # No explicit branch, or HEAD: it pushes the checked-out branch.
        if not refspecs or targets & {"HEAD"}:
            if current_branch(cwd) in PROTECTED:
                return True
        if "--all" in args or "--mirror" in args:
            return True
    return False


def in_life_os(cwd):
    parts = re.split(r"[\\/]+", os.path.abspath(cwd or ".").lower())
    return "life-os" in parts


def decide(payload):
    """Returns (agent, reason or None)."""
    if "toolCall" in payload:
        agent, call = "agy", payload["toolCall"]
        name, args = call.get("name", ""), call.get("args", {}) or {}
        cwd = args.get("Cwd") or (payload.get("workspacePaths") or [os.getcwd()])[0]
        command = args.get("CommandLine", "") if name == "run_command" else ""
    else:
        agent, name = "claude", payload.get("tool_name", "")
        args = payload.get("tool_input", {}) or {}
        cwd = payload.get("cwd") or os.getcwd()
        command = args.get("command", "") if name == "Bash" else ""

    if command and force_push_to_protected(command, cwd):
        return agent, "Force-pushing main or master is blocked. Push a branch and open a PR."
    # Known limits (accepted to keep the guard simple and stateless):
    # - A Bash command (e.g. a git commit message) that merely names life-os/documentos is also
    #   blocked when run from outside life-os.
    # - A command that `cd`s into life-os from another repo's cwd is still treated as outside
    #   life-os because the check inspects the tool call's initial cwd.
    if not in_life_os(cwd):
        for s in strings(args):
            if LIFE_OS_DOCS.search(s.replace("\\", "/")):
                return agent, "life-os/documentos is private: work on it from a session started in life-os."
    return agent, None


def main():
    try:
        sys.stdin.reconfigure(encoding="utf-8")
        payload = json.load(sys.stdin)
    except Exception:
        return 0  # not a hook payload: never block on our own parse failure
    agent, reason = decide(payload)
    if reason is None:
        if agent == "agy":
            print(json.dumps({"decision": "allow"}))
        return 0
    if agent == "agy":
        print(json.dumps({"decision": "deny", "reason": reason}))
        return 0
    print(reason, file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main())
