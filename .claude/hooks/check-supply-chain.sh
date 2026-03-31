#!/usr/bin/env bash
# PreToolUse hook: checks if supply chain protection is configured
# before package manager commands run.
#
# Input: JSON on stdin with tool_input.command
# Output: JSON with additionalContext if protection is missing
#         Silent exit 0 if protection is set or command isn't a package manager

set -euo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

[ -z "$COMMAND" ] && exit 0

CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
[ -z "$CWD" ] && CWD="."

# Detect which package manager command is being run
MANAGER=""
case "$COMMAND" in
  npm\ install*|npm\ i\ *|npm\ add*|npm\ update*|npm\ ci*) MANAGER="npm" ;;
  npx\ *) MANAGER="npm" ;;
  yarn\ add*|yarn\ install*) MANAGER="yarn" ;;
  pnpm\ add*|pnpm\ install*|pnpm\ i\ *|pnpm\ update*) MANAGER="pnpm" ;;
  bun\ add*|bun\ install*|bun\ i\ *|bun\ update*) MANAGER="bun" ;;
  bunx\ *) MANAGER="bun" ;;
  uv\ add*|uv\ pip\ install*|uv\ sync*|uv\ lock*) MANAGER="uv" ;;
  pip\ install*|pip3\ install*) MANAGER="pip" ;;
  *) exit 0 ;;
esac

# Check if protection is configured
check_npm() {
  grep -q "min-release-age" "$CWD/.npmrc" 2>/dev/null && return 0
  grep -q "min-release-age" "$HOME/.npmrc" 2>/dev/null && return 0
  return 1
}

check_yarn() {
  grep -q "npmMinimalAgeGate" "$CWD/.yarnrc.yml" 2>/dev/null && return 0
  return 1
}

check_pnpm() {
  grep -q "minimumReleaseAge" "$CWD/pnpm-workspace.yaml" 2>/dev/null && return 0
  return 1
}

check_bun() {
  grep -q "minimumReleaseAge" "$CWD/bunfig.toml" 2>/dev/null && return 0
  grep -q "minimumReleaseAge" "${XDG_CONFIG_HOME:-$HOME}/.bunfig.toml" 2>/dev/null && return 0
  return 1
}

check_uv() {
  grep -q "exclude-newer" "$CWD/pyproject.toml" 2>/dev/null && return 0
  grep -q "exclude-newer" "$CWD/uv.toml" 2>/dev/null && return 0
  grep -q "exclude-newer" "${XDG_CONFIG_HOME:-$HOME/.config}/uv/uv.toml" 2>/dev/null && return 0
  return 1
}

check_pip() {
  # pip has no persistent config for this — always warn, recommend uv
  return 1
}

PROTECTED=false
case "$MANAGER" in
  npm)  check_npm  && PROTECTED=true ;;
  yarn) check_yarn && PROTECTED=true ;;
  pnpm) check_pnpm && PROTECTED=true ;;
  bun)  check_bun  && PROTECTED=true ;;
  uv)   check_uv   && PROTECTED=true ;;
  pip)  PROTECTED=false ;;
esac

if [ "$PROTECTED" = "true" ]; then
  exit 0
fi

# Protection is missing — inject context with inline fix
case "$MANAGER" in
  npm)
    MSG="Supply chain protection is NOT configured for npm. Before proceeding, offer to add min-release-age=7 to the project .npmrc file (or ~/.npmrc for global). This rejects packages published less than 7 days ago." ;;
  yarn)
    MSG="Supply chain protection is NOT configured for Yarn. Before proceeding, offer to add npmMinimalAgeGate: 7d to .yarnrc.yml. This rejects packages published less than 7 days ago." ;;
  pnpm)
    MSG="Supply chain protection is NOT configured for pnpm. Before proceeding, offer to add minimumReleaseAge: 10080 to pnpm-workspace.yaml (value is in minutes, 10080 = 7 days). This rejects packages published less than 7 days ago." ;;
  bun)
    MSG="Supply chain protection is NOT configured for Bun. Before proceeding, offer to create/update bunfig.toml with [install] section containing minimumReleaseAge = 604800 (value is in seconds, 604800 = 7 days). This rejects packages published less than 7 days ago. Requires Bun v1.3.0+." ;;
  uv)
    MSG="Supply chain protection is NOT configured for uv. Before proceeding, offer to add exclude-newer = \"7 days\" under [tool.uv] in pyproject.toml (or in ~/.config/uv/uv.toml for global). This rejects packages published less than 7 days ago." ;;
  pip)
    MSG="Supply chain protection: pip has no persistent min-release-age config. Recommend switching to uv which supports exclude-newer = \"7 days\" in pyproject.toml." ;;
esac

jq -n --arg msg "$MSG" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "allow",
    additionalContext: $msg
  }
}'
