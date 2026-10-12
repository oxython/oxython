# oxython syntax reference

oxython is a Rust-flavoured syntax for Cython.  Today it compiles through
Cython to C or C++ extension modules; the design favours precise,
backend-independent meaning so that it can later be lowered to MLIR as well.

## Files

| oxython | Cython equivalent | Purpose |
| --- | --- | --- |
| `.oxy` | `.pyx` | module |
| `.oxd` | `.pxd` | declarations shared between modules |
| `.oxi` | `.pxi` | textual include |

`.pyx`, `.pxd` and `.pxi` files are plain Cython and are not affected.
`cythonize("**/*.oxy")` builds oxython modules, `use` finds `.oxd` files,
and a `.pyx` module can still cimport from an `.oxd` file.

Cython's declaration words are not used in oxython files:

| Cython | oxython |
| --- | --- |
| `def` | `fn name(...)` |
| `cdef` | `fn`, `let`, `static`, `struct`, `union`, `enum`, `impl`, `cppclass`, `fused`, `extern` |
| `cdef class` | `#[pyclass] struct` with `impl` |
| `ctypedef` | `type Name = ...` |
| `DEF` | `const NAME = ...` |
| `cimport` | `use module::name` |
| `# cython: ...` | `#![cython::...]` |
| `# distutils: ...` | `#![distutils::... = ...]` |
| `@decorator` | `#[decorator]` |
| `"""docstring"""` | `/// doc comment` |

All new words are contextual: they are keywords only where an item or
statement starts and remain valid names elsewhere.  A raw identifier such as
`r#fn` or `r#type` is always a plain name.  `from` is an ordinary name too,
except in `from ... import`, `yield from`, `raise ... from` and `extern from`.

## Comments

```rust
// line comment
/* block comment, /* nested */ as in Rust */
```

`#` does not start a comment; it only starts attributes.  `//` is therefore
not an operator (see division below).

### Doc comments

Doc comments are the docstrings; string literal docstrings are an error:

```rust
//! Documents the module (at the top of the file).

/// Documents the item that follows.
///
/// >>> add(1, 2)
/// 3
fn add(a, b):
    return a + b

/**
 * Block doc comments work too.
 */
fn block():
    pass
```

A doc comment goes before the item and its attributes.  Blank lines and
plain comments may come between.  Doctests in doc comments run like any
other doctests.

## Module attributes

Attributes at the top of a file replace Cython's header comments:

```rust
#![cython::boundscheck(false)]
#![cython::language_level = 3]
#![distutils::language = "c++"]
#![distutils::libraries = ["m"]]
```

## Types

| oxython | C | Notes |
| --- | --- | --- |
| `i8`, `i16`, `i32`, `i64` | `signed char`, `short`, `int`, `long long` | exact widths on every CPython platform |
| `u8`, `u16`, `u32`, `u64` | unsigned counterparts | |
| `isize`, `usize` | `Py_ssize_t`, `size_t` | |
| `f32`, `f64` | `float`, `double` | |
| `c64`, `c128` | `float complex`, `double complex` | |
| `u2` | `bint` | |
| `c_char`, `c_schar`, `c_uchar` | `char`, `signed char`, `unsigned char` | C types for interop, as Rust's `core::ffi` |
| `c_short` ... `c_ulonglong` | `short` ... `unsigned long long` | |
| `c_float`, `c_double`, `c_longdouble` | `float`, `double`, `long double` | |
| `&T` | `const T&` | C++ only |
| `&mut T` | `T&` | C++ only |
| `&&T` | `T&&` | C++ only |
| `r&T` | `const T*` | raw pointer |
| `r&mut T` | `T*` | raw pointer |

`i128`, `u128`, `f128` (IEEE binary128) and `c256` have no portable C
equivalent and are rejected for now.  C strings are `r&c_char`.

Ordinary C declarators still work: `let i32 *p` and `let f64 xs[4]`.

## Literals

```rust
true, false                 // True, False
255u8, 1_000i32, 7usize     // C integer constants of that type, range checked
2.5f32, 1f64                // C floating point constants of that type
```

## Division

As in Rust, `/` and `%` on integers truncate towards zero, so `-7 / 2` is
`-3` and `-7 % 2` is `-1`; integer division by zero raises
`ZeroDivisionError`.  Floats divide normally.  Python objects keep Python's
operators.

## Functions

`fn` is the only function keyword.  Without a return type it is a Python
function; with one it is a C function:

```rust
fn greet(name, greeting="hello"):    // def greet(name, greeting="hello"):
async fn fetch(url):                 // async def fetch(url):
fn i32 add(i32 a, i32 b):            // cdef int add(int a, int b):
fn object wrap(x):                   // cdef object wrap(x):
cpdef fn i32 twice(i32 x):           // cpdef int twice(int x):
pub fn i32 exported():               // cdef public int exported():
```

