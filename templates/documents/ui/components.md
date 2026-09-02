# Components

If a part is not listed, it is not approved. Add the row before you implement it.

Layout-sensitive parts (nav, split view, tab bar, inspector) obey [layout.md](layout.md). Do not invent a second nav pattern on one screen.

| Name | Tokens | States | Where used | Notes |
|---|---|---|---|---|
| Button primary | accent, radius-sm | default hover focus disabled loading | | one per view |
| Button secondary | border, text | | | |
| Field | border, radius-sm | empty error disabled | | label + hint + error |
| Card | surface, radius-md, shadow-1 | | | |
| Empty | | | | |
| Banner error | danger | | | |
| Nav | | | | pattern in layout.md |
| Split / inspector | | | | hidden on compact; see layout.md |

## Exceptions
None unless written here.
