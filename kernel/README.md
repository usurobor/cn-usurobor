# kernel/

Core system — non-negotiable protocol invariants.

Changing kernel/ requires protocol version bump. Breaking changes affect all CAs.

## Subdirectories

- **security/** — Trust boundaries, shell access, sandboxing policies
- **protocols/** — Actor model, git-CN message format, input/output protocol
- **identity/** — CA identity, coherence certification, badges

## Rules

1. Minimal surface area — if in doubt, it's not kernel
2. Stability over features — kernel changes are expensive
3. All CAs must comply — no opt-out
