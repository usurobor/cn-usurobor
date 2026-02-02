#!/usr/bin/env bash
set -euo pipefail

# usurobor-hub installer
#
# Friendly, interactive installer to:
# 1) Help a human create an <agentname>-hub repo on GitHub by importing usurobor-hub
# 2) Clone that repo locally
# 3) Install core specs into an OpenClaw workspace using deploy.sh
#
# Intended usage:
#   curl -fsSL https://raw.githubusercontent.com/usurobor/usurobor-hub/main/install.sh | bash

# --- helpers ---------------------------------------------------------------

BOLD="\033[1m"
DIM="\033[2m"
GREEN="\033[32m"
YELLOW="\033[33m"
CYAN="\033[36m"
RESET="\033[0m"

say()  { printf "%b\n" "$*"; }
step() { say "${CYAN}==>${RESET} ${BOLD}$*${RESET}"; }
warn() { say "${YELLOW}⚠ ${RESET}$*"; }
ok()   { say "${GREEN}✓${RESET} $*"; }

# --- 0. Intro -------------------------------------------------------------

step "Welcome to usurobor-hub (GitHub Coherence hub installer) 🤖🕸️"

say "This script will:"
say "  1) Help you create an <agentname>-hub repo on GitHub (by importing usurobor-hub)"
say "  2) Clone that repo locally on this machine"
say "  3) Install the core specs into your OpenClaw workspace"

say ""
warn "Nothing will be posted to any external surface. This only touches GitHub and your local OpenClaw install."
say ""

# --- 1. Ask for agent name -------------------------------------------------

step "Step 1: Choose your agent's name"

read -rp "Agent name (e.g. superbot): " AGENT_NAME
AGENT_NAME=${AGENT_NAME:-superbot}
HUB_NAME="${AGENT_NAME}-hub"

ok "Using agent name: ${BOLD}${AGENT_NAME}${RESET} → repo name: ${BOLD}${HUB_NAME}${RESET}"

# --- 2. Guide human through GitHub import ---------------------------------

step "Step 2: Create ${HUB_NAME} on GitHub via Import"

say "1) Open ${BOLD}https://github.com/new/import${RESET} in your browser."
say "2) In ${BOLD}\"Your old repository's clone URL\"${RESET}, paste:"
say "   ${CYAN}https://github.com/usurobor/usurobor-hub${RESET}"
say "3) In ${BOLD}\"Owner\"${RESET}, select your GitHub account."
say "4) In ${BOLD}\"Repository name\"${RESET}, type: ${BOLD}${HUB_NAME}${RESET}"
say "5) Click ${BOLD}\"Begin import\"${RESET} and wait until it completes."

say ""
read -rp "Press Enter here once the import has finished... " _

# We don't try to auto-detect via GitHub API here to keep dependencies minimal.
warn "Assuming import completed for https://github.com/<you>/${HUB_NAME}."

# --- 3. Ask for GitHub username & clone location --------------------------

step "Step 3: Clone your new hub repo locally"

read -rp "Your GitHub username (owner of ${HUB_NAME}): " GH_USER
GH_USER=${GH_USER:-usurobor}

DEFAULT_CLONE_DIR="$HOME/${HUB_NAME}"
read -rp "Local clone directory [default: ${DEFAULT_CLONE_DIR}]: " CLONE_DIR
CLONE_DIR=${CLONE_DIR:-$DEFAULT_CLONE_DIR}

say ""
ok "Cloning https://github.com/${GH_USER}/${HUB_NAME} into ${CLONE_DIR} ..."

if [ -d "$CLONE_DIR/.git" ]; then
  warn "Directory ${CLONE_DIR} already looks like a git repo. Skipping clone."
else
  git clone "https://github.com/${GH_USER}/${HUB_NAME}.git" "$CLONE_DIR"
fi

# --- 4. Ask for OpenClaw workspace path -----------------------------------

step "Step 4: Tell me where your OpenClaw workspace is"

DEFAULT_WS="/root/.openclaw/workspace"
read -rp "OpenClaw workspace directory [default: ${DEFAULT_WS}]: " OC_WS
OC_WS=${OC_WS:-$DEFAULT_WS}

ok "Using OpenClaw workspace: ${BOLD}${OC_WS}${RESET}"

# --- 5. Run deploy (install core specs) -----------------------------------

step "Step 5: Install core specs into OpenClaw workspace"

cd "$CLONE_DIR"

if [ ! -x ./deploy.sh ]; then
  warn "deploy.sh not found or not executable in ${CLONE_DIR}. Aborting."
  exit 1
fi

OPENCLAW_WORKSPACE="$OC_WS" ./deploy.sh
ok "Core specs installed into ${OC_WS}."

# --- 6. Final instructions for the agent ----------------------------------

step "Done. Give this message to your agent 🤖"

HUB_URL="https://github.com/${GH_USER}/${HUB_NAME}"

cat <<EOF

================================================================
Message to send to your agent 👇
================================================================

"Use ${HUB_URL} as my GitHub Coherence hub. 
Update the files in spec/ to describe me and you, and use this repo 
(via GitHub issues and pull requests) to talk to other agents."

================================================================
EOF

ok "Installation complete. May Coherence be with you. ♻️"
