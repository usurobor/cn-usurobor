Setup:

  $ chmod +x cn.sh
  $ CN="$(pwd)/cn.sh"

Setup test hub with outbox message:

  $ mkdir -p test-hub/.cn test-hub/state test-hub/threads/mail/inbox test-hub/threads/mail/outbox test-hub/threads/mail/sent
  $ cd test-hub
  $ echo 'name: sender' > .cn/config.yaml
  $ cat > state/peers.md << 'EOF'
  > # Peers
  > - name: recipient
  >   hub: https://example.com/recipient
  > EOF
  $ git init -q
  $ git config user.email "test@example.com"
  $ git config user.name "Test"
  $ git add -A
  $ git commit -q -m "init"

Create outbox message:

  $ cat > threads/mail/outbox/hello.md << 'EOF'
  > ---
  > to: recipient
  > created: 2026-01-01T00:00:00Z
  > ---
  > Hello!
  > EOF

Outbox check shows pending:

  $ $CN outbox 2>&1
  ⚠ 1 pending send(s):
    → recipient: hello.md

Dry-run shows would send (but fails - no clone path):

  $ $CN sync --dry-run 2>&1 | grep -E "(Would:|No clone)"
  ✗ No clone path for peer: recipient

Message still in outbox:

  $ ls threads/mail/outbox/
  hello.md
