Inbox Protocol Test
===================

Verifies: inbound branches are detected in PEER's clone, not own hub.

Protocol: peer pushes <my-name>/* branch to THEIR repo, I fetch and detect.

Setup:

  $ export NO_COLOR=1
  $ chmod +x cn.sh
  $ CN="$(pwd)/cn.sh"

Create my hub (cn-sigma → name derives to "sigma"):

  $ mkdir -p cn-sigma/.cn peer-clone
  $ cd cn-sigma
  $ git init -q -b main
  $ git config user.email "test@test"
  $ git config user.name "Sigma"
  $ echo "# Sigma Hub" > README.md
  $ git add -A && git commit -q -m "init"

  $ echo '{"name":"sigma","version":"1.0.0"}' > .cn/config.json
  $ mkdir -p state threads/mail/inbox
  $ cat > state/peers.md << 'EOF'
  > # Peers
  > 
  > ```yaml
  > - name: pi
  >   clone: ../peer-clone
  >   kind: agent
  > ```
  > EOF
  $ git add -A && git commit -q -m "add peers"

Create peer clone (simulating pi's repo with sigma/* branch):

  $ cd ../peer-clone
  $ git init -q -b main
  $ git config user.email "pi@test"
  $ git config user.name "Pi"
  $ echo "# Pi Hub" > README.md
  $ mkdir -p threads/mail/outbox
  $ git add -A && git commit -q -m "init"

Create message branch and make it look like origin/sigma/*:

  $ git checkout -q -b tmp-branch
  $ cat > threads/mail/outbox/test.md << 'EOF'
  > ---
  > to: sigma
  > from: pi
  > created: 2026-02-09
  > ---
  > Hello from pi!
  > EOF
  $ git add -A && git commit -q -m "message for sigma"
  $ COMMIT=$(git rev-parse HEAD)
  $ git checkout -q main
  $ git update-ref refs/remotes/origin/sigma/test-message $COMMIT
  $ git branch -D tmp-branch > /dev/null

Verify remote branch exists in peer clone:

  $ git branch -r
    origin/sigma/test-message

Test: cn inbox detects inbound from peer's clone (not own hub):

  $ cd ../cn-sigma
  $ $CN inbox 2>&1 | grep -E "(From pi:|sigma/)"
  ⚠ From pi: 1 inbound
    ← sigma/test-message
