---
name: rust-pattern-review
description: Review Rust code for anti-patterns, missed idioms and design-pattern opportunities, citing the Rust Design Patterns book. Use when the user asks to "review my Rust code", "check this crate for anti-patterns", "make this more idiomatic", "audit unsafe/FFI code", or runs /rust-pattern-review on a file, directory, diff or pasted snippet.
argument-hint: "[path | diff | pasted code]"
---

# Rust Pattern Review

Audit Rust code against the idioms, patterns and anti-patterns of the *Rust Design Patterns* book. The book's chapters are bundled with the sibling skill at `../rust-design-patterns/references/` (index: `../rust-design-patterns/SKILL.md`). Cite a chapter for every finding.

## Workflow

1. **Scope.** Determine what to review from the argument: a file, a directory (all `*.rs`), a git diff (`git diff` / a branch range — review only changed hunks plus needed context), or a pasted snippet. If nothing is given, ask once; default to the current crate's `src/`.
2. **Context.** Note whether it's a library (public API stability matters → `#[non_exhaustive]`, borrowed args, `Default`) or a binary/prototype (cloning and simplicity are more acceptable). Check `Cargo.toml` for `[lints]`, edition and crate type.
3. **Tooling (if available).** If `cargo` is runnable, run `cargo clippy --all-targets -- -W clippy::pedantic 2>&1 | head -200` and fold relevant lints into findings. Never treat clippy output as the whole review.
4. **Scan.** Use the signal table below (grep first, then read the surrounding code). Every grep hit is a *candidate*; confirm by reading the code before reporting.
5. **Read the chapter** for each confirmed finding before writing the fix, so the suggestion matches the book's recommended form and trade-offs.
6. **Report** using the output format below. Order by severity. Skip categories with no findings — don't pad.

## Signal table

| Grep / look for | Candidate issue | Chapter |
|---|---|---|
| `#!\[deny\(warnings\)\]` | Anti-pattern: deny(warnings) | `anti_patterns/deny-warnings.md` |
| `impl\s+(std::ops::)?Deref\s+for` on a non-pointer/non-collection type | Anti-pattern: Deref polymorphism | `anti_patterns/deref.md` |
| `\.clone\(\)` next to a later borrow of the original, or cloning a field then reassigning | Anti-pattern: clone to satisfy borrow checker; often fixable with `mem::take` | `anti_patterns/borrow_clone.md`, `idioms/mem-replace.md` |
| `: &String`, `: &Vec<`, `: &Box<` in fn params | Use borrowed types | `idioms/coercion-arguments.md` |
| `push_str` / `String + &` chains mixing literals and values | `format!` | `idioms/concat-format.md` |
| `pub fn new() -> Self` with no `Default` impl (clippy `new_without_default`) | Add `Default` | `idioms/ctor.md`, `idioms/default.md` |
| Same cleanup duplicated before multiple `return`s / after `?` | Destructor guard | `idioms/dtor-finally.md` |
| `Box<dyn Trait>` used only to pick between two concrete locals in one scope | On-stack dynamic dispatch | `idioms/on-stack-dyn-dispatch.md` |
| `if let Some(x) = opt { v.push(x) }` / `match opt { Some(..) => .. None => {} }` in iterator contexts | Treat `Option` as an iterator | `idioms/option-iter.md` |
| Clones with new names before a `move` closure leaking into outer scope | Rebind in a block | `idioms/pass-var-to-closure.md` |
| `pub struct` with all `pub` fields / `pub enum` in a library likely to grow | `#[non_exhaustive]` or private field | `idioms/priv-extend.md` |
| `let mut x` that is never mutated after setup | Temporary mutability | `idioms/temporary-mutability.md` |
| `fn ..(self/arg: T) -> Result<_, E>` where `E` drops `T` and callers would want to retry | Return consumed arg on error | `idioms/return-consumed-arg-on-error.md` |
| Raw `u64`/`String`/`f64` used for ids, units, secrets; mixed-up args of same type | Newtype | `patterns/behavioural/newtype.md` |
| Manual `lock`/`unlock`, `begin`/`end`, `acquire`/`release` pairs | RAII guard | `patterns/behavioural/RAII.md` |
| Constructors with many params, several `Option<_>` args, or `new_with_x_and_y` variants | Builder | `patterns/creational/builder.md` |
| Big `match` on a kind/tag repeated across many functions | Strategy / Command / Visitor (pick by shape) | `patterns/behavioural/*.md` |
| Recursive tree transforms rebuilding nodes by hand | Fold | `patterns/creational/fold.md` |
| `cannot borrow ... as mutable because it is also borrowed` workarounds on a large struct | Compose structs | `patterns/structural/compose-structs.md` |
| `unsafe` blocks spread across many modules / public fns | Contain unsafety in small modules | `patterns/structural/unsafe-mods.md` |
| Identical long `where` clauses / `F: FnMut() -> Result<T, E>, T: ..` repeated | Custom trait for bounds | `patterns/structural/trait-for-bounds.md` |
| `CString::new(..).unwrap().as_ptr()` as a temporary argument | **Dangling pointer** — passing strings | `idioms/ffi/passing-strings.md` |
| `CString::from_raw` / `into_raw` ownership handoffs; `String::from_utf8_lossy(CStr..)` copies | Accepting / passing strings | `idioms/ffi/accepting-strings.md`, `idioms/ffi/passing-strings.md` |
| `extern "C"` fns returning Rust enums/`Result` or ad-hoc ints | FFI errors | `idioms/ffi/errors.md` |
| `#[no_mangle]` fns exposing pointers to internal structs, iterators or borrowed data | Object-based API / wrapper consolidation | `patterns/ffi/export.md`, `patterns/ffi/wrappers.md` |

## Severity

- **High** — memory-safety or soundness risk (dangling FFI pointers, unsafe outside a contained module, ownership confusion across FFI), or something that breaks downstream builds (`deny(warnings)` in a published crate).
- **Medium** — anti-patterns and design issues with real cost: needless clones in hot paths, Deref polymorphism, API choices that are hard to change later (`&String` params, missing `#[non_exhaustive]` in a public lib, primitive obsession on public APIs).
- **Low** — idiom polish: `format!`, temporary mutability, `Option` iteration, closure rebinding.

Downgrade or drop a finding when the chapter's own disadvantages apply (e.g. clone in a prototype; builder for a 2-field struct; `#[non_exhaustive]` on a binary-internal type). Avoid YAGNI suggestions.

## Output format

Start with a one-line verdict (e.g. "Mostly idiomatic; 1 high, 3 medium, 4 low"). Then, per finding:

````markdown
### [High|Medium|Low] <short title> — <file>:<line>
**Chapter:** <book chapter title> (`<references path>`)
**Why:** one or two sentences tied to this code.
**Fix:**
```rust
// before (trimmed)
// after
```
````

Close with "Patterns worth considering" only if a structural pattern (builder, newtype, strategy, visitor, RAII, compose structs, custom trait bounds) would clearly simplify the code — one short paragraph each, no code unless asked.

When the user asks to apply fixes, edit the files directly, keep changes minimal per finding, and run `cargo check` / `cargo test` afterwards if available.

## Notes

- The `deny-warnings` chapter's lint list predates recent Rust (e.g. `const_err`, `private_in_public` no longer exist). Recommend the `[lints]` table in `Cargo.toml` or CI `RUSTFLAGS="-D warnings"` instead of copying that list verbatim.
- Clone is not always wrong: `Rc`/`Arc` clones, `Copy`-like small types, and prototypes are acceptable — say so rather than flagging.
