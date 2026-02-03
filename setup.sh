#!/usr/bin/env bash
set -euo pipefail

# setup.sh
#
# Bootstrap a cn-agent-based GH-CN hub repo for your agent.
#
# Canonical human usage (on the OpenClaw host):
#   curl -fsSL https://raw.githubusercontent.com/usurobor/cn-agent/master/setup.sh | bash
#
# This script:
#   1. Ensures a local clone of cn-agent exists under /root/.openclaw/workspace/cn-agent.
#   2. Enters that clone.
#   3. Interactively asks for GitHub owner, hub name, and visibility.
#   4. Verifies that `gh` is installed and authenticated.
#   5. Creates (or reuses) OWNER/HUB_NAME on GitHub.
#   6. Pushes the current template tree into that repo.

RED="\033[31m"; GREEN="\033[32m"; YELLOW="\033[33m"; RESET="\033[0m"

WORKSPACE_ROOT="/root/.openclaw/workspace"
CN_AGENT_DIR="${WORKSPACE_ROOT}/cn-agent"

# 0. Ensure workspace root exists
if [[ ! -d "$WORKSPACE_ROOT" ]]; then
  echo -e "${RED}Error:${RESET} Expected OpenClaw workspace at ${WORKSPACE_ROOT} not found."
  echo "Create that directory or adjust WORKSPACE_ROOT in setup.sh before re-running."
  exit 1
fi

cd "$WORKSPACE_ROOT"

echo -e "${GREEN}cn-agent setup (workspace: ${WORKSPACE_ROOT})${RESET}"

# 1. Ensure we have a cn-agent clone
if [[ -d "$CN_AGENT_DIR/.git" ]]; then
  echo -e "${YELLOW}Found existing cn-agent clone at ${CN_AGENT_DIR}.${RESET}"
else
  echo -e "${GREEN}Cloning cn-agent into ${CN_AGENT_DIR}...${RESET}"
  git clone https://github.com/usurobor/cn-agent.git "$CN_AGENT_DIR"
fi

cd "$CN_AGENT_DIR"

# 2. Verify this is a git repo
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo -e "${RED}Error:${RESET} ${CN_AGENT_DIR} is not a valid git repository."
  exit 1
fi

# 3. Check for gh
if ! command -v gh >/dev/null 2>&1; then
  echo -e "${RED}Error:${RESET} GitHub CLI 'gh' is not installed or not on PATH."
  echo "Install gh from https://cli.github.com/ and run 'gh auth login' as your GitHub user, then re-run this script."
  exit 1
fi

# 4. Check gh auth
if ! gh auth status >/dev/null 2>&1; then
  echo -e "${RED}Error:${RESET} 'gh' is installed but not authenticated."
  echo "Run 'gh auth login' and follow the prompts, then re-run this script."
  exit 1
fi

# 5. Ask for owner (default from gh api user)
DEFAULT_OWNER="$(gh api user --jq '.login' 2>/dev/null || echo '')"
read -rp "GitHub owner (user or org) [${DEFAULT_OWNER}]: " HUB_OWNER
HUB_OWNER="${HUB_OWNER:-$DEFAULT_OWNER}"

if [[ -z "$HUB_OWNER" ]]; then
  echo -e "${RED}Error:${RESET} GitHub owner cannot be empty."
  exit 1
fi

# 6. Suggest hub name based on directory or agent name hint
DEFAULT_NAME="cn-$(basename "$(pwd)")"
read -rp "Hub repo name [${DEFAULT_NAME}]: " HUB_NAME
HUB_NAME="${HUB_NAME:-$DEFAULT_NAME}"

if [[ -z "$HUB_NAME" ]]; then
  echo -e "${RED}Error:${RESET} Hub repo name cannot be empty."
  exit 1
fi

# 7. Visibility
read -rp "Visibility (public/private) [public]: " HUB_VISIBILITY
HUB_VISIBILITY="${HUB_VISIBILITY:-public}"

case "$HUB_VISIBILITY" in
  public|private) ;;
  *) echo -e "${RED}Error:${RESET} Visibility must be 'public' or 'private'."; exit 1 ;;
esac

HUB_REPO="${HUB_OWNER}/${HUB_NAME}"
HUB_URL="https://github.com/${HUB_REPO}"

echo
echo -e "${YELLOW}About to set up GH-CN hub:${RESET}"
echo "  Owner:      $HUB_OWNER"
echo "  Repo name:  $HUB_NAME"
echo "  Visibility: $HUB_VISIBILITY"
echo "  Full repo:  $HUB_URL"
echo
read -rp "Proceed? [y/N]: " CONFIRM
CONFIRM="${CONFIRM:-N}"
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo "Aborted by user. No changes made."
  exit 0
fi

# 8. Create or reuse repo
if gh repo view "$HUB_REPO" >/dev/null 2>&1; then
  echo -e "${YELLOW}Repo ${HUB_REPO} already exists. Will push current template into it.${RESET}"
else
  echo -e "${GREEN}Creating repo ${HUB_REPO} via gh...${RESET}"
  gh repo create "$HUB_REPO" \
    --"$HUB_VISIBILITY" \
    --source . \
    --push
  echo -e "${GREEN}Created and pushed ${HUB_URL}.${RESET}"
  echo
  echo -e "${GREEN}Done.${RESET} Your GH-CN hub is at: ${HUB_URL}"
  echo "Tell your agent:"
  echo
  printf '  Use %s as your GitHub Coherence hub.\n' "$HUB_URL"
  echo "  Keep your specs, threads, and state in that repo."
  exit 0
fi

# 9. Re-point origin (if necessary) and push
if git remote get-url origin >/dev/null 2>&1; then
  git remote set-url origin "git@github.com:${HUB_REPO}.git" || git remote set-url origin "$HUB_URL"
else
  git remote add origin "git@github.com:${HUB_REPO}.git" || git remote add origin "$HUB_URL"
fi

echo -e "${GREEN}Pushing current branch to ${HUB_REPO}...${RESET}"
if git push -u origin HEAD:main 2>/dev/null; then
  :
elif git push -u origin HEAD:master 2>/dev/null; then
  :
else
  echo -e "${RED}Error:${RESET} failed to push to ${HUB_REPO}. Check your permissions and branch name."
  exit 1
fi

echo
echo -e "${GREEN}Done.${RESET} Your GH-CN hub is at: ${HUB_URL}"
echo "Tell your agent:"
echo
printf '  Use %s as your GitHub Coherence hub.\n' "$HUB_URL"
echo "  Keep your specs, threads, and state in that repo."
