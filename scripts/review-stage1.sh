#!/usr/bin/env bash
# Mechanical review. Exit 0 only if the gate is real and not obviously lied-to.
set -euo pipefail

ROOT="$(pwd)"
fail=0
notes=()
BASE=""
BASE_SRC=""

note() { notes+=("$1"); }
bad() { notes+=("FAIL: $1"); fail=1; }

read_field() {
  local file="$1" key="$2"
  [[ -f "$file" ]] || return 0
  grep -E "^${key}:" "$file" 2>/dev/null | head -1 | sed "s/^${key}:[[:space:]]*//" | sed 's/[[:space:]]*$//' || true
}

CHECK="$(read_field "$ROOT/.erixpo/stack.md" check)"
if [[ -z "$CHECK" ]]; then
  CHECK="$(read_field "$ROOT/AGENTS.md" check)"
fi

CLASS=""
if [[ -f "$ROOT/.erixpo/PROFILE.md" ]]; then
  CLASS="$(grep -E '^class:' "$ROOT/.erixpo/PROFILE.md" 2>/dev/null | head -1 | sed 's/^class:[[:space:]]*//' | awk '{print $1}' | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]' || true)"
fi

if [[ -z "$CHECK" ]]; then
  bad "no check: line in .erixpo/stack.md or AGENTS.md"
else
  case "$CHECK" in
    true|"exit 0"|":"|echo\ ok|echo\ "ok"|echo\ OK|echo\ "OK")
      bad "dummy check command: $CHECK"
      ;;
    *)
      note "check command: $CHECK"
      if bash -lc "$CHECK"; then
        note "check exited 0 in this review"
      else
        bad "check failed in this review"
      fi
      ;;
  esac
fi

scan_secrets_text() {
  local path="$1"
  [[ -f "$path" ]] || return 0
  if grep -E -I -n 'BEGIN PRIVATE KEY|AKIA[0-9A-Z]{16}|sk-[A-Za-z0-9]{20,}|ghp_[A-Za-z0-9]{20,}' "$path" >/dev/null 2>&1; then
    bad "secret-looking content in $path"
  fi
}

