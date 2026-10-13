---
name: rust-design-patterns
description: Rust idioms, design patterns and anti-patterns (from the Rust Design Patterns book). Use when writing, designing, refactoring or explaining Rust code, or when the user asks "what's the idiomatic way to do X in Rust", "which pattern fits", "is this an anti-pattern", or about builder, newtype, RAII guards, strategy, visitor, command, fold, mem::take, Default, Deref, #[non_exhaustive], unsafe modules, FFI strings/errors/object APIs, or Clone-to-satisfy-the-borrow-checker.
---

# Rust Design Patterns

Apply the guidance of the *Rust Design Patterns* book (rust-unofficial/patterns, MPL-2.0) when writing or advising on Rust. The full chapters live in `references/`, mirroring the book's layout. This file is the index: pick the relevant chapter(s) from the tables below and read them before giving detailed advice or non-trivial code.

## How to use

1. Match the situation to a row in the tables below (problem → chapter).
2. Read the referenced chapter(s) — they carry the canonical example, advantages, disadvantages and discussion. Do not paraphrase a chapter you have not read when the user wants specifics.
3. Apply the idiom in the code you write, and name it briefly ("using `mem::take` so the `String` is moved, not cloned").
4. Respect trade-offs. Every chapter lists disadvantages; mention them when they matter. Avoid YAGNI: do not introduce a pattern the problem does not need (`patterns/index.md`).
5. Prefer idioms over patterns, and patterns over cleverness. When `clippy` has a lint for the same thing, mention it.

## Idioms — default habits when writing Rust (`references/idioms/`)

| Situation | Do this | Chapter |
|---|---|---|
| Function only reads a string / vec / boxed value | Take `&str`, `&[T]`, `&T` — not `&String`, `&Vec<T>`, `&Box<T>` | `idioms/coercion-arguments.md` |
| Building a string from literals + values | Use `format!` over chains of `push_str` / `+` (use `push_str` on a preallocated `String` only when performance demands) | `idioms/concat-format.md` |
| Creating a value | Associated fn `new(...)`; for no-arg constructors also implement `Default` | `idioms/ctor.md`, `idioms/default.md` |
| Struct whose fields all have sensible defaults | `#[derive(Default)]`, then `..Default::default()` | `idioms/default.md` |
| Owning collection that should expose a borrowed view | Implement `Deref<Target = [T]>`-style, like `Vec`→slice, `String`→`str` | `idioms/deref.md` |
| Code that must run on every exit path (incl. `?` and panics) | Put it in a guard object's `Drop` — Rust has no `finally` | `idioms/dtor-finally.md` |
| Changing an enum variant through `&mut` while keeping owned fields | `mem::take` / `mem::replace` instead of `.clone()` | `idioms/mem-replace.md` |
| Choosing between different trait impls at runtime without heap allocation | Declare both locals, conditionally init one, borrow as `&mut dyn Trait` | `idioms/on-stack-dyn-dispatch.md` |
| Extending / chaining with an optional value | `Option` is `IntoIterator`: `vec.extend(opt)`, `iter.chain(opt)`; prefer `if let` for a single use | `idioms/option-iter.md` |
| Closure needs some vars moved, some cloned, some borrowed | Rebind in a block just before the closure, then `move` | `idioms/pass-var-to-closure.md` |
| Public struct/enum that may gain fields/variants | `#[non_exhaustive]` (or a private field) — but only when growth is truly likely | `idioms/priv-extend.md` |
| Doc examples need an expensive-to-build struct | Wrap the example in a hidden helper fn taking the struct as a parameter | `idioms/rustdoc-init.md` |
| Data is prepared mutably, then only read | Rebind as immutable (`let data = data;`) or build in a nested block | `idioms/temporary-mutability.md` |
| Fallible fn takes ownership of an argument | Return the argument back inside the error so the caller can retry | `idioms/return-consumed-arg-on-error.md` |

### FFI idioms (`references/idioms/ffi/`)

| Situation | Rule | Chapter |
|---|---|---|
| Returning errors to C | Flat enums → integer codes; structured enums → code + message string; custom error types → `#[repr(C)]` transparent | `idioms/ffi/errors.md` |
| Receiving `*const c_char` | Keep it borrowed (`CStr::from_ptr`), minimise `unsafe`, avoid copying | `idioms/ffi/accepting-strings.md` |
| Passing strings to C | Keep the `CString` alive for the whole call (never `CString::new(..)?.as_ptr()` as a temporary), use `Vec<u8>` if C writes into it, don't transfer ownership unless required | `idioms/ffi/passing-strings.md` |

