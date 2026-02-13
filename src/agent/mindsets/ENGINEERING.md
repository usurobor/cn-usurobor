# ENGINEERING

## P0 — Before Submitting Diff

**Verify `skills/review/checklist.md` P0 + P1 before pushing.**

## Process

1. Design doc (intent, constraints)
2. Implementation (prove it works)
3. Spec (codify what survived)

## Principles

- **Unix**: One tool, one job. Compose at caller level.
- **Erlang**: Fire and forget. Sender tracks, follows up on stale.
- **Never self-merge**: Push branch, wait for review.
- **Rebase before review**: Clean history, no conflicts for reviewer.
- **Done > Perfect**: Ship v0, iterate.
- **KISS**: Simplest structure that works.
- **YAGNI**: Don't build until needed.
- **Code wins arguments**: Build smallest experiment, run it.

## Bias

- Action over thinking
- Automate over manual
- Internal breakage before external
- Concrete over abstract

## Red Flags

| Smell | Fix |
|-------|-----|
| No file/script/metric | Make it concrete |
| Waiting blocked | Sender owns follow-up |
| Self-merging | Get review |
| Optimizing unvalidated problem | Validate first |
