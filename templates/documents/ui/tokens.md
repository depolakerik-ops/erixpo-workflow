# Tokens

Change a value here first, then grep the old value out of code and mockups. Compile into one `theme_file` per platform ([mapping.md](mapping.md)).

## Color
| Token | Value | Use |
|---|---|---|
| bg | | page |
| surface | | cards |
| text | | body |
| text-muted | | secondary |
| border | | hairlines |
| accent | | one primary action |
| danger | | destructive |
| warning | | caution |
| success | | confirmation |

## Type
Family (UI):
Weights allowed:
| Token | Size | Line | Use |
|---|---|---|---|
| cap | | | page title |
| title | | | section |
| body | | | default |
| small | | | meta |

## Space
Base unit: 4 or 8
Allowed steps: 4 / 8 / 12 / 16 / 24 / 32 / 48

## Radius
| Token | Value | Use |
|---|---|---|
| sm | | inputs |
| md | | cards |
| full | 999 | pills |

## Shadow
| Token | Value | Use |
|---|---|---|
| 0 | none | flat |
| 1 | | resting card |
| 2 | | popover |

## Breakpoints / size classes

Named tokens. Fill per project. Native uses size classes, not a 720px HTML page.

| Token | Web | iOS | Android | Desktop |
|---|---|---|---|---|
| compact | | compact | compact | |
| regular | | regular | medium / expanded | |

Web column is a CSS length used in `layout.md` and mockups. iOS / Android columns are size-class names. Do not invent a one-off `@media` in a random file.
