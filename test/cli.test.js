// CLI smoke tests
// Uses Node's built-in test runner (node:test, available since Node 18)

const { describe, it } = require('node:test');
const assert = require('node:assert');
const { spawnSync } = require('child_process');
const path = require('path');

const CLI_PATH = path.join(__dirname, '..', 'cli', 'index.js');
const { sanitizeName } = require('../cli/sanitize');
const { buildHubConfig } = require('../cli/hubConfig');
const { normalizeGitHubUrl } = require('../cli/github');

// Helper: run CLI with args, return { code, stdout, stderr }
function runCLI(args = []) {
  const result = spawnSync('node', [CLI_PATH, ...args], {
    encoding: 'utf8',
    timeout: 5000,
  });
  return {
    code: result.status,
    stdout: result.stdout || '',
    stderr: result.stderr || '',
  };
}

describe('CLI flags', () => {
  it('--help exits 0 and prints usage', () => {
    const { code, stdout } = runCLI(['--help']);
    assert.strictEqual(code, 0);
    assert.ok(stdout.includes('cn-agent-setup'), 'should mention cn-agent-setup');
    assert.ok(stdout.includes('Usage:'), 'should include usage section');
  });

  it('-h exits 0 and prints usage', () => {
    const { code, stdout } = runCLI(['-h']);
    assert.strictEqual(code, 0);
    assert.ok(stdout.includes('Usage:'));
  });

  it('--version exits 0 and prints semver', () => {
    const { code, stdout } = runCLI(['--version']);
    assert.strictEqual(code, 0);
    // Version should match semver pattern
    assert.ok(/^\d+\.\d+\.\d+/.test(stdout.trim()), `expected semver, got: ${stdout.trim()}`);
  });

  it('-v exits 0 and prints semver', () => {
    const { code, stdout } = runCLI(['-v']);
    assert.strictEqual(code, 0);
    assert.ok(/^\d+\.\d+\.\d+/.test(stdout.trim()));
  });
});

describe('sanitizeName', () => {
  it('lowercases and preserves alphanumerics', () => {
    const result = sanitizeName('Sigma');
    assert.deepStrictEqual(result, { valid: true, name: 'sigma' });
  });

  it('replaces spaces with hyphens', () => {
    const result = sanitizeName('My Agent');
    assert.deepStrictEqual(result, { valid: true, name: 'my-agent' });
  });

  it('strips special characters', () => {
    const result = sanitizeName('Test@Agent#123');
    assert.deepStrictEqual(result, { valid: true, name: 'testagent123' });
  });

  it('handles mixed spaces and special chars', () => {
    const result = sanitizeName('Nova X-1!');
    assert.deepStrictEqual(result, { valid: true, name: 'nova-x-1' });
  });

  it('rejects empty string', () => {
    const result = sanitizeName('');
    assert.strictEqual(result.valid, false);
    assert.ok(result.error.includes('required'));
  });

  it('rejects null', () => {
    const result = sanitizeName(null);
    assert.strictEqual(result.valid, false);
  });

  it('rejects string that collapses to empty', () => {
    const result = sanitizeName('!!!');
    assert.strictEqual(result.valid, false);
    assert.ok(result.error.includes('alphanumeric'));
  });

  it('rejects string that collapses to single hyphen', () => {
    const result = sanitizeName('---');
    assert.strictEqual(result.valid, false);
  });

  it('rejects leading hyphen after sanitization', () => {
    // " -test" -> "-test" (leading hyphen)
    const result = sanitizeName(' -test');
    assert.strictEqual(result.valid, false);
  });

  it('rejects trailing hyphen after sanitization', () => {
    // "test- " -> "test-" (trailing hyphen)
    const result = sanitizeName('test- ');
    assert.strictEqual(result.valid, false);
  });
});

describe('buildHubConfig', () => {
  it('builds correct config from sanitized name and owner', () => {
    const config = buildHubConfig('sigma', 'usurobor', '/root/.openclaw/workspace');
    assert.deepStrictEqual(config, {
      hubName: 'cn-sigma',
      hubRepo: 'usurobor/cn-sigma',
      hubUrl: 'https://github.com/usurobor/cn-sigma',
      hubDir: '/root/.openclaw/workspace/cn-sigma',
    });
  });

  it('handles hyphenated names', () => {
    const config = buildHubConfig('my-agent', 'someuser', '/workspace');
    assert.strictEqual(config.hubName, 'cn-my-agent');
    assert.strictEqual(config.hubRepo, 'someuser/cn-my-agent');
  });

  it('handles org owners', () => {
    const config = buildHubConfig('bot', 'my-org', '/workspace');
    assert.strictEqual(config.hubRepo, 'my-org/cn-bot');
    assert.strictEqual(config.hubUrl, 'https://github.com/my-org/cn-bot');
  });

  it('handles different workspace roots', () => {
    const config = buildHubConfig('test', 'user', '/custom/path');
    assert.strictEqual(config.hubDir, '/custom/path/cn-test');
  });
});

describe('normalizeGitHubUrl', () => {
  it('normalizes SSH URLs', () => {
    const result = normalizeGitHubUrl('git@github.com:usurobor/cn-sigma.git');
    assert.strictEqual(result, 'usurobor/cn-sigma');
  });

  it('normalizes HTTPS URLs', () => {
    const result = normalizeGitHubUrl('https://github.com/usurobor/cn-sigma.git');
    assert.strictEqual(result, 'usurobor/cn-sigma');
  });

  it('handles URLs without .git suffix', () => {
    const result = normalizeGitHubUrl('https://github.com/usurobor/cn-sigma');
    assert.strictEqual(result, 'usurobor/cn-sigma');
  });

  it('returns null for null input', () => {
    const result = normalizeGitHubUrl(null);
    assert.strictEqual(result, null);
  });

  it('returns null for undefined input', () => {
    const result = normalizeGitHubUrl(undefined);
    assert.strictEqual(result, null);
  });

  it('handles org repos', () => {
    const result = normalizeGitHubUrl('git@github.com:my-org/my-repo.git');
    assert.strictEqual(result, 'my-org/my-repo');
  });
});

describe('CLI environment', () => {
  it('--help mentions CN_WORKSPACE env var', () => {
    const { stdout } = runCLI(['--help']);
    assert.ok(stdout.includes('CN_WORKSPACE'), 'should document CN_WORKSPACE env var');
  });

  it('--help mentions NO_COLOR env var', () => {
    const { stdout } = runCLI(['--help']);
    assert.ok(stdout.includes('NO_COLOR'), 'should document NO_COLOR env var');
  });

  it('respects NO_COLOR environment variable', () => {
    const result = spawnSync('node', [CLI_PATH, '--help'], {
      encoding: 'utf8',
      timeout: 5000,
      env: { ...process.env, NO_COLOR: '1' },
    });
    // Output should not contain ANSI escape codes
    assert.ok(!result.stdout.includes('\x1b['), 'should not contain ANSI codes when NO_COLOR is set');
  });
});
