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
    "new",
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
    "update",
)

UI_WORDS = (
    r"themes?",
    r"spacing",
    r"fonts?",
    r"typefaces?",
    r"colors?",
    r"colours?",
    r"palettes?",
    r"animations?",
    r"radius",
    r"mockups?",
    r"design language",
    r"make it consistent",
    r"recompose",
    r"redesign",
    r"breakpoints?",
    r"layouts?",
    r"sidebars?",
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
UPDATE = re.compile(
    r"\b(update erixpo|upgrade erixpo|refresh erixpo|reinstall erixpo|erixpo.{0,60}new update|new update.{0,40}erixpo)\b",
    re.I | re.S,
)
LEARN = re.compile(r"\b(remember|don't forget|what did we learn|refine|skillify)\b", re.I)
SEARCH = re.compile(
    r"\b(what did we do|find the session|search history|prior run|prior session)\b",
    re.I,
)
# Creation intent takes precedence over visual attributes of the new product.
# Existing-product edits remain features/fixes/UI work.
PRODUCT = r"(?:app|application|product|site|website|script|tool|cli|dashboard|landing page|game|client|api|service|robot|controller|brain|firmware|animation|graphics|illustration|poster|3d model)"
NEW = re.compile(
    r"\b(?:greenfield|new\s+(?:(?!existing\b)\w+[ -]+){0,6}" + PRODUCT + r")\b"
    r"|\b(?:build|create|develop|make|design|i want|i need)\s+"
    r"(?:(?!existing\b)\w+[ -]+){0,8}" + PRODUCT + r"\b",
    re.I,
)
CONTINUE = re.compile(r"\b(go ahead|continue|keep going|resume|keep building|auto)\b|^\s*go[.!]?\s*$", re.I)
FEATURE = re.compile(r"\b(add|implement|extra screen|extra endpoint)\b", re.I)
DOCS = re.compile(r"\b(wiki|readme|progress\.html|docs only)\b", re.I)
WORK = re.compile(
    r"\b(automate|assistant|research this|draft|inbox|ops|help me with|summarize)\b",
    re.I,
)
AND_SPLIT = re.compile(r"\s+(?:and then|then|and)\s+", re.I)

UI_RE = re.compile(r"\b(?:" + "|".join(UI_WORDS) + r")\b", re.I)

ART = re.compile(r"\b(blender|3d|animations?|graphics|illustration|poster|render|sculpture)\b", re.I)
ROBOT = re.compile(r"\b(robot(?:ics)?|embedded|microcontroller|firmware|arduino|esp32)\b", re.I)
APP_UI = re.compile(r"\b(ui|interface|app|application|website|web|landing|html|css|dashboard|screen|button|navigation|control panel|login|checkout|menu)\b", re.I)


def non_ui_domain(text: str) -> str:
    if APP_UI.search(text):
        return ""
    if ROBOT.search(text):
        return "embedded"
    if ART.search(text):
        return "art"
    return ""


SURFACE_MAP = (
    (re.compile(r"\b(macos|appkit|os x)\b", re.I), "macos"),
    (re.compile(r"\b(iphone|ios)\b", re.I), "ios"),
    (re.compile(r"\b(android)\b", re.I), "android"),
    (re.compile(r"\b(windows|winui|wpf|winforms)\b", re.I), "windows"),
    (re.compile(r"\b(linux)\b", re.I), "linux"),
    (re.compile(r"\b(website|web|landing|react(?! native)|next\.?js|html|css|breakpoint)\b", re.I), "web"),
    (re.compile(r"\b(flutter|react native)\b", re.I), "mixed"),
    (re.compile(r"\b(tui|terminal ui)\b", re.I), "tui"),
    (re.compile(r"\b(slide|deck|pdf|print)\b", re.I), "slides"),
    (re.compile(r"\b(cli|python script|shell script)\b", re.I), "none"),
)


def _norm(s: str) -> str:
    return re.sub(r"\s+", " ", s.strip())


def surface_hint(text: str) -> str:
    domain = non_ui_domain(text)
    if domain:
        return "none" if domain == "embedded" else "other"
    explicit = (
        r"\b(?:macos|os x)\b", r"\b(?:iphone|ios)\b", r"\bandroid\b",
        r"\bwindows\b", r"\blinux\b", r"\b(?:web|website)\b",
    )
    if sum(bool(re.search(pattern, text, re.I)) for pattern in explicit) > 1:
        return "mixed"
    for rx, val in SURFACE_MAP:
        if rx.search(text):
            return val
    if ROBOT.search(text) and APP_UI.search(text):
        return "other"
    return ""


def ui_change(text: str) -> str:
    if non_ui_domain(text):
        return "none"
    t = text.lower()
    if re.search(r"\b(redesign|new brand|new look|new direction|tutorial look)\b", t):
        return "relanguage"
    if re.search(r"\b(sidebar|recompose|rearrange|tabs|nav pattern|grouping)\b", t):
        return "recompose"
    if re.search(r"\b(breakpoint|responsive|small screens?|mobile and desktop|compact|size class)\b", t):
        return "reflow"
    if re.search(r"\b(bounce|animations?|motion|duration|easing|parallax)\b", t):
        return "remotion"
    if re.search(r"\b(consistent|consistency|looks off|drift)\b", t):
        return "consistency"
    if re.search(r"\b(extra (screen|page)|new screen|add (a )?(page|screen))\b", t):
        return "new-screen"
    if re.search(
        r"\b(calmer|palette|hex|colours?|colors?|fonts?|typefaces?|spacing|radius|roundness|corners|blue|accent)\b",
        t,
    ):
        return "retoken"
    if UI_RE.search(t):
        return "retoken"
    return "none"


def request_class(text: str) -> str:
    t = _norm(text)
    low = t.lower()

    # Only an explicit slash alias (or a bare track name) overrides sentence intent.
    m = re.match(r"^/erixpo\s+(" + "|".join(ALIASES) + r")\b", low)
    if not m:
        m = re.fullmatch(r"(" + "|".join(ALIASES) + r")", low)
    if m:
        return m.group(1)

    if UNINSTALL.search(low):
        return "uninstall"
    if UPDATE.search(low):
        return "update"
    if LEARN.search(low) and not SEARCH.search(low):
        return "learn"
    if SEARCH.search(low):
        return "search"

    look = bool(LOOK_AT.search(low))
    ui = bool(UI_RE.search(low)) and not non_ui_domain(low)
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

    if FEATURE.search(low) and re.search(r"\b(error handl(?:er|ing)|crash report(?:er|ing)|bug report(?:er|ing)|feature|support|endpoint|integration|authentication|pagination|search|export|filter|sync|offline|billing|screen|page)\b", low):
        return "feature"
    # "Fix my new app" is still repair; explicit creation can mention errors
    # as a domain (for example, a crash-reporting app).
    if NEW.search(low) and not re.search(r"\b(fix|repair|debug|resolve)\b", low):
        return "new"
    if uc != "none":
        return "ui"
    if defect:
        return "fix"
    if ui:
        return "ui"
    if non_ui_domain(low):
        return "work"
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
    if (surf in {"ios", "android", "macos", "windows", "linux", "mixed", "web"}
        or re.search(r"\b(swiftui|xcode|kotlin|compose)\b", low)) and re.search(
        r"\b(app|application|site|website|game|client)\b", low
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
    # Product attributes joined by "and" are not separate jobs.
    if classes[0] == "new" and all(
        not re.search(r"^(?:please\s+)?(?:add|implement|fix|repair|debug|review|inspect|audit|redesign|create|build|update|write|draft)\b", part, re.I)
        and not DEFECT.search(part)
        for part in parts[1:]
    ):
        return [t]
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
    ("/erixpo new", "new", "none"),
    ("Build a robot controller with motion planning", "new", "none"),
    ("Create a brain for my robot", "new", "none"),
    ("Develop firmware for an ESP32", "new", "none"),
    ("Create a Blender 3D animation with blue graphics", "new", "none"),
    ("I want to make a 3D animation", "new", "none"),
    ("Adjust the motion of the robot", "work", "none"),
    ("Improve the colors of this Blender animation", "work", "none"),
    ("Inspect this Blender animation", "review", "none"),
    ("Create a Flutter app", "new", "none"),
    ("Build a React Native app", "new", "none"),
    ("Build a Linux desktop app", "new", "none"),
    ("Build an app using an unfamiliar framework", "new", "none"),
    ("Build a responsive HTML website for my bakery", "new", "reflow"),
    ("I want a new website with a sidebar", "new", "recompose"),
    ("Create a landing page with animations", "new", "remotion"),
    ("I need a macOS SwiftUI app with a calm blue theme", "new", "retoken"),
    ("Develop an Android app with responsive layout", "new", "reflow"),
    ("Build a Windows desktop application", "new", "none"),
    ("Create a Go CLI for processing CSV files", "new", "none"),
    ("Implement CSV parsing in our Go CLI", "feature", "none"),
    ("Go", "auto", "none"),
    ("go ahead", "auto", "none"),
    ("continue the approved plan", "auto", "none"),
    ("Add promotion codes to checkout", "feature", "none"),
    ("Fix the promotion code calculation bug", "fix", "none"),
    ("Add search to the existing app sidebar", "feature", "recompose"),
    ("Implement offline sync and billing support in the existing app", "feature", "none"),
    ("Add pagination to the API", "feature", "none"),
    ("Add a new screen to the app", "feature", "new-screen"),
    ("Make the existing website responsive", "ui", "reflow"),
    ("Fix a crash in my new app", "fix", "none"),
    ("Fix the failing CSV export", "fix", "none"),
    ("HTML website", "new", "none"),
    ("update the README", "docs", "none"),
    ("add an error handler", "feature", "none"),
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
    ("update erixpo", "update", "none"),
    ("please update erixpo there is new update", "update", "none"),
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
    for sentence, expected in (
        ("I need a macOS SwiftUI app", "macos"),
        ("Build an iOS app", "ios"),
        ("Develop an Android app", "android"),
        ("Build a Windows desktop application", "windows"),
        ("Create a Go CLI", "none"),
        ("SwiftUI app like Things", ""),
        ("Create an app using Xcode", ""),
        ("Build a Kotlin Compose app", ""),
        ("Build an iOS and Android app", "mixed"),
        ("Build a macOS and Linux app", "mixed"),
        ("Build a web and Android app", "mixed"),
        ("Build a robot controller with motion planning", "none"),
        ("Create a Blender 3D animation", "other"),
        ("Create a Flutter app", "mixed"),
        ("Build a React Native app", "mixed"),
        ("Build an Android app with Flutter", "android"),
        ("Build a Linux app with React Native", "linux"),
        ("Build a macOS app with Flutter", "macos"),
        ("Build an app using an unfamiliar framework", ""),
        ("Build a web dashboard for a robot controller", "web"),
        ("Build a control interface for a robot controller", "other"),
        ("Build a responsive HTML website", "web"),
    ):
        if classify(sentence)["surface"] != expected:
            print(f"FAIL surface {sentence!r}: want {expected}", file=sys.stderr)
            bad += 1
    combined = classify("Build a responsive website with a sidebar and blue colors")
    if combined["request_class"] != "new" or len(combined["jobs"]) != 1:
        print(f"FAIL product attributes split into jobs: {combined}", file=sys.stderr)
        bad += 1
    if bad:
        print(f"{bad} fixture(s) failed", file=sys.stderr)
        return 1
    print(f"ok {len(FIXTURES)} classify fixtures")
    return 0


def main(argv: list[str]) -> int:
    if sys.version_info < (3, 8):
        print("classify-signals.py needs python3.8+", file=sys.stderr)
        return 2
    if len(argv) > 1 and argv[1].startswith("--") and argv[1] != "--selftest":
        print("usage: classify-signals.py [--selftest] <sentence>", file=sys.stderr)
        return 2
    if "--selftest" in argv[1:]:
        return selftest()
    text = " ".join(a for a in argv[1:] if a != "--selftest").strip()
    if not text or text in ("-h", "--help"):
        print("usage: classify-signals.py [--selftest] <sentence>", file=sys.stderr)
        return 2
    try:
        sys.stdout.write(format_md(classify(text)))
    except BrokenPipeError:
        pass
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
