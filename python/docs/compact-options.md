# SARP compact formatting options

These nine options are added to Ruff by the patches in `../patches/`. Together they produce
the SARP style described in the [repository README](../../README.md), which is the standard
for new code.

Each option defaults to standard Black/PEP 8 behavior, so an unconfigured build formats
exactly as upstream Ruff does. That default exists so an existing codebase can adopt the
tooling without a reformatting commit touching every file, and can then enable the style a
directory at a time — it is a migration path, not a reason to stay on the old style.

## Configuration

All options live under `[format]` in `ruff.toml` or `pyproject.toml`:

```toml
[format]
dict-spacing = "compact"
slice-spacing = "compact"
nested-blank-lines = "zero"
default-value-spacing = "compact"
import-trailing-comma = "never"
comment-blank-lines = "compact"
```

To enable all compact options at once alongside the previously added options:

```toml
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
```

______________________________________________________________________

## Option Reference

### `dict-spacing`

Controls spacing after the colon in dictionary literals.

| Value                | Description                    |
| -------------------- | ------------------------------ |
| `"spaced"` (default) | Standard PEP 8 / Black spacing |
| `"compact"`          | No space after colon           |

**Default (`"spaced"`):**

```python
config = {"host": "localhost", "port": 8080, "debug": True}
```

**Compact (`"compact"`):**

```python
config = {"host":"localhost", "port":8080, "debug":True}
```

Note: this applies to dict *literals*. A dict comprehension keeps its spacing —
`{k: v for k, v in items}` is unchanged — because there the colon separates two expressions in
a clause rather than joining a key to its value.

______________________________________________________________________

### `slice-spacing`

Controls spacing around colons in slice expressions. Black normally adds spaces around colons when any sub-expression is "complex" (a function call, binary operation, etc.). Compact mode removes those spaces unconditionally.

| Value                | Description                                                     |
| -------------------- | --------------------------------------------------------------- |
| `"spaced"` (default) | Spaces around colons for complex expressions (Black compatible) |
| `"compact"`          | Never add spaces around colons                                  |

**Default (`"spaced"`):**

```python
items = data[1:10:2]
result = matrix[get_start() : get_end()]
chunk = buffer[offset() : limit() : step()]
```

**Compact (`"compact"`):**

```python
items = data[1:10:2]
result = matrix[get_start():get_end()]
chunk = buffer[offset():limit():step()]
```

Note: simple slices like `data[1:10:2]` are already compact in both modes (Black default behavior). The difference only appears with complex expressions.

______________________________________________________________________

### `nested-blank-lines`

Controls blank lines between statements in nested scopes — class bodies, function bodies, and other compound statements.

| Value             | Description                                                          |
| ----------------- | -------------------------------------------------------------------- |
| `"one"` (default) | One blank line between methods/nested definitions (Black compatible) |
| `"zero"`          | No blank lines between methods/nested definitions                    |

**Default (`"one"`):**

```python
class UserService:
    def __init__(self, db):
        self.db = db

    def get_user(self, id):
        return self.db.find(id)

    def delete_user(self, id):
        self.db.remove(id)
```

**Compact (`"zero"`):**

```python
class UserService:
    def __init__(self, db):
        self.db = db
    def get_user(self, id):
        return self.db.find(id)
    def delete_user(self, id):
        self.db.remove(id)
```

______________________________________________________________________

### `default-value-spacing`

Controls spacing around `=` in function parameter default values. Black adds spaces around `=` only when a type annotation is present. Compact mode removes those spaces unconditionally.

| Value                | Description                                                   |
| -------------------- | ------------------------------------------------------------- |
| `"spaced"` (default) | Spaces around `=` for annotated parameters (Black compatible) |
| `"compact"`          | No spaces around `=` regardless of annotation                 |

**Default (`"spaced"`):**

```python
def connect(host: str = "localhost", port: int = 8080, timeout: float = 30.0):
    pass

def simple(x=1, y=2):
    pass
```

**Compact (`"compact"`):**

```python
def connect(host: str="localhost", port: int=8080, timeout: float=30.0):
    pass

def simple(x=1, y=2):
    pass
```

Note: unannotated defaults like `x=1` are already compact in both modes (Black default behavior). The difference only appears when a type annotation is present.

______________________________________________________________________

### `import-trailing-comma`

Controls whether trailing commas are added to multi-line import statements. Removing trailing commas allows the formatter to collapse short imports back onto a single line.

| Value                | Description                                                         |
| -------------------- | ------------------------------------------------------------------- |
| `"always"` (default) | Always add trailing commas to multi-line imports (Black compatible) |
| `"never"`            | Never add trailing commas to multi-line imports                     |

**Default (`"always"`):**

```python
from collections import (
    OrderedDict,
    defaultdict,
    namedtuple,
)

from pathlib import (
    Path,
    PurePath,
)
```

**Compact (`"never"`):**

```python
from collections import OrderedDict, defaultdict, namedtuple

from pathlib import Path, PurePath
```

Note: when `"never"` is set, imports that fit on one line will be collapsed. Long imports that exceed the line width will still be wrapped across multiple lines, but without a trailing comma.

______________________________________________________________________

### `comment-blank-lines`

Controls blank lines around comments in nested (non-top-level) scopes such as class and function bodies.

