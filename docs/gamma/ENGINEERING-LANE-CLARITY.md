# Engineering Lane Clarity

## Design Amendment for eng/README.md and ENGINEERING-LEVELS.md

Version: 1.0.0
Status: Draft

Purpose: Make the engineering lane legible and make L5 / L6 / L7 stable, local terms inside cnos.

---

## 0. Coherence Contract

### Gap

The engineering skill suite has grown into a real lane, but its top-level description is still too small and too stale. At the same time, the repo uses level language such as:

- L5
- L6
- L7

but does not yet have one canonical local definition of those levels.

This produces:

- weak discoverability of the engineering lane
- fuzzy level references
- unnecessary disagreement about what "L7" means in cnos

### Mode

MCA — add and revise top-level engineering docs.

### α / β / γ target

- α PATTERN: one explicit engineering lane map, one explicit levels definition
- β RELATION: align skills, essay, design/review language, and bundle selection
- γ EXIT: future skill work and engineering assessments can reference a stable shared vocabulary

---

## 1. Core Decision

The engineering lane should have:

1. a lane README
2. a levels definition doc

These do different jobs.

### 1.1 eng/README.md

This is the operational map:

- what the engineering lane contains
- what bundles are recommended
- what to load for what class of work

### 1.2 ENGINEERING-LEVELS.md

This is the normative vocabulary:

- what L5 means
- what L6 means
- what L7 means
- how to interpret those levels in cnos

### 1.3 The essay stays descriptive

The assessment essay is not replaced. It remains the observed/historical account of actual work in a period.

---

## 2. Normative level meanings

The shortest stable definitions are:

- L5 — local correctness
- L6 — system-safe execution
- L7 — system-shaping leverage

These should be stated explicitly and then unpacked.

### 2.1 L5

- local implementation quality
- follows existing architecture
- reasonable tests
- happy-path and nearby edge correctness

### 2.2 L6

- cross-surface coherence
- bounded failure and recovery
- docs/tests/runtime/operator truth alignment
- reliable execution inside the chosen architecture

### 2.3 L7

- challenge architecture assumptions
- choose higher-leverage boundaries
- strengthen proof discipline where needed
- price process and operational cost
- leave behind a platform that changes future work

---

## 3. Engineering lane map

The README should group engineering skills by work context, not org chart.

Recommended groups:

### Local implementation

- coding
- functional
- ocaml
- testing
- performance-reliability

### Design / system-shaping

- design
- architecture-evolution
- process-economics
- rca

### Review / closeout

- review
- ship
- follow-up

### Tooling / operator surfaces

- tool-writing
- ux-cli

### Authoring engineering knowledge

- documenting
- skill

---

## 4. Recommended engineering bundles

The README should define recommended bundles such as:

### Coding bundle

- coding
- functional
- ocaml
- testing
- performance-reliability

### Review bundle

- review
- documenting
- testing

### Design bundle

- design
- architecture-evolution
- process-economics

### Runtime / platform bundle

- design
- architecture-evolution
- performance-reliability
- testing
- review

### Tooling bundle

- tool-writing
- ux-cli
- testing

### Writing bundle

- documenting
- skill
- review

---

## 5. Relationship to the assessment essay

The new levels doc should explicitly state:

- the essay is descriptive
- the levels doc is normative

That avoids future conflict where an essay observation gets mistaken for the official definition.

---

## 6. Acceptance criteria

This amendment is complete when:

1. eng/README.md accurately reflects the current engineering skill suite.
2. ENGINEERING-LEVELS.md defines L5/L6/L7 in stable cnos-local terms.
3. The README maps skills to recommended bundles by work context.
4. The levels doc and the essay are clearly differentiated as normative vs descriptive.
5. Future design/review discussion can point to one canonical explanation of "L6" and "L7".

---

## 7. Summary

The engineering lane is now large enough that it needs:

- a better map
- and a clearer vocabulary

This amendment provides both:

- eng/README.md for operational loading context
- ENGINEERING-LEVELS.md for stable level meaning
