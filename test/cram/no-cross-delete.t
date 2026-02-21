No Cross-Delete Test
=====================

Hard rule: receiver NEVER deletes sender's branches.
Only the branch owner deletes their own branches.

Setup:

  $ chmod +x cn.sh
  $ CN="$(pwd)/cn.sh"

Create receiver hub (cn-sigma):

  $ mkdir -p cn-sigma/.cn cn-sigma/state cn-sigma/threads/mail/inbox cn-sigma/threads/mail/outbox cn-sigma/threads/mail/sent
  $ cd cn-sigma
  $ git init -q -b main
  $ git config user.email "sigma@test"
  $ git config user.name "Sigma"
  $ echo "# Sigma Hub" > README.md
  $ echo '{"name":"sigma","version":"1.0.0"}' > .cn/config.json
  $ git add -A && git commit -q -m "init"
  $ git remote add origin "file://$(pwd)/../sigma-origin"
  $ cd ..
  $ git clone --bare cn-sigma sigma-origin 2>&1 | grep -v "^Cloning"
  done.

Create pi's repo with a sigma/* branch (message addressed to sigma):

  $ mkdir pi-hub
  $ cd pi-hub
  $ git init -q -b main
  $ git config user.email "pi@test"
  $ git config user.name "Pi"
  $ echo "# Pi Hub" > README.md
  $ git add -A && git commit -q -m "init"
  $ git remote add origin "file://$(pwd)/../pi-origin"
  $ cd ..
  $ git clone --bare pi-hub pi-origin 2>&1 | grep -v "^Cloning"
  done.

Push a sigma/* branch to pi-origin (simulating Pi sending a message to Sigma):

  $ cd pi-hub
  $ git checkout -q -b sigma/hello-from-pi
  $ mkdir -p threads/in
  $ cat > threads/in/hello-from-pi.md << 'EOF'
  > ---
  > to: sigma
  > from: pi
  > created: 2026-02-21
  > ---
  > Hello Sigma!
  > EOF
  $ git add -A && git commit -q -m "pi: hello-from-pi"
  $ git push -q -u origin sigma/hello-from-pi
  $ git checkout -q main
  $ cd ..

Create pi-clone for sigma (sigma's local clone of pi's repo):

  $ git clone pi-origin pi-clone 2>&1 | grep -v "^Cloning"
  done.
  $ cd pi-clone
  $ git config user.email "sigma@test"
  $ git config user.name "Sigma"
  $ cd ..

Configure sigma's peers:

  $ cd cn-sigma
  $ cat > state/peers.md << 'EOF'
  > # Peers
  > 
  > ```yaml
  > - name: pi
  >   clone: ../pi-clone
  >   kind: agent
  > ```
  > EOF
  $ git add -A && git commit -q -m "add peers"
  $ git push -q origin main

Verify branch exists on pi-origin before sync:

  $ git -C ../pi-origin branch | grep "sigma/"
    sigma/hello-from-pi

Run sync — should materialize the message:

  $ $CN sync 2>&1 | grep -E "(Materialized|From pi)"
  ⚠ From pi: 1 inbound
  ✓ Materialized: 20260221-121722-pi-hello-from-pi.md

Verify message was materialized in inbox:

  $ ls threads/mail/inbox/ | grep "pi-hello-from-pi"
  20260221-121722-pi-hello-from-pi.md

CRITICAL: Verify sender's branch was NOT deleted from pi-origin:

  $ git -C ../pi-origin branch | grep "sigma/"
    sigma/hello-from-pi

Branch still exists on pi-origin. Receiver did not delete sender's branch. ✓

Run sync again — should detect duplicate, still not delete:

  $ $CN sync 2>&1 | grep -E "(duplicate|Skipping|no inbound|From pi)"
  ⚠ From pi: 1 inbound
    Skipping duplicate: sigma/hello-from-pi

Sender's branch STILL exists after second sync:

  $ git -C ../pi-origin branch | grep "sigma/"
    sigma/hello-from-pi
