#!/usr/bin/env bash
# Build ruff with the SARP compact patches applied.
#
# Clones upstream at the pinned tag, applies patches/, and builds. Nothing here is
# vendored — the upstream tree is fetched fresh each time, so this repo only ever
# holds the difference.
#
# Usage: build.sh [output-dir]        (default: ./build)
#        PROFILE=debug build.sh       (default: release)
#        TARGET=<triple> build.sh     (default: host)
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
out="${1:-$here/build}"
version="$(tr -d '[:space:]' < "$here/UPSTREAM_VERSION")"
profile="${PROFILE:-release}"
target_args=()
target_dir=""
if [ -n "${TARGET:-}" ]; then
  target_args=(--target "$TARGET")
  target_dir="$TARGET/"
fi
src="$out/ruff"

echo "==> upstream ruff $version"
rm -rf "$src"; mkdir -p "$out"
git clone --quiet --depth 1 --branch "$version" https://github.com/astral-sh/ruff "$src"

patches=("$here"/patches/*.patch)
echo "==> applying ${#patches[@]} patches"

# `git am --3way` can only merge if it has the blobs the patches were generated
# against. The clone above is shallow, so when the pin has moved ahead of the
# patch base — exactly what the upstream watch does before a human has rebased
# the series — those blobs are missing and git fails with "sha1 information is
# lacking or useless / could not build fake ancestor". That message names no
# conflicting hunk and hides how much would have merged cleanly, which defeats
# the early warning this repo exists to give. The series records its own base
# via `format-patch --base`, so fetch that commit when the clone lacks it.
base="$(grep -h '^base-commit:' "${patches[@]}" | tail -1 | awk '{print $2}')"
if [ -n "$base" ] && ! git -C "$src" cat-file -e "${base}^{commit}" 2>/dev/null; then
  echo "==> fetching patch base ${base} so --3way can merge"
  git -C "$src" fetch --quiet --depth 1 origin "$base" ||
    echo "warning: could not fetch the patch base; a conflict here will report less precisely"
fi

# --3way gives a usable conflict when upstream has moved. Do NOT add --skip or
# fuzz: a patch that no longer applies is precisely the signal this repo exists
# to surface, and silently dropping it would ship a build missing the option.
git -C "$src" -c user.email=build@localhost -c user.name=build \
    am --3way "${patches[@]}"

echo "==> regenerating derived files"
# ruff.schema.json and the options docs are generated, never patched — carrying a
# binary schema delta in the series would make it unreviewable and conflict-prone.
( cd "$src" && cargo dev generate-all )

echo "==> building"
if [ "$profile" = "debug" ]; then
  ( cd "$src" && cargo build --locked --bin ruff "${target_args[@]}" )
else
  ( cd "$src" && cargo build --release --locked --bin ruff "${target_args[@]}" )
fi

bin="$src/target/${target_dir}$profile/ruff"
[ -x "$bin" ] || bin="$bin.exe"
echo "==> $bin"
"$bin" --version
