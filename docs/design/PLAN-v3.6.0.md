# PLAN-v3.6.0
## Output Plane Separation — Implementation Plan

**Status:** Draft
**Implements:** `AGENT-RUNTIME.md` v3.6.0 amendment
**Problem statement:** prevent control-plane syntax (`ops: [...]`, raw frontmatter, pseudo-tool wrappers) from leaking to human-facing sinks while preserving post-call governed capability execution.
**Primary issue:** #24

---

## 0. Coherence Contract

### Gap
Today, a single `state/output.md` can be interpreted both as:
- **control plane** (ops, metadata, coordination intent)
- **presentation plane** (what a human should see)

This allows incoherent outcomes such as:
- raw `ops:` JSON being shown to Telegram users
- XML-like pseudo-tool syntax leaking to humans
- conversation history storing control-plane artifacts instead of final projected assistant text

### Mode
**MCA** — change the runtime, not just docs or prompts.

### α / β / γ target
- **α PATTERN:** separate control vs presentation planes cleanly and make invalid projections unrepresentable
- **β RELATION:** align runtime behavior with `AGENT-RUNTIME.md`, `TRACEABILITY.md`, and agent-facing instructions
- **γ EXIT:** create a reusable sink-rendering layer for Telegram, conversation store, future Discord/peer surfaces

### Smallest coherent intervention
Introduce a parsed output AST and sink-specific renderers below the FSM and above projection/send paths. Do not change the agent interface, typed-op execution model, or FSM semantics.

---

## 1. Scope

### In scope
- Parse `state/output.md` into a structured output AST
- Introduce sink-specific rendering:
  - `HumanSurface`
  - `ConversationStore`
  - `AuditFile`
  - `PeerOutbox` (shape only; minimal implementation)
- Block control-plane leaks to human-facing sinks
- Preserve ops execution for Telegram-origin sessions
- Emit `projection.render.*` events
- Route conversation append through presentation-plane rendering

### Out of scope
- FSM changes
- typed op schema changes
- capability execution changes
- transport protocol changes
- agent prompt changes (already handled via doctrine/skills/capabilities)
- new sinks beyond the enum/shape
- markdown rendering/styling improvements

---

## 2. Design Summary

v3.6.0 introduces a new boundary:

- **Control plane**
  - frontmatter metadata
  - legacy coordination ops
  - typed `ops:` manifest
  - `ops_version`

- **Presentation plane**
  - markdown body
  - safe human-facing text derived from:
    1. body
    2. `reply` coordination payload
    3. `"(acknowledged)"` fallback

The runtime MUST:
1. parse output once into a structured form
2. execute control-plane semantics from that structure
3. render sink-specific presentation text from that structure
4. never project raw control-plane syntax to a human-facing sink

---

## 3. Files / Modules

### New module
- `src/cmd/cn_output.ml`

### Modified modules
- `src/cmd/cn_runtime.ml`
- `src/cmd/cn_orchestrator.ml` (if needed only for type imports / no semantic changes)
- `src/cmd/dune` / `test/cmd/dune`

### New test module
- `test/cmd/cn_output_test.ml`

---

## 4. New Module: `cn_output.ml`

### Purpose
Own the output-plane separation:
- parse and normalize `state/output.md`
- expose control-plane data for execution
- expose safe presentation-plane renderers for sinks

### Types

```ocaml
type sink =
  | AuditFile
  | HumanSurface of [ `Telegram | `Discord | `Generic ]
  | ConversationStore
  | PeerOutbox

type render_reason =
  | Control_plane_leak
  | Raw_frontmatter
  | Xml_tool_syntax
  | No_presentation_payload

type render_result =
  | Renderable of string
  | Skipped
  | Invalid of render_reason

