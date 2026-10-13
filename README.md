# rust-design-patterns

Rust idioms, design patterns and anti-patterns for Claude, built from the
[Rust Design Patterns](https://rust-unofficial.github.io/patterns/) book.

## Skills

| Skill | What it does |
|---|---|
| `rust-design-patterns` | Loaded automatically when writing, designing or refactoring Rust. A problem → chapter index over all idioms, patterns, anti-patterns, FFI and functional chapters, with the full chapters bundled in `references/`. |
| `rust-pattern-review` | `/rust-pattern-review [path \| diff \| snippet]` — audits Rust code for anti-patterns (clone-to-satisfy-borrowck, `deny(warnings)`, Deref polymorphism), missed idioms, FFI hazards and pattern opportunities. Reports findings by severity with chapter citations and before/after fixes. Uses `cargo clippy` when available. |

## Downloads

Prebuilt, installable artifacts are committed at the repo root — grab one directly,
no build step required:

| File | Tool | Manual install |
|---|---|---|
| `rust-design-patterns-claude.plugin` | Claude Code | Drop into a Claude Code plugin marketplace / unzip where plugins are loaded from. |
| `rust-design-patterns-cursor.mdc` | Cursor | Unzip into a project's `.cursor/` directory (adds `.cursor/rules/rust-design-patterns.mdc` and `.cursor/rules/rust-pattern-review.mdc`). |

Cursor also has a native plugin path: `.cursor-plugin/plugin.json` points Cursor
at the same `skills/` directory the Claude plugin uses, no build needed.

## Build

Both root files above are generated from `skills/` and committed — re-run the
matching target and commit the result after editing a `SKILL.md` or its
`references/`:

- `make build-claude` — (re)packages `skills/`, `.claude-plugin/`, `README.md`
  and `LICENSE` into `rust-design-patterns-claude.plugin` (via `scripts/build_plugin.py`).
- `make build-cursor` — (re)generates `rust-design-patterns-cursor.mdc` from
  `skills/*/SKILL.md` (via `scripts/build_cursor_mdc.py`).
- `make build` — runs both.
- `make clean` — removes both generated files.

## Coverage

- **Idioms (17):** borrowed argument types, `format!`, constructors, `Default`,
  collections as smart pointers, finalisation in destructors, `mem::take/replace`,
  on-stack dynamic dispatch, `Option` iteration, passing vars to closures,
  `#[non_exhaustive]`, rustdoc init, temporary mutability, return consumed arg on
  error, FFI errors / accepting strings / passing strings.
- **Patterns (14):** Command, Interpreter, Newtype, RAII guards, Strategy, Visitor,
  Builder, Fold, Compose structs, Small crates, Contain unsafety, Custom traits for
  bounds, FFI object-based APIs, FFI wrapper consolidation.
- **Anti-patterns (3):** Clone to satisfy the borrow checker, `#![deny(warnings)]`,
  Deref polymorphism.
- **Functional:** paradigms, generics as type classes, optics.
- **Design principles:** SOLID, CRP, DRY, KISS, LoD, DbC, CQS, POLA and more.

## License

Book content in `skills/rust-design-patterns/references/` is © the
rust-unofficial/patterns contributors, licensed under the Mozilla Public License 2.0
(see `LICENSE`). Source: https://github.com/rust-unofficial/patterns
