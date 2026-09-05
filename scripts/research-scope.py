#!/usr/bin/env python3
"""When live-search is needed. skip | narrow | full.

Usage:
  python3 scripts/research-scope.py --class new --ui none
  python3 scripts/research-scope.py --selftest
"""
from __future__ import annotations

import argparse
import sys

# Research responds to uncertainty. memory_hit means verified, version-matched evidence.
BUILD_FULL = {"new", "init"}
BUILD_NARROW = {"feature", "work", "auto"}
NONBUILD = {"fix", "learn", "search", "docs", "uninstall", "review", "update"}
UI_FULL = {"create", "relanguage", "recompose"}
UI_NARROW = {"reflow", "remotion", "new-screen", "retoken", "consistency"}


def scope(
    request_class: str,
    ui_change: str = "none",
    *,
    new_infra: bool = False,
    unknown_api: bool = False,
    user_named_ref: bool = False,
    memory_hit: bool = False,
    large_change: bool = False,
) -> str:
    rc = (request_class or "").strip().lower()
    ui = (ui_change or "none").strip().lower()

    if rc in BUILD_FULL or ui in UI_FULL or large_change:
        return "full"
    # Explicit reference or unknown dependencies/API needs evidence even during a fix.
    if new_infra or unknown_api or user_named_ref:
        return "narrow"
    if memory_hit:
        return "skip"
    if rc in NONBUILD:
        return "skip"
    return "narrow"



FIXTURES = [
    ({"request_class": "new"}, "full"),
    ({"request_class": "feature", "large_change": True}, "full"),
    ({"request_class": "feature", "large_change": True, "memory_hit": True}, "full"),
    ({"request_class": "init"}, "full"),
    ({"request_class": "fix"}, "skip"),
    ({"request_class": "fix", "unknown_api": True}, "narrow"),
    ({"request_class": "review", "user_named_ref": True}, "narrow"),
    ({"request_class": "feature", "memory_hit": True}, "skip"),
    ({"request_class": "feature", "memory_hit": True, "new_infra": True}, "narrow"),
    ({"request_class": "auto"}, "narrow"),
    ({"request_class": "feature"}, "narrow"),
    ({"request_class": "feature", "new_infra": True}, "narrow"),
    ({"request_class": "ui", "ui_change": "retoken"}, "narrow"),
    ({"request_class": "ui", "ui_change": "relanguage"}, "full"),
    ({"request_class": "ui", "ui_change": "recompose"}, "full"),
    ({"request_class": "ui", "ui_change": "reflow"}, "narrow"),
    ({"request_class": "learn"}, "skip"),
    ({"request_class": "review"}, "skip"),
    ({"request_class": "update"}, "skip"),
    ({"request_class": "work"}, "narrow"),
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
            large_change=kwargs.get("large_change", False),
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
    p.add_argument("--large-change", action="store_true")
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
        large_change=args.large_change,
    ))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