type parsed_output = {
  id : string option;
  body : string option;
  coordination_ops : Cn_lib.agent_op list;
  typed_ops : Cn_shell.typed_op list;
  ops_receipts : Cn_shell.receipt list;
  ops_version : string option;
  raw_output : string;
}
```

### Functions

**`parse_output : string -> parsed_output`**

Responsibilities:
- parse frontmatter
- extract id
- extract markdown body via existing `Cn_lib.extract_body`
- extract legacy coordination ops via existing `Cn_lib.extract_ops`
- parse `ops:` via `Cn_shell.parse_ops_manifest`
- parse `ops_version` as string if present

Notes:
- `typed_ops` + `ops_receipts` must come from the same parse pass
- raw text is preserved only for audit/debug

**`is_control_plane_like : string -> render_reason option`**

Detects human-unsafe payloads.

Must block at minimum:
- strings starting with `ops:` / raw frontmatter-like `key: value` control lines
- XML-like pseudo-tool wrappers: `<observe>`, `<fs_read>`, etc.
- raw frontmatter fences `---` in presentation candidate

Initial heuristic:
- exact/anchored patterns only (avoid over-blocking normal prose)

**`render_for_sink : sink -> parsed_output -> render_result`**

Rendering rules:

| Sink | Rule |
|------|------|
| `AuditFile` | Always `Renderable raw_output` |
| `HumanSurface _` | Candidate precedence: body → first Reply payload → `"(acknowledged)"`. If chosen candidate is control-plane-like → `Invalid reason`, caller may fallback to next candidate. |
| `ConversationStore` | Same precedence as `HumanSurface` — conversation history stores what the assistant effectively "said", not raw frontmatter. |
| `PeerOutbox` | For v3.6.0: `Renderable send_body` only when a `Send` op is explicitly being rendered by caller, otherwise `Skipped`. |

---

## 5. Integration in `cn_runtime.ml`

### 5.1 Parse once in `finalize`

Current flow parses output in pieces. Replace with:
1. `let parsed = Cn_output.parse_output output_content`
2. control-plane execution uses: `parsed.coordination_ops`, `parsed.typed_ops`, `parsed.ops_receipts`
3. presentation uses `Cn_output.render_for_sink`

### 5.2 Control-plane execution remains unchanged in meaning

Do not change:
- typed op execution model
- Pass A/B orchestration
- effect gating
- FSM transition rules

Only change the source of truth from raw text / ad hoc body helpers to `parsed_output`.

### 5.3 Projection path

Replace direct use of `telegram_payload ops body` with:
- `Cn_output.render_for_sink (HumanSurface `Telegram) parsed`

Behavior:
- `Renderable msg` → attempt projection as before
- `Invalid reason` → emit `projection.render.blocked`, then try fallback candidate via renderer logic
- `Skipped` → no projection

Important:
- typed ops still execute even for Telegram-origin sessions
- projection is only the user-facing rendering layer

### 5.4 Conversation append

Replace current assistant text derivation with:
- `Cn_output.render_for_sink ConversationStore parsed`

This prevents conversation history from storing:
- raw frontmatter
- `ops:` lines
- pseudo-tool syntax

### 5.5 Preserve control-plane receipts

`parsed.ops_receipts` (denials from manifest parse) should still be merged into the normal receipt flow as today.

---

## 6. Events / Traceability

Emit the new projection-render events defined in the spec:
- `projection.render.start`
- `projection.render.ok`
- `projection.render.blocked`
- `projection.render.fallback`

Reason codes:
- `control_plane_leak`
- `raw_frontmatter`
- `xml_tool_syntax`
- `no_presentation_payload`

Where: in `cn_runtime.finalize`, immediately before the transport-specific projection attempt.

These are a **sub-namespace** of the existing `projection.{start,ok,skipped,error}` lifecycle events (see TRACEABILITY §12.1). They refine the render step, not replace it.

---

## 7. Tests

### 7.1 Pure tests — `cn_output_test.ml`

Required coverage:

**Parsing**
- body + legacy ops + typed ops all extracted from one file
- missing body handled
- no frontmatter handled
- malformed `ops:` produces parser receipts, not exceptions

**Control-plane leak detection**
- bare `ops: [...]` line blocked
- raw frontmatter line blocked
- XML `<observe>` / `<fs_read>` blocked
- ordinary prose mentioning "ops" not blocked spuriously

**Rendering precedence (HumanSurface / ConversationStore)**
1. valid body wins
2. invalid body + reply present → reply wins
3. invalid body + no reply → `"(acknowledged)"`
4. no body + reply → reply
5. no body + no reply → fallback

**AuditFile**
- returns raw output unchanged

### 7.2 Integration tests

Required runtime behaviors:

**Telegram-origin trigger with valid body + typed ops**
- typed ops still execute
- Telegram sees only body

**Telegram-origin trigger with body = bare `ops: [...]`**
- projection blocked
- fallback used
- typed ops still execute

**XML hallucination in body**
- not sent to Telegram
- fallback used
- event `projection.render.blocked` emitted

**Conversation store**
- final stored assistant text is the presentation-plane result, not raw output text

**Pass A / Pass B**
- no change in orchestration semantics
- only rendering behavior changes

---

## 8. Compile-safe step order

| Step | Action | Behavior change |
|------|--------|-----------------|
| 1 | Add `cn_output.ml` with pure types/functions and tests. | None |
| 2 | Integrate parser into `cn_runtime.finalize` for read-only use. Assert parity with existing ad-hoc parsing. | None — parity assertion only |
| 3 | Switch conversation append to `ConversationStore` renderer. | Conversation history now stores presentation text |
| 4 | Switch Telegram projection to `HumanSurface` renderer. | Control-plane leaks blocked |
| 5 | Add `projection.render.*` events. | Observability |
| 6 | Integration tests. | None |

This order keeps each step buildable and reviewable. Step 2 includes a parity assertion to verify the new parser produces identical control-plane data before any rendering behavior changes.

---

## 9. Estimated change surface

| Component | LOC |
|-----------|-----|
| `cn_output.ml` (new) | ~180–260 |
| `cn_output_test.ml` (new) | ~150–220 |
| `cn_runtime.ml` (modified) | ~60–120 |
| dune files | small |
| **Total** | **~400–600** |

---

## 10. Success criteria

The implementation is done when:
1. A human-facing sink can no longer receive raw control-plane syntax.
2. Telegram-origin sessions still execute typed ops under policy.
3. Conversation history stores the projected assistant text, not raw output control syntax.
4. Projection-render events explain blocked/fallback behavior.
5. No FSM semantics are changed.
6. Existing CN Shell orchestration tests still pass.

---

## 11. Explicit non-goals for this iteration
- Rich markdown-to-chat formatting
- New capability kinds
- Generic sink plugins
- PeerOutbox refactor beyond type shape
- Agent prompt changes
- XML detection beyond simple explicit wrappers
- Changing typed op execution order or receipts semantics

---

## 12. Final note

This is an MCA fix:
we are changing the runtime so that invalid output-context leakage becomes impossible by construction, rather than trying to prompt the agent harder.

That is the right layer for issue #24.
