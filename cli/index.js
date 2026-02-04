#!/usr/bin/env node

// cn-agent-setup CLI
// Sets up a complete cn-agent workspace: template + personal hub.
//
// Intended usage on the host:
//   npx --yes @usurobor/cn-agent-setup
//
// This script:
//   1. Ensures workspace exists (CN_WORKSPACE env var, or /root/.openclaw/workspace).
//   2. Clones or updates the cn-agent template into workspace/cn-agent.
//   3. Prompts the human for agent name, GitHub owner, and visibility.
//   4. Creates a hub directory (cn-<agentname>) with personal spec files.
//   5. Creates the GitHub repo via `gh` and pushes the hub.
//   6. Prints the "Cohere as <hub-url>" cue for the human to paste into their agent.

const { spawn, spawnSync } = require('child_process');
const path = require('path');
const fs = require('fs');
const readline = require('readline');

const VERSION = require('../package.json').version;
const { sanitizeName } = require('./sanitize');
const { buildHubConfig } = require('./hubConfig');

// Simple ANSI helpers (only used for human-facing output)
const cyan = (str) => `\x1b[36m${str}\x1b[0m`;
const bold = (str) => `\x1b[1m${str}\x1b[0m`;
const green = (str) => `\x1b[32m${str}\x1b[0m`;

