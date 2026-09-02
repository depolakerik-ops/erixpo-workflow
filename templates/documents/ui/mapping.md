# Mapping

Tokens compile into **one** theme file per platform. Product views consume the theme, not raw hex. Hard-coded hex / radius / duration outside `theme_file` is a fail.

HTML mockups are **not** the contract on native surfaces.

## theme_file for THIS repo

Path:

Platform: web | ios | android | macos | windows | tui | other

Compile [tokens.md](tokens.md) into that file. Grep for leftover hex / radius / duration in product views after every `retoken`.

## Token map

| Token | CSS | SwiftUI | Compose | WinUI | notes |
|---|---|---|---|---|---|
| bg | --bg | | | | |
| surface | --surface | | | | |
| text | --text | | | | |
| text-muted | --text-muted | | | | |
| border | --border | | | | |
| accent | --accent | | | | |
| danger | --danger | | | | |
| warning | --warning | | | | |
| success | --success | | | | |
| cap / title / body / small | --font-* | | | | |
| space steps | --space-* | | | | |
| radius-sm / md / full | --radius-* | | | | |
| shadow-0 / 1 / 2 | --shadow-* | | | | |
| compact / regular | --bp-* | compact / regular | compact / medium / expanded | window width | see tokens.md |

Fill only the columns this repo uses. Leave the rest blank.

## Preview

- Web: `mockups/*.html` at compact **and** regular, same CSS variables as tokens.
- Native: simulator / device screenshot or platform preview path (not HTML as source of truth). Path:
- HTML wire on native only if they asked or the host cannot preview — label "wire, not production."
