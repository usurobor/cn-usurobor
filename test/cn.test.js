const { describe, it } = require('node:test');
const assert = require('node:assert');
const { execSync } = require('child_process');
const path = require('path');

const CN = path.join(__dirname, '..', 'bin', 'cn');

describe('cn CLI', () => {
  
  describe('--help', () => {
    it('shows help text', () => {
      const output = execSync(`node ${CN} --help`, { encoding: 'utf8' });
      assert.match(output, /cn - Coherent Network agent CLI/);
      assert.match(output, /Commands:/);
      assert.match(output, /inbox/);
      assert.match(output, /doctor/);
      assert.match(output, /update/);
    });
  });

  describe('--version', () => {
    it('shows version', () => {
      const output = execSync(`node ${CN} --version`, { encoding: 'utf8' });
      assert.match(output, /cn \d+\.\d+\.\d+/);
    });
  });

  describe('aliases', () => {
    it('s expands to status', () => {
      // Will fail with "not in hub" but that's expected
      try {
        execSync(`node ${CN} s`, { encoding: 'utf8', cwd: '/tmp' });
      } catch (e) {
        assert.match(e.stderr || e.stdout, /Not in a cn hub/);
      }
    });
  });

  describe('not in hub error', () => {
    it('shows helpful message with two options', () => {
      try {
        execSync(`node ${CN} status`, { encoding: 'utf8', cwd: '/tmp' });
        assert.fail('Should have thrown');
      } catch (e) {
        const output = e.stderr || e.stdout || '';
        assert.match(output, /Not in a cn hub/);
        assert.match(output, /cd/);
        assert.match(output, /cn init/);
      }
    });
  });

  describe('update command', () => {
    it('works without being in a hub', () => {
      // Just check it starts (don't actually update)
      try {
        // This will try to update, which is fine
        execSync(`node ${CN} update`, { encoding: 'utf8', cwd: '/tmp', timeout: 5000 });
      } catch (e) {
        // May timeout or succeed, but should NOT say "not in hub"
        const output = (e.stderr || e.stdout || '').toString();
        assert.doesNotMatch(output, /Not in a cn hub/);
      }
    });
  });

  describe('doctor in hub', () => {
    it('shows all checks when in a valid hub', () => {
      const hubPath = path.join(__dirname, '..', '..', 'cn-sigma');
      try {
        const output = execSync(`node ${CN} doctor`, { encoding: 'utf8', cwd: hubPath });
        assert.match(output, /cn v\d+\.\d+\.\d+/);
        assert.match(output, /Checking health/);
        assert.match(output, /git.*✓/);
      } catch (e) {
        // Doctor may fail if cn-sigma doesn't exist, skip
        if (!e.message.includes('Not in a cn hub')) {
          throw e;
        }
      }
    });
  });

});
