// GitHub URL utilities

const { spawnSync } = require('child_process');

// Normalize GitHub URL to owner/repo format for comparison
// Handles both SSH (git@github.com:owner/repo.git) and HTTPS (https://github.com/owner/repo.git)
function normalizeGitHubUrl(url) {
  if (!url) return null;
  return url
    .replace(/^git@github\.com:/, '')
    .replace(/^https:\/\/github\.com\//, '')
    .replace(/\.git$/, '');
}

// Check if a GitHub repo exists via gh CLI
function ghRepoExists(repoPath) {
  const result = spawnSync('gh', ['repo', 'view', repoPath, '--json', 'name'], { 
    encoding: 'utf8',
    timeout: 15000
  });
  return result.status === 0;
}

// Get the origin remote URL for a git repo
function getGitRemote(dir) {
  const result = spawnSync('git', ['remote', 'get-url', 'origin'], {
    cwd: dir,
    encoding: 'utf8',
    timeout: 5000
  });
  return result.status === 0 ? result.stdout.trim() : null;
}

module.exports = { normalizeGitHubUrl, ghRepoExists, getGitRemote };
