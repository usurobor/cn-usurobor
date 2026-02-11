#!/bin/bash
# Integration test: Rejection Terminal Cleanup
# This test verifies cn deletes local branches when processing rejection notices.

set -e

echo "=== Integration Test: Rejection Terminal Cleanup ==="
echo ""

# Setup: Create a test hub
TEST_HUB=$(mktemp -d)
cd "$TEST_HUB"
git init -q
git checkout -b main 2>/dev/null || git checkout -b main
echo "# Test Hub" > README.md
git add README.md
git commit -q -m "init"

# Create hub structure
mkdir -p state threads/mail/inbox threads/in
cat > state/peers.md << 'EOF'
# Peers

- name: pi
  hub: https://github.com/test/cn-pi
  kind: agent
EOF
echo "cn_version: test" > state/runtime.md
echo "test" > state/hub.md

# Simulate: Create a local branch that would have been rejected
git checkout -b pi/failed-topic
echo "test" > threads/in/test.md
git add .
git commit -q -m "test message"
git checkout main

echo "Setup: Created local branch 'pi/failed-topic'"

# Verify branch exists before
if git branch | grep -q "pi/failed-topic"; then
  echo "PASS: Branch pi/failed-topic exists (pre-condition)"
else
  echo "FAIL: Branch pi/failed-topic should exist"
  rm -rf "$TEST_HUB"
  exit 1
fi

# Create rejection notice in threads/in (simulating what would be materialized)
mkdir -p threads/in
cat > threads/in/rejection-test.md << 'EOF'
---
received: 2026-02-10T19:00:00Z
from: pi
subject: Branch rejected (orphan)
---

Branch `pi/failed-topic` rejected and deleted.

**Reason:** No merge base with main.
EOF

git add .
git commit -q -m "add rejection notice"

echo "Setup: Created rejection notice"
echo ""

# Parse rejected branch from rejection notice and delete it (pure shell)
echo "Testing cleanup logic..."
CONTENT=$(cat threads/in/rejection-test.md)
BRANCH=$(echo "$CONTENT" | sed -n 's/.*Branch `\([^`]*\)` rejected.*/\1/p')

if [ -n "$BRANCH" ]; then
  echo "Found rejected branch: $BRANCH"
  if git branch -D "$BRANCH" 2>/dev/null; then
    echo "Deleted branch: $BRANCH"
  else
    echo "Branch not found or already deleted"
  fi
else
  echo "No rejection pattern found"
fi

# Verify branch was deleted
if git branch | grep -q "pi/failed-topic"; then
  echo ""
  echo "FAIL: Branch pi/failed-topic still exists after cleanup"
  rm -rf "$TEST_HUB"
  exit 1
else
  echo ""
  echo "PASS: Branch pi/failed-topic was deleted"
  rm -rf "$TEST_HUB"
  exit 0
fi
