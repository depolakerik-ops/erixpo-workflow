#!/usr/bin/env python3
"""Mechanical request_class / ui_change hints. LLM still writes classify.md.

The LOOK collision and UI change-type live here so they cannot drift in prose.
Usage: python3 scripts/classify-signals.py "look at the checkout"
"""
from __future__ import annotations

import re
import sys

ALIASES = (
    "init",
    "auto",
    "feature",
    "fix",
    "review",
    "docs",
    "work",
    "learn",
    "search",
    "ui",
    "uninstall",
)

UI_WORDS = (
    r"theme",
    r"spacing",
    r"font",
    r"typeface",
    r"color",
    r"colour",
    r"palette",
    r"animation",
    r"radius",
    r"mockup",
    r"design language",
    r"make it consistent",
    r"recompose",
    r"redesign",
    r"breakpoint",
    r"layout",
    r"sidebar",
    r"motion",
)

LOOK_AT = re.compile(
    r"\b(look at|look over|take a look(?:\s+at)?|inspect|audit)\b",
    re.I,
)
BARE_LOOK = re.compile(r"^\s*look\s*[.?!]?\s*$", re.I)
DEFECT = re.compile(
    r"\b(broken|crash|error|fail(?:ing|ed)?|typo|regression|doesn't work|does not work|bug)\b",
    re.I,
)
UNINSTALL = re.compile(
    r"\b(uninstall|remove erixpo|get rid of erixpo|don't want erixpo|do not want erixpo)\b",
    re.I,
)
LEARN = re.compile(r"\b(remember|don't forget|what did we learn|refine|skillify)\b", re.I)
SEARCH = re.compile(
    r"\b(what did we do|find the session|search history|prior run|prior session)\b",
    re.I,
)
NEW = re.compile(
    r"\b(i want to build|i wanna build|new (app|product|site|script)|greenfield)\b",
    re.I,
)
CONTINUE = re.compile(r"\b(go|continue|keep going|resume|keep building|auto)\b", re.I)
FEATURE = re.compile(r"\b(add|implement|extra screen|extra endpoint)\b", re.I)
DOCS = re.compile(r"\b(wiki|readme|progress\.html|docs only)\b", re.I)
WORK = re.compile(
    r"\b(automate|assistant|research this|draft|inbox|ops|help me with|summarize)\b",
    re.I,
)
AND_SPLIT = re.compile(r"\s+(?:and then|then|and)\s+", re.I)

UI_RE = re.compile("|".join(UI_WORDS), re.I)

SURFACE_MAP = (
    (re.compile(r"\b(swiftui|iphone|ios|xcode)\b", re.I), "ios"),
    (re.compile(r"\b(kotlin|android|jetpack|compose)\b", re.I), "android"),
    (re.compile(r"\b(macos|appkit|os x)\b", re.I), "macos"),
    (re.compile(r"\b(windows|winui|wpf|winforms)\b", re.I), "windows"),
    (re.compile(r"\b(website|web app|landing|react|next\.?js|html|css|breakpoint)\b", re.I), "web"),
    (re.compile(r"\b(tui|terminal ui)\b", re.I), "tui"),
    (re.compile(r"\b(slide|deck|pdf|print)\b", re.I), "slides"),
    (re.compile(r"\b(cli|python script|shell script)\b", re.I), "none"),
)


def _norm(s: str) -> str:
    return re.sub(r"\s+", " ", s.strip())


def surface_hint(text: str) -> str:
    for rx, val in SURFACE_MAP:
        if rx.search(text):
            return val
    return ""


def ui_change(text: str) -> str:
    t = text.lower()
    if re.search(r"\b(redesign|new brand|new look|new direction|tutorial look)\b", t):
        return "relanguage"
    if re.search(r"\b(sidebar|recompose|rearrange|tabs|nav pattern|grouping)\b", t):
        return "recompose"
    if re.search(r"\b(breakpoint|responsive|small screens?|mobile and desktop|compact|size class)\b", t):
        return "reflow"
    if re.search(r"\b(bounce|animation|motion|duration|easing|parallax)\b", t):
        return "remotion"
    if re.search(r"\b(consistent|consistency|looks off|drift)\b", t):
        return "consistency"
    if re.search(r"\b(extra (screen|page)|new screen|add (a )?(page|screen))\b", t):
        return "new-screen"
    if re.search(
        r"\b(calmer|palette|hex|colour|color|font|typeface|spacing|radius|roundness|corners|blue|accent)\b",
        t,
    ):
        return "retoken"
    if UI_RE.search(t):
        return "retoken"
    return "none"


def request_class(text: str) -> str:
    t = _norm(text)
    low = t.lower()

    m = re.match(r"^(?:/erixpo\s+)?(" + "|".join(ALIASES) + r")\b", low)
    if m:
        return m.group(1)

    if UNINSTALL.search(low):
        return "uninstall"
    if LEARN.search(low) and not SEARCH.search(low):
        return "learn"
    if SEARCH.search(low):
        return "search"

    look = bool(LOOK_AT.search(low))
    ui = bool(UI_RE.search(low))
    defect = bool(DEFECT.search(low))
    uc = ui_change(low)

    if look and defect and uc == "none":
        return "fix"
    if look and ui:
        return "ui"
    if look:
        return "review"
    if BARE_LOOK.match(low):
        return "ask"

    if uc != "none":
        return "ui"
    if defect:
        return "fix"
    if ui:
        return "ui"
    if NEW.search(low):
        return "new"
    if CONTINUE.search(low) and not FEATURE.search(low):
        return "auto"
    if FEATURE.search(low):
        return "feature"
    if DOCS.search(low) and not FEATURE.search(low) and not NEW.search(low):
        return "docs"
    if WORK.search(low):
        return "work"
    surf = surface_hint(t)
    if surf in {"ios", "android", "macos", "windows", "web"} and re.search(
        r"\b(app|application|site|game|client)\b", low
    ):
        return "new"
    return "unknown"


