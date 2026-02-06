# documenting

Keep documentation current, versioned, and consistent with code.

## Rules

- Docs match code — if code changes, docs change
- Version in docs matches `package.json`/`dune-project`
- No stale references to removed features
- Examples must run

## When to Update

| Code Change | Doc Update |
|-------------|------------|
| New command | README, help text |
| New type/function | Relevant skill/mindset |
| Removed feature | Remove from all docs |
| Version bump | Update all version refs |

## Checklist

See `checklists/documenting.md` for review checklist with severities.

## Structure

| Doc | Purpose |
|-----|---------|
| README.md | Entry point, quick start |
| CHANGELOG.md | Version history |
| docs/design/ | Architecture decisions |
| skills/ | How-to guides |
| mindsets/ | Principles |

## Style

From `mindsets/WRITING.md`:
- Short, direct sentences
- Concrete facts, no vibes
- Only claim what you can prove
