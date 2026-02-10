# Release

Ship a version. Tag, changelog, push.

---

## TERMS

1. All branches merged or returned
2. Tests passing
3. Clean main branch
4. Know what version (semver)

---

## Checklist

- [ ] Decide version (major/minor/patch)
- [ ] Update CHANGELOG.md (table + detailed notes)
- [ ] Commit: `git commit -m "release: vX.Y.Z — Summary"`
- [ ] Tag: `git tag -a vX.Y.Z -m "vX.Y.Z: Summary"`
- [ ] Push: `git push origin main --tags`
- [ ] GitHub Release: `gh release create vX.Y.Z ...`

---

## Versioning (Semver)

| Bump | When | Example |
|------|------|---------|
| **Major** (X.0.0) | Paradigm shift, breaking changes | v1.x → v2.0.0 |
| **Minor** (x.Y.0) | New features, backwards compatible | v2.0.0 → v2.1.0 |
| **Patch** (x.y.Z) | Bug fixes only | v2.1.0 → v2.1.1 |

---

## Process

### 1. Check readiness

```bash
# All branches merged?
git branch -r --no-merged origin/main

# On main, up to date?
git checkout main && git pull
```

### 2. Decide version

Review commits since last tag:
```bash
git log --oneline $(git describe --tags --abbrev=0)..HEAD
```

Ask: Major? Minor? Patch?

### 3. Update CHANGELOG.md

Add entry to version table:
```markdown
| v2.0.0 | A+ | A+ | A+ | A+ | Summary of changes |
```

Add detailed release notes:
```markdown
## v2.0.0 (YYYY-MM-DD)

**Title**

### Added
- Feature 1
- Feature 2

### Changed
- Change 1

### Fixed
- Fix 1
```

### 4. Commit and tag

```bash
git add CHANGELOG.md
git commit -m "release: vX.Y.Z — Summary"
git tag -a vX.Y.Z -m "vX.Y.Z: Summary"
git push origin main --tags
```

### 5. Create GitHub Release

```bash
# Create release with notes from CHANGELOG
gh release create vX.Y.Z --title "vX.Y.Z: Summary" --notes "
## What's New

- Feature 1
- Feature 2

## Changed

- Change 1

## Full Changelog

See CHANGELOG.md for details.
"
```

Or use `--generate-notes` for auto-generated notes:
```bash
gh release create vX.Y.Z --title "vX.Y.Z: Summary" --generate-notes
```

### 6. Announce

Post summary to relevant channels.

---

## TSC Scoring

Rate each release on coherence axes:

| Axis | Question |
|------|----------|
| **α (Pattern)** | Is the codebase structurally consistent? |
| **β (Relation)** | Do parts fit together? Docs match code? |
| **γ (Process)** | Is evolution stable? Clear upgrade path? |

Grades: A+ / A / A- / B+ / B / B- / C+ / C / C- / D / F

---

## Quick Reference

```bash
# Check what's new
git log --oneline $(git describe --tags --abbrev=0)..HEAD

# Tag and push
git tag -a v2.1.0 -m "v2.1.0: New feature"
git push origin main --tags
```

---

## Anti-Patterns

- Releasing without updating CHANGELOG
- Forgetting to push tags (`--tags`)
- Major version for minor changes
- Patch version for breaking changes
- Releasing with unmerged branches

---

## NOTES

- See `skills/ship/` for branch → main workflow
- See `CHANGELOG.md` for version history
- Tags trigger GitHub releases automatically (if configured)
