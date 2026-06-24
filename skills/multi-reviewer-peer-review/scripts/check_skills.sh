#!/usr/bin/env bash
# check_skills.sh — verify every skill required by multi-reviewer-peer-review
# is installed under a known Agent Skills root.
#
# Usage:
#   bash scripts/check_skills.sh
#   SKILLS_EXTRA_PATHS="/abs/path/one:/abs/path/two" bash scripts/check_skills.sh
#
# A skill "resolves" if a directory named <skill> containing SKILL.md (or
# skill.md) exists directly under any skills root, OR (for repos that keep a
# nested layout) one level deeper under any root.
#
# Exit codes: 0 = all found; 1 = one or more missing; 2 = usage/internal error.

set -uo pipefail

# --- required skills (bare names; namespace prefix is stripped) -------------
REQUIRED_SKILLS=(
  "superpowers:dispatching-parallel-agents"
  "superpowers:subagent-driven-development"
  "superpowers:requesting-code-review"
  "scientific-agent-skills:peer-review"
  "scientific-agent-skills:markitdown"
  "scientific-agent-skills:pdf"
  "scientific-agent-skills:literature-review"
  "scientific-agent-skills:citation-management"
  "scientific-agent-skills:scientific-writing"
  "scientific-agent-skills:research-grants"
  "scientific-agent-skills:venue-templates"
)

# --- candidate skills roots, in priority order -----------------------------
ROOTS=(
  "$PWD/.claude/skills"
  "$PWD/.agents/skills"
  "$PWD/.codex/skills"
  "$HOME/.claude/skills"
  "$HOME/.codex/skills"
  "$HOME/.openclaw/skills"
  "$HOME/.gemini/config/skills"
  "$HOME/.agents/skills"
)

# Append colon-separated extra roots supplied by the user/orchestrator.
if [[ -n "${SKILLS_EXTRA_PATHS:-}" ]]; then
  IFS=':' read -r -a EXTRA <<< "${SKILLS_EXTRA_PATHS}"
  for p in "${EXTRA[@]}"; do
    [[ -n "$p" ]] && ROOTS+=("$p")
  done
fi

has_skill_md() {
  # $1 = candidate directory; true if it contains SKILL.md (case-insensitive)
  local d="$1"
  [[ -f "$d/SKILL.md" || -f "$d/skill.md" || -f "$d/Skill.md" ]]
}

resolve_skill() {
  # $1 = bare skill name; echoes the resolved path and returns 0 if found.
  local name="$1" root hit
  for root in "${ROOTS[@]}"; do
    [[ -d "$root" ]] || continue
    # direct: <root>/<name>/SKILL.md
    if [[ -d "$root/$name" ]] && has_skill_md "$root/$name"; then
      echo "$root/$name"; return 0
    fi
    # nested one level: <root>/*/<name>/SKILL.md  (e.g. repo-name/<name>)
    for hit in "$root"/*/"$name"; do
      if [[ -d "$hit" ]] && has_skill_md "$hit"; then
        echo "$hit"; return 0
      fi
    done
  done
  return 1
}

echo "Scanning skills roots:"
for root in "${ROOTS[@]}"; do
  if [[ -d "$root" ]]; then echo "  [ok]   $root"; else echo "  [skip] $root (absent)"; fi
done
echo

missing=()
for dep in "${REQUIRED_SKILLS[@]}"; do
  bare="${dep##*:}"          # strip namespace prefix
  if path="$(resolve_skill "$bare")"; then
    printf '  FOUND    %-55s -> %s\n' "$dep" "$path"
  else
    printf '  MISSING  %-55s\n' "$dep"
    missing+=("$dep")
  fi
done
echo

if [[ ${#missing[@]} -eq 0 ]]; then
  echo "ALL SKILLS FOUND"
  exit 0
fi

echo "MISSING ${#missing[@]} SKILL(S):"
for m in "${missing[@]}"; do
  echo "  - $m"
done
cat <<'EOF'

ACTION REQUIRED — point the orchestrator to a local install for each missing
skill, then re-run with the extra path(s):

  SKILLS_EXTRA_PATHS="/abs/path/to/skills_root:/another/root" bash scripts/check_skills.sh

Or install them, e.g.:
  gh skill install K-Dense-AI/scientific-agent-skills <name>     # scientific-agent-skills:*
  git clone https://github.com/obra/superpowers ~/.claude/skills/superpowers-src   # superpowers:*

Or explicitly authorize proceeding without a given skill (degraded review).
EOF
exit 1