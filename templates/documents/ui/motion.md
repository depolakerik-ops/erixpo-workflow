# Motion

Nothing moves unless it is on this list. `remotion` changes start here, then grep durations / easings in `theme_file` and product code.

## Scale
| Token | Duration | Use |
|---|---|---|
| instant | 0 | reduced-motion |
| fast | 120ms | hover, opacity |
| md | 200ms | panels |
| slow | 320ms | rare page-level |

## Allowed
Fade, short translate (≤16px), height expand, accent color.

## Forbidden unless approved playful
Bounce-everywhere, infinite pulse, large parallax, autoplay loops, different easing per screen.

## Reduced motion
instant or short fade only. No large parallax. Honor the platform flag (`prefers-reduced-motion`, iOS Reduce Motion, etc.).
