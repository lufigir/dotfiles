#!/bin/sh
# Rejects a commit message that credits an AI agent: a Co-Authored-By (or similar) trailer naming
# one, a "Generated with ..." style line, an agent's noreply address, a session link, or the robot
# emoji. Naming an agent as a topic ("fix(claude): ...", "docs: describe the Gemini table") is fine.
# $1 is the message file git passes to commit-msg.

trailer_agents='claude|anthropic|gemini|google ai|copilot|cursor|antigravity|agy|codex|openai|chatgpt'
phrase_agents='claude|anthropic|gemini|google ai|copilot|cursor ai|antigravity|agy|codex|openai|chatgpt'

# Drop git's own comment lines, then look at what is left.
msg="$(grep -v '^#' "$1")"

bad="$(printf '%s\n' "$msg" | grep -n -i -E \
    -e "^[[:space:]]*(co-authored-by|signed-off-by|reviewed-by|assisted-by|generated-by|authored-by)[[:space:]]*:.*($trailer_agents)" \
    -e "^[[:space:]]*([-*•🤖][[:space:]]*)?(generated|authored|assisted|co-authored)[[:space:]]+(with|by)[[:space:]]+(\[|the[[:space:]]+)?($phrase_agents)\b" \
    -e "noreply@(anthropic|google|openai|cursor)" \
    -e "^[[:space:]]*claude-session[[:space:]]*:" \
    -e "claude\.ai/code/session" \
    -e "🤖" )"

if [ -n "$bad" ]; then
    echo "commit-msg: the message credits an AI agent, which this setup never does:" >&2
    printf '%s\n' "$bad" | sed 's/^/  line /' >&2
    echo "Remove those lines and commit again." >&2
    exit 1
fi
exit 0
