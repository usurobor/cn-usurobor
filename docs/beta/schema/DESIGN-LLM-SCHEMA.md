# Design: Structured LLM Request Schema

## Problem

The current `cn_llm.call` sends everything — identity, mindsets, skills,
reflections, conversation history, and the inbound message — as a **single
user message** with no system prompt:

```json
{
  "messages": [{"role": "user", "content": "<4000-word markdown blob>"}]
}
```

This has three issues:

1. **No system prompt.** Claude treats `system` as authoritative instructions
   and `user` messages as requests. Stuffing identity/skills into a user
   message degrades instruction-following.

2. **No prompt caching.** The entire prompt changes every call (the inbound
   message is at the end). Anthropic's prompt caching requires a stable
   prefix marked with `cache_control` — impossible with a flat string.

3. **No multi-turn.** Conversation history is rendered as markdown inside
   the user message (`**user**: ... **assistant**: ...`). Claude understands
   prior exchanges better when they appear as actual message turns.

## Decision

Split the packed context into three parts:

| Part | API parameter | Content | Caching |
|------|--------------|---------|---------|
| **Stable identity** | `system[0]` | SOUL.md + USER.md + Mindsets | `cache_control: ephemeral` |
| **Dynamic context** | `system[1]` | Reflections + Skills | No cache marker |
| **Conversation** | `messages[]` | History turns + inbound message | N/A |

### JSON wire format

```json
{
  "model": "claude-sonnet-4-latest",
  "max_tokens": 8192,
  "system": [
    {
      "type": "text",
      "text": "## Identity\n\n...\n\n## User\n\n...\n\n## Mindsets\n\n...",
      "cache_control": {"type": "ephemeral"}
    },
    {
      "type": "text",
      "text": "## Recent Reflections\n\n...\n\n## Relevant Skills\n\n..."
    }
  ],
  "messages": [
    {"role": "user", "content": "previous user message"},
    {"role": "assistant", "content": "previous assistant response"},
    {"role": "user", "content": "current inbound message"}
  ]
}
```

### Why two system blocks (not one, not three)

- **Block 1** (SOUL + USER + Mindsets) changes only when the operator edits
  persona files. Marking it with `cache_control` means Anthropic caches
  this prefix across calls — ~90% input token savings on the stable part.

- **Block 2** (Reflections + Skills) changes daily (reflections) or
  per-message (skills vary by keyword match). No cache marker — it sits
  after the cached prefix and is re-read each call.

- Splitting further (one block per section) would burn the 4-breakpoint
  limit with no additional cache benefit.

### Why real message turns

Claude's training optimizes for the `user`/`assistant` turn structure.
Formatting prior exchanges as markdown inside a user message is an
approximation that loses:

- Turn boundaries (Claude can't distinguish where one exchange ends)
- Role attribution (bold-text markers are heuristic, not structural)
- The model's own "voice" from prior assistant turns

With real turns, the model sees its prior outputs as `assistant` messages
and produces more consistent follow-up responses.

## OCaml types (Schema)

### Why not ppx_deriving_yojson / atdgen

OCaml has PPX-based auto-serialization (`ppx_yojson_conv`,
`ppx_deriving_yojson`) and schema-first code generation (`atdgen`).
These would let us write:

```ocaml
type system_block = { text : string; cache : bool } [@@deriving yojson]
```

and get `system_block_to_yojson` / `system_block_of_yojson` for free.

**We don't use them** because the project has a zero-external-dependency
constraint (stdlib + Unix only). Adding ppx_deriving_yojson would pull in:
ppx infrastructure, yojson, seq, and their transitive deps — a major
dependency cliff for ~15 lines of manual conversion functions.

Instead: define OCaml types, write manual `to_json` helpers using the
existing `cn_json.ml`. Same type safety, zero deps, ~15 lines total.

### Type definitions (in `cn_llm.ml`)

```ocaml
type system_block = {
  text : string;
  cache : bool;   (* emit cache_control breakpoint *)
}

type message_turn = {
  role : string;   (* "user" | "assistant" *)
  content : string;
}
```

### JSON conversion (in `cn_llm.ml`)

```ocaml
let system_block_to_json (b : system_block) =
  let fields = [
    "type", Cn_json.String "text";
    "text", Cn_json.String b.text;
  ] in
  if b.cache then
    Cn_json.Object (fields @ [
      "cache_control", Cn_json.Object ["type", Cn_json.String "ephemeral"]
    ])
  else
    Cn_json.Object fields

let message_to_json (m : message_turn) =
  Cn_json.Object [
    "role", Cn_json.String m.role;
    "content", Cn_json.String m.content;
  ]
```

### Packed context type (in `cn_context.ml`)

```ocaml
type packed = {
  trigger_id : string;
  from : string;
  system : Cn_llm.system_block list;
  messages : Cn_llm.message_turn list;
  raw_inbound : string;   (* original message text, for conversation log *)
  audit_text : string;    (* flattened markdown, written to state/input.md *)
}
```

`audit_text` preserves backward compatibility: `state/input.md` and
`logs/input/` keep the same human-readable markdown format. The recovery
path (State 2 in `cn_runtime.ml`) uses `extract_inbound_message` on
the audit text to reconstruct the original message, then re-packs to
get fresh structured data for the LLM call.

### Updated call signature (in `cn_llm.ml`)

```ocaml
val call : api_key:string -> model:string -> max_tokens:int
           -> system:system_block list -> messages:message_turn list
           -> (response, string) result
```

## Module changes

| File | Change |
|------|--------|
| `src/cmd/cn_llm.ml` | Add types + `to_json` helpers. Change `call` to accept `~system` + `~messages`. Build structured request body. |
| `src/cmd/cn_context.ml` | New `packed` type. Split `pack` into system blocks + message turns. Add `load_conversation_turns`. Keep `audit_text` for input.md. |
| `src/cmd/cn_runtime.ml` | Pass structured data to `Cn_llm.call`. On recovery (State 2), re-pack from extracted inbound message. Update `build_input_md` to use `audit_text`. |

## Impact

| Metric | Before | After |
|--------|--------|-------|
| System prompt | None | Stable identity + dynamic context |
| Prompt caching | No benefit | ~90% cache hits on identity block |
| Conversation format | Markdown in user msg | Real user/assistant turns |
| Token cost (repeat calls) | Full re-read | Cached prefix + delta |
| Recovery behavior | Replay exact input.md | Re-pack fresh (same result) |
| Wire format | 1 user message | system[] + messages[] |
