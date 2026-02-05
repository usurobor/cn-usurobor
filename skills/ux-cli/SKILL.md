# SKILL: UX-CLI — Terminal Application User Experience

**VERSION:** 1.0.0  
**STATUS:** Normative (prescriptive)  
**AUDIENCE:** Agents that design, critique, or generate CLI output

---

## 0. PURPOSE

UX-CLI specifies how terminal applications communicate state, progress, failure, and next actions to human users with minimal ambiguity.

**Primary goal:**
- Help a user recover and continue without external help.

**Secondary goals:**
- Enable experts to scan state quickly.
- Preserve trust via predictability and honest output.
- Provide stable machine-readable signals without harming human UX.

**UX-CLI is NOT about:**
- aesthetic flair
- ASCII art
- cleverness
- maximum color usage

**UX-CLI is about:**
- operational clarity under stress

---

## 1. FUNDAMENTAL PRINCIPLES (NON-NEGOTIABLE)

**P1. Color encodes semantics, never decoration.**
- Every color has exactly one meaning.
- Colors must never be the only signal (symbols + text required).

**P2. Output must be self-sufficient.**
- A user must know: (a) what happened (b) what is blocked (c) what to do next without reading docs.

**P3. Failure paths are first-class.**
- Spend more design budget on failure UX than success UX.
- Errors must be calm, structured, and recoverable.

**P4. Predictability beats "smart guessing."**
- A deterministic parser is preferable to a probabilistic one when stakes exist.
- Avoid silent assumptions that can schedule, delete, or modify incorrectly.

**P5. No blame, no vibes.**
- No emotional language, no scolding, no shame.
- Use neutral tone and direct causality.

**P6. The CLI is a constrained UI; embrace constraints.**
- Favor structure and short lines.
- Prefer stable patterns over novelty.

---

## 2. SEMANTIC CHANNELS (MUST NOT CONFLICT)

UX-CLI uses four orthogonal channels:

1. **TEXT:** wording, labels, concise explanations
2. **STRUCTURE:** alignment, indentation, grouping, whitespace
3. **SYMBOLS:** ✓ ✗ ⚠ ⏸ • → etc.
4. **COLOR:** limited palette mapped to meaning

**Rule:** No channel may contradict another.

**Example:** If text says "blocked" but symbol says ✓, UX-CLI FAILS.

---

## 3. CANONICAL COLOR MAP (NORMATIVE DEFAULT)

| State | Color | Meaning |
|-------|-------|---------|
| OK / SUCCESS | Green (soft) | check passed, operation completed, ready state |
| ERROR / BLOCKING FAILURE | Red | cannot proceed until fixed |
| WARNING / NON-BLOCKING | Yellow/Amber | continue possible, but user should notice |
| INFO / SECTION | Cyan | neutral information, headings, "what we're doing" |
| USER ACTION / COMMANDS | Magenta | commands user should run; interactive prompts |
| DIM / INACTIVE | Gray (dim) | de-emphasized, metadata, skipped, non-critical |

**Rules:**
- Do not introduce additional colors without a new version.
- If color is unavailable (NO_COLOR / dumb terminal), the CLI MUST remain usable.

---

## 4. CANONICAL SYMBOL MAP (NORMATIVE DEFAULT)

Symbols must encode state even without color:

| Symbol | Meaning |
|--------|---------|
| ✓ | OK / satisfied |
| ✗ | missing / fail / cannot proceed |
| ⚠ | warning / risky / continue with attention |
| ⏸ | blocked (waiting on prerequisite) |
| • | bullet in lists |
| → | next step / progression / hint of direction |

**Rules:**
- Symbols must be single-width where possible.
- If Unicode symbols break, provide ASCII fallbacks: `[OK]`, `[X]`, `[!]`, `[..]`

---

## 5. STRUCTURAL LAYOUT RULES

### R1. Hierarchy

Every output sequence should have:
1. Title (tool name + version)
2. Current phase (what it is doing)
3. Structured results (checklist / summary)
4. Next actions (if needed)
5. Optional machine footer

### R2. Checklist alignment

When listing checks:
- Labels left-aligned
- Status token right-aligned
- Use dot leaders or fixed-width padding for scan-ability
- Color ONLY the status token and symbol, not the entire row

```
Good: git...................... ✓
Bad:  (entire line green) git...................... ✓
```

### R3. Dependency encoding

If a check depends on another:
- Indent dependent checks by 2 spaces
- Mark dependent check as BLOCKED with explicit cause

```
gh....................... ✗
  gh auth................ ⏸ (blocked: gh missing)
```

