#!/usr/bin/env node

// cn-agent-setup CLI
// Sets up a complete cn-agent workspace: template + personal hub.
//
// Intended usage on the host:
//   npx --yes @usurobor/cn-agent-setup
//
// This script is designed to be robust, rerunnable, and non-blocking:
//   - Never silently blocks on SSH/host prompts (uses timeouts + BatchMode)
//   - Idempotent: safe to rerun after partial failure
//   - Detects existing hubs/repos and offers to reuse them
//   - Confirms destructive actions before proceeding

const { spawn, spawnSync } = require('child_process');
const path = require('path');
const fs = require('fs');
const readline = require('readline');

const VERSION = require('../package.json').version;
const { sanitizeName } = require('./sanitize');
const { buildHubConfig } = require('./hubConfig');
const { normalizeGitHubUrl, ghRepoExists, getGitRemote } = require('./github');

// NO_COLOR support (https://no-color.org)
const useColor = !process.env.NO_COLOR;
const cyan = (str) => useColor ? `\x1b[36m${str}\x1b[0m` : str;
const bold = (str) => useColor ? `\x1b[1m${str}\x1b[0m` : str;
const green = (str) => useColor ? `\x1b[32m${str}\x1b[0m` : str;
const yellow = (str) => useColor ? `\x1b[33m${str}\x1b[0m` : str;
const red = (str) => useColor ? `\x1b[31m${str}\x1b[0m` : str;
const dim = (str) => useColor ? `\x1b[2m${str}\x1b[0m` : str;

// SSH command with timeout and batch mode to prevent hanging
const SSH_COMMAND = 'ssh -o ConnectTimeout=10 -o BatchMode=yes -o StrictHostKeyChecking=accept-new';

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
  console.log('');
  console.log('Environment:');
  console.log('  CN_WORKSPACE     Workspace root (default: /root/.openclaw/workspace)');
  console.log('  NO_COLOR         Disable colored output');
  process.exit(0);
}
if (arg === '--version' || arg === '-v') {
  console.log(VERSION);
  process.exit(0);
}

const WORKSPACE_ROOT = process.env.CN_WORKSPACE || '/root/.openclaw/workspace';
const CN_AGENT_REPO = 'https://github.com/usurobor/cn-agent.git';
const CN_AGENT_DIR = path.join(WORKSPACE_ROOT, 'cn-agent');
const STATE_FILE = path.join(WORKSPACE_ROOT, '.cn-agent-setup.json');

// Persistent state for reruns
function loadState() {
  try {
    if (fs.existsSync(STATE_FILE)) {
      return JSON.parse(fs.readFileSync(STATE_FILE, 'utf8'));
    }
  } catch {}
  return {};
}

function saveState(state) {
  try {
    fs.writeFileSync(STATE_FILE, JSON.stringify(state, null, 2));
  } catch {}
}

// Run a command with timeout and SSH safety
function run(cmd, args, options = {}) {
  return new Promise((resolve, reject) => {
    const env = { ...process.env, ...options.env };
    // Add SSH command for git operations
    if (cmd === 'git' && !env.GIT_SSH_COMMAND) {
      env.GIT_SSH_COMMAND = SSH_COMMAND;
    }
    
    const child = spawn(cmd, args, { 
      stdio: options.quiet ? 'pipe' : 'inherit',
      cwd: options.cwd,
      env
    });
    
    const timeout = options.timeout || 60000; // 60s default
    const timer = setTimeout(() => {
      child.kill('SIGTERM');
      reject(new Error(`${cmd} ${args.join(' ')} timed out after ${timeout/1000}s`));
    }, timeout);
    
    child.on('exit', (code) => {
      clearTimeout(timer);
      if (code === 0) resolve();
      else reject(new Error(`${cmd} ${args.join(' ')} exited with code ${code}`));
    });
    child.on('error', (err) => {
      clearTimeout(timer);
      reject(err);
    });
  });
}

// Run and capture output
function runCapture(cmd, args, options = {}) {
  const env = { ...process.env, ...options.env };
  if (cmd === 'git' && !env.GIT_SSH_COMMAND) {
    env.GIT_SSH_COMMAND = SSH_COMMAND;
  }
  const result = spawnSync(cmd, args, { 
    encoding: 'utf8',
    cwd: options.cwd,
    env,
    timeout: options.timeout || 30000 // 30s default for capture
  });
  return (result.stdout || '').trim();
}

