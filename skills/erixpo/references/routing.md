# Routing rules

Use this after classify, when `/erixpo` input is messy. Do **not** first-match a synonym.

Protocol and schema: [classify.md](classify.md). Write `.erixpo/classify.md` before loading a track except for the explicit one-shot and maintenance exceptions in classify.md.

## Order

1. Run classify ([classify.md](classify.md)). One-shot light work can run directly without persistent files. For project/recurring work, **init** first when no populated `.erixpo/PROFILE.md` describes the project, retaining the original request. Installed engine files do not count as initialization. Pack-maintenance requests load their track directly.
2. If `jobs:` has multiple entries, announce the queue in one line, start the first. Example: `Queue: ui (checkout redesign) → fix (login) → auto. Starting ui.` Do not drop the rest.
3. Route by **`request_class`** from classify, not by the first synonym in the sentence.
4. Explicit alias in the message (`init`, `auto`, `feature`, `fix`, `review`, `docs`, `work`, `learn`, `search`, `ui`, `uninstall`, `update`) still forces that `request_class` **after** classify of repo / surface / ceremony.
5. **Look** is decided while filling `request_class` ([classify.md](classify.md)), not by the word "look" winning first:
   - "look at" / "look over" / "take a look" / "inspect" / "audit" → **review** (unless they also named theme / color / layout / mockup)
   - "look" + theme / spacing / font / color / animation / radius / mockup / design language / "make it consistent" → **ui**
   - Bare "look" with no object → one clarifying question, never a command menu
   - Both review-look and ui-look → **ui**
6. Defect language → **fix**. Additive on a *known software* stack → **feature**. Continue language → **auto** only if the plan is `approved`. Remove erixpo → **uninstall**. Update/upgrade/reinstall **erixpo** → **update** (not work). Non-product → **work**. New product / new platform / "I want to build" → **new**.
7. After the first job's check, continue the remaining `jobs:` in `.erixpo/classify.md` or tell the user what is next.

## request_class → skill

| request_class | skill |
|---|---|
| init | `erixpo-init` |
| new | `erixpo-new` |
| feature | `erixpo-feature` |
| fix | `erixpo-fix` |
| review | `erixpo-review` |
| ui | `erixpo-ui` |
| work | `erixpo-work` |
| learn | `erixpo-learn` |
| search | `erixpo-search` |
| auto | `erixpo-auto` |
| docs | `erixpo-docs` |
| uninstall | `erixpo-uninstall` |
| update | `erixpo-update` |

On a known repo, search sessions before planning. If classify is still torn between two classes and the user asked for only one job, pick the narrower one (fix beats feature beats work beats new).

## Do not

- Do not show a command menu.
- Do not run research for a one-line typo fix.
- Do not run the full new-product interview for "add a logout button" when `documents/` already names the stack.
- Do not start auto if the plan is still `draft`.
- Do not start auto on a dirty human checkout without isolate or an explicit "do it here".
- Do not uninstall by deleting the whole project. Load `erixpo-uninstall` and ask.
- Do not install skills into every vendor folder. Detect the current agent. Expand later if they switch CLI.
- Do not drop remaining jobs in `.erixpo/classify.md`.
- Do not treat "update erixpo" as product `work`. Do not rewrite the product classify.md.
