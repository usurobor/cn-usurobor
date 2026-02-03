#!/usr/bin/env node

// cn-agent-setup CLI
// Sets up a complete cn-agent workspace: template + personal hub.
//
// Intended usage on the host:
//   npx --yes @usurobor/cn-agent-setup
//
// This script:
//   1. Ensures /root/.openclaw/workspace exists.
//   2. Clones or updates the cn-agent template into workspace/cn-agent.
//   3. Prompts the human for agent name, GitHub owner, and visibility.
//   4. Creates a hub directory (cn-<agentname>) with personal files + BOOTSTRAP.md.
//   5. Creates the GitHub repo via `gh` and pushes the hub.
//   6. Prints the "Cohere as <hub-url>" cue for the human to paste into their agent.

const { spawn, spawnSync } = require('child_process');
const path = require('path');
const fs = require('fs');
const readline = require('readline');

const VERSION = require('../package.json').version;

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
      console.error('Create that directory on the host (or adjust WORKSPACE_ROOT in the CLI) and re-run.');
      process.exit(1);
    }

    // 2. Clone or update cn-agent template
    console.log('Step 1: Template');
    if (!fs.existsSync(path.join(CN_AGENT_DIR, '.git'))) {
      console.log(`  Cloning cn-agent template into ${CN_AGENT_DIR} ...`);
      await run('git', ['clone', CN_AGENT_REPO, CN_AGENT_DIR], { cwd: WORKSPACE_ROOT });
    } else {
      console.log(`  Updating cn-agent template at ${CN_AGENT_DIR} ...`);
      await run('git', ['pull', '--ff-only'], { cwd: CN_AGENT_DIR });
    }
    console.log('');

    // 3. Prompt for hub details
    console.log('Step 2: Create your agent\'s hub');
    console.log('');

    // Agent name
    const agentName = await ask(rl, '  Agent name (e.g. Sigma, Nova, Echo, Onyx): ');
    if (!agentName) {
      console.error('Error: agent name is required.');
      process.exit(1);
    }
    const hubName = 'cn-' + agentName.toLowerCase().replace(/\s+/g, '-');

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

    const hubRepo = `${hubOwner}/${hubName}`;
    const hubUrl = `https://github.com/${hubRepo}`;
    const hubDir = path.join(WORKSPACE_ROOT, hubName);

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
      console.error(`Error: ${hubDir} already exists. Remove it or choose a different name.`);
      process.exit(1);
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

    // Write BOOTSTRAP.md — the agent's birth certificate
    const bootstrapContent = `# BOOTSTRAP

You are **${agentName}**. This is your hub.

## Template

The cn-agent template is at: \`${CN_AGENT_DIR}\`
Remote: ${CN_AGENT_REPO.replace('.git', '')}

Read skills and mindsets from the template. Your personal files live here.

## What to do now

1. Read \`skills/self-cohere/SKILL.md\` from the template.
2. Follow the self-cohere EFFECTS to wire yourself to this hub.
3. Run \`configure-agent\` to personalize your spec files.
4. Run the \`hello-world\` kata to confirm the loop works.
5. Delete this file when you're done — you won't need it again.
`;
    fs.writeFileSync(path.join(hubDir, 'BOOTSTRAP.md'), bootstrapContent);

    // Write a minimal README
    const readmeContent = `# ${hubName}

git-CN hub for **${agentName}**.

Created from [cn-agent](https://github.com/usurobor/cn-agent) template.
`;
    fs.writeFileSync(path.join(hubDir, 'README.md'), readmeContent);

    console.log('  Created hub directory with spec/, state/, BOOTSTRAP.md, README.md');

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

    // 6. Print success + cohere cue
    console.log('');
    console.log(green('============================================================'));
    console.log(green(`  ✓ Hub created: ${hubUrl}`));
    console.log(green('============================================================'));
    console.log('');
    console.log('Workspace:');
    console.log(`  ${CN_AGENT_DIR}  (template — skills, mindsets, docs)`);
    console.log(`  ${hubDir}  (hub — your agent's identity + state)`);
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
