CN CLI Tests
=============

Setup:

  $ export NO_COLOR=1
  $ chmod +x cn.sh
  $ export CN="$(pwd)/cn.sh"

Help:

  $ $CN --help | head -5
  cn - Coherent Network agent CLI
  
  Usage: cn <command> [options]
  
  Commands:

Version:

  $ $CN --version
  cn 2.3.0

Init - create a new hub:

  $ mkdir test-init && cd test-init
  $ git init -q
  $ git config user.email "test@test.local"
  $ git config user.name "Test"
  $ $CN init my-hub 2>&1 | head -3
  Initializing hub: my-hub
  hint: Using 'master' as the name for the initial branch. This default branch name
  hint: is subject to change. To configure the initial branch name to use in all

Status - check hub status:

  $ cd cn-my-hub
  $ $CN status 2>&1 | grep -E "^(cn hub|name\.)"
  cn hub: my-hub
  name.................... ✓ my-hub

Inbox (empty):

  $ $CN inbox 2>&1 | grep -v "^Checking"
  ✓ Inbox clear

Outbox (empty):

  $ $CN outbox 2>&1 | grep -v "^Checking"
  ✓ Outbox clear

Send (self-message):

  $ $CN send self "Test message" 2>&1 | head -1
  ✓ Created message to self: test-message

Outbox (with message):

  $ $CN outbox 2>&1 | grep "test-message"
    → self: test-message.md

Doctor - health check:

  $ $CN doctor 2>&1 | head -2
  cn v2.3.0
  Checking health...

Aliases:

  $ $CN i 2>&1 | grep -v "^Checking"
  ✓ Inbox clear

  $ $CN s 2>&1 | grep "^cn hub"
  cn hub: my-hub
