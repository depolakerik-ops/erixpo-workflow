# erixpo workflow

Adaptive autonomous workflow. One command. Any agent. Any kind of work in a repo.

You talk. The agent **classifies** the repo, the request, the surface, and the UI change-type, then runs the matching track. Software, site, SwiftUI, Android, Windows, macOS, responsive web, Python script, automation, research, writing, ops, assistant — the folder decides. It scaffolds *this* repo's boilerplate, writes tests, and stops on a real check. Progress and memory live on disk.

Not a credit platform. Skills route and teach. A loop + a test gate keeps going when you leave. Finished worktrees **close**; they do not litter the machine.

## Install into a project

From the project you want to work on:

```bash
git clone https://github.com/depolakerik-ops/erixpo-workflow /tmp/erixpo-workflow
bash /tmp/erixpo-workflow/install.sh
```

Host-aware: `.agents/skills/` plus the vendor folder for the agent that is actually running. CLI into `bin/` + `.erixpo/`.

Then in the agent:

```
/erixpo
```

### Global install (every project on this machine)

```bash
bash /tmp/erixpo-workflow/install.sh --global
```

### Claude Code plugin

```
/plugin marketplace add depolakerik-ops/erixpo-workflow
/plugin install erixpo-workflow@erixpo
```

## Commands

Almost always just `/erixpo` plus a sentence.

| You say | Router does |
|---|---|
| `/erixpo` in a raw repo | init (profile, USER, constitution, ceremony) |
| `/erixpo I want a SwiftUI app` | new (research *that* surface, slice 0 = native scaffold) |
| `/erixpo add share with friend` | feature |
| `/erixpo login is broken` | fix (+ regression test) |
| `/erixpo look at the checkout` | two-stage **review** (not UI) |
| `/erixpo calmer blue` / `sidebar to tabs` | ui (retoken vs recompose — different paths) |
| `/erixpo what did we do about checkout` | session search |
| `/erixpo go` / `/erixpo continue` | auto |
| `/erixpo remember we never commit .env.local` | learn |
| `/erixpo draft a weekly status from documents/` | work |
| `/erixpo I don't want erixpo anymore` | uninstall interview |
| `/erixpo update` / `there is a new erixpo update` | **update** the pack only (not the product) |

Leave-the-room loop:

```bash
bin/erixpo run --worker claude --max 20
bin/erixpo review --stage 1
# then a new agent session: /erixpo review
bin/erixpo close --id s-…    # merge + remove worktree + delete branch
bin/erixpo sweep             # report leftover trees (sweep --apply to clean)
bin/erixpo classify "look at checkout"   # mechanical request_class (review, not ui)
bin/erixpo capabilities                  # xcodebuild / android-sdk / … actually on PATH
bin/erixpo research-scope --class new    # skip | narrow | full live-search
```

Unattended runs isolate into a sibling git worktree. No auto-merge to the branch you are sitting on. After stage-2 `ship` and you say close/merge, `close` removes the tree so it does not stay on disk. Done means `check:` in `.erixpo/stack.md` exits 0 **and** the slice tests ran.

## Status

See `VERSION` (now **0.6.2**). Pack version is that file, not a guess. Compare `.erixpo/VERSION` in a project to GitHub `VERSION` on `main` to know if an update is needed.

## License

MIT
