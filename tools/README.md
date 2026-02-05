# Tools

OCaml tools compiled to JavaScript via Melange.

## Structure

```
tools/
├── src/          ← OCaml source
│   └── peer-sync/
├── test/         ← ppx_expect tests
│   └── peer-sync/
└── dist/         ← Pre-built JS (committed, single file per tool)
    └── peer-sync.js
```

## For Users

Just run the pre-built JS:

```bash
node tools/dist/peer-sync.js <hub-path>
```

No OCaml required.

## For Contributors

### Prerequisites

```bash
opam install dune melange ppx_expect ppxlib
npm install -g esbuild
```

### Build

```bash
eval $(opam env)
dune build @peer-sync    # compile
dune runtest             # test
```

### Bundle for dist

```bash
esbuild _build/default/tools/src/peer-sync/output/tools/src/peer-sync/peer_sync.js \
  --bundle --platform=node --outfile=tools/dist/peer-sync.js
```

### Adding a new tool

1. Create `tools/src/<tool-name>/` with `.ml` files and `dune`
2. Create `tools/test/<tool-name>/` with test file and `dune`
3. Add alias to dune: `(alias <tool-name>)`
4. Build, test, bundle to `tools/dist/<tool-name>.js`

## Why OCaml?

We're an OCaml shop. Type safety, pattern matching, and functional style.

See [mindsets/FUNCTIONAL.md](../mindsets/FUNCTIONAL.md) for the philosophy.
