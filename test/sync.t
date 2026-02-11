Setup:

  $ chmod +x cn.sh
  $ CN="$(pwd)/cn.sh"

Setup test hub:

  $ mkdir -p test-hub/.cn test-hub/state test-hub/threads/mail/inbox test-hub/threads/mail/outbox
  $ cd test-hub
  $ echo 'name: test' > .cn/config.yaml
  $ echo '# Peers' > state/peers.md
  $ git init -q
  $ git config user.email "test@example.com"
  $ git config user.name "Test"
  $ git add -A
  $ git commit -q -m "init"

Sync shows dry-run banner:

  $ $CN sync --dry-run 2>&1 | head -4
  ⚠ DRY RUN — no changes will be made
  Syncing...
  Checking inbox for test-hub...
  ✓ Inbox clear

Status works:

  $ $CN status 2>&1 | head -1
  cn hub: test-hub
