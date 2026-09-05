# Security

- Never commit API keys, tokens, or `.env` files.
- Factory adapters run a coding agent with file and shell access. Use them only in a project you accept that risk for.
- Do not install third-party skills or MCP servers without reading them first.
- `install.sh` installs owned skills, runtime helpers, and templates; ownership hashes protect unrelated/modified files during update/removal.
- Worktrees protect checkout separation, not process permissions. Provider adapters have different permission policies; review adapters/README.md.
- Review evidence binds results to project contents but does not authenticate the reviewer or make an untrusted check command safe.
- Review (`.erixpo/REVIEW.md`) should flag secrets, unsafe shell, and auth holes.
