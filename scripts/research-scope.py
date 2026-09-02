#!/usr/bin/env python3
"""When live-search is needed. skip | narrow | full.

Usage:
  python3 scripts/research-scope.py --class new --ui none
  python3 scripts/research-scope.py --selftest
"""
from __future__ import annotations

import argparse
import sys

FULL_CLASS = {"new", "init"}
NARROW_CLASS = {"feature", "work"}
SKIP_CLASS = {"fix", "learn", "search", "docs", "uninstall", "review", "auto"}

FULL_UI = {"create", "relanguage", "recompose"}
NARROW_UI = {"reflow", "remotion", "new-screen"}
SKIP_UI = {"retoken", "consistency", "none", ""}


def scope(
    request_class: str,
    ui_change: str = "none",
    *,
    new_infra: bool = False,
    unknown_api: bool = False,
    user_named_ref: bool = False,
    memory_hit: bool = False,
) -> str:
    rc = (request_class or "").strip().lower()
    ui = (ui_change or "none").strip().lower()

    if memory_hit and rc in SKIP_CLASS and ui in SKIP_UI and not new_infra and not unknown_api:
        return "skip"
    if rc in FULL_CLASS:
        return "full"
    if ui in FULL_UI:
        return "full"
    if user_named_ref and rc in {"ui", "new", "feature"}:
        return "narrow" if rc != "new" else "full"
    if new_infra or unknown_api:
        return "narrow"
    if rc == "ui" and ui in NARROW_UI:
        return "narrow"
    if rc in NARROW_CLASS:
        return "narrow" if (new_infra or unknown_api or ui in FULL_UI | NARROW_UI) else "skip"
    if rc in SKIP_CLASS:
        return "skip"
    if rc == "ui" and ui in SKIP_UI:
        return "skip"
    if rc == "unknown":
        return "narrow"
    return "skip"


FIXTURES = [
    ({"request_class": "new"}, "full"),
    ({"request_class": "fix"}, "skip"),
    ({"request_class": "auto"}, "skip"),
    ({"request_class": "feature"}, "skip"),
    ({"request_class": "feature", "new_infra": True}, "narrow"),
    ({"request_class": "feature", "unknown_api": True}, "narrow"),
    ({"request_class": "ui", "ui_change": "retoken"}, "skip"),
    ({"request_class": "ui", "ui_change": "relanguage"}, "full"),
    ({"request_class": "ui", "ui_change": "recompose"}, "full"),
    ({"request_class": "ui", "ui_change": "reflow"}, "narrow"),
    ({"request_class": "learn"}, "skip"),
    ({"request_class": "work"}, "skip"),
    ({"request_class": "work", "unknown_api": True}, "narrow"),
    ({"request_class": "unknown"}, "narrow"),
]


def selftest() -> int:
    bad = 0
    for kwargs, exp in FIXTURES:
        got = scope(
            kwargs.get("request_class", ""),
            kwargs.get("ui_change", "none"),
            new_infra=kwargs.get("new_infra", False),
            unknown_api=kwargs.get("unknown_api", False),
            user_named_ref=kwargs.get("user_named_ref", False),
            memory_hit=kwargs.get("memory_hit", False),
        )
        if got != exp:
            print(f"FAIL {kwargs}: got {got} want {exp}", file=sys.stderr)
            bad += 1
    if bad:
        print(f"{bad} fixture(s) failed", file=sys.stderr)
        return 1
    print(f"ok {len(FIXTURES)} research-scope fixtures")
    return 0


def main(argv: list[str]) -> int:
    p = argparse.ArgumentParser(description="skip | narrow | full live-search")
    p.add_argument("--class", dest="request_class", default="")
    p.add_argument("--ui", dest="ui_change", default="none")
    p.add_argument("--new-infra", action="store_true")
    p.add_argument("--unknown-api", action="store_true")
    p.add_argument("--user-ref", action="store_true")
    p.add_argument("--memory-hit", action="store_true")
    p.add_argument("--selftest", action="store_true")
    args = p.parse_args(argv[1:])
    if args.selftest:
        return selftest()
    if not args.request_class:
        print("usage: research-scope.py --class new|feature|fix|ui|... [--ui relanguage] [--new-infra]", file=sys.stderr)
        return 2
    print(scope(
        args.request_class,
        args.ui_change,
        new_infra=args.new_infra,
        unknown_api=args.unknown_api,
        user_named_ref=args.user_ref,
        memory_hit=args.memory_hit,
    ))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
