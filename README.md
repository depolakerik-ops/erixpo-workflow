# erixpo workflow

Adaptive autonomous workflow. One command. Any agent. Any kind of work in a repo.

You talk. The agent classifies the **repo** and the **request** (software, site, automation, research, writing, ops, assistant), researches only what that job needs, asks the decisions that change the work, then does it against a real check. Progress and memory live on disk.

Not a credit platform. Skills route and teach. A loop + a test gate keeps going when you leave.

## Install into a project

From the project you want to work on:

```bash
git clone https://github.com/depolakerik-ops/erixpo-workflow /tmp/erixpo-workflow
bash /tmp/erixpo-workflow/install.sh
```

That copies skills into `.agents/skills/`, `.claude/skills/`, `.cursor/skills/`, `.codex/skills/`, `.github/skills/` and the CLI into `bin/` + `.erixpo/`.

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
| `/erixpo` in a raw repo | init |
| `/erixpo I want an e-shop` | new work (talk + research + plan) |
| `/erixpo add share with friend` | feature |
| `/erixpo login is broken` | fix |
| `/erixpo review the checkout` | two-stage review |
| `/erixpo what did we do about checkout` | session search |
| `/erixpo go` / `/erixpo continue` | auto |
| `/erixpo remember we never commit .env.local` | learn |
| `/erixpo draft a weekly status from documents/` | work |

Leave-the-room loop:

```bash
bin/erixpo run --worker claude --max 20
bin/erixpo review --stage 1
# then a new agent session: /erixpo review
bin/erixpo merge --id s-…
```

Unattended runs isolate into a sibling git worktree. No auto-merge to the branch you are sitting on. Done means `check:` in `.erixpo/stack.md` exits 0.

## Status

v0.3 — installer, router, two-stage review, worktree isolation, session search, failure catalog.

## License

MIT
