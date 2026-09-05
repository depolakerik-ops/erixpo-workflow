# Install erixpo workflow

Requirements: Bash, Git, and Python 3.9+ on macOS or Linux (including a suitable WSL environment). Agent Skills compatibility and verified unattended CLI support are separate; see [adapter support](adapters/README.md).

## Project install

From the project that should receive erixpo:

```bash
git clone https://github.com/depolakerik-ops/erixpo-workflow /tmp/erixpo-workflow
bash /tmp/erixpo-workflow/install.sh --target "$PWD" --host auto
.erixpo/bin/erixpo --help
```

The canonical entry point is `.erixpo/bin/erixpo`. If free, `bin/` points into the engine; if `bin/` already exists, an owned `bin/erixpo` shim is installed when available. Unrelated files and symlinks are preserved. Do not install the pack into its own source checkout.

The installer copies skills into `.agents/skills/` and the detected host's directory. Engine files, templates, ownership records, and provenance live under `.erixpo/`. Reinstalling retains previously selected hosts. Use `--host <name>` to select explicitly; `--host all` is opt-in.

```bash
bash /tmp/erixpo-workflow/install.sh --target "$PWD" --dry-run
bash /tmp/erixpo-workflow/install.sh --target "$PWD" --expand --host claude
```

Dry run describes changes without creating or deleting files. Installation stages file contents, checks ownership before mutation, and rolls back ordinary write failures. Individual replacements are atomic; an abrupt machine shutdown is not a whole-install transaction. Rerun installation after interruption and inspect any ownership conflict.

`install-manifest.json` records version, source commit, content digest, hosts, and file hashes. Modified installed files are preserved and conflicting updates stop before writing. Keep local customization in project knowledge or local skills. Legacy files are adopted only when a legacy manifest claims them and their bytes match the bundled hashes of known 0.6.2 pack revisions (or the current pack). Unknown or modified old files need inspection rather than deletion by name. The regression suite upgrades real archived revisions twice and checks their installed CLI.

## Global install

```bash
bash /tmp/erixpo-workflow/install.sh --global --host auto
~/.erixpo/bin/erixpo --root /path/to/project status
```

Global installation targets the home directory only: home skill folders plus `~/.erixpo/` engine and manifest. It does not install into the current project. `--global --uninstall` removes the same owned global files. Project state remains in the selected project. A host must support global skill discovery to load those skills automatically.

## Updates and provenance

Say `/erixpo update` or reinstall from a reviewed pack release. Check `.erixpo/VERSION` and `.erixpo/install-manifest.json`; the commit/content digest distinguishes builds that share a version. Prefer immutable release tags for reproducible installations. This repository prepares release metadata; it does not publish a release automatically.

## Removal

```bash
bash /tmp/erixpo-workflow/install.sh --target "$PWD" --uninstall
bash /tmp/erixpo-workflow/install.sh --target "$PWD" --uninstall --purge
bash /tmp/erixpo-workflow/install.sh --target "$PWD" --uninstall --purge --purge-worktrees --purge-docs
```

Pack-only removal preserves project knowledge. `--purge` additionally removes recognized workflow memory; unrelated extras and worktree bookkeeping remain unless worktree purge is requested. `--purge-worktrees` uses the lifecycle's cleanliness, ownership, and running-worker checks. It refuses unsafe cleanup rather than discarding files. `--purge-docs` removes only files recorded by init; new entries use `SHA256<TAB>relative-path`, so edited documents are preserved. Legacy plain file entries remain supported. It never recursively deletes an arbitrary documents directory.

Review `--dry-run` output to inspect any removal plan. Refused or preserved files are reported.
