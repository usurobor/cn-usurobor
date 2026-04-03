---
name: release
description: Execute coherent releases where every version bump is a measured coherence delta with a complete audit trail. Use for all tagged releases.
artifact_class: skill
kata_surface: embedded
governing_question: Do all version surfaces agree, and does the release body foreground the coherence delta?
---

# Release

## Core Principle

**Coherent release: every version bump is a measured coherence delta with a complete audit trail.**

A release has parts: readiness check, version decision, changelog, tag, binaries, deployment, validation. Coherence = each part completed and each artifact matches the others (version in code = tag = changelog = binary = deployed agent).

Failure mode: version drift — tag says X, binary says Y, agent reports Z. Or: releasing without validation, so breakage ships silently.

## 1. Define

1.1. **Identify the parts**
  - Readiness: CI green, branches merged or returned, main clean
  - Version: semver bump decided from commit content
  - Artifacts: cn.json, cn_lib.ml, cram tests, CHANGELOG, tag, GitHub release, binaries
  - Deployment: binary on target hosts, `cn deps restore`, validation
  - ❌ Push tag, hope it works
  - ✅ Every artifact checked, deployed, validated end-to-end

1.2. **Articulate how they fit**
  - Version flows: cn.json + cn_lib.ml → cram tests → CHANGELOG → commit → tag → CI → binaries → deploy → validate
  - Each step depends on the prior; skip one and the chain breaks
  - ❌ Tag pushed before version bumped in code (binary reports old version)
  - ✅ Version string updated everywhere before commit, tag matches code

1.3. **Name the failure mode**
  - Version drift: any two artifacts disagree on the version
  - Silent breakage: release ships but CI failed or validation skipped
  - Incomplete deploy: binary updated but packages stale (`cn deps restore` not run)
  - ❌ "cn update worked" (but agent still reports old version)
  - ✅ `cn --version` matches tag, `cn deps restore` run, agent can execute ops

## 2. Unfold