def split_jobs(text: str) -> list[str]:
    t = _norm(text)
    if not AND_SPLIT.search(t):
        return [t] if t else []
    parts = [p.strip() for p in AND_SPLIT.split(t) if p.strip()]
    if len(parts) < 2:
        return [t]
    classes = [request_class(p) for p in parts]
    if len(set(c for c in classes if c not in ("unknown", "ask"))) >= 2:
        return parts
    return [t]


LIKE = re.compile(r"\blike\s+([A-Za-z][\w.+-]{1,40})", re.I)
URL = re.compile(r"https?://[^\s)]+")


def references(text: str) -> list[str]:
    found = []
    for m in URL.findall(text):
        found.append(m.rstrip(".,;"))
    for m in LIKE.findall(text):
        if m.lower() not in {"this", "that", "it", "the"}:
            found.append(f"like {m}")
    return found


def classify(text: str) -> dict:
    jobs_text = split_jobs(text)
    jobs = []
    for part in jobs_text:
        rc = request_class(part)
        uc = ui_change(part) if rc in ("ui", "feature", "new") or UI_RE.search(part) else "none"
        if rc == "ui" and uc == "none":
            uc = "relanguage" if re.search(r"redesign", part, re.I) else "retoken"
        jobs.append({"request_class": rc, "ui_change": uc, "intent": part, "surface": surface_hint(part)})
    first = jobs[0] if jobs else {"request_class": "unknown", "ui_change": "none", "intent": text, "surface": ""}
    return {
        "request_class": first["request_class"],
        "ui_change": first["ui_change"],
        "surface": first["surface"] or surface_hint(text),
        "jobs": jobs,
        "ask": first["request_class"] == "ask",
        "references": references(text),
    }


def format_md(result: dict) -> str:
    lines = [
        f"request_class: {result['request_class']}",
        f"ui_change: {result['ui_change']}",
        f"surface: {result['surface'] or 'none'}",
        "jobs:",
    ]
    for j in result["jobs"]:
        lines.append(f"  - {j['request_class']}: {j['intent']}")
    refs = result.get("references") or []
    if refs:
        lines.append("references:")
        for r in refs:
            lines.append(f"  - {r}")
    if result["ask"]:
        lines.append("ask: one question — bare look, never a command menu")
    return "\n".join(lines) + "\n"


FIXTURES = [
    ("look at the checkout", "review", "none"),
    ("look over login", "review", "none"),
    ("take a look at settings", "review", "none"),
    ("inspect the checkout", "review", "none"),
    ("look at this crash", "fix", "none"),
    ("look at checkout color", "ui", "retoken"),
    ("calmer blue", "ui", "retoken"),
    ("sidebar to tabs", "ui", "recompose"),
    ("redesign the checkout", "ui", "relanguage"),
    ("doesn't work on small screens", "ui", "reflow"),
    ("less bounce", "ui", "remotion"),
    ("make it consistent", "ui", "consistency"),
    ("login is broken", "fix", "none"),
    ("I want to build a SwiftUI app", "new", "none"),
    ("SwiftUI app like Things", "new", "none"),
    ("look", "ask", "none"),
    ("what did we do about checkout", "search", "none"),
    ("remember we never commit .env", "learn", "none"),
    ("I don't want erixpo anymore", "uninstall", "none"),
    ("redesign checkout and login is broken", "ui", "relanguage"),
]


def selftest() -> int:
    bad = 0
    for sentence, exp_rc, exp_uc in FIXTURES:
        got = classify(sentence)
        rc, uc = got["request_class"], got["ui_change"]
        if rc != exp_rc or (exp_uc != "none" and uc != exp_uc) or (exp_uc == "none" and uc not in ("none",)):
            # allow ui_change none vs unused
            if rc != exp_rc or uc != exp_uc:
                print(f"FAIL {sentence!r}: got {rc}/{uc} want {exp_rc}/{exp_uc}", file=sys.stderr)
                bad += 1
        if " and " in sentence.lower() or " then " in sentence.lower():
            if sentence.startswith("redesign checkout and") and len(got["jobs"]) < 2:
                print(f"FAIL multi-intent {sentence!r}: {got['jobs']}", file=sys.stderr)
                bad += 1
    if bad:
        print(f"{bad} fixture(s) failed", file=sys.stderr)
        return 1
    print(f"ok {len(FIXTURES)} classify fixtures")
    return 0


def main(argv: list[str]) -> int:
    if argv[1:] == ["--selftest"]:
        return selftest()
    text = " ".join(argv[1:]).strip()
    if not text or text in ("-h", "--help"):
        print("usage: classify-signals.py [--selftest] <sentence>", file=sys.stderr)
        return 2
    sys.stdout.write(format_md(classify(text)))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
