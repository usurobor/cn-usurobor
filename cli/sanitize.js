// Sanitize agent name for use as a GitHub repo name component.
// Returns { valid: true, name: string } or { valid: false, error: string }.

function sanitizeName(input) {
  if (!input || typeof input !== 'string') {
    return { valid: false, error: 'agent name is required' };
  }

  // Lowercase, replace spaces with hyphens, strip non-alphanumeric/hyphen chars
  const sanitized = input
    .toLowerCase()
    .replace(/\s+/g, '-')
    .replace(/[^a-z0-9-]/g, '');

  if (!sanitized || sanitized === '-') {
    return { valid: false, error: 'agent name must contain at least one alphanumeric character' };
  }

  if (sanitized.startsWith('-') || sanitized.endsWith('-')) {
    return { valid: false, error: 'agent name must contain at least one alphanumeric character' };
  }

  return { valid: true, name: sanitized };
}

module.exports = { sanitizeName };