2.1. **Readiness check**
  - CI passing on main (unit tests + cram tests)
  - No unmerged branches that should be in this release
  - `git branch -r --no-merged origin/main` — review each, merge or defer
  - ❌ Release with failing CI ("it's just a flaky test")
  - ✅ CI green, or known failure documented and accepted (e.g. Coherence workflow on #22)

2.2. **Version decision**
  - Review commits since last tag: `git log --oneline $(git describe --tags --abbrev=0)..HEAD`
  - Major: breaking changes, paradigm shift
  - Minor: new features, backwards compatible (new ops, new skills, new specs)
  - Patch: bug fixes only
  - ❌ Patch for a new runtime feature (undersells the change)
  - ✅ Minor for new `Cn_shell.execute` entry point; patch for CI fix

2.3. **Version bump — VERSION-first flow**
  - `VERSION` file at repo root is the single source of truth
  - Edit `VERSION` to the new version string (bare, no `v` prefix)
  - Run `scripts/stamp-versions.sh` — derives all manifests (`cn.json`, package `cn.package.json` files) from VERSION
  - Run `scripts/check-version-consistency.sh` — validates all version-stamped files agree
  - `cn_lib.ml` reads version from a dune-generated module at build time — no manual edit needed
  - Cram tests read version dynamically — no manual edit needed
  - ❌ Edit cn.json or cn_lib.ml by hand (bypasses single source of truth)
  - ❌ Skip stamp-versions.sh ("I'll update the manifests manually")
  - ✅ `echo "X.Y.Z" > VERSION && scripts/stamp-versions.sh && scripts/check-version-consistency.sh`

2.4. **CHANGELOG**
  - Add a ledger row matching the format defined in `CHANGELOG.md` § Release Coherence Ledger. That format is canonical — do not reinvent the row shape here.
  - The ledger row includes: Version, C_Σ, α, β, γ, Level, and a coherence note.
  - Add a detailed section below the ledger: Added / Changed / Fixed, with each commit's impact named and linked to issues.
  - ❌ "Various improvements" (no detail)
  - ❌ Ledger row without engineering level (Level column is required)
  - ✅ Each commit's impact named, linked to issues
  - ✅ Honest TSC grades — not everything is A+
  - `RELEASE.md` must restate the ledger row as the Outcome section in prose. The ledger row remains canonical; the release body explains it.
  - If release notes or CHANGELOG wording are being authored, load the writing skill and record it in the CDD Trace.

2.5. **Release notes — RELEASE.md**
  - Write `RELEASE.md` at repo root before tagging. This is the GitHub release body.
  - A release is a measured coherence delta. The release body must foreground what got more coherent and why, then detail the changes.
  - The release CI workflow uses `RELEASE.md` as the release body if present; otherwise it auto-generates (which produces only PR titles — not acceptable).
  - `RELEASE.md` is committed in the release commit and consumed by CI. It stays in the repo until the next release overwrites it.
  - ❌ Let CI auto-generate release notes (just PR titles, no detail)
  - ❌ Jump straight into Fixed/Added/Changed (change-loggy, not coherence-framed)
  - ❌ Manually create the GitHub release after CI (race condition with workflow)
  - ✅ Outcome first, then changes, then proof
  - ✅ Write `RELEASE.md` → commit in release commit → CI uses it as release body

  ```markdown
  # RELEASE.md format

  ## Outcome

  Coherence delta: C_Σ <grade> (`α <grade>`, `β <grade>`, `γ <grade>`) · **Level:** `L<level>`

  One short paragraph:
  - what became more coherent
  - what surface is now more truthful / portable / durable / explicit

  ## Why it matters

  One short paragraph:
  - what incoherence this cycle targeted
  - why it mattered operationally or structurally
  - what changed in the system's behavior or authority model

  ## Fixed

  - **Short description** (#issue): what changed and why it matters.

  ## Added

  - **Short description** (#issue): what was added and what new capability or clarity it provides.

  ## Changed

  - **Short description** (#issue): what changed in behavior, authority, or shape.

  ## Removed

  - **Short description** (#issue): what was removed and what incoherence it eliminated.

  ## Validation

  - Deployed to [target], validated [specific check].
  - State what was proven coherent by the validation, not only that deployment succeeded.

  ## Known Issues

  - #N — description (if any found during validation)
  ```

2.6. **Tag and push**
  - **Tag naming convention:** use bare version numbers without `v` prefix: `3.15.1`, not `v3.15.1`. This matches VERSION file content, branch naming (`claude/3.15.0-22-...`), and snapshot directory names (`docs/gamma/cdd/3.15.0/`). Consistency across all version surfaces.
  - Commit: `git commit -m "release: X.Y.Z — summary"` (includes VERSION, manifests, CHANGELOG, RELEASE.md)
  - Tag: `git tag X.Y.Z` (lightweight tag, bare version)
  - Push: `git push origin main && git push origin X.Y.Z`
  - ❌ Push commit without tag (release CI doesn't trigger)
  - ❌ Mix `v` prefix and bare versions across tags (`v3.14.6` then `3.14.7`)
  - ❌ Tag without RELEASE.md (CI auto-generates sparse notes)
  - ✅ Commit (with RELEASE.md), tag (bare), push in sequence; verify release CI starts

2.7. **Wait for release CI**
  - Release workflow builds binaries (linux-x64, macos-x64, macos-arm64)
  - Wait for completion before deploying
  - ❌ Deploy while CI still running (stale binary from previous release)
  - ✅ `gh run watch <id> --exit-status` then verify assets attached

2.8. **Deploy to target hosts**
  - Stop daemon, download binary, replace, start daemon
  - `cn deps restore` to sync cognitive substrate
  - Validate: `cn --version`, test an op that exercises the fix
  - ❌ Replace binary while daemon running (`Text file busy`)
  - ✅ `systemctl stop → cp → chmod → systemctl start → cn --version`

2.9. **Validate**
  - Version matches everywhere: binary, cn.json, tag
  - The specific fix or feature works end-to-end
  - Check telemetry for errors on first cycle
  - Validation must confirm the targeted coherence delta, not only binary/version correctness.
  - ❌ "It deployed" (no functional validation)
  - ✅ Trace telemetry, confirm receipts/artifacts exist, agent responds correctly

2.10. **CDD Trace update**
  - Update the primary branch artifact's CDD Trace with the release row:
    - artifact: tag / CHANGELOG / release artifact
    - skills loaded: release, plus writing if used
    - decision: released version X.Y.Z
  - If the branch has no primary branch artifact, the PR body must carry the trace instead.

## 3. Rules

3.1. **All version strings must agree**
  - VERSION, cn.json, package manifests, tag, binary output, CHANGELOG
  - `scripts/check-version-consistency.sh` validates this mechanically
  - ❌ Tag is 3.15.1 but VERSION says 3.15.2 (forgot to commit before tagging)
  - ✅ `scripts/check-version-consistency.sh` passes before commit

3.2. **CI must pass before tag**
  - If CI fails after tag, fix and force-push tag (amend release commit)
  - ❌ Ship with known test failure ("we'll fix it next patch")
  - ✅ Fix the test, amend, force-push tag, wait for green

3.3. **Never deploy stale binaries**
  - Release CI builds from the tag; wait for it to complete
  - Clear cached downloads (`--clobber` or `rm` old artifacts)
  - ❌ `cn update` downloads cached v3.5.1 binary from /tmp
  - ✅ Fresh download after CI completes, verify binary version after install

3.4. **Deploy includes deps restore**
  - Binary update alone leaves cognitive substrate stale
  - `cn deps restore` syncs doctrine, mindsets, skills from packages
  - ❌ Binary is v3.9.1 but skills are from v3.8.0 (package drift)
  - ✅ `cn deps restore` immediately after binary update

3.5. **Validate with the specific fix**
  - Don't just check version — exercise the feature or fix
  - ❌ "Version looks right, ship it"
  - ✅ For #46: send a message, check telemetry for receipts, confirm artifacts exist

3.6. **If CI fails post-tag, amend don't re-tag**
  - `git commit --amend --no-edit && git tag -d vX.Y.Z && git tag -a vX.Y.Z && git push --force --tags`
  - Keeps a clean single tag, single release commit
  - ❌ v3.9.1, v3.9.1-fix, v3.9.1-fix2
  - ✅ One tag, amended until CI green

3.7. **RELEASE.md must exist before tag**
  - The release commit must include `RELEASE.md` at repo root
  - If `RELEASE.md` is missing, the tag must not be pushed (CI will auto-generate sparse notes)
  - ❌ Tag without RELEASE.md ("I'll update the release body manually later")
  - ✅ Write RELEASE.md → include in release commit → tag → push

3.8. **TSC scoring in CHANGELOG**
  - Rate α (pattern), β (relation), γ (process) for each release
  - Honest grades — not everything is A+
  - ❌ Every release is A+ (grade inflation, no signal)
  - ✅ "β: A- — DUR skills synced but README.md still references old framing"

---

## 4. Kata

**Scenario:** A bugfix is ready on main. Execute the release.

1. Readiness check — CI green, no unmerged branches
2. Version decision — patch, minor, or major
3. VERSION bump + stamp-versions.sh + check-version-consistency.sh
4. CHANGELOG ledger row with honest TSC grades
5. RELEASE.md with Outcome mirroring the ledger row
6. Commit, tag (bare version), push
7. Wait for release CI, deploy, validate with the specific fix
8. Post-release assessment

**Verify:** Does `scripts/check-version-consistency.sh` pass? Does RELEASE.md start with the coherence delta? Does validation confirm the targeted incoherence is closed?
