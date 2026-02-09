# Agent Output Tests
# Tests for cn out command - the ONLY way agent can output decisions

Setup:

  $ export NO_COLOR=1
  $ chmod +x cn.sh
  $ CN="$(pwd)/cn.sh"

# =============================================================================
# Missing args → Unknown command (current behavior)
# =============================================================================

cn out do reply without --message returns unknown command:

  $ $CN out do reply 2>&1 | head -1
  ✗ Unknown command: out

cn out defer without --reason returns unknown command:

  $ $CN out defer 2>&1 | head -1
  ✗ Unknown command: out

cn out delegate without --to returns unknown command:

  $ $CN out delegate 2>&1 | head -1
  ✗ Unknown command: out

cn out delete without --reason returns unknown command:

  $ $CN out delete 2>&1 | head -1
  ✗ Unknown command: out

# =============================================================================
# Valid commands with hub context
# =============================================================================

Create test hub:

  $ mkdir -p test-hub/.cn test-hub/state test-hub/threads/mail/outbox test-hub/logs/runs
  $ echo '{"name":"test","version":"1.0.0"}' > test-hub/.cn/config.json
  $ cd test-hub
  $ git init -q -b main
  $ git config user.email "test@test"
  $ git config user.name "Test"
  $ git add -A && git commit -q -m "init" --allow-empty

Create input.md:

  $ cat > state/input.md << 'EOF'
  > ---
  > id: test-123
  > from: pi
  > queued: 2026-02-09T00:00:00Z
  > ---
  > Test message from pi
  > EOF

cn out do reply with message:

  $ $CN out do reply --message "LGTM" 2>&1 | grep -E "(State|Run complete)"
  ✓ State cleared
  ✓ Run complete: do (test-123)

Verify output.md exists (cn writes before execution):

  $ test -f state/output.md && echo "output.md exists" || echo "output.md missing"
  output.md exists

Verify outbox message created:

  $ ls threads/mail/outbox/
  pi-reply-test-123.md

  $ cat threads/mail/outbox/pi-reply-test-123.md | grep -E "^(to|in-reply-to):"
  to: pi
  in-reply-to: test-123
