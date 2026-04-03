No Cross-Delete Test
=====================

Hard rule: receiver NEVER deletes sender's packet refs.
Only the sender manages their own refs/cn/msg/ namespace.

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

Create pi's repo with a packet ref (message addressed to sigma):

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

Create packet ref in pi-origin (simulating Pi sending a message to Sigma):

  $ cd pi-hub
  $ PAYLOAD="Hello Sigma!"
  $ PAYLOAD_SHA=$(printf '%s' "$PAYLOAD" | shasum -a 256 | cut -d' ' -f1)
  $ PAYLOAD_BYTES=$(printf '%s' "$PAYLOAD" | wc -c | tr -d ' ')
  $ ENVELOPE=$(printf '{"schema":"cn.packet.v1","msg_id":"hello-001@pi","sender":"pi","recipient":"sigma","created_at":"2026-02-21T00:00:00Z","content_type":"text/markdown","payload_path":"packet/message.md","payload_sha256":"%s","payload_bytes":%s,"topic":"hello-from-pi","protocol":{"transport_kind":"git","packet_version":1}}' "$PAYLOAD_SHA" "$PAYLOAD_BYTES")
  $ ENV_BLOB=$(printf '%s' "$ENVELOPE" | git hash-object -w --stdin)
  $ PAY_BLOB=$(printf '%s' "$PAYLOAD" | git hash-object -w --stdin)
  $ SUBTREE=$(printf '100644 blob %s\tenvelope.json\n100644 blob %s\tmessage.md' "$ENV_BLOB" "$PAY_BLOB" | git mktree)
  $ ROOT_TREE=$(printf '040000 tree %s\tpacket' "$SUBTREE" | git mktree)
  $ COMMIT=$(git commit-tree "$ROOT_TREE" -m "packet: pi -> sigma [hello-from-pi]")
  $ git update-ref refs/cn/msg/pi/hello-001@pi "$COMMIT"
  $ git push -q origin refs/cn/msg/pi/hello-001@pi
  $ cd ..

Create pi-clone for sigma (sigma's local clone of pi's repo):

  $ git clone pi-origin pi-clone 2>&1 | grep -v "^Cloning"
  done.
  $ cd pi-clone
  $ git config user.email "sigma@test"
  $ git config user.name "Sigma"
  $ git fetch origin '+refs/cn/msg/pi/*:refs/remotes/origin/cn/msg/pi/*' 2>&1 | grep -v "^From"
   * [new ref]         refs/cn/msg/pi/hello-001@pi -> origin/cn/msg/pi/hello-001@pi
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

Verify packet ref exists on pi-origin before sync:

  $ git -C ../pi-origin for-each-ref --format='%(refname)' refs/cn/msg/pi/
  refs/cn/msg/pi/hello-001@pi

Run sync -- should materialize the message:

  $ $CN sync 2>&1 | grep "Materialized" | sed 's/[0-9]\{8\}-[0-9]\{6\}/TIMESTAMP/g'
  ✓ Materialized: TIMESTAMP-pi-hello-from-pi.md

Verify message was materialized in inbox:

  $ ls threads/mail/inbox/ | grep "pi-hello-from-pi" | sed 's/[0-9]\{8\}-[0-9]\{6\}/TIMESTAMP/'
  TIMESTAMP-pi-hello-from-pi.md

CRITICAL: Verify sender's packet ref was NOT deleted from pi-origin:

  $ git -C ../pi-origin for-each-ref --format='%(refname)' refs/cn/msg/pi/
  refs/cn/msg/pi/hello-001@pi

Packet ref still exists on pi-origin. Receiver did not delete sender's ref.

Run sync again -- should detect duplicate, still not delete:

  $ $CN sync 2>&1 | grep -E "(duplicate|Duplicate)" | sed 's/[0-9]\{8\}-[0-9]\{6\}/TIMESTAMP/g'
    Duplicate packet: hello-001@pi

Sender's packet ref STILL exists after second sync:

  $ git -C ../pi-origin for-each-ref --format='%(refname)' refs/cn/msg/pi/
  refs/cn/msg/pi/hello-001@pi
