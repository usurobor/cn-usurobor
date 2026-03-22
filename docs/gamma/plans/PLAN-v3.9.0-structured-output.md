# PLAN-v3.9.0
## Structured Output Contract

**Status:** Draft
**Date:** 2026-03-22
**Implements:** [`STRUCTURED-OUTPUT-v3.9.0.md`](../../alpha/STRUCTURED-OUTPUT-v3.9.0.md)
**Scope:** Replace markdown-with-frontmatter as the primary output contract with tool_use structured output. Compile state/output.md from the structured object.
**Issues:** #52

---

## 0. Coherence Contract

### Gap

The LLM's output is freeform markdown parsed heuristically. A formatting mistake becomes a semantic bug (issue #51). The control plane and presentation plane are not structurally separate.

### Mode

**MCA** — change the LLM call path and output parsing.

### Smallest coherent intervention

Add tool_use to the LLM call, extract structured fields, compile audit markdown. Keep all downstream semantics (N-pass, receipts, coordination) unchanged.

---

## 1. Compile-safe step order

### Step 1 — Add tool types to cn_llm.ml

**Goal:** Extend the LLM client to support tools and tool_choice.

#### Add types

```ocaml
type tool = {
  name : string;
  description : string;
  input_schema : Cn_json.t;
}

type tool_choice =
  | Auto
  | Tool of string  (* force specific tool *)

type content_block =
  | Text of string
  | Tool_use of { id : string; name : string; input : Cn_json.t }
```

#### Extend call signature

```ocaml
val call : api_key:string -> model:string -> max_tokens:int
  -> system:system_block list -> messages:message_turn list
  -> ?tools:tool list -> ?tool_choice:tool_choice
  -> unit -> (response, string) result
```

#### Extend response type

```ocaml
type response = {
  content : string;           (* concatenated text blocks *)
  content_blocks : content_block list;  (* all blocks including tool_use *)
  stop_reason : string;
  ...
}
```

#### Acceptance

- Existing callers (no tools) still work unchanged
- New callers can pass tools and get tool_use blocks back

---

### Step 2 — Define the cn_respond tool schema

**Goal:** Define the tool that structures the agent's output.

#### In cn_output.ml or cn_shell.ml

```ocaml
val cn_respond_tool : Cn_llm.tool
```

The schema defines:
- `body` (string, required): presentation text
- `coordination_ops` (array, optional): coordination op objects
- `typed_ops` (array, optional): CN Shell typed op objects

#### Acceptance

Tool definition compiles and produces valid JSON schema.

---

### Step 3 — Add structured output parser to cn_output.ml

**Goal:** Parse a `tool_use` input JSON into `parsed_output`.

#### Add

```ocaml
val parse_structured : trigger_id:string -> Cn_json.t -> parsed_output
```

Takes the `input` field from a `cn_respond` tool_use block and produces the same `parsed_output` type used by the existing `parse_output`.

#### Key differences from parse_output

- No frontmatter parsing — fields are typed JSON
- `has_misplaced_ops` is always false (ops cannot be misplaced in structured output)
- Coordination ops parsed from structured array, not from frontmatter key:value
- Typed ops parsed from structured array, not from `ops:` single-line JSON

#### Acceptance

- Structured parse produces equivalent parsed_output to markdown parse for the same logical content
- has_misplaced_ops is false when using structured path

---

### Step 4 — Add output.md compiler to cn_output.ml

**Goal:** Compile a structured output into markdown for audit.

#### Add

```ocaml
val compile_output_md : trigger_id:string -> parsed_output -> string
```

Produces:
```markdown
---
id: {trigger_id}
ops: [{typed_ops as JSON}]
{coordination ops as key: value}
ops_version: 3.9
---
{body}
```

#### Acceptance

- Compiled markdown round-trips through `parse_output` to equivalent parsed_output
- Audit files are human-readable

---

### Step 5 — Wire structured output into cn_runtime.ml

**Goal:** Use tool_use for LLM calls, extract structured response, compile audit file.

#### Changes to finalize/orchestrate

1. Build `cn_respond` tool definition
2. Pass `~tools:[cn_respond_tool] ~tool_choice:(Tool "cn_respond")` to `Cn_llm.call`
3. Extract `Tool_use` block from response content_blocks
4. If found: parse with `parse_structured` → compile to output.md → continue
5. If not found (text-only fallback): use existing `parse_output` → issue #51 correction path

#### Acceptance

- Structured responses execute correctly
- Text fallback still works
- state/output.md is always written (compiled or raw)

---

### Step 6 — Update cn_capabilities.ml

**Goal:** Instruct the model to use the cn_respond tool.

#### Changes

- Replace frontmatter-specific formatting instructions with tool-use instructions
- Keep the same op vocabulary and budget descriptions
- Add: "Always use the cn_respond tool to emit your response"

#### Acceptance

- Model uses cn_respond tool on every response
- Existing op semantics preserved

---

### Step 7 — Tests

#### 7.1 Structured parser tests

- Parse valid structured JSON → correct parsed_output
- Parse with typed_ops → correct op extraction
- Parse with coordination_ops → correct op extraction
- Parse with empty ops → no misplaced flag
- Malformed typed op → denial receipt

#### 7.2 Compiler tests

- Compile structured output → valid markdown
- Round-trip: parse_structured → compile → parse_output → equivalent

#### 7.3 LLM client tests

- Tool definition serializes correctly
- tool_use content blocks are extracted
- Text-only fallback works
- Mixed text + tool_use extracts both

#### 7.4 Integration tests

- Structured response → typed ops execute → receipts
- Structured response → coordination ops execute
- Text fallback → existing markdown parse → correction if needed

---

## 2. Estimated change surface

| Module | Impact |
|--------|--------|
| `cn_llm.ml` | moderate — add tool types, extend call/response |
| `cn_output.ml` | moderate — add parse_structured, compile_output_md |
| `cn_runtime.ml` | moderate — wire structured extraction |
| `cn_capabilities.ml` | small — update instructions |
| `cn_shell.ml` | none |
| `cn_orchestrator.ml` | none |

---

## 3. Success criteria

1. LLM calls include `cn_respond` tool with forced tool_choice
2. Structured responses extracted and executed without markdown parsing
3. state/output.md compiled from structured object for audit
4. Text-only responses fall back to existing parser
5. All existing tests pass
6. New structured parser tests pass
