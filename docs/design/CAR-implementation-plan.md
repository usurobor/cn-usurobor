# CAR v3.4 Implementation Plan

## Overview

Implement the Cognitive Asset Resolver per CAR-v3.4.md. The work is ordered
so each step compiles and tests independently — no big-bang integration.

---

## Step 1: Add `Deps` command type to `cn_lib.ml`

**File:** `src/lib/cn_lib.ml`

Add command variants for the `cn deps` subcommands:

```ocaml
(* Add to the command type *)
| Deps of Deps.cmd

(* New submodule *)
module Deps = struct
  type cmd = List | Restore | Doctor | Add of string | Remove of string
           | Update of string option | Vendor
end
```

Add to `parse_command`:
- `["deps"; "list"]` → `Deps Deps.List`
- `["deps"; "restore"]` → `Deps Deps.Restore`
- `["deps"; "doctor"]` → `Deps Deps.Doctor`
- `["deps"; "add"; pkg]` → `Deps (Deps.Add pkg)`
- `["deps"; "remove"; pkg]` → `Deps (Deps.Remove pkg)`
- `["deps"; "update"]` → `Deps (Deps.Update None)`
- `["deps"; "update"; pkg]` → `Deps (Deps.Update (Some pkg))`
- `["deps"; "vendor"]` → `Deps Deps.Vendor`

Add to `help_text`.

**Tests:** `cn deps list` parses without error. Existing commands unchanged.

---

## Step 2: Create `cn_assets.ml` — three-layer asset resolver

**New file:** `src/cmd/cn_assets.ml`

This is the core module. Pure functions that resolve assets from the three layers.

### Types

```ocaml
type asset_source = Core | Package of string | Hub_local

type resolved_mindset = {
  name : string;        (* e.g. "COHERENCE.md" *)
  content : string;
  source : asset_source;
}

type resolved_skill = {
  rel_path : string;    (* relative path for dedup, e.g. "agent/agent-ops" *)
  content : string;
  source : asset_source;
}

type asset_summary = {
  profile : string option;
  core_mindsets : int;
  core_skills : int;
  packages : (string * int) list;  (* name, skill count *)
  hub_overrides_mindsets : int;
  hub_overrides_skills : int;
}
```

### Key functions

```ocaml
(** Vendor paths *)
val vendor_core_path : string -> string
  (* hub_path -> hub_path/.cn/vendor/core *)
val vendor_packages_path : string -> string
  (* hub_path -> hub_path/.cn/vendor/packages *)
val hub_overrides_mindsets_path : string -> string
  (* hub_path -> hub_path/agent/mindsets *)
val hub_overrides_skills_path : string -> string
  (* hub_path -> hub_path/agent/skills *)

(** Core validation — checks that .cn/vendor/core/ exists and contains
    required assets. Returns Error with message if missing. *)
val validate_core : hub_path:string -> (unit, string) result

(** Load mindsets from all three layers, merged by name (hub > pkg > core).
    Returns in deterministic order per CAR spec. *)
val load_mindsets : hub_path:string -> role:string option -> string

(** Walk skills from all three layers, merged by relative path
    (hub > pkg > core). Returns list of (path, content) pairs for scoring. *)
val collect_skills : hub_path:string -> (string * string * asset_source) list

(** Build asset summary for capability block. *)
val summarize : hub_path:string -> asset_summary
```

### Implementation notes

- `validate_core` checks for `.cn/vendor/core/mindsets/COHERENCE.md` and
  `.cn/vendor/core/skills/agent/agent-ops/SKILL.md` at minimum
- `load_mindsets` scans three directories, deduplicates by filename
  (hub-local wins), then loads all 10 core mindsets in deterministic order:
  COHERENCE → role-file → ENGINEERING → PM → WRITING → OPERATIONS →
  PERSONALITY → MEMES → THINKING → WISDOM → FUNCTIONAL

  Role-file inserts the active role's mindset second (e.g. if role=engineer,
  ENGINEERING is loaded at position 2; it is not duplicated later).
  All 10 are loaded if present — no "file exists but agent never sees it".
