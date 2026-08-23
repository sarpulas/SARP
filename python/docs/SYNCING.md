# Tracking upstream Ruff

This directory holds a set of patches against `astral-sh/ruff`, not a copy of it. Upstream is
fetched fresh at the tag pinned in `UPSTREAM_VERSION` and the patches are applied on top. The
diff of this directory *is* the difference from upstream — there is no vendored tree to search
through, and nothing here is ever rewritten.

## Taking a new upstream release

This happens on its own. `python-upstream.yml` asks `astral-sh/ruff` for its latest release
every morning, and when that is newer than `UPSTREAM_VERSION` it re-pins, verifies, commits the
pin, tags `python-v<version>-SARP.1` and publishes the binaries.

Verification is a hard gate, not a report: nothing is committed, tagged or published unless the
patched tree builds, passes upstream's `ruff_linter` and `ruff_python_formatter` suites,
regenerates its derived files to a fixed point, and still converges on the corpus. When any of
that fails the run stops and opens an issue, leaving the pin on `main` and every existing
release untouched. Prereleases are ignored, and a version older than the current pin is ignored
too, so a yanked release cannot drag the pin backwards.

Two things it needs to work: `main` must accept a push from `github-actions[bot]`, and Actions
must be allowed to create releases. A protected `main` will fail the push step and open an
issue, which is at least a loud failure rather than a silent one.

`workflow_dispatch` takes a `force_version` input for pinning to a specific version by hand —
useful to skip a bad release or to test the path without waiting for the schedule.

### When it opens an issue

The patches no longer apply, which is the notification this repository exists to produce.
Resolve it locally:

```sh
echo 0.16.5 > UPSTREAM_VERSION
scripts/build.sh
```

**When `git am` fails**, upstream has changed something the patches depend on. That failure is the
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

Normally you do not. A new upstream release produces `python-v<upstream>-SARP.1` and its five
platform binaries without anyone doing anything.

Cut one by hand when the patches change against an unchanged upstream — that is what the
revision after `SARP.` counts:

```sh
git tag python-v0.16.4-SARP.2
git push origin python-v0.16.4-SARP.2
```

Creating the release through GitHub's web UI works too. That makes the tag and the release
together, and the workflow attaches the archives to the release it finds rather than failing on
one that already exists.

The Cargo version is upstream's, untouched, so `ruff --version` reports the upstream release the
build came from. Fork identity lives in the git tag.
