CN CLI Tests
=============

Setup:

  $ export NO_COLOR=1
  $ chmod +x cn.sh
  $ export CN="$(pwd)/cn.sh"
  $ CNOS_VERSION=$(cat ../../../VERSION | tr -d '\n')

Help:

  $ $CN --help | head -5
  cn - Coherent Network agent CLI

  Usage: cn <command> [options]

  Commands:

Version (derived from VERSION file, not hardcoded):

  $ ACTUAL=$($CN --version)
  $ EXPECTED="cn $CNOS_VERSION"
  $ [ "$ACTUAL" = "$EXPECTED" ] && echo "version ok" || echo "MISMATCH: got '$ACTUAL' expected '$EXPECTED'"
  version ok

Init - create a new hub:

  $ mkdir test-init && cd test-init
  $ git init -q
  $ git config --global user.email "test@test.local"
  $ git config --global user.name "Test"
  $ $CN init my-hub 2>&1 | head -3
  Initializing hub: my-hub
  * Updated state/runtime.md (glob)
  Installing cognitive packages...

Status - check hub status:

  $ cd cn-my-hub
  $ $CN status 2>&1 | grep -E "^(cn hub|name\.)"
  cn hub: my-hub
  name.................... * my-hub (glob)

Inbox (empty):

  $ $CN inbox 2>&1 | grep -v "^Checking"
  * Inbox clear (glob)

Outbox (empty):

  $ $CN outbox 2>&1 | grep -v "^Checking"
  * Outbox clear (glob)

Send (self-message):

  $ $CN send self "Test message" 2>&1 | head -1
  * Created message to self: test-message (glob)

Outbox (with message):

  $ $CN outbox 2>&1 | grep "test-message"
  * test-message.md (glob)

Doctor - health check (version derived from VERSION file):

  $ DOCTOR_LINE=$($CN doctor 2>&1 | head -1)
  $ EXPECTED_DOC="cn v$CNOS_VERSION"
  $ [ "$DOCTOR_LINE" = "$EXPECTED_DOC" ] && echo "doctor version ok" || echo "MISMATCH: got '$DOCTOR_LINE' expected '$EXPECTED_DOC'"
  doctor version ok

Aliases:

  $ $CN i 2>&1 | grep -v "^Checking"
  * Inbox clear (glob)

  $ $CN s 2>&1 | grep "^cn hub"
  cn hub: my-hub
