# UX CLI

Terminal application UX standards.

## Principles

- Color encodes semantics, never decoration
- Output must be self-sufficient (what happened, what's blocked, what to do)
- Failure paths are first-class
- No blame, no vibes

## Colors

| Color | Meaning |
|-------|---------|
| Green | OK / success |
| Red | Error / blocking |
| Yellow | Warning / non-blocking |
| Cyan | Info / headings |
| Magenta | Commands to run |
| Gray | Dim / inactive |

## Symbols

| Symbol | Meaning |
|--------|---------|
| ✓ | OK |
| ✗ | Fail |
| ⚠ | Warning |
| ⏸ | Blocked |
| → | Next step |

## Patterns

### Success

```
✓ All prerequisites satisfied.
```

### Warning

```
⚠ Warning: impact
Continue possible.
```

### Error

```
✗ Cannot continue — cause

Fix by running:
  1) cmd args
  2) cmd args

Then rerun: cmd
```

## Anti-Patterns

- Color as decoration
- Color-only signaling (no symbols)
- Paragraph errors (action buried in prose)
- Silent assumptions
- "Something went wrong" (non-causal)

## Checklist

- [ ] Expert can identify failures in <2s
- [ ] Novice can fix using only terminal output
- [ ] Usable with NO_COLOR
