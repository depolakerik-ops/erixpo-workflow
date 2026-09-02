# Plan

status: draft
ceremony: unknown
# full | standard | light

## Product

One paragraph. Who, outcome, surface. What this folder is for.

## Non-goals

## Ceremony

- Level: full | standard | light
- Why (class × surface × request):
- Artifacts this plan will write (see pack ceremony.md):
- Slice 0 scaffold? yes (greenfield) / no (project already exists) / n/a

## Job type and stack

- Job:
- Surface (mandatory; do not default to web):
- Language / runtime:
- UI kit / platform guide:
- Data:
- Test:
- Check command (must run tests or the class-appropriate proof; no echo / exit 0 / true):
- Install (worktree):

## UI

- Surface? yes / no
- change-type: none | create | relanguage | retoken | recompose | reflow | remotion | new-screen | consistency | n/a
- Spec: `documents/ui/LANGUAGE.md` (none | draft | approved)
- Native mapping: `documents/ui/mapping.md` (n/a | present)
- Mockups: HTML only if surface is web (or last-resort wire); else n/a
- Direction:
- Mockups required for slices:

## Research

Pointer to `.erixpo/research.md`. Why this stack. What you rejected.

Judgment four lines live in research.md (pack judgment.md): default, reframe, non-obvious option, what we will not do.

## Constitution

Pointer to `.erixpo/CONSTITUTION.md`. Fill during init or slice 0.

## Slices

Each slice is small enough to review. Do not hide a second feature inside one.

### 0. Scaffold (greenfield only — skip if the project already exists)

Required before UI chrome and before feature slices. Protocol: pack scaffold.md.

- Goal: official current-year init for this surface; project opens/builds; check runs
- Files likely touched:
- Acceptance (observable): official project opens; `check:` runs tests or the class proof
- Edges: empty folder, existing files, official tool failure
- Tests to add: create the harness in this slice; do not ask whether to have tests
- UI change-type: n/a (no product pixels yet)
- Check:
- Status: todo | skipped-existing | done

### 1. —

- Goal:
- Files likely touched:
- Acceptance (observable):
- Edges (empty / invalid / denied / offline / first-run):
- Tests to add:
- UI change-type: none | create | relanguage | retoken | recompose | reflow | remotion | new-screen | consistency | n/a
- UI: tokens/components/screens touched (or n/a):
- Check:
- Status: todo

## Risks and unknowns

## Optional extras (not approved)

Do not implement these unless the user says so.