## Design patterns (`references/patterns/`)

| Need | Pattern | Chapter |
|---|---|---|
| Represent actions as values (undo/redo, queues, migrations) | Command — trait objects, fn pointers or `Fn` boxes | `patterns/behavioural/command.md` |
| Recurring problem expressible as a tiny language | Interpreter (or `macro_rules!`) | `patterns/behavioural/interpreter.md` |
| Type safety / distinct semantics over a primitive, custom trait impls on foreign types, hiding the inner type | Newtype (`struct Meters(f64);`) | `patterns/behavioural/newtype.md` |
| Access to a resource must be mediated and released automatically | RAII guard tied to a borrow (like `MutexGuard`) | `patterns/behavioural/RAII.md` |
| Swappable algorithm behind a fixed workflow | Strategy — trait + generic/dyn param, or closures | `patterns/behavioural/strategy.md` |
| Many operations over a heterogeneous tree (AST etc.) without modifying it | Visitor (`visit_*` methods + `walk_*` helpers) | `patterns/behavioural/visitor.md` |
| Many optional params / complex construction | Builder (`FooBuilder::new().a(..).b(..).build()`) | `patterns/creational/builder.md` |
| Transform a data structure into a new one, node by node | Fold (folder trait with default per-node methods) | `patterns/creational/fold.md` |
| Borrow checker blocks borrowing two fields of a big struct | Decompose into smaller structs and compose them | `patterns/structural/compose-structs.md` |
| Choosing dependencies / splitting a project | Prefer small, focused crates | `patterns/structural/small-crates.md` |
| `unsafe` code | Isolate in the smallest module that can uphold the invariants; expose a safe API | `patterns/structural/unsafe-mods.md` |
| Same long `where` / `Fn(..) -> Result<..>` bounds repeated everywhere | Define a custom trait + blanket impl, use associated types to drop type params | `patterns/structural/trait-for-bounds.md` |
| Exposing a Rust library to other languages | Object-based API: opaque owned handles, transparent user-owned data, behaviour as functions on handles | `patterns/ffi/export.md` |
| Several related Rust types with lifetimes exposed via FFI | Consolidate into one wrapper type to shrink unsafe surface | `patterns/ffi/wrappers.md` |

## Anti-patterns — flag and avoid (`references/anti_patterns/`)

| Smell | Why it's bad | Instead | Chapter |
|---|---|---|---|
| `.clone()` added just to make a borrow error go away | Hides a design problem, diverging copies, extra allocation | Restructure borrows (scopes, `mem::take`, struct decomposition); `Rc`/`Arc` only when shared ownership is intended. Clone is fine in prototypes or when ownership is truly needed | `anti_patterns/borrow_clone.md` |
| `#![deny(warnings)]` in crate root | New compiler/lint versions break the build for everyone downstream | `RUSTFLAGS="-D warnings"` in CI, or deny specific named lints (today usually via the `[lints]` table in `Cargo.toml`) | `anti_patterns/deny-warnings.md` |
| `impl Deref for Child { Target = Parent }` to "inherit" methods | Surprising, no subtyping, traits on `Parent` are not inherited, breaks expectations of `Deref` | Composition with explicit delegation, traits with default methods, or `AsRef` | `anti_patterns/deref.md` |

## Functional Rust (`references/functional/`)

- `functional/paradigms.md` — imperative vs declarative (loops vs iterator chains like `(1..11).fold(0, |a, b| a + b)`).
- `functional/generics-type-classes.md` — use generic type parameters (type-state) so impls are only available for specific types; each instantiation is a distinct type.
- `functional/optics.md` — Iso, Poly Iso, Prism; explains Serde's `Serializer`/`Deserializer`/`Visitor` design. Read when designing serde-like or visitor-heavy APIs.

## Other references

- `intro.md`, `patterns/index.md` (YAGNI, Rust-specific patterns), `idioms/index.md` (KISS), `anti_patterns/index.md`, `refactoring/index.md` (tests first, small changes).
- `additional_resources/design-principles.md` — SOLID, composition over inheritance, DRY, KISS, Law of Demeter, Design by Contract, encapsulation, CQS, POLA, linguistic modular units, self-documentation, uniform access, single choice, persistence closure.

## Attribution

Chapter content in `references/` is from *Rust Design Patterns* (https://rust-unofficial.github.io/patterns/), © its contributors, licensed MPL-2.0 (see `references/LICENSE`). When quoting at length, cite the book.