// --help / --version
const arg = process.argv[2];
if (arg === '--help' || arg === '-h') {
  console.log(`cn-agent-setup v${VERSION}`);
  console.log('');
  console.log('Set up a cn-agent workspace: clone the template, create a personal hub repo,');
  console.log('and print the cohere cue for your agent.');
  console.log('');
  console.log('Usage: npx --yes @usurobor/cn-agent-setup');
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

const WORKSPACE_ROOT = process.env.CN_WORKSPACE || '/root/.openclaw/workspace';
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

function runCapture(cmd, args, options = {}) {
  const result = spawnSync(cmd, args, { encoding: 'utf8', ...options });
  return (result.stdout || '').trim();
}

function ask(rl, question) {
  return new Promise((resolve) => {
    rl.question(question, (answer) => resolve(answer.trim()));
  });
}

(async () => {
  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });

  try {
    console.log(`cn-agent-setup v${VERSION}`);
    console.log('');

    // 1. Ensure workspace root exists
    if (!fs.existsSync(WORKSPACE_ROOT)) {
      console.error(`Error: expected OpenClaw workspace at ${WORKSPACE_ROOT} not found.`);
      console.error('Create that directory, or set CN_WORKSPACE env var to your workspace path.');
      process.exit(1);
    }

    // 1b. Ensure git identity is configured
    let gitName = runCapture('git', ['config', 'user.name']);
    let gitEmail = runCapture('git', ['config', 'user.email']);

    if (!gitName) {
      gitName = await ask(rl, '  git user.name (for commits, e.g. "usurobor"): ');
    }
    if (!gitEmail) {
      gitEmail = await ask(rl, '  git user.email (for commits): ');
    }

    if (!gitName || !gitEmail) {
      console.error('Error: git user.name and user.email are required for commits.');
      process.exit(1);
    }

    if (!runCapture('git', ['config', 'user.name'])) {
      await run('git', ['config', '--global', 'user.name', gitName]);
    }
    if (!runCapture('git', ['config', 'user.email'])) {
      await run('git', ['config', '--global', 'user.email', gitEmail]);
    }

    // 1c. Ensure GitHub CLI is installed and authenticated
    const ghVersion = runCapture('gh', ['--version']);
    if (!ghVersion) {
      console.error('Error: GitHub CLI (gh) is not installed or not on PATH.');
      console.error('Install gh, then run: gh auth login');
      process.exit(1);
    }
    const ghUser = runCapture('gh', ['api', 'user', '--jq', '.login']);
    if (!ghUser) {
      console.error('Error: gh is installed but not authenticated.');
      console.error('Run: gh auth login');
      process.exit(1);
    }

    // 2. Clone or update cn-agent template
    console.log('Step 1: Template');
    if (!fs.existsSync(path.join(CN_AGENT_DIR, '.git'))) {
      console.log(`  Cloning cn-agent template into ${CN_AGENT_DIR} ...`);
      await run('git', ['clone', CN_AGENT_REPO, CN_AGENT_DIR], { cwd: WORKSPACE_ROOT });
    } else {
      console.log(`  Updating cn-agent template at ${CN_AGENT_DIR} ...`);
      try {
        await run('git', ['pull', '--ff-only'], { cwd: CN_AGENT_DIR });
      } catch (e) {
        console.log('  Warning: could not fast-forward update for cn-agent (local commits or diverged history).');
        console.log('  Continuing with the existing template clone.');
        console.log('  To inspect/fix:');
        console.log(`    cd ${CN_AGENT_DIR} && git status`);
        console.log('    # then either rebase/merge your local changes, or');
        console.log('    # reset to origin if you do not need them.');
      }
    }
    console.log('');

    // 3. Prompt for hub details
    console.log('Step 2: Create your agent\'s hub');
    console.log('');

    // Agent name
    const agentName = await ask(rl, '  Agent name (e.g. Sigma, Nova, Echo, Onyx): ');
    const nameResult = sanitizeName(agentName);
    if (!nameResult.valid) {
      console.error(`Error: ${nameResult.error}.`);
      process.exit(1);
    }
    let sanitizedAgentName = nameResult.name;

    // GitHub owner
    const inferredOwner = runCapture('gh', ['api', 'user', '--jq', '.login']);
    const defaultOwner = inferredOwner || '';
    const ownerPrompt = defaultOwner
      ? `  GitHub owner [${defaultOwner}]: `
      : '  GitHub owner (username or org): ';
    const ownerInput = await ask(rl, ownerPrompt);
    const hubOwner = ownerInput || defaultOwner;
    if (!hubOwner) {
      console.error('Error: GitHub owner is required. Make sure `gh auth login` is done.');
      process.exit(1);
    }

    // Visibility
    const visInput = await ask(rl, '  Visibility (public/private) [public]: ');
    const hubVisibility = (visInput === 'private') ? 'private' : 'public';

    // Build hub configuration
    let config = buildHubConfig(sanitizedAgentName, hubOwner, WORKSPACE_ROOT);
    let { hubName, hubRepo, hubUrl, hubDir } = config;

    // Confirm
    console.log('');
    console.log(`  Will create: ${bold(hubUrl)} (${hubVisibility})`);
    console.log(`  Local path:  ${hubDir}`);
    const confirm = await ask(rl, '  Good to go? (y/N): ');
    if (!confirm.match(/^y(es)?$/i)) {
      console.log('Aborted.');
      process.exit(0);
    }
    console.log('');

    // 4. Create hub directory with personal files
    console.log('Step 3: Scaffolding hub');

    if (fs.existsSync(hubDir)) {
      console.log(`  Found existing directory: ${hubDir}`);
      const choice = (await ask(rl, '  [D]elete and recreate, [N]ew name, or [A]bort? [a]: ')).toLowerCase();

      if (choice === 'd') {
        fs.rmSync(hubDir, { recursive: true, force: true });
        console.log(`  Deleted ${hubDir}, recreating...`);
      } else if (choice === 'n') {
        const newAgentName = await ask(rl, '  New agent name: ');
        const newNameResult = sanitizeName(newAgentName);
        if (!newNameResult.valid) {
          console.error(`Error: ${newNameResult.error}.`);
          process.exit(1);
        }
        // Rebuild config with new name
        config = buildHubConfig(newNameResult.name, hubOwner, WORKSPACE_ROOT);
        ({ hubName, hubRepo, hubUrl, hubDir } = config);
        console.log(`  Using new hub: ${hubUrl}`);
      } else {
        console.log('Aborted.');
        process.exit(0);
      }
    }

    fs.mkdirSync(hubDir, { recursive: true });
    fs.mkdirSync(path.join(hubDir, 'spec'), { recursive: true });
    fs.mkdirSync(path.join(hubDir, 'state', 'threads'), { recursive: true });

    // Copy personal spec files from template (not AGENTS.md — that stays in template)
    const specFiles = ['SOUL.md', 'USER.md', 'HEARTBEAT.md', 'TOOLS.md'];
    for (const f of specFiles) {
      const src = path.join(CN_AGENT_DIR, 'spec', f);
      const dst = path.join(hubDir, 'spec', f);
      if (fs.existsSync(src)) {
        fs.copyFileSync(src, dst);
      }
    }

    // Copy state scaffolds
    const peersPath = path.join(CN_AGENT_DIR, 'state', 'peers.md');
    if (fs.existsSync(peersPath)) {
      fs.copyFileSync(peersPath, path.join(hubDir, 'state', 'peers.md'));
    }

    // Write a minimal README
    const readmeContent = `# ${hubName}

git-CN hub for **${agentName}**.

Created from [cn-agent](https://github.com/usurobor/cn-agent) template.
`;
    fs.writeFileSync(path.join(hubDir, 'README.md'), readmeContent);

    console.log('  Created hub directory with spec/, state/, README.md');

    // 5. Git init, commit, create GitHub repo, push
    console.log('');
    console.log('Step 4: Creating GitHub repo');

    await run('git', ['init'], { cwd: hubDir });
    await run('git', ['add', '.'], { cwd: hubDir });
    await run('git', ['commit', '-m', `Bootstrap ${hubName} from cn-agent template`], { cwd: hubDir });

    try {
      await run('gh', ['repo', 'create', hubRepo, `--${hubVisibility}`, '--source', '.', '--push'], { cwd: hubDir });
    } catch (e) {
      // Fallback: repo might already exist
      console.log('  gh repo create failed, trying manual remote...');
      await run('git', ['remote', 'add', 'origin', `git@github.com:${hubRepo}.git`], { cwd: hubDir });
      await run('git', ['push', '-u', 'origin', 'HEAD:main'], { cwd: hubDir });
    }

    // 6. Clean workspace and create symlinks
    console.log('');
    console.log('Step 5: Setting up workspace symlinks');

    // Delete any existing OpenClaw workspace files
    const ocFiles = ['AGENTS.md', 'SOUL.md', 'USER.md', 'HEARTBEAT.md', 'TOOLS.md', 'IDENTITY.md'];
    for (const f of ocFiles) {
      const p = path.join(WORKSPACE_ROOT, f);
      if (fs.existsSync(p)) {
        fs.unlinkSync(p);
      }
    }

    // Create symlinks
    // AGENTS.md -> cn-agent/spec/AGENTS.md (generic rules from template)
    fs.symlinkSync('cn-agent/spec/AGENTS.md', path.join(WORKSPACE_ROOT, 'AGENTS.md'));
    
    // Personal files -> hub/spec/* 
    const hubRelPath = hubName; // e.g., "cn-sigma"
    fs.symlinkSync(`${hubRelPath}/spec/SOUL.md`, path.join(WORKSPACE_ROOT, 'SOUL.md'));
    fs.symlinkSync(`${hubRelPath}/spec/USER.md`, path.join(WORKSPACE_ROOT, 'USER.md'));
    fs.symlinkSync(`${hubRelPath}/spec/HEARTBEAT.md`, path.join(WORKSPACE_ROOT, 'HEARTBEAT.md'));
    fs.symlinkSync(`${hubRelPath}/spec/TOOLS.md`, path.join(WORKSPACE_ROOT, 'TOOLS.md'));

    console.log('  Removed existing OpenClaw workspace files');
    console.log('  Created symlinks: AGENTS.md, SOUL.md, USER.md, HEARTBEAT.md, TOOLS.md');

    // 7. Print success + cohere cue
    console.log('');
    console.log(green('============================================================'));
    console.log(green(`  ✓ Hub created: ${hubUrl}`));
    console.log(green('============================================================'));
    console.log('');
    console.log('Workspace:');
    console.log(`  ${CN_AGENT_DIR}  (template — skills, mindsets, docs)`);
    console.log(`  ${hubDir}  (hub — your agent's identity + state)`);
    console.log('');
    console.log('Symlinks in workspace root point to hub/template files.');
    console.log('');
    console.log('Paste this into your agent\'s chat:');
    console.log('');
    console.log('  ' + bold(`Cohere as ${hubUrl}`));
    console.log('');

  } catch (err) {
    console.error('cn-agent-setup failed:', err.message || err);
    process.exit(1);
  } finally {
    rl.close();
  }
})();
