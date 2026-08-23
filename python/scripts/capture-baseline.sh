#!/usr/bin/env bash
# Capture `ruff format` output over the compact corpus under every option profile.
# Usage: capture-baseline.sh <path-to-ruff-binary> <output-dir>
set -euo pipefail

RUFF="${1:?usage: capture-baseline.sh <ruff-binary> <out-dir>}"
# Resolve to an absolute path: these helpers `cd` into a temp working directory, at which
# point a relative binary path (e.g. `target/debug/ruff`) would silently fail to resolve and
# every check would report zero findings.
RUFF="$(cd "$(dirname "$RUFF")" && pwd)/$(basename "$RUFF")"
if [ ! -x "$RUFF" ]; then
  echo "error: no executable ruff at $RUFF" >&2
  exit 1
fi
OUT="${2:?usage: capture-baseline.sh <ruff-binary> <out-dir>}"
CORPUS="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/corpus"

# profile-name : toml body
declare -A PROFILES=(
  [defaults]=""
  [annotation_spacing]='annotation-spacing = "compact"'
  [top_level_blank_lines]='top-level-blank-lines = "one"'
  [operator_spacing]='operator-spacing = "precedence"'
  [dict_spacing]='dict-spacing = "compact"'
  [slice_spacing]='slice-spacing = "compact"'
  [nested_blank_lines]='nested-blank-lines = "zero"'
  [default_value_spacing]='default-value-spacing = "compact"'
  [import_trailing_comma]='import-trailing-comma = "never"'
  [comment_blank_lines]='comment-blank-lines = "compact"'
  [all_compact]='annotation-spacing = "compact"
top-level-blank-lines = "one"
operator-spacing = "precedence"
dict-spacing = "compact"
slice-spacing = "compact"
nested-blank-lines = "zero"
default-value-spacing = "compact"
import-trailing-comma = "never"
comment-blank-lines = "compact"'
)

rm -rf "$OUT"; mkdir -p "$OUT"

for profile in "${!PROFILES[@]}"; do
  work="$(mktemp -d)"
  cp "$CORPUS"/*.py "$work/"
  { echo "[format]"; echo "${PROFILES[$profile]}"; } > "$work/ruff.toml"
  # Do NOT swallow errors: a fixture that fails to parse is left untouched by
  # `ruff format`, which silently yields a meaningless baseline.
  if ! ( cd "$work" && "$RUFF" format --no-cache --config ruff.toml . ) >"$work/.log" 2>&1; then
    echo "ERROR: profile '$profile' failed to format:" >&2
    sed 's/^/    /' "$work/.log" >&2
    exit 1
  fi
  if grep -qE '^(error|warning: Failed)' "$work/.log"; then
    echo "ERROR: profile '$profile' reported problems:" >&2
    grep -E '^(error|warning: Failed)' "$work/.log" | sed 's/^/    /' >&2
    exit 1
  fi
  mkdir -p "$OUT/$profile"
  cp "$work"/*.py "$OUT/$profile/"
  rm -rf "$work"
done

# Stable manifest of every output file's hash, for cheap diffing across builds.
( cd "$OUT" && find . -name '*.py' | sort | xargs sha256sum ) > "$OUT/MANIFEST.sha256"
echo "captured $(find "$OUT" -name '*.py' | wc -l) files across ${#PROFILES[@]} profiles -> $OUT"
