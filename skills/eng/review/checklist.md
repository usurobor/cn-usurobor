# Review Checklist

Pre-submit and review checklist. Both author and reviewer must verify.

## P0 — Governance

- [ ] **P0.1 No self-merge.** Author never merges own diff to main unless human explicitly instructs.
- [ ] **P0.2 Branch current.** Rebased on main. No missing commits from main.

## P1 — Process

- [ ] **P1.1 Author rebases.** Reviewer never rebases. Reviewer's time > author's time.
- [ ] **P1.2 Only author deletes branch.** Reviewer returns branches, never deletes.

## P2 — Quality

- [ ] **P2.1 Purpose.** Solves stated problem?
- [ ] **P2.2 Simplicity.** Simplest solution?
- [ ] **P2.3 Necessity.** No unnecessary additions?
- [ ] **P2.4 Types.** Correct and semantic?
- [ ] **P2.5 Edge cases.** Handled?
- [ ] **P2.6 Tests.** Tested?
- [ ] **P2.7 History.** Clean commits?

---

**Author:** Verify P0 + P1 before pushing branch.

**Reviewer:** Verify all. If P0 fails → REQUEST REBASE or reject.
