# SARP

A compact code style, and the tooling that enforces it. One directory per language.

| Directory | What it is |
|---|---|
| [`python/`](python/) | Patches against [Ruff](https://github.com/astral-sh/ruff) adding nine formatting options, plus the linter adjustments that keep `ruff format` and `ruff check` in agreement. Ships prebuilt binaries. |
| [`rust/`](rust/) | rustfmt configuration. |

Nothing here vendors its upstream. `python/` pins an upstream release, fetches it at build
time and applies patches on top, so the contents of this repository are only ever the
difference from upstream.

## The style

Conventional formatters spend whitespace uniformly: one space around every binary operator, one
blank line between every definition, a line per element once a collection wraps. That is easy to
specify and easy to implement, but it throws away a channel that could be carrying meaning.
Uniform spacing makes `a * b + c / d` and `a + b * c + d` look alike, when they group quite
differently.

The style here spends whitespace where it distinguishes things and withholds it where it does
not. Four principles, in rough order of how much they change the look of a file:

**Space is inversely proportional to how tightly things bind.** Operators that bind more tightly
than addition close up; everything looser keeps its spaces. So `a*b + c/d` and `a*b > c/d` show
their grouping at a glance, without parentheses and without reading right to left. The same idea
applies below the operator level: in a dictionary the colon joins a key to its value and closes
up, while the comma separates entries and keeps its space — `{"host":"localhost", "port":8080}`.
In a parameter, `x:int=1` is a single unit; in a statement, `value:int = 3` keeps the assignment
spaced, because assignment is what the statement is doing.

**Blank lines mark structure, not statements.** A blank line means a new top-level definition
begins, and nothing else. Methods within a class sit directly against each other, and a comment
sits against the code it describes rather than floating between two gaps. This makes the shape
of a file legible from its indentation and its blank lines alone.

**What is inside a construct does not change the construct's own spacing.** `x[a:b]` and
`x[compute_start():compute_end()]` are spaced identically. A slice looks like a slice however
complicated its bounds, so you can recognise one without parsing it.

**A line is not spent on syntax that carries no information.** A trailing comma whose only
purpose is to force a multi-line layout is removed, so where lines break is decided by content
and width rather than by punctuation left behind.

This style is not minification. It never removes a space that was carrying information, and the
output stays diff-friendly and reviewable — the goal is to read faster, not to occupy fewer
bytes.

It is mandatory on new code. Every option nonetheless defaults to the conventional behaviour,
and that is a migration affordance rather than a statement about the style being optional: it
lets an existing codebase adopt the tooling without a reformatting commit touching every file,
and lets a project turn the options on a directory at a time. An unconfigured build is
indistinguishable from the stock tool, which is what makes the incremental path possible — it
is not an invitation to stay on the old style.

The Python options are documented in [`python/docs/compact-options.md`](python/docs/compact-options.md),
with a before-and-after for each.
