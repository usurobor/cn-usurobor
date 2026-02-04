// Build hub configuration from sanitized name and owner.
// Returns { hubName, hubRepo, hubUrl, hubDir }

function buildHubConfig(sanitizedName, owner, workspaceRoot) {
  const hubName = 'cn-' + sanitizedName;
  const hubRepo = `${owner}/${hubName}`;
  const hubUrl = `https://github.com/${hubRepo}`;
  const hubDir = workspaceRoot + '/' + hubName;
  
  return { hubName, hubRepo, hubUrl, hubDir };
}

module.exports = { buildHubConfig };
