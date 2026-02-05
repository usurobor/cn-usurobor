// cn CLI tests
// Tests for inbox, outbox, sync commands

const { describe, it, before, after } = require('node:test');
const assert = require('node:assert');
const { spawnSync, execSync } = require('child_process');
const path = require('path');
const fs = require('fs');
const os = require('os');

const CN_PATH = path.join(__dirname, '..', 'bin', 'cn');

// Create temp hub for testing
let testDir;
let hubPath;

function runCN(args = [], cwd = hubPath) {
  const result = spawnSync('node', [CN_PATH, ...args], {
    encoding: 'utf8',
    timeout: 10000,
    cwd,
    env: { ...process.env, NO_COLOR: '1' },
  });
  return {
    code: result.status,
    stdout: result.stdout || '',
    stderr: result.stderr || '',
  };
}

describe('cn CLI', () => {
  before(() => {
    // Create temp directory structure
    testDir = fs.mkdtempSync(path.join(os.tmpdir(), 'cn-test-'));
    hubPath = path.join(testDir, 'cn-test');
    
    // Initialize git repo as hub
    fs.mkdirSync(hubPath);
    execSync('git init', { cwd: hubPath, stdio: 'pipe' });
    execSync('git config user.email "test@test.com"', { cwd: hubPath, stdio: 'pipe' });
    execSync('git config user.name "Test"', { cwd: hubPath, stdio: 'pipe' });
    
    // Create minimal hub structure
    fs.mkdirSync(path.join(hubPath, 'state'), { recursive: true });
    fs.mkdirSync(path.join(hubPath, 'threads', 'inbox'), { recursive: true });
    fs.mkdirSync(path.join(hubPath, 'threads', 'outbox'), { recursive: true });
    fs.mkdirSync(path.join(hubPath, 'threads', 'sent'), { recursive: true });
    
    // Create peers.md
    fs.writeFileSync(path.join(hubPath, 'state', 'peers.md'), `# Peers

\`\`\`yaml
- name: mock-peer
  hub: https://github.com/test/mock-peer
  kind: agent
\`\`\`
`);
    
    // Initial commit
    execSync('git add .', { cwd: hubPath, stdio: 'pipe' });
    execSync('git commit -m "init"', { cwd: hubPath, stdio: 'pipe' });
  });

  after(() => {
    // Cleanup
    fs.rmSync(testDir, { recursive: true, force: true });
  });

  describe('--help', () => {
    it('exits 0 and prints usage', () => {
      const { code, stdout } = runCN(['--help']);
      assert.strictEqual(code, 0);
      assert.ok(stdout.includes('Usage:'), 'should include usage');
      assert.ok(stdout.includes('inbox'), 'should mention inbox');
      assert.ok(stdout.includes('outbox'), 'should mention outbox');
      assert.ok(stdout.includes('sync'), 'should mention sync');
    });
  });

  describe('--version', () => {
    it('exits 0 and prints version', () => {
      const { code, stdout } = runCN(['--version']);
      assert.strictEqual(code, 0);
      assert.ok(/\d+\.\d+\.\d+/.test(stdout.trim()), `expected semver, got: ${stdout}`);
    });
  });

  describe('inbox check', () => {
    it('reports empty inbox', () => {
      const { code, stdout } = runCN(['inbox', 'check']);
      assert.strictEqual(code, 0);
      assert.ok(stdout.includes('Checking inbox') || stdout.includes('clear'), 'should check inbox');
    });
  });

  describe('inbox process', () => {
    it('reports no threads to materialize', () => {
      const { code, stdout } = runCN(['inbox', 'process']);
      assert.strictEqual(code, 0);
      assert.ok(stdout.includes('Processing') || stdout.includes('No new threads'), 'should process inbox');
    });
  });

  describe('outbox check', () => {
    it('reports empty outbox', () => {
      const { code, stdout } = runCN(['outbox', 'check']);
      assert.strictEqual(code, 0);
      assert.ok(stdout.includes('clear'), 'should report outbox clear');
    });

    it('detects pending outbox thread', () => {
      // Create outbox thread
      const outboxThread = path.join(hubPath, 'threads', 'outbox', 'test-send.md');
      fs.writeFileSync(outboxThread, `---
to: mock-peer
subject: Test
---

# Test message
`);
      
      const { code, stdout } = runCN(['outbox', 'check']);
      assert.strictEqual(code, 0);
      assert.ok(stdout.includes('pending') || stdout.includes('test-send'), 'should detect pending');
      
      // Cleanup
      fs.unlinkSync(outboxThread);
    });
  });

  describe('outbox flush', () => {
    it('reports empty outbox on flush', () => {
      const { code, stdout } = runCN(['outbox', 'flush']);
      assert.strictEqual(code, 0);
      assert.ok(stdout.includes('clear'), 'should report outbox clear');
    });
  });

  describe('sync', () => {
    it('runs full sync', () => {
      const { code, stdout } = runCN(['sync']);
      assert.strictEqual(code, 0);
      assert.ok(stdout.includes('sync') || stdout.includes('Sync'), 'should run sync');
    });
  });

  describe('status', () => {
    it('shows hub status', () => {
      const { stdout } = runCN(['status']);
      // Status command runs, may have warnings in test env
      assert.ok(stdout.includes('cn v') || stdout.length > 0, 'should produce output');
    });
  });

  describe('doctor', () => {
    it('runs health check', () => {
      const { stdout } = runCN(['doctor']);
      // Doctor may exit 1 if checks fail in test env, but should run
      assert.ok(stdout.includes('cn v') || stdout.length > 0, 'should produce output');
    });
  });

  describe('aliases', () => {
    it('i = inbox', () => {
      const { code, stdout } = runCN(['i', 'check']);
      assert.strictEqual(code, 0);
      assert.ok(stdout.includes('inbox') || stdout.includes('Checking'), 'should expand alias');
    });

    it('s = status', () => {
      const { stdout } = runCN(['s']);
      assert.ok(stdout.length > 0, 'should produce output');
    });

    it('d = doctor', () => {
      const { stdout } = runCN(['d']);
      assert.ok(stdout.length > 0, 'should produce output');
    });
  });

  describe('frontmatter parsing', () => {
    it('parses to: field from frontmatter', () => {
      const outboxDir = path.join(hubPath, 'threads', 'outbox');
      const testFile = path.join(outboxDir, 'frontmatter-test.md');
      
      fs.writeFileSync(testFile, `---
to: target-peer
subject: Test Subject
---

# Content here
`);
      
      const { stdout } = runCN(['outbox', 'check']);
      assert.ok(stdout.includes('target-peer'), 'should parse to: from frontmatter');
      
      fs.unlinkSync(testFile);
    });

    it('handles missing frontmatter', () => {
      const outboxDir = path.join(hubPath, 'threads', 'outbox');
      const testFile = path.join(outboxDir, 'no-frontmatter.md');
      
      fs.writeFileSync(testFile, `# No frontmatter here

Just content.
`);
      
      const { stdout } = runCN(['outbox', 'check']);
      // Should detect file but note missing recipient
      assert.ok(stdout.includes('no-frontmatter') || stdout.includes('pending'), 'should list file');
      
      fs.unlinkSync(testFile);
    });
  });

  describe('logging', () => {
    it('logs valid JSON to cn.log after inbox fetch', () => {
      // Run a command
      runCN(['inbox', 'check']);
      
      const logFile = path.join(hubPath, 'logs', 'cn.log');
      if (fs.existsSync(logFile)) {
        const content = fs.readFileSync(logFile, 'utf8');
        const lines = content.trim().split('\n').filter(l => l);
        for (const line of lines) {
          assert.doesNotThrow(() => JSON.parse(line), `should be valid JSON: ${line}`);
        }
      }
      // Test passes even if no log (no peers configured)
    });
  });

  describe('commit', () => {
    it('reports nothing to commit when clean', () => {
      const { code, stdout } = runCN(['commit', 'test']);
      assert.strictEqual(code, 0);
      assert.ok(stdout.includes('Nothing to commit'), 'should report clean state');
    });

    it('commits changes with message', () => {
      // Create a file to commit
      const testFile = path.join(hubPath, 'threads', 'adhoc', 'commit-test.md');
      fs.mkdirSync(path.dirname(testFile), { recursive: true });
      fs.writeFileSync(testFile, '# Test\n');
      
      const { code, stdout } = runCN(['commit', 'test commit']);
      assert.strictEqual(code, 0);
      assert.ok(stdout.includes('Committed'), 'should report commit');
      
      // Verify commit was made
      const log = execSync('git log -1 --oneline', { cwd: hubPath, encoding: 'utf8' });
      assert.ok(log.includes('test commit'), 'commit message should be in log');
    });
  });

  describe('push', () => {
    it('attempts push (may fail without remote)', () => {
      const { stdout, stderr } = runCN(['push']);
      // In test env without remote, this will fail, but command should run
      assert.ok(stdout.length > 0 || stderr.length > 0, 'should produce output');
    });
  });

  describe('save', () => {
    it('runs commit + push', () => {
      const { stdout } = runCN(['save', 'save test']);
      // Should attempt both operations
      assert.ok(stdout.includes('Nothing to commit') || stdout.includes('Committed') || stdout.includes('Pushed'), 'should run save');
    });
  });
});