In `extern from` blocks and C++ classes, where Python functions cannot exist,
`fn name(...)` keeps its C meaning.  In classes, `static fn` declares a
static method; in C++ classes, `const fn` declares a const method.

## Items

| oxython | Cython |
| --- | --- |
| `let f64 x = 1.5` | `cdef double x = 1.5` |
| `let auto p = make_point(1, 2)` | a local typed like its initial value |
| `static i32 counter = 0` | module level `cdef int counter = 0` |
| `const i32 SIZE = 4` | `DEF SIZE = 4` |
| `type IntPtr = i32*` | `ctypedef int *IntPtr` |
| `struct Point:` / `union U:` / `enum Color:` | `cdef struct Point:` / ... |
| `packed struct P:` | `cdef packed struct P:` |
| `cppclass Stack[T]:` | `cdef cppclass Stack[T]:` |
| `fused Number:` | `ctypedef fused Number:` |
| `extern from "math.h":` | `cdef extern from "math.h":` |
| `extern fn i32 puts(r&c_char s)` | `cdef extern int puts(const char *s)` |

`pub`, `extern`, `api` and `readonly` set visibility.  Struct fields keep
the C form `f64 x`.  Inside `extern from` blocks, `struct`, `union` and
`enum` name C typedefs, as `ctypedef struct` does; write
`struct tm "struct tm":` for a tagged C struct.  In `extern` blocks and C++
classes, `const` keeps its C meaning unless it is followed by `fn`.  `type`
aliases also work inside C++ classes.

`fn` must declare a function and `let` must declare a variable.  As in
Cython, C variables are declared at the top level of a module, class or
function body.  `let auto x = value` gives a local the C type of its initial
value, like C++ `auto`; later assignments convert to that type, and it works
even when `infer_types` is off.

## Extension types

Python extension types are structs marked `#[pyclass]`, with their methods in
`impl` blocks:

```rust
#[pyclass]
struct Account:
    """A bank account."""
    pub i32 owner_id          // readable and writable from Python
    readonly f64 balance      // readable from Python
    f64 limit                 // C only

impl Account:
    fn __init__(self, i32 owner_id):
        self.owner_id = owner_id

    fn void add(self, f64 amount) noexcept:
        self.balance += amount

#[pyclass]
struct Savings(Account):
    pub f64 rate
```

A type may have several `impl` blocks.  An `impl` in an `.oxy` file without a
struct implements the type declared in the module's `.oxd`.  A qualified name
or type options also make an extension type:
`pub struct Shape [object ShapeObject, type ShapeType]:` and, in extern
blocks, `struct numpy::ndarray [object PyArrayObject]:`.

## Attributes

```rust
use cython

#[cython::boundscheck(false)]
fn total(f64[:] xs): ...
```

`@` decorators are not used.

## Imports

`use` is `cimport` with Rust's use trees:

| oxython | Cython |
| --- | --- |
| `use cython` | `cimport cython` |
| `use libc::stdio` | `from libc cimport stdio` |
| `use libc::math::sqrt as root` | `from libc.math cimport sqrt as root` |
| `use libc::stdlib::{malloc, free}` | `from libc.stdlib cimport malloc, free` |
| `use libc::{stdlib::{malloc, free}, math::sqrt}` | both of the above |
| `use libc::stdio::{self, printf}` | `from libc cimport stdio` and `from libc.stdio cimport printf` |
| `use libc::limits::*` | `from libc.limits cimport *` |
| `use super::geometry::Point` | `from .geometry cimport Point` |

Each `super` goes up one package level.  Python imports keep using `import`.

## Expressions

| oxython | Python / Cython |
| --- | --- |
| `math::sqrt(2)` | `math.sqrt(2)` |
| `0..n` / `1..=n` | `range(0, n)` / `range(1, n + 1)` |
| `seq[a..b]` / `seq[a..=b]` | `seq[a:b]` / `seq[a:b + 1]` |
| `Point { x = 1, y = 2 }` | a C struct value with those fields |

* `::` is a slice inside a subscript, so `seq[i::step]` is unchanged.
* `..` binds looser than arithmetic and tighter than comparisons, so
  `0..n*2` and `x in 0..n` read naturally.  Loops over ranges of C integers
  compile to C loops.
* Struct expressions build C structs and unions only, field by field;
  nothing is called.  A union literal sets exactly one field.

## Statements

```rust
loop:                       // while True:
    if done:
        break

if let [a, b] = pair:       // match pair: case [a, b]: ...
    print(a + b)
elif let Point(x=0, y=y) = value:
    print(y)
else:
    ...

while let (key, value) = next_item():
    ...
```

`if let` and `while let` take Python's `match` patterns.  `while let` has no
`else` clause.

## Known limitations

* A block comment that starts a line cannot be followed by code on its last
  line.
* A type named `r` followed by `&` reads as a raw pointer; write `r#r`.
* `1..real` lexes as a range, not as the attribute of the float `1.`.
