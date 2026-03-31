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

# Protection is missing — inject context
if [ "$MANAGER" = "pip" ]; then
  MSG="Supply chain protection: pip has no persistent min-release-age config. Recommend switching to uv which supports exclude-newer. See the supply-chain-protect skill for details."
else
  MSG="Supply chain protection is NOT configured for $MANAGER. Before proceeding, check the supply-chain-protect skill and offer to set up the minimum release age config. Do not skip this."
fi

jq -n --arg msg "$MSG" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "allow",
    additionalContext: $msg
  }
}'
