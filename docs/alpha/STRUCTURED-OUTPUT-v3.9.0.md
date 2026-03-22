# STRUCTURED-OUTPUT-v3.9.0
## Structured Output Contract

**Status:** Draft
**Version:** 3.9.0
**Date:** 2026-03-22
**Authors:** usurobor
**Scope:** Replace markdown-with-frontmatter as the primary LLM output contract with a schema-validated structured object. Treat `state/output.md` as a compiled audit artifact, not the source of execution truth.
**Issues:** #52

---

## 0. Coherence Contract

### Gap

The current runtime uses markdown-with-frontmatter as the single carrier for both control-plane data (ops, coordination ops, metadata) and presentation-plane data (body text for humans).

This means:
- a formatting mistake becomes a semantic bug (issue #51)
- the parser must heuristically split one artifact into two planes
- body scanning must detect misplaced ops as anomalies
- the model's prompt discipline is the only guarantee of correct formatting

This weakens:
- α: the output contract is implicit (frontmatter conventions, not schema)
- β: control and presentation planes are not structurally separated
- γ: adding new op kinds or metadata fields requires parser changes

### Mode

**MCA** — change the runtime LLM call path and output parsing.

### α / β / γ target

- **α PATTERN:** one schema-validated output object with typed fields for each plane
- **β RELATION:** control plane and presentation plane are structurally separate; state/output.md becomes a compiled view
- **γ EXIT:** new op kinds and metadata fields are schema additions, not parser changes

### Smallest coherent intervention

Keep:
- CN Shell typed ops model
- coordination ops vocabulary
- receipts / artifacts model
- output-plane separation (now structural, not heuristic)
- N-pass bind loop semantics
- one LLM call per pass

Change only:
- how the LLM emits its response (tool_use with structured schema)
- how the runtime extracts control-plane data from the response
- how state/output.md is generated (compiled from structured object)

---

## 1. Core Decision

The runtime SHALL use Anthropic tool_use to define a structured output schema for the agent's response.

### 1.1 The output tool

The LLM call includes a single tool definition:

```json
{
  "name": "cn_respond",
  "description": "Emit your response with structured control-plane and presentation-plane fields.",
  "input_schema": {
    "type": "object",
    "properties": {
      "body": {
        "type": "string",
        "description": "Presentation text for the user (markdown). This is the only field that reaches human-facing sinks."
      },
      "coordination_ops": {
        "type": "array",
        "items": {
          "type": "object",
          "properties": {
            "kind": { "type": "string", "enum": ["ack", "done", "fail", "reply", "send", "delegate", "defer", "delete", "surface"] },
            "id": { "type": "string" },
            "message": { "type": "string" },
            "peer": { "type": "string" },
            "reason": { "type": "string" },
            "body": { "type": "string" }
          },
          "required": ["kind"]
        },
        "description": "Coordination ops (reply, send, done, ack, etc.)."
      },
      "typed_ops": {
        "type": "array",
        "items": {
          "type": "object",
          "properties": {
            "kind": { "type": "string" },
            "op_id": { "type": "string" },
            "path": { "type": "string" },
            "content": { "type": "string" },
            "unified_diff": { "type": "string" },
            "command": { "type": "string" },
            "ref": { "type": "string" },
            "message": { "type": "string" },
            "pattern": { "type": "string" },
            "branch": { "type": "string" },
            "files": { "type": "array", "items": { "type": "string" } }
          },
          "required": ["kind"]
        },
        "description": "CN Shell typed capability ops (fs_read, fs_write, git_diff, etc.)."
      }
    },
    "required": ["body"]
  }
}
```

The call uses `tool_choice: {"type": "tool", "name": "cn_respond"}` to force the model to always use the tool.

### 1.2 Why tool_use, not prefill or JSON mode

- **tool_use with forced tool_choice** guarantees the response is a valid JSON object matching the schema
- the model cannot accidentally emit ops in the body because body is a separate field
- no parsing heuristics needed — the response is typed at the API level
- Anthropic explicitly supports this pattern for structured output

### 1.3 Invariant

The structured object is the **source of truth** for execution.
`state/output.md` is compiled from the object for audit/human readability.
The runtime MUST NOT parse `state/output.md` for execution decisions.

---

## 2. Response Extraction

### 2.1 From tool_use content blocks

The API response contains `content` blocks. When `tool_choice` forces `cn_respond`:
- exactly one block has `type: "tool_use"` with `name: "cn_respond"`
- the `input` field contains the structured object

### 2.2 Fallback: text-only response

If the model emits a text block instead of (or in addition to) tool_use:
- treat it as the issue #51 misplaced-ops pattern
- the text becomes the `body` field
- `typed_ops` and `coordination_ops` are empty
- `has_misplaced_ops` detection runs on the text
- correction pass may fire if misplaced ops detected

This provides backward compatibility and graceful degradation.

---

## 3. Compilation to state/output.md

The runtime compiles the structured object into `state/output.md` for audit:

```markdown
---
id: {trigger_id}
ops: {typed_ops as single-line JSON array}
{coordination ops as key: value lines}
ops_version: 3.9
---
{body}
```

This preserves:
- existing audit tooling that reads output.md
- existing log archives
- human readability

But the compiled markdown is never the source of execution truth.

---

## 4. Impact on Existing Modules

### 4.1 cn_llm.ml

- Add `tool` type and `tool_choice` to the request
- Parse `tool_use` content blocks from the response
- Return structured response alongside text content

### 4.2 cn_output.ml

- Add `parse_structured` that directly constructs `parsed_output` from the JSON object
- `parse_output` (markdown parser) remains for backward compat / fallback
- Add `compile_output_md` that renders structured object to markdown

### 4.3 cn_runtime.ml

- Extract structured response from LLM call
- Compile to state/output.md for audit
- Use structured object directly for execution (no markdown parsing)

### 4.4 cn_capabilities.ml

- Update the capabilities block to instruct the model to use `cn_respond` tool
- Remove markdown-specific formatting instructions

### 4.5 cn_context.ml

- No changes needed to the pack function

---

## 5. Backward Compatibility

### 5.1 Fallback parsing

If the model returns text instead of tool_use (e.g., model doesn't support tools, or edge case), the existing markdown parser (`Cn_output.parse_output`) is used as fallback.

### 5.2 Issue #51 correction

The misplaced-ops correction path remains active as a defense layer for the fallback case. When the primary contract works, correction is never triggered.

### 5.3 Existing tests

All existing tests that use `parse_output` continue to work. New tests verify the structured path.

---

## 6. Acceptance Criteria

1. LLM calls include the `cn_respond` tool with forced tool_choice
2. Structured responses are extracted from `tool_use` content blocks
3. `state/output.md` is compiled from the structured object (not the raw response)
4. Control-plane fields (`typed_ops`, `coordination_ops`) never reach human-facing sinks
5. Text-only responses fall back to existing markdown parsing
6. Existing two-pass / N-pass behavior is preserved
7. Issue #51 correction remains active for fallback text responses

---

## 7. Non-goals

- No changes to the N-pass bind loop semantics
- No changes to the FSM or actor model
- No changes to capability authority
- No new op kinds
- No streaming support (future)

---

## 8. Summary

v3.9.0 moves execution authority from markdown-with-frontmatter to a schema-validated structured output object:

- **control plane** → `typed_ops` + `coordination_ops` fields in the tool_use response
- **presentation plane** → `body` field, the only field projected to human sinks
- **audit** → `state/output.md` compiled from the structured object

The result is:
- structural separation of control and presentation (no more heuristic parsing)
- format mistakes cannot become semantic bugs
- new fields are schema additions, not parser changes
- backward compat via fallback to markdown parsing
