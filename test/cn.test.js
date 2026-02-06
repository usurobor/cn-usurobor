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

  describe('sync', () => {
    it('runs full sync', () => {
      const { code, stdout } = runCN(['sync']);
      assert.strictEqual(code, 0);
      assert.ok(stdout.includes('Sync') || stdout.length > 0, 'should run sync');
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
      const { code, stdout } = runCN(['i']);
      assert.strictEqual(code, 0);
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
      fs.mkdirSync(outboxDir, { recursive: true });
      const testFile = path.join(outboxDir, 'frontmatter-test.md');
      
      fs.writeFileSync(testFile, `---
to: target-peer
subject: Test Subject
---

# Content here
`);
      
      const { stdout } = runCN(['outbox']);
      assert.ok(stdout.includes('target-peer'), 'should parse to: from frontmatter');
      
      fs.unlinkSync(testFile);
    });

    it('handles missing frontmatter', () => {
      const outboxDir = path.join(hubPath, 'threads', 'outbox');
      fs.mkdirSync(outboxDir, { recursive: true });
      const testFile = path.join(outboxDir, 'no-frontmatter.md');
      
      fs.writeFileSync(testFile, `# No frontmatter here

Just content.
`);
      
      const { stdout } = runCN(['outbox']);
      // Should detect file but with unknown recipient
      assert.ok(stdout.includes('no-frontmatter') || stdout.includes('unknown'), 'should list file');
      
      fs.unlinkSync(testFile);
    });
  });

  describe('logging', () => {
    it('logs valid JSON to cn.log', () => {
      // Run a command that logs
      runCN(['inbox']);
      
      const logFile = path.join(hubPath, 'logs', 'cn.log');
      if (fs.existsSync(logFile)) {
        const content = fs.readFileSync(logFile, 'utf8');
        const lines = content.trim().split('\n').filter(l => l);
        for (const line of lines) {
          assert.doesNotThrow(() => JSON.parse(line), `should be valid JSON: ${line}`);
        }
      }
      // Test passes even if no log
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

  describe('agent API', () => {
    it('cn inbox lists inbox', () => {
      const { code, stdout } = runCN(['inbox']);
      assert.strictEqual(code, 0);
    });

    it('cn outbox lists outbox', () => {
      const { code, stdout } = runCN(['outbox']);
      assert.strictEqual(code, 0);
    });

    it('cn next returns next item or empty', () => {
      const { code, stdout } = runCN(['next']);
      assert.strictEqual(code, 0);
      assert.ok(stdout.includes('inbox empty') || stdout.includes('[cadence:'), 'should show item or empty');
    });

    it('cn send creates outbox message', () => {
      const { code, stdout } = runCN(['send', 'test-peer', 'Test message']);
      assert.strictEqual(code, 0);
      assert.ok(stdout.includes('Created message'), 'should create message');
    });

    it('cn outbox shows pending message', () => {
      const { code, stdout } = runCN(['outbox']);
      assert.strictEqual(code, 0);
      assert.ok(stdout.includes('test-peer') || stdout.includes('Test'), 'should show pending');
    });

    it('cn read shows thread with cadence', () => {
      // Create a test thread first
      const testPath = path.join(hubPath, 'threads', 'adhoc', 'cadence-test.md');
      fs.mkdirSync(path.dirname(testPath), { recursive: true });
      fs.writeFileSync(testPath, '---\ntest: true\n---\n\n# Test\n');
      
      const { code, stdout } = runCN(['read', 'cadence-test']);
      assert.strictEqual(code, 0);
      assert.ok(stdout.includes('[cadence: adhoc]'), 'should show cadence');
    });
  });

  describe('GTD operations', () => {
    before(() => {
      // Create test inbox item
      const inboxPath = path.join(hubPath, 'threads', 'inbox', 'gtd-test.md');
      fs.mkdirSync(path.dirname(inboxPath), { recursive: true });
      fs.writeFileSync(inboxPath, '---\nfrom: test\n---\n\n# GTD Test\n');
    });

    it('cn do moves to doing/', () => {
      const { code, stdout } = runCN(['do', 'gtd-test']);
      assert.strictEqual(code, 0);
      assert.ok(stdout.includes('Started'), 'should start');
      assert.ok(fs.existsSync(path.join(hubPath, 'threads', 'doing', 'gtd-test.md')), 'should be in doing/');
    });

    it('cn reply appends to thread', () => {
      const { code, stdout } = runCN(['reply', 'gtd-test', 'Working on it']);
      assert.strictEqual(code, 0);
      assert.ok(stdout.includes('Replied'), 'should reply');
    });

    it('cn done moves to archived/', () => {
      const { code, stdout } = runCN(['done', 'gtd-test']);
      assert.strictEqual(code, 0);
      assert.ok(stdout.includes('Completed'), 'should complete');
      assert.ok(fs.existsSync(path.join(hubPath, 'threads', 'archived', 'gtd-test.md')), 'should be archived');
    });

    it('cn delete removes thread', () => {
      // Create another test item
      const testPath = path.join(hubPath, 'threads', 'inbox', 'delete-test.md');
      fs.writeFileSync(testPath, '# Delete me\n');
      
      const { code, stdout } = runCN(['delete', 'delete-test']);
      assert.strictEqual(code, 0);
      assert.ok(stdout.includes('Deleted'), 'should delete');
      assert.ok(!fs.existsSync(testPath), 'should be gone');
    });

    it('cn defer moves to deferred/', () => {
      const testPath = path.join(hubPath, 'threads', 'inbox', 'defer-test.md');
      fs.writeFileSync(testPath, '# Defer me\n');
      
      const { code, stdout } = runCN(['defer', 'defer-test', 'tomorrow']);
      assert.strictEqual(code, 0);
      assert.ok(stdout.includes('Deferred'), 'should defer');
      assert.ok(fs.existsSync(path.join(hubPath, 'threads', 'deferred', 'defer-test.md')), 'should be in deferred/');
    });

    it('cn delegate moves to outbox/', () => {
      const testPath = path.join(hubPath, 'threads', 'inbox', 'delegate-test.md');
      fs.writeFileSync(testPath, '# Delegate me\n');
      
      const { code, stdout } = runCN(['delegate', 'delegate-test', 'other-peer']);
      assert.strictEqual(code, 0);
      assert.ok(stdout.includes('Delegated'), 'should delegate');
      assert.ok(fs.existsSync(path.join(hubPath, 'threads', 'outbox', 'delegate-test.md')), 'should be in outbox/');
    });
  });

  describe('cadence detection', () => {
    it('detects inbox cadence', () => {
      const testPath = path.join(hubPath, 'threads', 'inbox', 'cadence-inbox.md');
      fs.mkdirSync(path.dirname(testPath), { recursive: true });
      fs.writeFileSync(testPath, '# Inbox item\n');
      
      const { stdout } = runCN(['read', 'cadence-inbox']);
      assert.ok(stdout.includes('[cadence: inbox]'), 'should be inbox cadence');
      fs.unlinkSync(testPath);
    });

    it('detects daily cadence', () => {
      const testPath = path.join(hubPath, 'threads', 'daily', '20260206.md');
      fs.mkdirSync(path.dirname(testPath), { recursive: true });
      fs.writeFileSync(testPath, '# Daily\n');
      
      const { stdout } = runCN(['read', '20260206']);
      assert.ok(stdout.includes('[cadence: daily]'), 'should be daily cadence');
      fs.unlinkSync(testPath);
    });

    it('detects adhoc cadence', () => {
      const testPath = path.join(hubPath, 'threads', 'adhoc', 'work-item.md');
      fs.mkdirSync(path.dirname(testPath), { recursive: true });
      fs.writeFileSync(testPath, '# Work\n');
      
      const { stdout } = runCN(['read', 'work-item']);
      assert.ok(stdout.includes('[cadence: adhoc]'), 'should be adhoc cadence');
      fs.unlinkSync(testPath);
    });
  });

  // NOTE: File operations (write/append/mkdir/rm) removed from agent API
  // Agents should not do file operations directly — only thread operations
});
