# Domains — this repo can be anything

erixpo is not only a software factory. It is a workflow that specializes to **the folder it is in**.

## PROFILE.md

Init writes `.erixpo/PROFILE.md` from inventory + one question if needed:

```
# Profile
class: software | site | automation | research | writing | ops | assistant | mixed
ceremony: full | standard | light
surfaces:
  - web | ios | android | windows | macos | desktop | cli | script | tui | notes | inbox | wiki | embedded | assistant | other
one_liner: …
check: <command or "n/a — human accepts artifact">
```

`class` decides default research and default check. `ceremony` decides which files to write — see [ceremony.md](ceremony.md). Neither locks the router: a writing folder can still ask for a small script (light harness, not a SaaS).

`surfaces` is a real list, not a slogan. Do not assume this folder is software. Do not assume web.

Greenfield boilerplate: [scaffold.md](scaffold.md). Wiki set: [ceremony.md](ceremony.md).

## Scale (BMAD)

| Size | Process |
|---|---|
| One-line typo / rename | fix or work, no research interview |
| Feature on a known stack | feature |
| New product | new (talk → research → plan → go) |
| Assistant / research / ops | work |
| "what did we learn" | learn |

Do not run the full product interview for "file these PDFs into documents/".

## Check per class

Software: a command that **runs tests** (not typecheck-only) and exits 0.
Site: build plus browser rendering and relevant interaction checks with available authorized tooling; report unavailable verification.
Automation: script on a fixture exits 0.
Research / writing: the file exists and the claims that can be checked are checked. Light writing may set `check: n/a — human accepts artifact`.
Assistant / ops: the specified file or folder change is visible.

Never claim done without that evidence.

## Adaptation contract — any domain

The labels above are broad organizational buckets, not a supported-platform allowlist. For an unfamiliar domain, use the closest class or `mixed` and describe the real field in `one_liner` and classification evidence. Do not squeeze the work into an app merely to match a template. Surface, programming language, framework and deliverable are different facts.

Before choosing setup or tools, establish:

1. **Outcome:** what is being made, for whom, and what observable result counts as success.
2. **Environment:** source/assets, file formats, runtime or physical target, operating systems, framework and pinned versions, hardware, tool availability and constraints.
3. **Research:** official domain/tool documentation, applicable standards, comparable work, failure modes, and the skills/MCP capability assessment in research.md. New projects receive a full pass even outside software. A small known edit reuses evidence.
4. **Plan:** smallest reproducible starting artifact, domain-appropriate slices, interfaces between them, acceptance checks and known limitations. Ask only for consequential missing facts.
5. **Proof:** use the tools that can actually observe this domain's output. Separate source validity, simulated behavior, rendered quality and real-world verification. Record which were performed.

Examples illustrate adaptation; they are not prescribed stacks:

| Work | Discover and research | Evidence of quality |
|---|---|---|
| Robot control / embedded behavior | Hardware, sensors/actuators, firmware/runtime, control constraints, simulator, applicable safety requirements | Unit/integration tests, simulation scenarios and fault handling; physical operation requires the appropriate controlled hardware validation and authorization. Passing a simulator is not proof of real-world safety. |
| 3D animation / graphics | Authoring tool/version, scene and asset formats, renderer, dimensions, frame rate, color pipeline, delivery medium and asset rights | Open the project, validate assets, render representative frames or a clip, inspect composition/timing/artifacts, verify export and reproducibility. Do not create app-navigation specs for a film. |
| Flutter / React Native / other cross-platform software | Actual target OS/device set, framework version, native integrations, distribution, official tooling | Platform builds, behavior tests and device/simulator checks on the requested targets; one web preview does not verify all platforms. |
| Linux desktop / service / CLI | Desktop environment or service manager where relevant, packaging/runtime, permissions and installation constraints | Build and tests plus launch/service/CLI scenarios on the stated environment. |
| Python / scientific or automation script | Input/output contract, numerical assumptions, dependency versions and reproducibility | Representative fixtures, failure cases and independently known outputs; use accuracy/tolerance checks where appropriate. |
| Unfamiliar domain | Identify authoritative sources and inspect available tools before choosing a workflow | Define a domain-specific observable check; state missing expertise/tooling rather than inventing certainty. |

Application UI guidance applies only when the deliverable includes an interface. Other visible work still requires intentional composition, hierarchy, typography or timing where applicable, backed by references and an inspected output. Keep documents proportional to the work.