| Value                  | Description                                                                    |
| ---------------------- | ------------------------------------------------------------------------------ |
| `"standard"` (default) | Preserve blank lines around comments in compound statements (Black compatible) |
| `"compact"`            | Remove blank lines around comments in nested scopes                            |

**Default (`"standard"`):**

```python
class Router:
    # GET endpoints

    def get_index(self):
        pass

    # POST endpoints

    def post_item(self):
        pass
```

**Compact (`"compact"`):**

```python
class Router:
    # GET endpoints
    def get_index(self):
        pass
    # POST endpoints
    def post_item(self):
        pass
```

Note: this option only affects nested scopes. Top-level comment spacing is unchanged. When combined with `nested-blank-lines = "zero"`, the result is a very dense class body with no blank lines at all.

______________________________________________________________________

## Combined Example

With all compact options enabled, a typical class transforms from:

```python
from collections import (
    OrderedDict,
    defaultdict,
    namedtuple,
)


class UserService:
    defaults = {"host": "localhost", "port": 8080}

    # Configuration

    def __init__(self, host: str = "localhost", port: int = 8080):
        self.data = buffer[get_start() : get_end()]

    # Lookup

    def get_user(self, id):
        return self.db.find(id)
```

To:

```python
from collections import OrderedDict, defaultdict, namedtuple


class UserService:
    defaults = {"host":"localhost", "port":8080}
    # Configuration
    def __init__(self, host: str="localhost", port: int=8080):
        self.data = buffer[get_start():get_end()]
    # Lookup
    def get_user(self, id):
        return self.db.find(id)
```

______________________________________________________________________

## Markdown code blocks

Since upstream 0.16.0, `ruff format` formats Python code blocks inside Markdown files by
default. The compact options apply there too:

````markdown
```python
config = {"host":"localhost", "port":8080}
```
````

This is deliberate — a style setting should not change depending on whether the code sits in a
`.py` file or a fenced block. To opt out, exclude Markdown from formatting rather than turning
off individual options.

______________________________________________________________________

## Interaction with the linter

Each compact option relaxes exactly the lint rules whose expectations it contradicts, so that
`ruff format` and `ruff check --fix` agree instead of undoing each other. This happens
automatically — setting the `[format]` option is enough.

| Option                              | Rules relaxed                                       |
| ----------------------------------- | --------------------------------------------------- |
| `annotation-spacing = "compact"`    | E225 (`->`), E231 (annotation colons, including variable and class-attribute annotations) |
| `operator-spacing = "precedence"`   | E225/E226/E227/E228 (`*`, `**`, `/`, `//`, `%`, `@`) |
| `dict-spacing = "compact"`          | E231 (`:` in dict literals)                         |
| `default-value-spacing = "compact"` | E251                                                |
| `import-trailing-comma = "never"`   | COM812, and isort's own emitter (I001)              |
| `top-level-blank-lines = "one"`     | E302, E303, E305, and isort's `lines-after-imports` |
| `nested-blank-lines = "zero"`       | E301, E306                                          |

`import-trailing-comma` and `top-level-blank-lines` need the isort adjustments because I001
rewrites import blocks itself rather than leaving them to the formatter. I001 is enabled by
default as of upstream 0.16.0, so without those adjustments the two would oscillate on every
`format` / `check --fix` cycle.

`slice-spacing` and `comment-blank-lines` have no lint counterpart and need no relaxation.

______________________________________________________________________

## The standard profile

This is the configuration new code is held to. It turns on the full compact style, and pairs
it with the upstream rules that reduce code volume rather than just tightening layout:

```toml
[format]
preview = true
annotation-spacing = "compact"
top-level-blank-lines = "one"
operator-spacing = "precedence"
dict-spacing = "compact"
slice-spacing = "compact"
nested-blank-lines = "zero"
default-value-spacing = "compact"
import-trailing-comma = "never"
comment-blank-lines = "compact"

[lint]
preview = true
future-annotations = true
extend-select = ["PLR1712", "RUF050", "RUF070", "RUF072"]
```

Why each part:

- **`format.preview`** — enables upstream's nested-pragma line-width handling, so a trailing
    `# noqa:` no longer counts against the line budget and forces an otherwise-fitting call to
    wrap.
- **`lint.preview`** — makes `SIM102`'s fix safe, so `ruff check --fix` will collapse nested
    `if` statements instead of only reporting them. `SIM102` is already enabled by default.
- **`lint.future-annotations`** — lets `UP006`/`UP007`/`UP045` insert
    `from __future__ import annotations` themselves, which unlocks `list[int]` over `List[int]`
    and `X | None` over `Optional[X]` on older target versions.
- **`extend-select`** — these four are preview rules that are *not* in upstream's default set,
    so `preview = true` alone will not enable them. They remove empty `if` bodies (`RUF050`),
    useless `finally` clauses (`RUF072`), temp-variable swaps (`PLR1712`), and assignments made
    purely to `yield` (`RUF070`).

Two of these carry **unsafe** fixes and need `--unsafe-fixes` to apply: `RUF070` (dropping the
binding changes what `locals()` sees while a generator is suspended) and the
`UP006`/`UP007`/`UP045` `__future__` insertion (runtime-annotation libraries such as Pydantic).
