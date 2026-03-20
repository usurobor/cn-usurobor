# Adhoc Thread

## Core Principle

**Coherent adhoc thread: the content justifies a standalone thread, and the type matches the nature of the content.**

An adhoc thread captures something worth preserving outside the normal cadence — a proposal, learning, question, or decision that doesn't belong in a reflection or an issue but would be lost if left inline.

Failure mode: under-capture (insights lost in chat) or over-capture (noise elevated to threads, cluttering the hub).

## 1. Define

1.1. **Identify the parts**
  - Trigger: something happened worth preserving as a standalone record
  - Type: proposal, learning, question, or decision
  - Content: the substance — grounded, specific, addressed to someone
  - ❌ "I'll remember this" (no thread, lost in a week)
  - ✅ Recognized the trigger, picked a type, wrote it down

1.2. **Articulate how they fit**
  - The trigger justifies creating a thread (not everything deserves one)
  - The type determines the structure (each type has its own shape)
  - The content fills that structure with specifics, not vague notes
  - ❌ A "learning" that's actually a question (type mismatch)
  - ✅ Type matches content: learning has what-happened/why-wrong/lesson

1.3. **Name the failure mode**
  - Under-capture: insight stays in chat, never becomes a thread, lost across sessions
  - Over-capture: routine observations elevated to threads, hub becomes noisy
  - Type mismatch: content shaped as one type but filed as another
  - ❌ Filing a decision thread when you haven't actually decided yet (that's a question)
  - ✅ Recognizing "I don't know yet" → question thread, not decision thread

## 2. Unfold

2.1. **Trigger recognition — when to create a thread**
  - Something happened that a future session would benefit from knowing
  - A peer needs input or context on something not covered by existing threads
  - A pattern, irony, or structural insight surfaced that's worth naming
  - ❌ "The build passed" (routine, not thread-worthy)
  - ✅ "We filed a 'move off GitHub Issues' issue on GitHub Issues — that's a substrate coherence gap worth naming"
  - ❌ Every small observation gets a thread (over-capture)
  - ✅ Thread created when content would be lost or hard to find otherwise

2.2. **Type selection — match structure to content**

  **Proposal (CLP structure)**
  - You have a suggested change and want input
  - Structure: TERMS → POINTER → EXIT
  - ❌ "We should maybe change X" in chat (no record, no structure)
  - ✅ Thread with clear terms, what prompted it, proposed exit

  **Learning**
  - Something went wrong or revealed a non-obvious truth
  - Structure: What Happened → Why It Was Wrong → Lesson
  - ❌ "TIL you can do X" (trivial, not thread-worthy)
  - ✅ "We hit X failure because of assumption Y — lesson: Z"

  **Question**
  - You need peer input and the question has enough context to be answerable
  - Structure: Context → Question → Options
  - ❌ "What do you think?" (no context, not actionable)
  - ✅ "Given X context, should we do A or B? Here's the tradeoff."

  **Decision**
  - A choice was made and the reasoning should be preserved
  - Structure: Decision → Alternatives → Why This One
  - ❌ "We went with X" (no alternatives, no reasoning)
  - ✅ "Chose X over Y and Z because of constraint W"

2.3. **Content — fill the structure with specifics**
  - Addressed to someone (From/To)
  - Dated
  - Status tracked (Open/Resolved)
  - ❌ Vague notes with no audience or date
  - ✅ Concrete, attributed, timestamped, closeable

## 3. Rules

3.1. **Capture or lose — bias toward writing it**
  - When in doubt between capturing and not, capture
  - A thread you can close later costs less than an insight you can't recover
  - ❌ "I'll remember" (you won't, you're stateless across sessions)
  - ✅ Write the thread, close it later if it turns out trivial

3.2. **One thread, one topic**
  - Split compound topics into separate threads
  - ❌ "Proposal + also here's a question + also we decided something"
  - ✅ Three threads, each with the right type

3.3. **Type must match content**
  - Don't file a decision when you haven't decided (that's a question)
  - Don't file a learning when nothing went wrong (that might be a decision)
  - ❌ "Decision: we should probably do X" (that's a proposal)
  - ✅ "Proposal: should we do X?" → later → "Decision: we chose X because Y"

3.4. **Close when resolved**
  - Threads have a lifecycle: Create → Share → Discuss → Resolve
  - Update status to Resolved when done; don't leave threads open indefinitely
  - ❌ 15 open threads from two months ago, all stale
  - ✅ Resolved threads marked, open threads are genuinely open

3.5. **Location and naming**
  - Path: `threads/adhoc/YYYYMMDD-topic.md`
  - Topic slug: lowercase, hyphenated, descriptive
  - ❌ `threads/adhoc/thread1.md`
  - ✅ `threads/adhoc/20260320-meta-irony-native-issues.md`
