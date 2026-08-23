#!/usr/bin/env bash
# Verify the compact formatter output does not trip the very pycodestyle/flake8-commas rules
# the compat shims exist to relax. Without the shims, `ruff format` and `ruff check --fix`
# disagree forever.
set -uo pipefail
RUFF="${1:?usage: check-convergence.sh <ruff-binary>}"
# Resolve to an absolute path: these helpers `cd` into a temp working directory, at which
# point a relative binary path (e.g. `target/debug/ruff`) would silently fail to resolve and
# every check would report zero findings.
RUFF="$(cd "$(dirname "$RUFF")" && pwd)/$(basename "$RUFF")"
if [ ! -x "$RUFF" ]; then
  echo "error: no executable ruff at $RUFF" >&2
  exit 1
fi
CORPUS="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/corpus"
SEL="E1,E2,E3,W2,W3,COM,I001"

work="$(mktemp -d)"; cp "$CORPUS"/*.py "$work/"
cat > "$work/ruff.toml" <<'TOML'
[format]
annotation-spacing = "compact"
top-level-blank-lines = "one"
operator-spacing = "precedence"
dict-spacing = "compact"
slice-spacing = "compact"
nested-blank-lines = "zero"
default-value-spacing = "compact"
import-trailing-comma = "never"
comment-blank-lines = "compact"

# E2xx/E3xx/W3xx are preview-gated. Without this they are silently skipped, which would leave
# the whitespace and blank-line rules the shims exist to relax entirely untested.
[lint]
preview = true
TOML

cd "$work" || exit 1
"$RUFF" format --no-cache --config ruff.toml . >/dev/null 2>&1
n=$("$RUFF" check --no-cache --config ruff.toml --select "$SEL" --output-format concise . 2>/dev/null | grep -cE "^[a-z_]+\.py:")
echo "diagnostics from [$SEL] on compact-formatted output: $n"
if [ "$n" -ne 0 ]; then
  echo "--- offenders ---"
  "$RUFF" check --no-cache --config ruff.toml --select "$SEL" --output-format concise . 2>/dev/null | head -20
fi

# Convergence: apply format -> check --fix -> format twice. The FIRST round may legitimately
# change the file (e.g. sorting a deliberately unsorted import block). A fixed point means the
# SECOND round changes nothing. Comparing round 1 against the pre-round state would wrongly
# flag that one-time legitimate fix as instability.
round() {
  "$RUFF" format --no-cache --config ruff.toml . >/dev/null 2>&1
  "$RUFF" check  --no-cache --config ruff.toml --select "$SEL" --fix . >/dev/null 2>&1
  "$RUFF" format --no-cache --config ruff.toml . >/dev/null 2>&1
}

round                       # settle
snapshot="$(mktemp -d)"; cp ./*.py "$snapshot/"
round                       # must be a no-op

if diff -rq "$snapshot" . --exclude=ruff.toml --exclude=.log >/dev/null 2>&1; then
  echo "convergence: FIXED POINT reached (round 2 is a no-op)"
else
  echo "convergence: NOT STABLE — round 2 still changes files:"
  for f in ./*.py; do
    diff -q "$snapshot/$(basename "$f")" "$f" >/dev/null 2>&1 || {
      echo "  --- $(basename "$f") ---"
      diff "$snapshot/$(basename "$f")" "$f" | head -8
    }
  done
fi
rm -rf "$snapshot" "$work"
