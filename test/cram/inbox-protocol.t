Inbox Protocol Test
===================

Verifies: inbound packet refs are detected in PEER's clone, not own hub.

Protocol: sender creates refs/cn/msg/{sender}/{msg_id} packet refs in THEIR repo.
Receiver fetches sender's repo to see packet refs addressed to them.

Setup:

  $ export NO_COLOR=1
  $ chmod +x cn.sh
  $ CN="$(pwd)/cn.sh"

Create my hub (cn-sigma -> name derives to "sigma"):

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

Create peer clone (simulating pi's repo with a packet ref for sigma):

  $ cd ../peer-clone
  $ git init -q -b main
  $ git config user.email "pi@test"
  $ git config user.name "Pi"
  $ echo "# Pi Hub" > README.md
  $ git add -A && git commit -q -m "init"

Create a packet ref with envelope + payload:

  $ PAYLOAD="Hello from pi!"
  $ PAYLOAD_SHA=$(printf '%s' "$PAYLOAD" | shasum -a 256 | cut -d' ' -f1)
  $ PAYLOAD_BYTES=$(printf '%s' "$PAYLOAD" | wc -c | tr -d ' ')
  $ ENVELOPE=$(printf '{"schema":"cn.packet.v1","msg_id":"test-msg-001@pi","sender":"pi","recipient":"sigma","created_at":"2026-04-03T00:00:00Z","content_type":"text/markdown","payload_path":"packet/message.md","payload_sha256":"%s","payload_bytes":%s,"topic":"hello","protocol":{"transport_kind":"git","packet_version":1}}' "$PAYLOAD_SHA" "$PAYLOAD_BYTES")
  $ ENV_BLOB=$(printf '%s' "$ENVELOPE" | git hash-object -w --stdin)
  $ PAY_BLOB=$(printf '%s' "$PAYLOAD" | git hash-object -w --stdin)
  $ SUBTREE=$(printf '100644 blob %s\tenvelope.json\n100644 blob %s\tmessage.md' "$ENV_BLOB" "$PAY_BLOB" | git mktree)
  $ ROOT_TREE=$(printf '040000 tree %s\tpacket' "$SUBTREE" | git mktree)
  $ COMMIT=$(git commit-tree "$ROOT_TREE" -m "packet: pi -> sigma [hello]")
  $ git update-ref refs/remotes/origin/cn/msg/pi/test-msg-001@pi "$COMMIT"

Verify packet ref exists in peer clone:

  $ git for-each-ref --format='%(refname)' refs/remotes/origin/cn/msg/
  refs/remotes/origin/cn/msg/pi/test-msg-001@pi

Test: cn inbox detects inbound packet from peer's clone:

  $ cd ../cn-sigma
  $ $CN inbox 2>&1 | grep -E "(From pi:|refs/cn/msg)"
  ⚠ From pi: 1 inbound packet(s)
    ← refs/cn/msg/pi/test-msg-001@pi
