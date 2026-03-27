# Emoji Language

Compressed operator↔agent signaling via emoji. Reduces friction, preserves intent. First step toward CTB.

## 1. Core Principle

**Say more with less, unambiguously.** Emoji shorthand replaces multi-word commands with single symbols. Both operator and agent use them — as messages, as reactions, as inline modifiers.

## 2. Protocol

### 2.1 Operator → Agent

Operator sends an emoji (as message or reaction). Agent interprets per the active mapping table and acts immediately. No confirmation needed unless ambiguous.

### 2.2 Agent → Operator

Agent uses emoji reactions on operator messages to signal acknowledgment, status, or intent. Lighter than a text reply.

### 2.3 Adding new mappings

- Only add mappings observed in actual use
- Operator defines meaning, agent learns
- Ambiguous until confirmed = ask once, then remember
- Track in the hub's emoji language thread

### 2.4 Reaction discipline

- React when it replaces a text reply (saves bandwidth)
- Don't react + reply with the same meaning (redundant)
- Platform-dependent: check available reaction set (Telegram, Discord, etc.)

## 3. Default mappings

These are starting points. Operator overrides are authoritative.

| Emoji | iOS keyboard | Meaning | Context |
|-------|-------------|---------|---------|
| 🧢 | cap | cap it / apply CAP / just do it | Stop deliberating, act |
| 🔍 | search, magnifying | review this | PR or artifact review |
| 🚢 | ship | ship it / merge | Approve and merge |
| 🧠 | brain | MCI / capture as learning | Write adhoc thread or memory |
| ⚡ | zap, lightning | MCA / act now | Execute, don't plan |
| 🔄 | arrows, cycle | CLP / iterate on divergence | Run convergence loop |
| 📸 | camera, snap | snapshot / capture state | Daily, memory, or state dump |
| 🧹 | broom | clean up | Remove stale artifacts |
| ✅ | check | approved / go | Confirmation |
| 🛑 | stop | stop / don't merge | Block action |
| 📝 | memo, note | update the issue/doc | Write to the source of truth |
| 🌊 | wave, ocean | daily/EOD reflection | Trigger daily + adhoc threads |

## 4. Progression

emoji shorthand → structured shorthand → CTB expressions

This skill is the first layer. As patterns stabilize, frequently-used sequences become structured commands. Eventually, the most precise operations graduate to CTB expressions for deterministic, verifiable agent coordination.

See: [CTB v4.0.0 Vision](docs/alpha/ctb/CTB-v4.0.0-VISION.md)

## 5. Anti-patterns

- ❌ Inventing mappings without observed use (speculative)
- ❌ Using emoji when the situation needs nuance (compressed ≠ always better)
- ❌ Reacting to every message (noise, not signal)
- ✅ Emoji when it's unambiguous and saves a round-trip
- ✅ Text when context or judgment is needed
