# Tracking upstream Ruff

This directory holds a set of patches against `astral-sh/ruff`, not a copy of it. Upstream is
fetched fresh at the tag pinned in `UPSTREAM_VERSION` and the patches are applied on top. The
diff of this directory *is* the difference from upstream — there is no vendored tree to search
through, and nothing here is ever rewritten.

## Taking a new upstream release

```sh
echo 0.16.5 > UPSTREAM_VERSION
scripts/build.sh
```

If `git am` applies cleanly, that is the whole job. Commit the bumped version and tag.

**If it fails**, upstream has changed something the patches depend on. That failure is the
point of this repo — a precise notification arriving the moment it becomes true, rather than a
surprise months later. Resolve it:

```sh
cd build/ruff                      # the scratch clone, already at the new tag
git status                         # git am leaves the conflict staged
# ...fix the conflict...
git add -A && git am --continue
git format-patch -o ../../patches 0.16.5..HEAD    # regenerate the series
```

Then re-run `scripts/build.sh` from a clean state to confirm, and commit the regenerated
patches. The diff of that commit is exactly what upstream broke and how it was fixed — a far
more useful record than a merge commit.

Never pass `--skip` or increase fuzz to get past a failure. A patch that no longer applies
means the option it carries is missing from the build, and skipping it ships that silently.

## The acceptance gate

A clean compile proves nothing about whether the formatter and linter still agree. Before
tagging:

```sh
scripts/check-convergence.sh build/ruff/target/release/ruff
```

This asserts two things: that compact output does not trip the very rules the patches relax,
and that `format` → `check --fix` → `format` reaches a fixed point. Without it the two can
disagree forever, each undoing the other on every run.

To compare behaviour across an upstream bump, capture the corpus before and after:

```sh
scripts/capture-baseline.sh <old-ruff> /tmp/before
scripts/capture-baseline.sh <new-ruff> /tmp/after
diff -r /tmp/before /tmp/after
```

Every difference is either an intended upstream style change — justify it in the commit
message — or a regression. Do not accept diffs without deciding which.

## What to watch for in each upstream release

- **New `[format]` options.** They land in the same structs the patches touch. Behaviourally
  independent, textually conflicting. Keep both sides.
- **Changes to `DEFAULT_SELECTORS`** in `crates/ruff_linter/src/settings/mod.rs`. Take
  upstream's wholesale, then check whether any newly default-enabled rule fights a compact
  option. This is exactly how the I001 conflict arose: upstream 0.16.0 made `unsorted-imports`
  a default, and isort's own emitter kept restoring the trailing comma that
  `import-trailing-comma = "never"` strips.
- **Formatter style-guide changes.** These surface as diffs in the corpus comparison above.
- **Anything touching `comments/format.rs` or `statement/suite.rs`.** The blank-line and
  comment options hook in there, and upstream edits those files often.

## Why patches rather than a fork

The predecessor was a full fork of `astral-sh/ruff`. It worked, but every sync rewrote history
and so needed a force-push; the repository carried some fourteen thousand upstream commits,
which tripped tooling that could not tell them apart from local work; and the ~600 lines that
were actually ours were invisible inside a vendored tree.

Here the patches are the asset. They are plain files, reviewable in a pull request, and nothing
is ever rewritten.

The cost is real and worth stating: there is no full checkout to browse or grep, and conflict
resolution happens in a scratch clone under `build/`. If that becomes painful, `sarpulas/ruff`
still holds the full tree at the last fork point.

## Regenerating derived files

`ruff.schema.json` and the options documentation are **generated, never patched**.
`scripts/build.sh` runs `cargo dev generate-all` after applying. Carrying the schema as a patch
would mean a binary delta in the series — it is marked `-diff` in upstream's `.gitattributes` —
which is unreviewable and conflicts on every upstream change.

## Releasing

```sh
git tag python-v0.16.4-sarp.1
git push origin python-v0.16.4-sarp.1
```

The Cargo version is upstream's, untouched, so `ruff --version` reports the upstream release the
build came from. Fork identity lives in the git tag.