### R4. Whitespace as comprehension

- Use one blank line before an ERROR block.
- Use one blank line before "Fix by running…"
- Do not sprinkle blank lines randomly.

### R5. Line length

- Target <= 80 columns for readability.
- If a line exceeds, wrap with indentation that preserves structure.

---

## 6. STANDARD OUTPUT PATTERNS

### 6.1 INFO Pattern (Neutral progress)

Use for: starting checks, announcing phases, neutral notes.

```
<cyan>Checking system prerequisites...</cyan>
```

Rules:
- Do not spam "info" lines.
- Prefer one line per phase, not per micro-step.

### 6.2 WARNING Pattern (Non-blocking)

Use for: suboptimal states, missing optional dependencies, degraded mode.

```
<yellow>⚠ Warning:</yellow> <plain>Message explaining impact</plain>
<plain>Continue possible.</plain>
```

Rules:
- Must state whether continuing is safe.
- Must state impact ("X feature will be unavailable").

### 6.3 ERROR Pattern (Blocking)

Use for: missing prerequisites, invalid configuration, permission errors.

```
<red>✗ Cannot continue — <cause></red>

• item 1
• item 2

Fix by running these commands in order:

  1) <magenta>cmd</magenta> args...
  2) <magenta>cmd</magenta> args...

After completing the steps above, run:

  <magenta>rerun command</magenta>
```

Rules:
- Must use calm language.
- Must be structured (header → list → fix → rerun).
- Must not include paragraphs of prose.
- Must not include ambiguous "try reinstalling" without specific commands.

### 6.4 SUCCESS Pattern

Use for: completion of a phase or entire tool.

```
<green>✓ All prerequisites satisfied.</green>
<plain>Continuing setup...</plain>
```

Rules:
- Keep success output short.
- Do not over-celebrate.

### 6.5 INTERACTIVE PROMPT Pattern

Use for: confirmations, choices, input requests.

```
<magenta>Proceed?</magenta> (y/N)
```

Rules:
- Default must be explicit and safe.
- Show current default state (capital letter or explicit label).
- Avoid ambiguous prompts like "Ok?" without context.
- Never ask for secrets unless necessary; if asking, mask input.

### 6.6 COMMAND DISPLAY Pattern (Copy-safe)

Commands must be easy to copy and understand.

Rules:
- Number commands when multiple.
- Group commands by dependency where possible.
- Color only the command verb (first token) if feasible; leave args plain.

```
1) sudo apt install gh
2) gh auth login
3) git config --global user.name "Your Name"
4) git config --global user.email "you@example.com"
```

---

## 7. MACHINE-READABLE FOOTER (RECOMMENDED)

UX-CLI encourages a final dim-gray machine footer:

```
[status] ok=git,workspace missing=gh,git_identity blocked=gh_auth version=1.5.13
```

**Rules:**
- Must be stable across versions unless major bump.
- Use snake_case keys.
- Values are comma-separated lists or scalars.
- Must not rely on color.

---

## 8. ANTI-PATTERNS (MUST AVOID)

| Anti-Pattern | Description | Failure Mode |
|--------------|-------------|--------------|
| A1. Color as decoration | rainbow output, gradients, random colors | users cannot map meaning |
| A2. Color-only signaling | red/green without symbols and text | inaccessible and ambiguous |
| A3. Paragraph errors | long explanations before giving next steps | users need action first |
| A4. Silent assumptions | tool "guesses" state and proceeds without stating decisions | trust erosion |
| A5. Unstructured commands | dumping 10 commands without order or grouping | user hesitation and mistakes |
| A6. Non-causal language | "something went wrong", "unable to process" | no actionable diagnosis |
| A7. Over-animation | spinners everywhere, flashing text, progress bars that lie | distraction, reduced trust |

---

## 9. EVALUATION CHECKLIST (PASS/FAIL)

UX-CLI PASS requires:

- **E1. Scan test:** Expert can identify failures in < 2 seconds.
- **E2. Recovery test:** Novice can fix blocking issues using only terminal output.
- **E3. Consistency test:** Colors and symbols map 1:1 to semantics across the tool.
- **E4. Dependency test:** Blocked states are labeled and causally explained.
- **E5. Degradation test:** Output remains usable with NO_COLOR or monochrome terminal.
- **E6. Safety test:** Defaults are safe; tool does not proceed on ambiguous prompts.

---

## 10. VERSIONING

- **Patch:** copy tweaks, small structural improvements, new examples
- **Minor:** new semantic state, new required section, altered footer keys
- **Major:** breaking changes to palette mapping or output contracts
