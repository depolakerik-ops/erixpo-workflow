# Security

- Never commit API keys, tokens, or `.env` files.
- Factory adapters run a coding agent with file and shell access. Use them only in a project you accept that risk for.
- Do not install third-party skills or MCP servers without reading them first.
- `install.sh` only copies files from this repository into skill folders.
- Review (`.erixpo/REVIEW.md`) should flag secrets, unsafe shell, and auth holes.
