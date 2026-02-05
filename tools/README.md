# tools/

OCaml tools compiled to JavaScript via Melange.

## Philosophy

**Tokens for thinking. Electrons for clockwork.**

Tools handle mechanical work (git fetching, branch detection) so AI can focus on judgment (what to do about inbound messages).

## Available Tools

### inbox

Check and process inbound messages from peers.

```bash
# Check for inbound branches
node tools/dist/inbox.js check ./cn-sigma sigma

# Process one message (interactive triage)
node tools/dist/inbox.js process ./cn-sigma sigma

# Process all messages
node tools/dist/inbox.js flush ./cn-sigma sigma
```

Actions are type-safe (OCaml variants):
```ocaml
type action =
  | Check    (* list inbound branches *)
  | Process  (* triage one message *)
  | Flush    (* triage all messages *)
```

Exit codes:
- 0: No inbound branches
- 1: Error (missing files, invalid args)
- 2: Inbound branches found (alert)

### peer-sync (deprecated)

Renamed to `inbox`. Use `inbox check` instead.

## Structure

```
tools/
├── src/           ← OCaml source
│   └── inbox/
│       ├── inbox.ml       # CLI with Node.js bindings
│       ├── inbox_lib.ml   # Pure functions (testable)
│       └── dune
├── test/          ← ppx_expect tests
│   └── inbox/
│       ├── inbox_test.ml
│       └── dune
└── dist/          ← Bundled JS (committed)
    └── inbox.js   # Single-file, no deps
```

## Building

Requires OCaml toolchain (see docs/AUTOMATION.md for setup).

```bash
# Build
dune build @inbox

# Test
dune runtest

# Bundle
npx esbuild _build/default/tools/src/inbox/output/tools/src/inbox/inbox.js \
  --bundle --platform=node --outfile=tools/dist/inbox.js
```

## Automation

See `docs/AUTOMATION.md` for cron setup. The pattern:

1. System cron runs `inbox check` every N minutes
2. Exit code 2 → trigger OpenClaw system event
3. AI evaluates and responds to inbound messages

Zero tokens for routine checks. AI only on alerts.