- `collect_skills` walks all three skill trees, deduplicates by relative
  path (hub-local wins over package, package over core), returns unified
  list for the existing `score_skill` + `tokenize` algorithm in cn_context
- Package directory listing: `readdir .cn/vendor/packages/`, filter dirs
  matching `name@version` pattern

**Tests:** Unit test with mock directory structures. validate_core returns
Error when core is missing. Mindset merge respects priority order.

---

## Step 3: Modify `cn_context.ml` — delegate to `Cn_assets`

**File:** `src/cmd/cn_context.ml`

### Changes

1. **Add fail-fast validation at top of `pack`:**
   ```ocaml
   let pack ~hub_path ~trigger_id ~message ~from ?shell_config () =
     (* Fail fast if core assets are missing *)
     (match Cn_assets.validate_core ~hub_path with
      | Ok () -> ()
      | Error msg ->
          failwith (Printf.sprintf
            "Core cognitive assets missing: %s\n\
             Run 'cn setup' or 'cn deps restore' to materialize assets." msg));
     ...
   ```

2. **Replace `load_mindsets`:**
   Change from reading `hub_path/src/agent/mindsets/` to calling
   `Cn_assets.load_mindsets ~hub_path ~role`.

3. **Replace `load_skills`:**
   Change from walking `hub_path/src/agent/skills/` to:
   ```ocaml
   let load_skills ~hub_path ~message ~(role : string option) ~n =
     let all_skills = Cn_assets.collect_skills ~hub_path in
     let keywords = tokenize message in
     if keywords = [] then []
     else
       all_skills
       |> List.map (fun (path, content, _source) ->
            let base = score_skill keywords content in
            let score = base + bonus_for_path path role in
            (path, content, base, score))
       |> List.filter (fun (_, _, base, _) -> base > 0)
       |> List.sort (fun (p1, _, _, s1) (p2, _, _, s2) ->
            match compare s2 s1 with 0 -> String.compare p1 p2 | c -> c)
       |> (fun lst -> if List.length lst > n
                      then List.filteri (fun i _ -> i < n) lst else lst)
       |> List.map (fun (_, content, _, _) -> content)
   ```

4. Keep `tokenize`, `score_skill`, `contains_sub`, `load_conversation_turns`,
   `load_role` unchanged — they don't touch asset paths.

5. Extract `bonus_for_path` as a standalone helper (currently inline).

**Tests:** With `.cn/vendor/core/` populated, `pack` produces the same
output structure. With `.cn/vendor/core/` missing, `pack` raises a clear error.

---

## Step 4: Create `cn_deps.ml` — manifest/lockfile + materialize

**New file:** `src/cmd/cn_deps.ml`

### Types

```ocaml
(** Manifest entry: what the human wants. *)
type manifest_dep = {
  name : string;
  version : string;   (* semver range, e.g. "^1.0.0" *)
}

(** Lockfile entry: what the resolver pinned. *)
type locked_dep = {
  name : string;
  version : string;   (* exact semver, e.g. "1.0.3" *)
  source : string;    (* git+https://... *)
  rev : string;       (* exact commit hash — reproducibility key *)
  integrity : string option;  (* sha256:... — optional in v3.4.0, required in v3.4.1 *)
}

type manifest = {
  schema : string;       (* "cn.deps.v1" *)
  profile : string;      (* "engineer" | "pm" *)
  packages : manifest_dep list;
}

type lockfile = {
  schema : string;       (* "cn.deps.lock.v1" *)
  packages : locked_dep list;
}
```

### Key functions

```ocaml
(** Read .cn/deps.json. Returns None if missing. *)
val read_manifest : hub_path:string -> manifest option

(** Read .cn/deps.lock.json. Returns None if missing. *)
val read_lockfile : hub_path:string -> lockfile option

(** Write .cn/deps.json *)
val write_manifest : hub_path:string -> manifest -> unit

(** Write .cn/deps.lock.json *)
val write_lockfile : hub_path:string -> lockfile -> unit

(** Materialize bundled core assets into .cn/vendor/core/.
    Source: cnos template repo (found via bundled_core_source). *)
val materialize_core : hub_path:string -> (unit, string) result

(** Install packages from lockfile into .cn/vendor/packages/.
    Fetches by rev, optionally verifies integrity, copies runtime dirs. *)
val restore : hub_path:string -> (unit, string) result

(** List installed packages from .cn/vendor/packages/. *)
val list_installed : hub_path:string -> (string * string) list

(** Verify installed packages match lockfile. *)
val doctor : hub_path:string -> (unit, string list) result

(** Find bundled core asset source path. Checks:
    1. Relative to cn binary location (production)
    2. CN_TEMPLATE_PATH env var (developer override)
    Returns Error if not found. *)
val bundled_core_source : unit -> (string, string) result
```

