#!/usr/bin/env bash
set -euo pipefail

# cn-usurobor installer
#
# Friendly, interactive installer to:
# 1) Help a human create a cn-<agentname> repo on GitHub by importing cn-usurobor
# 2) Clone that repo locally
# 3) Run initial setup to install core specs into an OpenClaw workspace
#
# Intended usage:
#   curl -fsSL https://raw.githubusercontent.com/usurobor/cn-usurobor/main/install.sh | bash

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

step "Welcome to cn-usurobor (Coherence Network repo installer)"

say "This script will:"
say "  1) Help you create a cn-<agentname> repo on GitHub (by importing cn-usurobor)"
say "  2) Clone that repo locally on this machine"
say "  3) Run initial setup to install core specs into your OpenClaw workspace"

say ""
warn "Nothing will be posted to any external surface. This only touches GitHub and your local OpenClaw install."
say ""

# 1. Agent name ------------------------------------------------------------

step "Step 1: Choose your agent's name"

read -rp "Agent name (e.g. superbot): " AGENT_NAME
AGENT_NAME=${AGENT_NAME:-superbot}
CN_NAME="cn-${AGENT_NAME}"

ok "Using agent name: ${BOLD}${AGENT_NAME}${RESET} → repo name: ${BOLD}${CN_NAME}${RESET}"

# 2. GitHub import ---------------------------------------------------------

step "Step 2: Create ${CN_NAME} on GitHub via Import"

say "1) Open ${BOLD}https://github.com/new/import${RESET} in your browser."
say "2) In ${BOLD}\"Your old repository's clone URL\"${RESET}, paste:"
say "   ${CYAN}https://github.com/usurobor/cn-usurobor${RESET}"
say "3) In ${BOLD}\"Owner\"${RESET}, select your GitHub account."
say "4) In ${BOLD}\"Repository name\"${RESET}, type: ${BOLD}${CN_NAME}${RESET}"
say "5) Click ${BOLD}\"Begin import\"${RESET} and wait until it completes."

say ""
read -rp "Press Enter here once the import has finished... " _

warn "Assuming import completed for https://github.com/<you>/${CN_NAME}."

# 3. Clone CN repo ---------------------------------------------------------

step "Step 3: Clone your CN repo locally"

read -rp "Your GitHub username (owner of ${CN_NAME}): " GH_USER
GH_USER=${GH_USER:-usurobor}

DEFAULT_CLONE_DIR="$HOME/${CN_NAME}"
read -rp "Local clone directory [default: ${DEFAULT_CLONE_DIR}]: " CLONE_DIR
CLONE_DIR=${CLONE_DIR:-$DEFAULT_CLONE_DIR}

say ""
ok "Cloning https://github.com/${GH_USER}/${CN_NAME} into ${CLONE_DIR} ..."

if [ -d "$CLONE_DIR/.git" ]; then
  warn "Directory ${CLONE_DIR} already looks like a git repo. Skipping clone."
else
  git clone "https://github.com/${GH_USER}/${CN_NAME}.git" "$CLONE_DIR"
fi

# 4. Ask for OpenClaw workspace -------------------------------------------

step "Step 4: Tell me where your OpenClaw workspace is"

DEFAULT_WS="/root/.openclaw/workspace"
read -rp "OpenClaw workspace directory [default: ${DEFAULT_WS}]: " OC_WS
OC_WS=${OC_WS:-$DEFAULT_WS}

ok "Using OpenClaw workspace: ${BOLD}${OC_WS}${RESET}"

# 5. Initial setup ---------------------------------------------------------

step "Step 5: Run initial setup (install core specs)"

cd "$CLONE_DIR"

if [ ! -x ./setup.sh ]; then
  warn "setup.sh not found or not executable in ${CLONE_DIR}. Aborting."
  exit 1
fi

OPENCLAW_WORKSPACE="$OC_WS" ./setup.sh
ok "Core specs installed into ${OC_WS}."

# 6. Final instructions for the agent -------------------------------------

step "Done. Give this message to your agent 🤖"

CN_URL="https://github.com/${GH_USER}/${CN_NAME}"

cat <<EOF

================================================================
Message to send to your agent 👇
================================================================

"Use ${CN_URL} as my Coherence Network repo (CN repo).
Treat spec/core/*.md in that repo as your self-spec files.
When I update them, I will re-run ./setup.sh on the server so
your runtime matches the CN repo."

================================================================
EOF

ok "Installation complete. May Coherence be with you. ♻️"
