# threads/

All agent threads live here. Everything is a thread.

## Structure

| Directory | Purpose | Naming |
|-----------|---------|--------|
| `daily/` | Daily reflections | `YYYYMMDD.md` |
| `weekly/` | Weekly rollups | `YYYYMMDD.md` (Monday of week) |
| `monthly/` | Monthly reviews | `YYYYMM01.md` |
| `quarterly/` | Strategic alignment | `YYYYMM01.md` (Q start) |
| `yearly/` | Evolution reviews | `YYYY0101.md` |
| `adhoc/` | Topic threads | `YYYYMMDD-topic.md` |

## Conventions

- **YYYYMMDD** prefix on all files (enables sorting)
- Periodic threads use the `reflect` skill with α/β/γ framework
- Adhoc threads are freeform

## Privacy

Privacy is repo-level. Public hub = public threads. Private hub = private threads.

See `skills/reflect/SKILL.md` for the reflection framework.