### `materialize_core` implementation

1. Call `bundled_core_source ()` to find the template's `src/agent/` dir
2. Create `.cn/vendor/core/mindsets/` and `.cn/vendor/core/skills/`
3. Copy all `.md` files from template `src/agent/mindsets/` to vendor core
4. Recursively copy `src/agent/skills/` tree to vendor core (preserving structure)
5. Use file copy (read + write), not symlinks — vendor must be self-contained

### `restore` implementation

1. Read `.cn/deps.lock.json`
2. Call `materialize_core` to ensure core is present
3. For each package not already in `.cn/vendor/packages/<name>@<version>/`:
   a. `git init` temp dir, `git fetch <source> <rev> --depth=1`
   b. `git checkout <rev>` — the lockfile rev is authoritative, not a tag
   c. If `integrity` is `Some hash`, verify sha256 (v3.4.1 enforcement)
   d. Copy `mindsets/` and `skills/` into `.cn/vendor/packages/<name>@<version>/`
   e. Clean up temp dir
4. Return Ok or Error with details

**Why fetch by rev, not tag:** Tags and branches can move. The lockfile
pins a commit hash. Restore must checkout that exact rev to guarantee
deterministic resolution. Tags are used during `cn deps update` (resolve
phase), not during `restore` (install phase).

### `bundled_core_source` implementation

v3.4.0 distribution model (template-checkout-based):
1. Check `CN_TEMPLATE_PATH` env var (explicit override)
2. Walk up from cwd looking for `src/agent/mindsets/COHERENCE.md`

This is the one place where template-repo awareness lives. Runtime never
calls this — only `cn setup` and `cn deps restore`.

v3.5+ may bundle core assets alongside the installed binary for
production installs that don't have a template checkout nearby.

**Tests:** `materialize_core` copies files correctly. `read_manifest` /
`write_manifest` round-trip. `restore` with empty lockfile succeeds
(only materializes core).

---

## Step 5: Wire `cn deps` commands in `cn.ml`

**File:** `src/cli/cn.ml`

Add dispatch for `Deps` commands:

```ocaml
| Deps Deps.List ->
    let installed = Cn_deps.list_installed ~hub_path in
    (* print table *)
| Deps Deps.Restore ->
    (match Cn_deps.restore ~hub_path with
     | Ok () -> print_endline (Cn_fmt.ok "Dependencies restored")
     | Error msg -> print_endline (Cn_fmt.fail msg); Cn_ffi.Process.exit 1)
| Deps Deps.Doctor ->
    (match Cn_deps.doctor ~hub_path with
     | Ok () -> print_endline (Cn_fmt.ok "All deps verified")
     | Error msgs -> List.iter (fun m -> print_endline (Cn_fmt.warn m)) msgs)
| Deps (Deps.Add pkg) ->
    (* parse pkg as name@version or git URL, update manifest, resolve *)
| Deps (Deps.Remove pkg) ->
    (* remove from manifest, update lockfile *)
| Deps (Deps.Update pkg_opt) ->
    (* re-resolve within version ranges *)
| Deps Deps.Vendor ->
    (* remove .cn/vendor from .gitignore, git add .cn/vendor *)
```

**Tests:** `cn deps list` in empty hub prints empty table. `cn deps restore`
materializes core.

---

## Step 6: Modify `cn_system.ml` — `cn setup` materializes core

**File:** `src/cmd/cn_system.ml`

### Changes to `run_setup`

Extend the current `cn setup` interactive flow (hub config, secrets,
role selection) to also materialize the cognitive substrate:

