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

2.3. **Version bump — all locations**
  - `cn.json` → `"version": "X.Y.Z"`
  - `src/lib/cn_lib.ml` → `let version = "X.Y.Z"`
  - `test/cram/version.t` → `cn X.Y.Z`
  - `test/cram/cli/cli.t` → `cn X.Y.Z` and `cn vX.Y.Z`
  - ❌ Update cn.json but forget cram tests (CI fails)
  - ✅ `grep -rn 'old_version'` to find all locations before committing

2.4. **CHANGELOG**
  - Add row to version table with TSC grades
  - Add detailed section: Added / Changed / Fixed
  - ❌ "Various improvements" (no detail)
  - ✅ Each commit's impact named, linked to issues

2.5. **Tag and push**
  - **Tag naming convention:** use bare version numbers without `v` prefix: `3.15.1`, not `v3.15.1`. This matches VERSION file content, branch naming (`claude/3.15.0-22-...`), and snapshot directory names (`docs/gamma/cdd/3.15.0/`). Consistency across all version surfaces.
  - Commit: `git commit -m "release: X.Y.Z — summary"`
  - Tag: `git tag X.Y.Z` (lightweight tag, bare version)
  - Push: `git push origin main && git push origin X.Y.Z`
  - GitHub release: `gh release create X.Y.Z --title "X.Y.Z — summary" --notes "..."`
  - ❌ Push commit without tag (release CI doesn't trigger)
  - ❌ Mix `v` prefix and bare versions across tags (`v3.14.6` then `3.14.7`)
  - ✅ Commit, tag (bare), push in sequence; verify release CI starts

2.6. **Wait for release CI**
  - Release workflow builds binaries (linux-x64, macos-x64, macos-arm64)
  - Wait for completion before deploying
  - ❌ Deploy while CI still running (stale binary from previous release)
  - ✅ `gh run watch <id> --exit-status` then verify assets attached

2.7. **Deploy to target hosts**
  - Stop daemon, download binary, replace, start daemon
  - `cn deps restore` to sync cognitive substrate
  - Validate: `cn --version`, test an op that exercises the fix
  - ❌ Replace binary while daemon running (`Text file busy`)
  - ✅ `systemctl stop → cp → chmod → systemctl start → cn --version`

2.8. **Validate**
  - Version matches everywhere: binary, cn.json, tag
  - The specific fix or feature works end-to-end
  - Check telemetry for errors on first cycle
  - ❌ "It deployed" (no functional validation)
  - ✅ Trace telemetry, confirm receipts/artifacts exist, agent responds correctly

## 3. Rules

3.1. **All version strings must agree**
  - cn.json, cn_lib.ml, cram tests, tag, binary output, CHANGELOG
  - ❌ Tag is v3.9.1 but `cn --version` says 3.9.0
  - ✅ `grep -rn 'old_version' src/ test/ cn.json` returns nothing after bump

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

3.7. **TSC scoring in CHANGELOG**
  - Rate α (pattern), β (relation), γ (process) for each release
  - Honest grades — not everything is A+
  - ❌ Every release is A+ (grade inflation, no signal)
  - ✅ "β: A- — DUR skills synced but README.md still references old framing"
