# sarp

Code style tooling, one directory per language.

| Directory | What it is |
|---|---|
| [`python/`](python/) | Patches against [Ruff](https://github.com/astral-sh/ruff) adding nine formatting options for a denser Python style, plus the linter adjustments that keep `ruff format` and `ruff check` in agreement. Ships prebuilt binaries. |
| [`rust/`](rust/) | rustfmt configuration. |

Nothing here vendors its upstream. `python/` pins an upstream release, fetches it at build
time and applies patches on top, so the contents of this repository are only ever the
difference from upstream.
