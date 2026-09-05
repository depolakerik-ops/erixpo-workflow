# Workflow verification — 2026-09-05

## Intended behavior

`/erixpo <request>` determines the intended outcome using the request and repository facts. It chooses the existing fix/feature/new/work/UI/review tracks without making the user choose a command. The workflow applies to any domain, including unfamiliar tools and physical or creative deliverables. Its platform examples are not a supported-project allowlist.

A small known change receives proportionate investigation and checks. A new project receives full research; a large architectural feature also receives full research and multiple slices. Research covers the actual toolchain, domain practices, applicable requirements, output quality, verification and missing skills/tools. Existing authorization carries forward; consequential unknowns receive focused questions.

## What was corrected

- New-project intent now takes precedence over visual attributes; Go language no longer means “continue,” and UI words do not match inside unrelated words.
- Added domain hints for robotics, standalone 3D/graphics, cross-platform frameworks and Linux. Hints remain advisory: unknown domains must be resolved from actual evidence rather than forced into web tooling.
- Added a domain adaptation contract separating deliverable, framework, platform, environment and proof. Standalone animations do not acquire application-navigation specs. Simulation, rendered output and physical verification are distinct evidence.
- Large architectural features have an explicit `--large-change` research flag; verified cached evidence cannot reduce them to a skipped pass.
- Full research now explicitly assesses compliance applicability and skills/MCP capability gaps. Discovery starts with installed tools and skills.sh; useful additions require concrete project-local proposals and authorization.
- Removed repeated approval gates, initialization detection based merely on installed engine files, and compulsory full design-direction work for a small change to existing UI.
- Clarified one-shot artifact exceptions, native preview limitations, evidence-driven reproduction attempts and code self-review criteria.

## Verification performed

- Classifier regression fixtures exercise bugs, additive features, project creation, UI changes, mixed requests and domain/platform collisions.
- Research-scope fixtures exercise fresh projects, large features, cached evidence, unknown APIs and UI changes.
- `tests/test_journeys.py` installs the pack in a disposable directory and invokes the installed CLI for 14 representative routing/research journeys: bugs, small and large features, HTML, responsive web, macOS, Android, Go CLI, robotics, Blender animation, Flutter, React Native and Linux.
- An independent agent walked through six requests against the protocols and reported contradictions; the corrections above address those findings.
- `bash check.sh` covers installer lifecycle, runtime boundaries, review evidence, worktrees, adapter contracts, schemas, version consistency and installed smoke behavior.

These checks verify implementation and protocol consistency. They do not prove every model will follow every instruction, nor do keyword fixtures replace repository-aware judgment. The installed CLI test does not simulate the host's slash-command UI. No live end-to-end provider benchmark, physical robot operation or rendered creative project was performed in this verification.

## Evidence sources inspected

- [skills.sh documentation](https://www.skills.sh/docs): discovery directory; review upstream content before installation.
- [Open skills CLI](https://github.com/vercel-labs/skills): project installation is the default; select specific skills and hosts, avoiding global/all flags for project-local proposals.
- [MCP Registry](https://modelcontextprotocol.io/registry/about): a discovery starting point alongside provider and host documentation.
- [W3C accessibility overview](https://www.w3.org/WAI/standards-guidelines/wcag/) and [Apple distribution guidelines](https://developer.apple.com/app-store/review/guidelines/): examples of primary sources to consult only where applicable.

Accessed 2026-09-05. The workflow must retrieve the relevant current sources for each future project; these examples are not a universal compliance checklist.


## Memory, self-improvement and dynamic expertise follow-up

Further verification found and corrected gaps in effective learning recall and worktree persistence. Updated lessons supersede earlier records by key; stale/retracted/quarantined entries must not return as active guidance. Refinement logs and project-grown procedures, including quarantine/approval metadata and support files, now reconcile into the parent project before worktree removal. Conflicting concurrent edits refuse cleanup; the next isolated job receives preserved procedures.

The protocols now require relevant retrieval at job start, evidence-backed capture after verification, bounded summary updates and explicit approval before default procedure activation. The runtime points workers at both memory and research contracts. Research and tool discovery recur when a new domain, version, failure mode or verification gap appears; suitable existing tools/evidence are reused.

The user-provided [Jakub Krehel skills repository](https://github.com/jakubkrehel/skills) was inspected as an optional UI expertise source. UI review guidance now connects layout, typography/copy, color/accessibility and motion to actual rendered states and interactions, preserving the project's platform and design language. No third-party skill was installed or copied into the pack.

Dedicated memory regressions and worktree tests verify retrieval and persistence mechanics. Semantic self-improvement remains agent-driven: these tests do not establish that every provider applies lessons correctly or independently produces excellent visual design.

Concurrent learning updates are compared against the isolation baseline by stable key. Conflicting revisions block close; independent revisions merge without replaying superseded active guidance. Retraction and later explicit reactivation are distinct lifecycle events.