1. Call `Cn_deps.materialize_core ~hub_path`
2. If `.cn/deps.json` doesn't exist, write a default manifest
   with the profile's default package pre-declared:
   ```json
   {
     "schema": "cn.deps.v1",
     "profile": "engineer",
     "packages": [
       { "name": "cnos.profile.engineer", "version": "^1.0.0" }
     ]
   }
   ```
   (Profile and package derived from the role selected during setup.
   PM role → `cnos.profile.pm`, etc. Per CAR-v3.4.md §16.1:
   "After cn setup, a new hub must be impossible to wake without
   baseline cognition.")
3. If `.cn/deps.lock.json` doesn't exist, write empty lockfile:
   ```json
   { "schema": "cn.deps.lock.v1", "packages": [] }
   ```
4. Call `Cn_deps.restore ~hub_path` to install any declared packages
5. Print success message with asset summary

This means `cn setup` is the single command that makes a hub wake-ready.
No separate `cn deps restore` required after first setup.

### Changes to `run_init`

After creating the hub directory structure, also call the new setup
steps above so a freshly init'd hub is immediately wake-ready.

### Changes to `run_doctor`

Add asset health checks:
- `.cn/vendor/core/` exists and contains required files
- `.cn/deps.json` exists
- `.cn/deps.lock.json` exists
- Installed packages match lockfile

**Tests:** `cn init test-hub && cd test-hub && cn agent --process` works
without manual `cn deps restore`.

---

## Step 7: Add asset summary to `cn_capabilities.ml`

**File:** `src/cmd/cn_capabilities.ml`

Extend `render` to accept an optional `asset_summary`:

```ocaml
val render : ?assets:Cn_assets.asset_summary -> Cn_shell.shell_config -> string
```

Append after existing capabilities block:

```markdown
### Cognitive Assets
- profile: engineer
- core: cnos v3.4.0 (10 mindsets, 5 core skills)
- packages:
  - cnos.eng@1.0.3 (8 skills)
- hub-local overrides: 0 mindsets, 0 skills
```

**Caller change:** In `cn_context.ml` `pack`, compute the summary via
`Cn_assets.summarize ~hub_path` and pass it to `Cn_capabilities.render`.

---

## Step 8: Update version and dune build

**Files:**
- `src/lib/cn_lib.ml`: bump `version` from `"3.3.0"` to `"3.4.0"`
- `src/cmd/dune`: add `cn_assets` and `cn_deps` to the modules list
- `cn.json`: bump version to `"3.4.0"`

---

## Build order and dependencies

```
cn_lib.ml (Step 1)          Pure types — no new deps
    ↓
cn_assets.ml (Step 2)       Depends on: cn_ffi, cn_hub
    ↓
cn_context.ml (Step 3)      Depends on: cn_assets (new)
    ↓
cn_deps.ml (Step 4)         Depends on: cn_ffi, cn_json, cn_hub
    ↓
cn.ml (Step 5)              Depends on: cn_deps (new)
cn_system.ml (Step 6)       Depends on: cn_deps (new)
cn_capabilities.ml (Step 7) Depends on: cn_assets (new)
    ↓
Version bump (Step 8)       All files
```

Steps 2 and 4 are independent and could be done in parallel.
Steps 3, 5, 6, 7 each depend on the modules they consume.

---

## What ships in v3.4.0 (MVP)

- `cn_assets.ml`: three-layer resolver (core + packages + hub-local)
- `cn_deps.ml`: materialize_core, restore from lockfile, manifest/lockfile I/O
- `cn_context.ml`: delegates to CAR, fail-fast on missing core
- `cn setup` / `cn init`: auto-materialize core + write default deps
- `cn deps list|restore|doctor`: operational commands
- Asset summary in capabilities block
- Version bump to 3.4.0

## What does NOT ship in v3.4.0

- `cn deps search` / `cn deps info` (requires index repo — v3.4.1)
- `cn deps add` with version resolution from index (v3.4.1)
- `cn deps add <git-url>` works but with manual version pinning
- Integrity enforcement (sha256 field is optional in v3.4.0 lockfile;
  v3.4.1 makes it required and verified on restore)
- `cn skill` aliases (ergonomic layer — v3.4.1)