if git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if git -C "$ROOT" status --porcelain | grep -q .; then
    note "working tree has changes (ok if this is the slice)"
  else
    note "working tree clean"
  fi
  secret_names="$(git -C "$ROOT" ls-files | grep -E '(^|/)\.env$|(^|/)id_rsa|(^|/)id_ed25519|\.pem$|\.p12$' | grep -v example || true)"
  if [[ -n "$secret_names" ]]; then
    bad "secret-looking tracked file names"
    note "$secret_names"
  fi
  secret_hits="$(git -C "$ROOT" grep -I -n -E 'BEGIN PRIVATE KEY|AKIA[0-9A-Z]{16}|sk-[A-Za-z0-9]{20,}|ghp_[A-Za-z0-9]{20,}' -- . 2>/dev/null || true)"
  if [[ -n "$secret_hits" ]]; then
    bad "secret-looking content in tracked files"
  fi

  docs_only=0
  skip_pair=0
  case "$CLASS" in
    writing|research|ops|assistant) docs_only=1 ;;
  esac
  [[ "${ERIXPO_DOCS_ONLY:-0}" == "1" ]] && docs_only=1
  [[ "${ERIXPO_SKIP_TEST_PAIRING:-0}" == "1" ]] && skip_pair=1

  if git -C "$ROOT" rev-parse --verify HEAD >/dev/null 2>&1; then
    if [[ -n "${ERIXPO_REVIEW_BASE:-}" ]]; then
      if b="$(git -C "$ROOT" rev-parse --verify "${ERIXPO_REVIEW_BASE}^{commit}" 2>/dev/null)"; then
        BASE="$b"
        BASE_SRC="ERIXPO_REVIEW_BASE"
      else
        note "ERIXPO_REVIEW_BASE is set but is not a commit"
      fi
    fi
    if [[ -z "$BASE" ]]; then
      for ref in origin/HEAD origin/main origin/master main master; do
        if git -C "$ROOT" rev-parse --verify "$ref" >/dev/null 2>&1; then
          if b="$(git -C "$ROOT" merge-base HEAD "$ref" 2>/dev/null)"; then
            headsha="$(git -C "$ROOT" rev-parse HEAD)"
            # Local main/master == HEAD is this branch; range would be empty. Fall through.
            if [[ "$b" == "$headsha" && ( "$ref" == "main" || "$ref" == "master" ) ]]; then
              continue
            fi
            BASE="$b"
            BASE_SRC="merge-base HEAD $ref"
            break
          fi
        fi
      done
    fi
    if [[ -z "$BASE" ]] && git -C "$ROOT" rev-parse --verify HEAD~1 >/dev/null 2>&1; then
      BASE="$(git -C "$ROOT" rev-parse HEAD~1)"
      BASE_SRC="HEAD~1"
    fi
  fi
  if [[ -n "$BASE" ]]; then
    note "review BASE: $BASE ($BASE_SRC)"
  else
    note "review BASE: none — pairing uses dirty/staged only"
  fi

  if [[ "$docs_only" -eq 1 ]]; then
    if [[ -n "$CLASS" ]]; then
      note "docs/non-software class ($CLASS) — skipped test-file pairing"
    else
      note "ERIXPO_DOCS_ONLY=1 — skipped test-file pairing"
    fi
  fi
  if [[ "$skip_pair" -eq 1 ]]; then
    note "ERIXPO_SKIP_TEST_PAIRING=1 — skipped test-file pairing"
  fi

  if [[ "$docs_only" -eq 0 && "$skip_pair" -eq 0 ]]; then
    changed="$(git -C "$ROOT" diff --name-only HEAD 2>/dev/null || true)"
    changed="${changed}"$'\n'"$(git -C "$ROOT" diff --name-only --cached 2>/dev/null || true)"
    if [[ -n "$BASE" ]]; then
      changed="${changed}"$'\n'"$(git -C "$ROOT" diff --name-only "${BASE}..HEAD" 2>/dev/null || true)"
    fi
    product=0
    tests=0
    while IFS= read -r f; do
      [[ -z "$f" ]] && continue
      case "$f" in
        documents/*|*.md|.erixpo/*|AGENTS.md|CLAUDE.md|README.md) continue ;;
        *test*|*spec*|*Test*|*Spec*|*Tests*|*UITests*|tests/*|__tests__/*|*/androidTest/*|*androidTest*|*_test.*|*.test.*|*.spec.*|*_spec.*) tests=1 ;;
        *) product=1 ;;
      esac
    done <<< "$changed"
    if [[ "$product" -eq 1 && "$tests" -eq 0 ]]; then
      bad "product files changed with no test/spec file in the slice range (set ERIXPO_DOCS_ONLY=1 or ERIXPO_SKIP_TEST_PAIRING=1 if this slice is not software)"
    fi
  fi
else
  note "not a git repo; skipped diff/secret filename scan"
  note "review BASE: none — not a git repo"
fi

# Built from pieces so this file does not contain the tautologies it greps for.
_t=true
_T=True
dummy_re="expect[(]${_t}[)]"
dummy_re="${dummy_re}|assert ${_T}|assert ${_t}"
dummy_re="${dummy_re}|assertTrue[(]${_t}[)]|assertTrue[(]${_T}[)]"
dummy_re="${dummy_re}|assert[(]${_t}[)]|assert[(]${_T}[)]"
dummy_re="${dummy_re}|XCTAssertTrue[(]${_t}[)]|XCTAssertTrue[(]${_T}[)]"
dummy_re="${dummy_re}|XCTAssert[(]${_t}[)]|XCTAssert[(]${_T}[)]"
dummy_re="${dummy_re}|Assert[.]True[(]${_t}[)]|Assert[.]True[(]${_T}[)]"
dummy_re="${dummy_re}|Assert[.]IsTrue[(]${_t}[)]|Assert[.]IsTrue[(]${_T}[)]"
dummy_re="${dummy_re}|assert![(]${_t}[)]|assert![(]${_T}[)]"
dummy_re="${dummy_re}|(^|[^[:alnum:]_])True[(]${_t}[)]|(^|[^[:alnum:]_])True[(]${_T}[)]"
dummy_re="${dummy_re}|shouldBe[(]${_t}[)]|shouldBe[(]${_T}[)]"

dummy_assert="$(grep -R -I -n --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=.erixpo \
  -E "$dummy_re" "$ROOT" 2>/dev/null | head -10 || true)"
if [[ -n "$dummy_assert" ]]; then
  bad "dummy tautology assertion found"
  note "$dummy_assert"
fi

slop="$(grep -R -I -n --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=.erixpo \
    -e 'TODO: implement' -e 'lorem ipsum' "$ROOT" 2>/dev/null | head -20 || true)"
if [[ -n "$slop" ]]; then
  bad "TODO: implement or lorem ipsum still in the tree"
fi

scan_secrets_text "$ROOT/.erixpo/sessions.jsonl"
scan_secrets_text "$ROOT/.erixpo/learnings.jsonl"

# Freelance hex outside theme_file (only when mapping names a real file).
if [[ "${ERIXPO_SKIP_HEX:-0}" != "1" && -f "$ROOT/documents/ui/mapping.md" ]]; then
  hex_out="$(python3 - "$ROOT" "$BASE" <<'PY' || true
import os, re, subprocess, sys
root = sys.argv[1]
base = sys.argv[2] if len(sys.argv) > 2 else ""
mapping = os.path.join(root, "documents", "ui", "mapping.md")
text = open(mapping, encoding="utf-8").read()
path = ""
for line in text.splitlines():
    m = re.match(r"(?i)^(?:path|theme_file)\s*:\s*(\S+)", line.strip())
    if m:
        cand = m.group(1).strip().strip("`")
        if cand.lower() not in ("", "none", "n/a", "|"):
            path = cand
            break
if not path:
    sys.exit(0)
theme = path if os.path.isabs(path) else os.path.join(root, path)
if not os.path.isfile(theme):
    print(f"mapping theme_file missing: {path}")
    sys.exit(0)
hex_re = re.compile(r"#[0-9A-Fa-f]{3,8}\b")
allowed = set(x.lower() for x in hex_re.findall(open(theme, encoding="utf-8", errors="replace").read()))
names = []
def add(out):
    for f in (out or "").splitlines():
        f = f.strip()
        if f:
            names.append(f)
try:
    add(subprocess.check_output(["git", "-C", root, "diff", "--name-only", "HEAD"], text=True, stderr=subprocess.DEVNULL))
    add(subprocess.check_output(["git", "-C", root, "diff", "--name-only", "--cached"], text=True, stderr=subprocess.DEVNULL))
    if base:
        add(subprocess.check_output(["git", "-C", root, "diff", "--name-only", f"{base}..HEAD"], text=True, stderr=subprocess.DEVNULL))
except subprocess.CalledProcessError:
    pass
skip_prefix = ("documents/", ".erixpo/")
skip_names = {"AGENTS.md", "CLAUDE.md", "README.md"}
skip_ext = {".md", ".svg", ".png", ".jpg", ".jpeg", ".webp", ".gif", ".pdf"}
theme_rel = os.path.relpath(theme, root)
hits = []
for f in sorted(set(names)):
    if f.startswith(skip_prefix) or f in skip_names:
        continue
    ext = os.path.splitext(f)[1].lower()
    if ext in skip_ext:
        continue
    if f == theme_rel or os.path.abspath(os.path.join(root, f)) == os.path.abspath(theme):
        continue
    fp = os.path.join(root, f)
    if not os.path.isfile(fp):
        continue
    try:
        body = open(fp, encoding="utf-8", errors="replace").read()
    except OSError:
        continue
    for h in hex_re.findall(body):
        if h.lower() not in allowed:
            hits.append(f"{f}: {h}")
if hits:
    print("hex outside theme_file:\n" + "\n".join(hits[:20]))
PY
)"
  if [[ -n "$hex_out" ]]; then
    if [[ "$hex_out" == mapping\ theme_file\ missing:* ]]; then
      note "$hex_out"
    else
      bad "hard-coded hex outside theme_file (set ERIXPO_SKIP_HEX=1 if this slice is not visual)"
      note "$hex_out"
    fi
  else
    note "theme_file hex check: ok or skipped (no path)"
  fi
fi

mkdir -p "$ROOT/.erixpo"
{
  echo "## Stage 1"
  echo "Result: $([[ $fail -eq 0 ]] && echo pass || echo fail)"
  echo "BASE: ${BASE:-none}${BASE_SRC:+ ($BASE_SRC)}"
  echo "Notes:"
  for n in "${notes[@]}"; do
    echo "- $n"
  done
} | tee "$ROOT/.erixpo/REVIEW-stage1.md"

if [[ $fail -ne 0 ]]; then
  echo "STAGE 1 FAILED"
  exit 1
fi
echo "STAGE 1 PASSED"
exit 0
