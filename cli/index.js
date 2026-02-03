#!/usr/bin/env node

// cn-agent-setup CLI
// Clones or updates the cn-agent TEMPLATE on an OpenClaw host and prints the self-cohere cue.
// The template is NOT the hub — the agent creates a separate hub repo via self-cohere.
//
// Intended usage on the host:
//   npx @usurobor/cn-agent-setup
//
// This script:
//   1. Ensures /root/.openclaw/workspace exists.
//   2. Clones or updates https://github.com/usurobor/cn-agent (template) into /root/.openclaw/workspace/cn-agent.
//   3. Prints the cue for the human to paste into their agent's chat.

const { spawn } = require('child_process');
const path = require('path');
const fs = require('fs');

const VERSION = require('../package.json').version;

// Simple ANSI helpers (only used for human-facing cue)
const cyan = (str) => `\x1b[36m${str}\x1b[0m`;
const bold = (str) => `\x1b[1m${str}\x1b[0m`;

// --help / --version
const arg = process.argv[2];
if (arg === '--help' || arg === '-h') {
  console.log(`cn-agent-setup v${VERSION}`);
  console.log('');
  console.log('Clone or update cn-agent on an OpenClaw host and print the self-cohere cue.');
  console.log('');
  console.log('Usage: npx @usurobor/cn-agent-setup');
  console.log('');
  console.log('Options:');
  console.log('  --help, -h       Show this help message');
  console.log('  --version, -v    Show version number');
  process.exit(0);
}
if (arg === '--version' || arg === '-v') {
  console.log(VERSION);
  process.exit(0);
}

const WORKSPACE_ROOT = '/root/.openclaw/workspace';
const CN_AGENT_REPO = 'https://github.com/usurobor/cn-agent.git';
const CN_AGENT_DIR = path.join(WORKSPACE_ROOT, 'cn-agent');

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

    // 3. Hand off to the cn-agent self-cohere flow
    console.log('');
    console.log(cyan('============================================================'));
    console.log(cyan('  Template ready. Now tell your agent to cohere.'));
    console.log(cyan('============================================================'));
    console.log('');
    console.log('Paste this into your agent\'s chat:');
    console.log('');
    console.log('  ' + bold('Cohere as https://github.com/usurobor/cn-agent'));
    console.log('');
    console.log('Your agent will read the template at ' + CN_AGENT_DIR);
    console.log('and create a separate hub repo (cn-<agentname>) for its identity and state.');
    console.log('');

  } catch (err) {
    console.error('cn-agent-setup failed:', err.message || err);
    process.exit(1);
  }
})();
