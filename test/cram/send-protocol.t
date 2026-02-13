Send Protocol Test
==================

Verifies: send pushes to MY origin (push-to-self), not peer's clone.

Protocol: sender creates <recipient>/* branch in OWN repo.
Peer fetches sender's repo to see branches addressed to them.

Setup:

  $ chmod +x cn.sh
  $ CN="$(pwd)/cn.sh"

Create sender hub (cn-sigma):

  $ mkdir -p cn-sigma/.cn cn-sigma/state cn-sigma/threads/mail/outbox cn-sigma/threads/mail/sent
  $ cd cn-sigma
  $ git init -q -b main
  $ git config user.email "sigma@test"
  $ git config user.name "Sigma"
  $ echo "# Sigma Hub" > README.md
  $ git add -A && git commit -q -m "init"
  $ git remote add origin "file://$(pwd)/../sigma-origin"

  $ echo '{"name":"sigma","version":"1.0.0"}' > .cn/config.json
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

Create bare origin for sigma (to receive pushes):

  $ cd ..
  $ git clone --bare cn-sigma sigma-origin 2>&1 | grep -v "^Cloning"
  done.

Create pi-clone (sigma's clone of pi's repo):

  $ mkdir pi-clone
  $ cd pi-clone
  $ git init -q -b main
  $ git config user.email "pi@test"
  $ git config user.name "Pi"
  $ echo "# Pi Hub" > README.md
  $ git add -A && git commit -q -m "init"
  $ git remote add origin "file://$(pwd)/../pi-origin"
  $ cd ..

Create bare origin for pi:

  $ git clone --bare pi-clone pi-origin 2>&1 | grep -v "^Cloning"
  done.

Create outbox message in sigma:

  $ cd cn-sigma
  $ cat > threads/mail/outbox/hello.md << 'EOF'
  > ---
  > to: pi
  > created: 2026-02-09
  > ---
  > Hello Pi!
  > EOF

Run sync to send:

  $ $CN sync 2>&1 | grep -E "(Sent|Flushing)"
  Flushing 1 thread(s)...
  ✓ Sent to pi: hello.md

Verify: branch pushed to MY origin (sigma-origin), not pi's:

  $ git -C ../sigma-origin branch | grep "pi/"
    pi/hello

  $ git -C ../pi-origin branch | grep "sigma/"
  [1]

The branch pi/hello should be in sigma-origin (my repo).
No sigma/* branch should be in pi-origin (peer's repo).
