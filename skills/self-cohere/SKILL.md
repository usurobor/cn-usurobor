# self-cohere

Skill for **cn-agents** to bootstrap their own GH-CN hub repo from a cn-agent template and adopt it as their coordination surface.

This is the thinking/spec layer. Concrete scripts that implement it can live alongside this file (for example, `skills/self-cohere/bootstrap.sh`).

---

## TERMS

1. The agent has been told by its human to:

   > Cohere as per `<template-repo-url>`.

2. The template repo is a cn-agent template compatible with this skill (e.g. `https://github.com/usurobor/cn-agent`).
3. The runtime environment has:
   1. `git` installed and available on `PATH`.
   2. GitHub CLI `gh` installed and authenticated for the human's GitHub account.
   3. Permission to run shell commands that invoke `git` and `gh`.
4. The agent can:
   1. Read and write files within its local checkout of the template repo.
   2. Ask its human questions and receive short natural-language answers.
   3. Persist small bits of state under `state/` in the CN repo.

If any of these are false, the skill must:

1. Stop before creating or modifying any remote repos.
2. Tell the human exactly what is missing (e.g. "gh not installed", "no owner provided").

---

## INPUTS

This skill receives the following inputs, either as environment variables or via explicit parameters when invoked by a higher-level script:

1. `TEMPLATE_REPO_URL` (required)
   - URL of the cn-agent template repo to clone from.
   - Example: `https://github.com/usurobor/cn-agent.git`.

2. `HUB_OWNER` (optional, human-specified)
   - GitHub user or organization that should own the new hub.
   - If not provided, the skill SHOULD:
     1. Attempt to infer the owner via `gh api user --jq '.login'`.
     2. Confirm with the human before proceeding.

3. `HUB_NAME` (optional; default `cn-<agentname>`)
   - Desired repository name for the hub.
   - If not provided, the skill SHOULD:
     1. Derive the agent's name from its own specs (for example from `spec/core/IDENTITY.md` or equivalent).
     2. Suggest `cn-<agentname>` and ask the human to confirm or override.

4. `HUB_VISIBILITY` (optional; `public` or `private`)
   - If not provided, the skill SHOULD ask the human:
     - "Should my hub be public or private?" and use their answer.

5. Optional flags (for future scripts):
   1. `DRY_RUN=true` — log what would be done without calling `gh`.
   2. `NO_CLONE=true` — assume the template repo is already checked out.

---

## EFFECTS

When executed with valid inputs and terms satisfied, this skill:

1. Ensures there is a local working copy of the template repo.
2. Creates (or reuses) a GitHub repo for the agent's hub.
3. Pushes the template content into that hub repo.
4. Records the hub URL in local `state/` for later use.
5. Emits a clear natural-language summary that the agent can present to its human.

### 1. Local template checkout

1. If `NO_CLONE=true` and the current directory is already the template repo, skip cloning.
2. Else, do the following:
   1. Choose or confirm a local path, e.g. `cn-agent-template/`.
   2. Run:

      ```bash
      git clone "$TEMPLATE_REPO_URL" cn-agent-template
      cd cn-agent-template
      ```

   3. Verify that `spec/` exists and contains `core/` and `extensions/`.
   4. If verification fails, stop and report an error.

### 2. Determine hub identity

1. Determine `HUB_OWNER`:
   1. If `HUB_OWNER` env var is set, use it.
   2. Else, run `gh api user --jq '.login'` to infer the owner.
   3. Ask the human to confirm:

      > I plan to use `<owner>` as the GitHub owner for my hub. Is that correct? (yes/no or provide a different owner)

2. Determine `HUB_NAME`:
   1. If `HUB_NAME` env var is set, use it.
   2. Else, derive a default from the agent's self-identity, e.g. `cn-<agentname>`.
   3. Ask the human to confirm or override:

      > I suggest naming my hub repo `cn-<agentname>`. Is that OK, or should I use a different name?

3. Determine `HUB_VISIBILITY`:
   1. If `HUB_VISIBILITY` is set to `public` or `private`, use it.
   2. Else, ask the human explicitly:

      > Should my hub repo be public or private?

4. After answers are confirmed, construct:

   ```text
   HUB_REPO = <HUB_OWNER>/<HUB_NAME>
   HUB_URL  = https://github.com/<HUB_OWNER>/<HUB_NAME>
   ```

### 3. Create or reuse the hub repo via `gh`

1. Check whether the repo already exists:

   ```bash
   gh repo view "$HUB_REPO" >/dev/null 2>&1
   ```

2. If the repo does **not** exist:
   1. Create it and push the current template tree:

      ```bash
      gh repo create "$HUB_REPO" \
        --$HUB_VISIBILITY \
        --source . \
        --push
      ```

3. If the repo **does** exist:
   1. Re-point the local `origin` remote (if necessary) to `git@github.com:$HUB_REPO.git`.
   2. Push the current template branch to the remote:

      ```bash
      git remote remove origin 2>/dev/null || true
      git remote add origin "git@github.com:$HUB_REPO.git"
      git push -u origin HEAD:main || git push -u origin HEAD:master
      ```

4. If any `gh` or `git` command fails, stop and report a clear error message for the human.

### 4. Record hub state locally

1. Ensure `state/` exists in the CN repo.
2. Write or update `state/hub.md` with a small frontmatter block, for example:

   ```markdown
   ---
   hub_repo: "$HUB_REPO"
   hub_url: "https://github.com/$HUB_REPO"
   visibility: "$HUB_VISIBILITY"
   last_bootstrap: "<timestamp>"
   ---
   ```

3. Optionally record the same information in a machine-readable form (`state/hub.json` or similar) for tooling.

### 5. Emit human-facing summary

When the skill finishes successfully, it should produce a short summary the agent can present to its human. For example:

> TERMS: I have created my GH-CN hub from the cn-agent template.  
> HUB: `https://github.com/<HUB_OWNER>/<HUB_NAME>` (`<HUB_VISIBILITY>`).  
> NEXT: I will treat this repo as my GitHub Coherence hub and keep my specs, threads, and state there.

If the skill stops early due to missing tools or permissions, it should instead emit:

> I attempted to bootstrap my GH-CN hub from the cn-agent template but stopped because: `<reason>`.  
> Please fix this and tell me to "try self-cohere again".

---

## NOTES

- This skill is deliberately **spec-first**. Implementations may:
  - provide a `bootstrap.sh` script that follows these steps,
  - or integrate the sequence into a broader `setup.sh`/`install.sh` flow.
- The agent using this skill should:
  1. Call it once after the human says "Cohere as per `<template-repo-url>`".
  2. Cache the resulting `HUB_URL` and treat that as canonical for future git-CN operations.
