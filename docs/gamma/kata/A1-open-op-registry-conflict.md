# KATA-A1

## Open Op Registry Conflict Determinism

**Kata ID:** A1-open-op-registry-conflict
**Family:** Local implementation + invariant proof
**Difficulty:** Medium
**Failure Family:** Local correctness looks fine, but the invariant is not proven across multiple inputs.
**Expected Governing Skills (hidden):** coding, testing

---

## Public Task Statement

You are implementing a runtime extension registry for cnos. The design rule is:

> If two installed extensions declare the same op kind, the runtime must reject the conflict.
> No extension may silently shadow another.

Current bug:

- the registry builder accepts extension manifests in list order
- whichever provider is seen first wins
- duplicate op kinds are silently shadowed

Your task:

1. propose the smallest coherent fix
2. describe the tests needed
3. if you include code or pseudocode, keep it minimal and implementation-oriented

Do not redesign the whole extension system. Focus on making op dispatch deterministic and conflict-safe.

---

## Public Context

### Existing behavior

The registry builder currently loops through manifests and inserts op kinds into a map:

```ocaml
type ext_manifest = {
  name : string;
  version : string;
  ops : ext_op list;
}

and ext_op = {
  kind : string;
  class_ : [ `Observe | `Effect ];
}

type registry = {
  by_name : (string, ext_manifest) Hashtbl.t;
  by_op_kind : (string, string) Hashtbl.t; (* op kind -> extension name *)
}

let build_registry manifests =
  let by_name = Hashtbl.create 16 in
  let by_op_kind = Hashtbl.create 16 in
  List.iter (fun m ->
    Hashtbl.replace by_name m.name m;
    List.iter (fun op ->
      if not (Hashtbl.mem by_op_kind op.kind) then
        Hashtbl.add by_op_kind op.kind m.name
      else
        () (* silently keep first one *)
    ) m.ops
  ) manifests;
  { by_name; by_op_kind }
```

### Design constraints

- duplicate extension names should also be rejected
- duplicate effective op kinds should be rejected
- registry behavior should be deterministic regardless of manifest order
- built-in op kinds remain separate and already deterministic
- do not solve discovery, only registry construction and validation

### Example conflicting inputs

Manifest A:

```json
{
  "name": "cnos.net.http",
  "ops": [ { "kind": "http_get", "class": "observe" } ]
}
```

Manifest B:

```json
{
  "name": "org.example.http2",
  "ops": [ { "kind": "http_get", "class": "observe" } ]
}
```

---

## Public Deliverable

Return:

1. Invariant
2. Minimal fix
3. Tests
4. Known edge cases

---

## Hidden Evaluator Rubric

### α

Strong answer should:

- state the invariant explicitly:
  - no duplicate effective op kinds
  - no duplicate extension names
- reject conflicts rather than shadow them
- keep the fix local to registry construction/validation
- avoid redesigning unrelated discovery/runtime layers

Weak answer:

- just overwrites the map differently
- keeps first/last-wins semantics
- adds "warning logs" without changing behavior

### β

Strong answer should:

- align with the runtime-extension design:
  - deterministic registry
  - conflict visible to doctor/traceability
- recognize that built-ins remain separate
- not confuse registry build with install/enable/runtime dispatch

Weak answer:

- mixes runtime contract rendering into the fix
- proposes ad hoc manual review of manifests instead of mechanical enforcement

### γ

Strong answer should:

- choose a minimal coherent move
- mention future doctor/traceability visibility if relevant
- avoid overclaiming end-to-end runtime support

Weak answer:

- proposes broad architecture redesign
- leaves conflict behavior ambiguous

### Hidden Checks / Tests

Must be able to detect these:

**Positive checks:**

- unique manifests with unique op kinds succeed
- duplicate extension name is rejected
- duplicate op kind is rejected

**Negative checks:**

- order [A; B] and [B; A] both reject the http_get conflict
- no silent shadowing

**Stronger proof signals:**

Bonus if the answer suggests:

- property-based test for order-independence
- deterministic rejection shape / reason
- exact error structure

### Transfer Variant (hidden)

Use after the same-task repair run.

**Task B:** Same registry builder, but now the conflict is:

- unique extension names
- unique op kinds
- engine incompatibility (engines.cnos mismatch)

Good transfer means the agent now treats this as the same family:

- deterministic validation
- reject invalid manifests structurally
- no silent acceptance of incompatible entries
