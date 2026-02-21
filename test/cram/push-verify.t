Push Verification Test
======================

Verifies: outbox flush verifies push landed via ls-remote,
not just exit code. Guards against silent push failures.

Setup:

  $ chmod +x cn.sh
  $ CN="$(pwd)/cn.sh"

Create sender hub:

  $ mkdir -p hub/.cn hub/state hub/threads/mail/outbox hub/threads/mail/sent
  $ cd hub
  $ git init -q -b main
  $ git config user.email "sigma@test"
  $ git config user.name "Sigma"
  $ echo "# Hub" > README.md
  $ git add -A && git commit -q -m "init"

Create bare origin:

  $ cd ..
  $ git clone --bare hub hub-origin 2>&1 | grep -v "^Cloning"
  done.
  $ cd hub
  $ git remote remove origin 2>/dev/null; git remote add origin "file://$(pwd)/../hub-origin"

Create peer clone:

  $ cd ..
  $ mkdir peer-clone
  $ cd peer-clone
  $ git init -q -b main
  $ git config user.email "pi@test"
  $ git config user.name "Pi"
  $ echo "# Peer" > README.md
  $ git add -A && git commit -q -m "init"
  $ cd ..

Configure hub:

  $ cd hub
  $ echo '{"name":"sigma","version":"1.0.0"}' > .cn/config.json
  $ cat > state/peers.md << 'EOF'
  > # Peers
  > 
  > ```yaml
  > - name: pi
  >   clone: ../peer-clone
  >   kind: agent
  > ```
  > EOF
  $ git add -A && git commit -q -m "config"
  $ git push origin main -q

Test 1: Normal send — push succeeds and is verified:

  $ cat > threads/mail/outbox/test-msg.md << 'EOF'
  > ---
  > to: pi
  > created: 2026-02-21
  > ---
  > Test message
  > EOF

  $ $CN sync 2>&1 | grep -E "(Sent|Flushing|flush)"
  Flushing 1 thread(s)...
  ✓ Sent to pi: test-msg.md
  ✓ Outbox flush complete

Verify branch exists on origin:

  $ git ls-remote ../hub-origin refs/heads/pi/test-msg 2>/dev/null | grep -c "pi/test-msg"
  1

Verify message moved to sent:

  $ ls threads/mail/outbox/
  $ ls threads/mail/sent/ | grep test-msg
  test-msg.md

Test 2: Verify sent file has correct state:

  $ grep "state:" threads/mail/sent/test-msg.md
  state: sent
