# SARP/python — compact Ruff

Nine formatting options for [Ruff](https://github.com/astral-sh/ruff) that produce a denser
Python style, plus the linter adjustments that stop `ruff format` and `ruff check --fix`
undoing each other.

Every option defaults to standard Black/PEP 8 behaviour, so an unconfigured build formats
identically to upstream. See [`docs/compact-options.md`](docs/compact-options.md) for the full
reference and a recommended profile.

```toml
[format]
dict-spacing = "compact"          # {"a":1}
operator-spacing = "precedence"   # a*b + c/d
nested-blank-lines = "zero"       # no blank lines between methods
```

## Install

Download a binary from [Releases](../../releases). Archives contain a single `ruff`
executable and a `.sha256` checksum, for linux (x86_64, aarch64), macOS (x86_64, aarch64) and
Windows (x86_64).

A release follows each upstream Ruff release automatically, tagged
`python-v<upstream version>-SARP.<revision>`, and is published only once the patches have been
shown to still hold against that upstream. See [`docs/SYNCING.md`](docs/SYNCING.md).

## Build from source

```sh
scripts/build.sh
```

This clones upstream Ruff at the tag in [`UPSTREAM_VERSION`](UPSTREAM_VERSION), applies
[`patches/`](patches/), regenerates derived files and builds. Nothing is vendored.

## Layout

```
UPSTREAM_VERSION    the upstream Ruff release these patches target
patches/            the actual changes, as a git-am-able series
corpus/             Python fixtures exercising each option
scripts/build.sh    clone upstream → apply → build
scripts/check-convergence.sh   asserts format and check --fix agree
scripts/capture-baseline.sh    formats the corpus under every option profile
docs/               option reference and the upstream-sync procedure
```

## Why patches instead of a fork

A fork of Ruff means carrying fourteen thousand upstream commits to express six hundred lines
of difference, and rewriting history on every sync. Here the patches *are* the content: they
review as plain files, and taking a new upstream release is a one-line version bump plus a
`git am`. When that `am` fails, it is telling you precisely which upstream change broke which
assumption — which is the entire early-warning mechanism.

[`docs/SYNCING.md`](docs/SYNCING.md) covers the upgrade procedure and what to watch for in
each upstream release.
