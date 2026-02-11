# tools/

Native OCaml CLI and libraries.

## cn CLI

The `cn` command is a native OCaml binary. Source: `tools/src/cn/`.

```bash
# Build
dune build tools/src/cn/cn.exe

# Run
./_build/default/tools/src/cn/cn.exe --version

# Test
dune runtest
```

See [CLI.md](../docs/design/CLI.md) for command reference.

## Structure

```
tools/
 +-- src/
 |    +-- cn/              Native CLI (14 modules)
 |    |    +-- cn.ml           Dispatch
 |    |    +-- cn_protocol.ml  4 typed FSMs
 |    |    +-- cn_agent.ml     Agent loop, queue
 |    |    +-- cn_mail.ml      Inbox/outbox transport
 |    |    +-- cn_gtd.ml       GTD lifecycle
 |    |    +-- ...
 |    +-- inbox/
 |         +-- inbox_lib.ml   Pure triage types (used by cn_lib)
 +-- test/
      +-- cn/              ppx_expect unit tests
      +-- inbox/           ppx_expect unit tests
```

## Building

Requires OCaml toolchain:

```bash
opam install dune ppx_expect ppxlib mdx
eval $(opam env)
dune build tools/src/cn/cn.exe
dune runtest
```

## Automation

See [AUTOMATION.md](../docs/how-to/AUTOMATION.md) for cron setup. The pattern:

1. System cron runs `cn sync` every 5 minutes
2. cn fetches peers, materializes inbox, queues items
3. Agent processes one item at a time via input.md/output.md

Zero tokens for routine checks. AI only on decisions.
