#!/usr/bin/env bash
# SessionStart hook - reads using-superpowers from skills.sh managed location
set -euo pipefail

SKILL_FILE="${HOME}/.agents/skills/using-superpowers/SKILL.md"

if [ ! -f "$SKILL_FILE" ]; then
    echo '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"Warning: using-superpowers skill not found at ~/.agents/skills/using-superpowers/SKILL.md"}}'
    exit 0
fi

using_superpowers_content=$(cat "$SKILL_FILE" 2>&1)

escape_for_json() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"
    s="${s//$'\r'/\\r}"
    s="${s//$'\t'/\\t}"
    printf '%s' "$s"
}

using_superpowers_escaped=$(escape_for_json "$using_superpowers_content")

cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "<EXTREMELY_IMPORTANT>\nYou have superpowers.\n\n**Below is the full content of your 'superpowers:using-superpowers' skill - your introduction to using skills. For all other skills, use the 'Skill' tool:**\n\n${using_superpowers_escaped}\n\n\n</EXTREMELY_IMPORTANT>"
  }
}
EOF

exit 0
