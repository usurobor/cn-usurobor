// Semantic CLI logger utility
// Color = meaning, not decoration. 6 colors max.

const useColor = !process.env.NO_COLOR;

const codes = {
  reset: '\x1b[0m',
  bold: '\x1b[1m',
  green: '\x1b[32m',    // ✓ success/ok
  red: '\x1b[31m',      // ✗ error/blocking
  yellow: '\x1b[33m',   // ⚠ warning/attention
  cyan: '\x1b[36m',     // ℹ info/headers
  magenta: '\x1b[35m',  // ▶ user action/commands
  gray: '\x1b[90m',     // - inactive/skipped
};

const wrap = (code, str) => useColor ? `${code}${str}${codes.reset}` : str;

const log = {
  // Semantic outputs
  success: (msg) => console.log(wrap(codes.green, `✓ ${msg}`)),
  error: (msg) => console.log(wrap(codes.red, `✗ ${msg}`)),
  warn: (msg) => console.log(wrap(codes.yellow, `⚠ ${msg}`)),
  info: (msg) => console.log(wrap(codes.cyan, msg)),
  action: (msg) => console.log(wrap(codes.magenta, `  ${msg}`)),
  skip: (msg) => console.log(wrap(codes.gray, `  ${msg}`)),
  
  // Header (bold + cyan)
  header: (msg) => console.log(wrap(codes.bold + codes.cyan, msg)),
  
  // Status check row: label............. ✓/✗/--
  check: (label, status, detail) => {
    const dots = '.'.repeat(Math.max(1, 20 - label.length));
    const detailStr = detail ? ` ${wrap(codes.gray, `(${detail})`)}` : '';
    if (status === true) {
      console.log(`  ${label}${dots} ${wrap(codes.green, '✓')}${detailStr}`);
    } else if (status === false) {
      console.log(`  ${label}${dots} ${wrap(codes.red, '✗')}`);
    } else {
      console.log(`  ${label}${dots} ${wrap(codes.gray, '--')}`);
    }
  },
  
  // Error block with commands
  errorBlock: (title, items, commands) => {
    console.log('');
    console.log(wrap(codes.red, `✗ ${title}`));
    if (items && items.length) {
      for (const item of items) {
        console.log(`  • ${item}`);
      }
    }
    if (commands && commands.length) {
      console.log('');
      console.log('Fix with:');
      for (const cmd of commands) {
        console.log(wrap(codes.magenta, `  ${cmd}`));
      }
    }
    console.log('');
  },
  
  // Raw colors for custom use
  green: (str) => wrap(codes.green, str),
  red: (str) => wrap(codes.red, str),
  yellow: (str) => wrap(codes.yellow, str),
  cyan: (str) => wrap(codes.cyan, str),
  magenta: (str) => wrap(codes.magenta, str),
  gray: (str) => wrap(codes.gray, str),
  bold: (str) => wrap(codes.bold, str),
};

module.exports = log;
