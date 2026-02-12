# Auto-Update Case Study

10 issues found in ~100 lines. Two review rounds.

## Round 1 (5 issues)

| Issue | Category |
|-------|----------|
| Shell injection in re_exec | Shell |
| Mutable ref coupling | State |
| No cleanup on failure | Files |
| FSM not called | Design |
| String version compare | Version |

## Round 2 (5 issues)

| Issue | Category |
|-------|----------|
| No recursion guard → infinite loop | Loop |
| Git pull doesn't rebuild binary | Silent failure |
| No binary validation | Files |
| No API cooldown | External |
| PATH lookup in execvp | Shell |

## Key Lesson

We had just fixed an infinite-loop bug (actor timeout). Then wrote auto-update with re-exec that could infinite loop. Same bug class, missed by author, caught by fresh reviewer.

## Fixes Applied

- Recursion guard: `CN_UPDATING=1` env var
- Binary validation: size check + `--version` test
- Cooldown: 6-hour minimum between API checks
- Absolute path: `/usr/local/bin/cn` not PATH lookup
- Git path removed: binary-only updates (git pull doesn't rebuild)
