# Regression fixture: `import-trailing-comma = "never"` vs isort (I001).
#
# The names below are deliberately UNSORTED and long enough that the block must wrap.
# Both conditions are required to reproduce the conflict:
#   - unsorted, so I001 fires at all
#   - wrapping, so isort takes its `format_multi_line` path, which appends a trailing
#     comma after every alias unconditionally
#
# Without a shim this oscillates forever:
#   ruff format          -> strips the trailing comma
#   ruff check --fix     -> I001 puts it back
#   ruff format          -> strips it again
from some.package import (
    ZebraNamedThing,
    AlphaLongClassName,
    BetaLongClassName,
    GammaLongClassName,
    DeltaLongClassName,
)