// Check if a command exists
function commandExists(cmd) {
  const result = spawnSync('which', [cmd], { encoding: 'utf8' });
  return result.status === 0;
}

function ask(rl, question) {
  return new Promise((resolve) => {
    rl.question(question, (answer) => resolve(answer.trim()));
  });
}

// Check if a directory is a git repo
function isGitRepo(dir) {
  return fs.existsSync(path.join(dir, '.git'));
}

(async () => {
  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  const state = loadState();

  // Helper for autoconf-style check output
  function showCheck(label, status, detail) {
    const dots = '.'.repeat(Math.max(1, 20 - label.length));
    if (status === true) {
      const info = detail ? ` ${dim(`(${detail})`)}` : '';
      console.log(`  ${label}${dots} ${green('yes')}${info}`);
    } else if (status === false) {
      console.log(`  ${label}${dots} ${red('no')}`);
    } else {
      // skipped (dependency not met)
      console.log(`  ${label}${dots} ${dim('--')}`);
    }
  }

  // Install instructions for each prerequisite
  const installInstructions = {
    git: [
      '# macOS:',
      'xcode-select --install',
      '',
      '# Debian/Ubuntu:',
      'sudo apt update && sudo apt install git',
      '',
      '# Fedora:',
      'sudo dnf install git',
      '',
      '# Windows:',
      'winget install Git.Git',
      '',
      'More info: https://git-scm.com/downloads',
    ],
    gh: [
      '# macOS:',
      'brew install gh',
      '',
      '# Debian/Ubuntu:',
      'sudo apt install gh',
      '',
      '# Fedora:',
      'sudo dnf install gh',
      '',
      '# Windows:',
      'winget install GitHub.cli',
      '',
      'More info: https://cli.github.com/',
    ],
    'gh auth': [
      'gh auth login',
      '',
      'Follow the prompts to authenticate with GitHub.',
    ],
    'git identity': [
      'git config --global user.name "Your Name"',
      'git config --global user.email "you@example.com"',
      '',
      'Or update your GitHub profile (name + public email):',
      'https://github.com/settings/profile',
    ],
    workspace: [
      `mkdir -p ${WORKSPACE_ROOT}`,
      '',
      'Or set CN_WORKSPACE to your preferred path:',
      'CN_WORKSPACE=/your/path npx --yes @usurobor/cn-agent-setup',
    ],
    openclaw: [
      '# Install OpenClaw:',
      'npm install -g openclaw',
      '',
      '# Then configure it:',
      'openclaw init',
      '',
      'More info: https://docs.openclaw.ai',
    ],
  };

  try {
    console.log(`cn-agent-setup v${VERSION}`);
    console.log('');

    // =========================================================================
    // PREREQUISITES CHECK (autoconf style - show all, then handle)
    // =========================================================================
    console.log(bold('Checking prerequisites...'));
    console.log('');

    // Collect all check results
    const checks = {};
    const details = {};

    // Check: git
    checks.git = commandExists('git');
    
    // Check: gh (only if git exists, but show anyway)
    checks.gh = commandExists('gh');
    
    // Check: gh auth (only meaningful if gh exists)
    let ghUser = null;
    if (checks.gh) {
      ghUser = runCapture('gh', ['api', 'user', '--jq', '.login']);
      checks['gh auth'] = !!ghUser;
      details['gh auth'] = ghUser;
    } else {
      checks['gh auth'] = null; // skipped
    }

    // Check: git identity (try to infer from GitHub if gh auth works)
    let gitName = null;
    let gitEmail = null;
    if (checks.git) {
      gitName = runCapture('git', ['config', 'user.name']);
      gitEmail = runCapture('git', ['config', 'user.email']);
      
      // Try to infer from GitHub profile if not configured locally
      if (checks['gh auth'] && (!gitName || !gitEmail)) {
        const ghName = runCapture('gh', ['api', 'user', '--jq', '.name']);
        const ghEmail = runCapture('gh', ['api', 'user', '--jq', '.email']);
        
        if (!gitName && ghName) gitName = ghName;
        if (!gitEmail && ghEmail) gitEmail = ghEmail;
      }
      
      checks['git identity'] = !!(gitName && gitEmail);
      if (checks['git identity']) {
        details['git identity'] = `${gitName} <${gitEmail}>`;
      }
    } else {
      checks['git identity'] = null; // skipped
    }

    // Check: workspace directory exists
    checks.workspace = fs.existsSync(WORKSPACE_ROOT);
    details.workspace = WORKSPACE_ROOT;
    
    // Check: openclaw is installed (command exists or ~/.openclaw dir with config)
    // This verifies OpenClaw is actually set up, not just that the workspace dir exists
    const openclawHome = path.join(process.env.HOME || '/root', '.openclaw');
    const openclawCmd = commandExists('openclaw');
    const openclawDir = fs.existsSync(openclawHome);
    checks.openclaw = openclawCmd || openclawDir;

    // Display all checks
    showCheck('git', checks.git);
    showCheck('gh', checks.gh);
    showCheck('gh auth', checks['gh auth'], details['gh auth']);
    showCheck('git identity', checks['git identity'], details['git identity']);
    showCheck('workspace', checks.workspace, details.workspace);
    showCheck('openclaw', checks.openclaw);

    console.log('');

    // Collect failures
    const failed = Object.entries(checks)
      .filter(([_, status]) => status === false)
      .map(([name]) => name);

    if (failed.length > 0) {
      // Show install instructions for each failure
      console.log(red(`Missing: ${failed.join(', ')}`));
      console.log('');
      
      for (const name of failed) {
        console.log(bold(`To install ${name}:`));
        console.log('');
        for (const line of installInstructions[name]) {
          console.log(`  ${line}`);
        }
        console.log('');
      }
      
      process.exit(1);
    }

    // All checks passed - continue
    console.log(green('All checks passed.'));

    // Set git config if not already set (using inferred values)
    if (!runCapture('git', ['config', 'user.name'])) {
      await run('git', ['config', '--global', 'user.name', gitName], { quiet: true });
    }
    if (!runCapture('git', ['config', 'user.email'])) {
      await run('git', ['config', '--global', 'user.email', gitEmail], { quiet: true });
    }

    console.log('');

    // =========================================================================
    // STEP 2: Template (cn-agent) Install/Update
    // =========================================================================
    console.log(bold('Step 2: Template'));
    console.log('');

    if (!isGitRepo(CN_AGENT_DIR)) {
      console.log(`  Cloning cn-agent template...`);
      try {
        await run('git', ['clone', CN_AGENT_REPO, CN_AGENT_DIR], { 
          cwd: WORKSPACE_ROOT,
          timeout: 120000 // 2 minutes for clone
        });
        console.log(green('  ✓ Template cloned'));
      } catch (err) {
        console.error('');
        console.error(red('Error: Failed to clone cn-agent template.'));
        console.error('');
        if (err.message.includes('timed out')) {
          console.error('The operation timed out. This usually means:');
          console.error('  - Network connectivity issues');
          console.error('  - SSH key not added to GitHub (if using SSH)');
          console.error('');
          console.error('Try: gh auth login (to set up HTTPS auth)');
        } else {
          console.error(err.message);
        }
        process.exit(1);
      }
    } else {
      console.log(`  Found existing template at ${CN_AGENT_DIR}`);
      try {
        await run('git', ['pull', '--ff-only'], { cwd: CN_AGENT_DIR, quiet: true, timeout: 30000 });
        console.log(green('  ✓ Template updated'));
      } catch (e) {
        console.log(yellow('  ⚠ Could not fast-forward update (local changes or diverged history)'));
        console.log(dim('    Continuing with existing template. To inspect:'));
        console.log(dim(`    cd ${CN_AGENT_DIR} && git status`));
      }
    }
    console.log('');

    // =========================================================================
    // STEP 3: Hub Selection (name/owner/visibility)
    // =========================================================================
    console.log(bold('Step 3: Hub Configuration'));
    console.log('');

    // Agent name - show last used as default
    const lastAgentName = state.lastAgentName;
    let agentNamePrompt = '  Agent name (e.g. Sigma, Nova, Echo): ';
    if (lastAgentName) {
      agentNamePrompt = `  Agent name [${lastAgentName}]: `;
    }
    
    let agentNameInput = await ask(rl, agentNamePrompt);
    if (!agentNameInput && lastAgentName) {
      agentNameInput = lastAgentName;
    }
    
    if (!agentNameInput) {
      console.error(red('Error: Agent name is required.'));
      process.exit(1);
    }
    
    const nameResult = sanitizeName(agentNameInput);
    if (!nameResult.valid) {
      console.error(red(`Error: ${nameResult.error}`));
      process.exit(1);
    }
    let sanitizedAgentName = nameResult.name;
    
    // Save for next run
    state.lastAgentName = agentNameInput;
    saveState(state);

    // GitHub owner - default to current gh user
    const ownerPrompt = `  GitHub owner [${ghUser}]: `;
    const ownerInput = await ask(rl, ownerPrompt);
    let hubOwner = ownerInput || ghUser;

    // Visibility
    const lastVisibility = state.lastVisibility || 'public';
    const visPrompt = `  Visibility (public/private) [${lastVisibility}]: `;
    const visInput = await ask(rl, visPrompt);
    let hubVisibility = visInput || lastVisibility;
    if (hubVisibility !== 'public' && hubVisibility !== 'private') {
      hubVisibility = 'public';
    }
    state.lastVisibility = hubVisibility;
    saveState(state);

    // Build configuration
    let config = buildHubConfig(sanitizedAgentName, hubOwner, WORKSPACE_ROOT);
    let { hubName, hubRepo, hubUrl, hubDir } = config;

    // =========================================================================
    // Pre-flight checks: detect existing local dir and GitHub repo
    // =========================================================================
    const localExists = fs.existsSync(hubDir);
    const localIsGit = localExists && isGitRepo(hubDir);
    const localRemote = localIsGit ? normalizeGitHubUrl(getGitRemote(hubDir)) : null;
    const expectedRemote = hubRepo;
    const localMatchesExpected = localRemote === expectedRemote;
    const ghRepoAlreadyExists = ghRepoExists(hubRepo);

    // =========================================================================
    // Summary and confirmation
    // =========================================================================
    console.log('');
    console.log(bold('  Summary:'));
    console.log(`    Hub name:     ${hubName}`);
    console.log(`    GitHub repo:  ${hubOwner}/${hubName} (${hubVisibility})`);
    console.log(`    Local path:   ${hubDir}`);
    console.log('');

    // Report existing state
    if (localExists) {
      if (localMatchesExpected) {
        console.log(green(`    ✓ Local directory exists and points to correct remote`));
      } else if (localIsGit) {
        console.log(yellow(`    ⚠ Local directory exists but points to: ${localRemote || '(no remote)'}`));
      } else {
        console.log(yellow(`    ⚠ Local directory exists but is not a git repo`));
      }
    }
    if (ghRepoAlreadyExists) {
      console.log(green(`    ✓ GitHub repo ${hubRepo} already exists`));
    }
    console.log('');

    // Determine action based on state
    let action = 'create'; // default: create from scratch
    
    if (localMatchesExpected && ghRepoAlreadyExists) {
      // Perfect match - just reuse
      console.log('  Existing hub detected. What would you like to do?');
      const choice = await ask(rl, '  [R]euse existing (default), [D]elete and recreate, [A]bort? ');
      const c = choice.toLowerCase() || 'r';
      if (c === 'a' || c === 'abort') {
        console.log('Aborted.');
        process.exit(0);
      } else if (c === 'd' || c === 'delete') {
        action = 'recreate';
      } else {
        action = 'reuse';
      }
    } else if (localExists && !localMatchesExpected) {
      // Local exists but doesn't match
      console.log('  Local directory exists but does not match expected configuration.');
      const choice = await ask(rl, '  [D]elete and recreate, [N]ew name, [A]bort? ');
      const c = choice.toLowerCase();
      if (c === 'a' || c === 'abort' || !c) {
        console.log('Aborted.');
        process.exit(0);
      } else if (c === 'n' || c === 'new') {
        const newName = await ask(rl, '  New agent name: ');
        const newResult = sanitizeName(newName);
        if (!newResult.valid) {
          console.error(red(`Error: ${newResult.error}`));
          process.exit(1);
        }
        config = buildHubConfig(newResult.name, hubOwner, WORKSPACE_ROOT);
        ({ hubName, hubRepo, hubUrl, hubDir } = config);
        state.lastAgentName = newName;
        saveState(state);
        // Recheck new name
        action = ghRepoExists(hubRepo) ? 'attach' : 'create';
      } else {
        action = 'recreate';
      }
    } else if (ghRepoAlreadyExists && !localExists) {
      // GitHub repo exists but no local - offer to clone/attach
      console.log(`  GitHub repo ${hubRepo} exists but no local directory.`);
      const choice = await ask(rl, '  [U]se existing repo (default), [N]ew name, [A]bort? ');
      const c = choice.toLowerCase() || 'u';
      if (c === 'a' || c === 'abort') {
        console.log('Aborted.');
        process.exit(0);
      } else if (c === 'n' || c === 'new') {
        const newName = await ask(rl, '  New agent name: ');
        const newResult = sanitizeName(newName);
        if (!newResult.valid) {
          console.error(red(`Error: ${newResult.error}`));
          process.exit(1);
        }
        config = buildHubConfig(newResult.name, hubOwner, WORKSPACE_ROOT);
        ({ hubName, hubRepo, hubUrl, hubDir } = config);
        state.lastAgentName = newName;
        saveState(state);
        action = 'create';
      } else {
        action = 'clone-existing';
      }
    } else {
      // Fresh creation - confirm
      const confirm = await ask(rl, '  [C]ontinue (default), [E]dit, [A]bort? ');
      const c = confirm.toLowerCase() || 'c';
      if (c === 'a' || c === 'abort') {
        console.log('Aborted.');
        process.exit(0);
      } else if (c === 'e' || c === 'edit') {
        console.log('');
        console.log('  Rerun the setup to change values.');
        process.exit(0);
      }
      action = 'create';
    }

    console.log('');

    // =========================================================================
    // STEP 4: Hub Creation/Wiring
    // =========================================================================
    console.log(bold('Step 4: Hub Setup'));
    console.log('');

    if (action === 'reuse') {
      console.log(green('  ✓ Using existing hub (no changes needed)'));
    } else if (action === 'clone-existing') {
      // Clone the existing GitHub repo
      console.log('  Cloning existing GitHub repo...');
      try {
        await run('gh', ['repo', 'clone', hubRepo, hubDir], { timeout: 120000 });
        console.log(green('  ✓ Cloned existing repo'));
      } catch (err) {
        console.error(red(`Error: Failed to clone ${hubRepo}`));
        console.error(err.message);
        process.exit(1);
      }
    } else if (action === 'recreate') {
      // Delete local and recreate
      console.log(`  Removing existing directory...`);
      fs.rmSync(hubDir, { recursive: true, force: true });
      await createHub(hubDir, hubName, agentNameInput, hubRepo, hubVisibility, ghRepoAlreadyExists);
    } else if (action === 'attach') {
      // Create local and attach to existing repo
      await createHub(hubDir, hubName, agentNameInput, hubRepo, hubVisibility, true);
    } else {
      // Fresh create
      await createHub(hubDir, hubName, agentNameInput, hubRepo, hubVisibility, false);
    }

    console.log('');

    // =========================================================================
    // STEP 5: Workspace Symlinks
    // =========================================================================
    console.log(bold('Step 5: Workspace Symlinks'));
    console.log('');

    // Remove existing files/symlinks
    const ocFiles = ['AGENTS.md', 'SOUL.md', 'USER.md', 'HEARTBEAT.md', 'TOOLS.md', 'IDENTITY.md'];
    for (const f of ocFiles) {
      const p = path.join(WORKSPACE_ROOT, f);
      try {
        if (fs.existsSync(p) || fs.lstatSync(p).isSymbolicLink()) {
          fs.unlinkSync(p);
        }
      } catch {}
    }

    // Create symlinks (relative paths for portability)
    const hubRelPath = hubName;
    const links = [
      ['cn-agent/spec/AGENTS.md', 'AGENTS.md'],
      [`${hubRelPath}/spec/SOUL.md`, 'SOUL.md'],
      [`${hubRelPath}/spec/USER.md`, 'USER.md'],
      [`${hubRelPath}/spec/HEARTBEAT.md`, 'HEARTBEAT.md'],
      [`${hubRelPath}/spec/TOOLS.md`, 'TOOLS.md'],
    ];

    for (const [target, linkName] of links) {
      const linkPath = path.join(WORKSPACE_ROOT, linkName);
      const targetPath = path.join(WORKSPACE_ROOT, target);
      if (fs.existsSync(targetPath)) {
        fs.symlinkSync(target, linkPath);
      }
    }
    
    console.log(green('  ✓ Symlinks created'));
    console.log('');

    // =========================================================================
    // Success
    // =========================================================================
    console.log(green('════════════════════════════════════════════════════════════'));
    console.log(green(`  ✓ Hub ready: ${hubUrl}`));
    console.log(green('════════════════════════════════════════════════════════════'));
    console.log('');
    console.log('Workspace layout:');
    console.log(`  ${CN_AGENT_DIR}  ${dim('← template (skills, mindsets, docs)')}`);
    console.log(`  ${hubDir}  ${dim('← hub (identity + state)')}`);
    console.log('');
    console.log('Paste this into your agent\'s chat:');
    console.log('');
    console.log('  ' + bold(`Cohere as ${hubUrl}`));
    console.log('');

  } catch (err) {
    console.error('');
    console.error(red('cn-agent-setup failed:'), err.message || err);
    process.exit(1);
  } finally {
    rl.close();
  }

  // Helper: create hub directory and initialize
  async function createHub(hubDir, hubName, agentName, hubRepo, visibility, repoExists) {
    // Create directory structure
    console.log('  Creating hub directory...');
    fs.mkdirSync(hubDir, { recursive: true });
    fs.mkdirSync(path.join(hubDir, 'spec'), { recursive: true });
    fs.mkdirSync(path.join(hubDir, 'state', 'threads'), { recursive: true });

    // Copy spec files from template
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

    // Write README
    const readmeContent = `# ${hubName}

git-CN hub for **${agentName}**.

Created from [cn-agent](https://github.com/usurobor/cn-agent) template.
`;
    fs.writeFileSync(path.join(hubDir, 'README.md'), readmeContent);
    console.log(green('  ✓ Hub scaffolded'));

    // Git init and commit
    console.log('  Initializing git...');
    await run('git', ['init'], { cwd: hubDir, quiet: true });
    await run('git', ['add', '.'], { cwd: hubDir, quiet: true });
    await run('git', ['commit', '-m', `Bootstrap ${hubName} from cn-agent template`], { cwd: hubDir, quiet: true });
    console.log(green('  ✓ Initial commit'));

    // Create or attach to GitHub repo
    if (repoExists) {
      console.log('  Attaching to existing GitHub repo...');
      await run('git', ['remote', 'add', 'origin', `https://github.com/${hubRepo}.git`], { cwd: hubDir, quiet: true });
      try {
        await run('git', ['pull', '--rebase', 'origin', 'main'], { cwd: hubDir, quiet: true, timeout: 60000 });
      } catch {
        // Might fail if repo is empty or different branch - that's ok
      }
      await run('git', ['push', '-u', 'origin', 'HEAD:main', '--force-with-lease'], { cwd: hubDir, timeout: 60000 });
      console.log(green('  ✓ Attached to existing repo'));
    } else {
      console.log('  Creating GitHub repo...');
      try {
        await run('gh', ['repo', 'create', hubRepo, `--${visibility}`, '--source', '.', '--push'], { 
          cwd: hubDir,
          timeout: 60000 
        });
        console.log(green('  ✓ GitHub repo created'));
      } catch (err) {
        console.error(red('  Failed to create GitHub repo'));
        console.error('');
        console.error('  The hub directory was created locally. To manually push:');
        console.error(`    cd ${hubDir}`);
        console.error(`    gh repo create ${hubRepo} --${visibility} --source . --push`);
        console.error('');
        throw err;
      }
    }
  }
})();
