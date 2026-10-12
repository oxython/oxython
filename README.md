# oxython

oxython is a Rust-flavoured syntax for [Cython](https://github.com/cython/cython),
maintained as a series of patches on top of upstream Cython rather than as a fork.

```oxython
# distances.oxy
use libc::math::sqrt

struct Point:
    f64 x
    f64 y

fn f64 norm(&Point p) noexcept:
    return sqrt(p.x * p.x + p.y * p.y)

fn distances(i32 n):
    let auto total = 0.0
    for i in 0..n:
        total += norm(Point { x = i, y = 1 })
    return total
```

oxython code lives in `.oxy` modules, `.oxd` declaration files and `.oxi`
includes.  It uses Rust's comments and doc comments, `fn` instead of `def`, `use` instead of
`cimport`, and `#[pyclass] struct` with `impl` for extension types.  Plain `.pyx` and `.pxd` files, including
Cython's own headers, are untouched, and `.pyx` modules can cimport from
`.oxd` files.  See [docs/syntax.md](docs/syntax.md) for the full
language reference.

## Layout

| Path | Contents |
| --- | --- |
| `upstream/` | git submodule pinned to a cython/cython commit |
| `patches/` | the patch series, applied in the order of `patches/series` |
| `tests/` | oxython's own tests, copied into the upstream test tree to run |
| `docs/` | the syntax reference |
| `editors/vscode/` | syntax highlighting for VS Code |
| `scripts/` | apply, test, refresh and packaging helpers |
| `VERSION` | the version of the `oxython` package |

## Using it

```sh
pip install oxython
```

The `oxython` package is the patched Cython.  It installs the `Cython`
module, so it replaces any Cython already in the environment.  Build
`.oxy` modules as usual:

```python
from setuptools import setup
from Cython.Build import cythonize

setup(ext_modules=cythonize("**/*.oxy"))
```

To build from source instead:

```sh
git clone --recursive https://github.com/oxython/oxython
cd oxython
scripts/apply.sh            # applies patches/ on top of upstream/
pip install ./upstream
```

## Working on it

The patches are developed as commits on the `oxython` branch inside
`upstream/`, one commit per patch.

```sh
scripts/apply.sh                    # rebuild the branch from patches/
# edit upstream/Cython/..., then commit or amend inside upstream/
scripts/test.sh                     # run the oxython tests (C and C++)
scripts/refresh.sh                  # write the commits back to patches/
```

Releases: bump `VERSION`, commit, then push a matching tag such as `v0.2.0`.
The PyPI workflow builds the sdist and wheel with `scripts/build-dist.sh` on
every push and publishes them when a `v*` tag is pushed.  It uses the
`PYPI_API_TOKEN` repository secret, or PyPI trusted publishing if that secret
is not set.

To move to a newer Cython, bump the submodule, run `scripts/apply.sh`, fix
any patch that no longer applies with `git am --3way`, then run
`scripts/refresh.sh`.  CI checks the series against upstream `master` every
night, so breakage shows up early.

CI also runs upstream's own test suite with `CYTHON_FORCE_OXYTHON=1`, which
parses every Cython file in oxython mode.  That checks that the new syntax
stays a strict superset of existing Cython.

## Patches

The series follows the order of the original pull requests:

1. `.oxy`, `.oxd` and `.oxi` files
2. Rust comments: `//`, nested `/* */`
3. Doc comments `///`, `//!`, `/** */` as docstrings
4. Raw identifiers and contextual keywords
5. Builtin types `i8` ... `u64`, `isize`, `usize`, `f32`, `f64`, `c64`, `c128`, `u2` and C types `c_char` ...
6. `true`, `false` and typed literals `10u8`, `2.5f32`
7. Integer division that truncates, as in Rust
8. `#[...]` attributes
9. `fn` items
10. `let`
11. `static`
12. `let auto`
13. `const`
14. `type` aliases
15. `struct`, `union` and `enum`
16. `pub`, `extern`, `api`, `readonly` and extern blocks
17. `use` trees
18. `::` paths
19. `#![...]` module attributes
20. Reference and pointer types `&T`, `&mut T`, `&&T`, `r&T`, `r&mut T`
21. `loop`
22. Ranges `a..b`, `a..=b`, `seq[a..b]`
23. Struct expressions `Point { x = 1, y = 2 }`
24. `fn` replaces `def`
25. `if let` and `while let`
26. `from` as an ordinary name
27. Extension types: `#[pyclass] struct` and `impl`
28. `cppclass` and `fused` items
29. No `cdef`, `cimport`, `ctypedef`, `DEF` or `@` decorators

## Roadmap

These designs from the original fork are not ported yet: `mod`, `let mut`
bindings, scoped enums, `#[repr(packed)]`, function pointer type syntax, and
the dereference and spread operators.

## License

Apache License 2.0, the same as Cython.  See [LICENSE](LICENSE).
