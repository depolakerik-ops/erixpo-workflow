# Install Erixpo Workflow in Codex

Anyone with access to the public GitHub repository and a Codex version that supports plugins can install Erixpo Workflow. No local developer paths or personal marketplace are required.

## Install

Run in your terminal:

```bash
codex plugin marketplace add erixpo/erixpo-workflow
codex plugin add erixpo-workflow@erixpo-workflow
```

Start a new Codex session after installation. Select **Erixpo Workflow** in the plugin picker and ask `Use erixpo to initialize this project.` You can also mention the `erixpo` skill using the skill picker. Slash-command discovery varies by host.

If `codex plugin` is unavailable, update Codex to a version with plugin support. Organization policies may control whether third-party plugins can be installed.

The plugin provides all 14 existing portable skills, a lime Erixpo icon, and starter prompts. Installing it does not run the project installer. For the unattended runner and project-local engine files, follow the [installation guide](../INSTALL.md) using `--host codex` from the target project.

## Update

```bash
codex plugin marketplace upgrade erixpo-workflow
codex plugin add erixpo-workflow@erixpo-workflow
```

Start a new session to load the updated skills. Update project-local engine files separately through `/erixpo update`.

## Distribution and maintenance

- `.codex-plugin/plugin.json` describes the Codex plugin and points at the existing `skills/` folder.
- `.agents/plugins/marketplace.json` points to the public Git repository on `main`. It uses a URL source because the plugin lives at the repository root.
- `assets/erixpo-icon.svg` reuses the mark from the README banner. It is bundled with the plugin and needs no external image host.
- Keep the Codex manifest version aligned with `VERSION` when releasing the pack.
- `bash check.sh` validates metadata, bundled paths, and version consistency alongside the repository checks.

These files must be merged and pushed to `main` before the public installation commands deliver this native Codex package. A marketplace points to published content; adding a local development marketplace does not publish uncommitted changes.

This repository marketplace provides GitHub distribution. Inclusion in the universal public plugin directory requires OpenAI's separate submission process.

See OpenAI's [plugin packaging documentation](https://developers.openai.com/plugins/build/plugins) for marketplace and interface fields.
