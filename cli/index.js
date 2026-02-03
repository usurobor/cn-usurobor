#!/usr/bin/env node

// cn-agent-setup CLI
// Bootstraps a cn-agent-based GH-CN hub on an OpenClaw host.
//
// Intended usage on the host:
//   npx @usurobor/cn-agent-setup
//
// This script:
//   1. Ensures /root/.openclaw/workspace exists.
//   2. Clones or updates https://github.com/usurobor/cn-agent into /root/.openclaw/workspace/cn-agent.
//   3. Runs setup_0.1.2.sh from that clone (interactive gh-based flow).

const { spawn } = require('child_process');
const path = require('path');
const fs = require('fs');

const WORKSPACE_ROOT = '/root/.openclaw/workspace';
const CN_AGENT_REPO = 'https://github.com/usurobor/cn-agent.git';
const CN_AGENT_DIR = path.join(WORKSPACE_ROOT, 'cn-agent');
const SETUP_SCRIPT = 'setup_0.1.2.sh';

function run(cmd, args, options = {}) {
  return new Promise((resolve, reject) => {
    const child = spawn(cmd, args, { stdio: 'inherit', ...options });
    child.on('exit', (code) => {
      if (code === 0) resolve();
      else reject(new Error(`${cmd} ${args.join(' ')} exited with code ${code}`));
    });
    child.on('error', reject);
  });
}

(async () => {
  try {
    console.log(`cn-agent-setup: workspace root ${WORKSPACE_ROOT}`);

    // 1. Ensure workspace root exists
    if (!fs.existsSync(WORKSPACE_ROOT)) {
      console.error(`Error: expected OpenClaw workspace at ${WORKSPACE_ROOT} not found.`);
      console.error('Create that directory on the host (or adjust WORKSPACE_ROOT in the CLI) and re-run.');
      process.exit(1);
    }

    // 2. Clone or update cn-agent
    if (!fs.existsSync(path.join(CN_AGENT_DIR, '.git'))) {
      console.log(`Cloning cn-agent into ${CN_AGENT_DIR} ...`);
      await run('git', ['clone', CN_AGENT_REPO, CN_AGENT_DIR], { cwd: WORKSPACE_ROOT });
    } else {
      console.log(`Found existing cn-agent clone at ${CN_AGENT_DIR}, pulling latest ...`);
      await run('git', ['pull', '--ff-only'], { cwd: CN_AGENT_DIR });
    }

    // 3. Ensure setup script exists and is executable
    const setupPath = path.join(CN_AGENT_DIR, SETUP_SCRIPT);
    if (!fs.existsSync(setupPath)) {
      console.error(`Error: expected ${SETUP_SCRIPT} in ${CN_AGENT_DIR} but it was not found.`);
      console.error('Make sure cn-agent repo is up to date and contains the versioned setup script.');
      process.exit(1);
    }
    fs.chmodSync(setupPath, 0o755);

    console.log(`Running ${SETUP_SCRIPT} ...`);
    await run(setupPath, [], { cwd: CN_AGENT_DIR });

  } catch (err) {
    console.error('cn-agent-setup failed:', err.message || err);
    process.exit(1);
  }
})();
