# Tree-sitter query audit - Step 4 of the upstream plan

Machine-driven alternative to opening every fixture in Neovim and eyeballing
`:Inspect`. The harness re-runs against the pinned grammar whenever the query
file changes, so a regression shows up as a diff in these logs.

## Layout

- `run_audit.py` - driver. Runs `tree-sitter query queries/noir/highlights.scm`
  against each fixture from the tree-sitter-noir grammar directory, then
  collapses the per-match output into the *effective* capture per byte range
  using the same rule Neovim applies (highest pattern index wins).
- `*.captures` - per-fixture report: one line per unique byte range with
  `row:col-row:col  capture  (pattern)  text`. Diffable across query edits.

## Running

```sh
python3 test/ts-query-audit/run_audit.py
```

Requires:
- `tree-sitter` CLI on `$PATH`
- grammar checkout at `~/source/tree_sitter_noir` pinned to the validated
  revision (see `lua/noir/treesitter.lua`). The script uses `cwd=` on that
  path so `tree-sitter query` picks up the local `tree-sitter.json` and the
  generated parser in `src/`.

## Findings in this pass

Issues the audit surfaced in the initial query, and the fixes applied:

1. **PascalCase path scopes were tagged `@module`.** Rules like
   `(path scope: (identifier) @module)` caught both `aztec::macros` (correct)
   and `T::zero()` / `FieldCompressedString::from_string` (wrong: those are
   type prefixes). Fix: predicate the `@module` rule to lowercase-leading
   identifiers, and add a matching `@type` rule for PascalCase scopes.

2. **Bare `self` in receiver / scope positions stayed dependent on the generic
   identifier fallback.** The grammar only emits a dedicated `(self)` node
   inside `self_pattern`; in `self.storage.foo.bar()` it shows up as a plain
   `(identifier)`. Fix: add a late `#eq?` rule so `self` has an explicit
   capture while still staying inside the Step 4 standard capture list.

## Grammar-level limitations (not fixable here)

These are documented for upstream attention rather than patched in queries:

- `match` is not a recognised construct; it falls into `ERROR` nodes.
- `enum` likewise: `pub enum Shape { ... }` parses as identifier + error.
- `unsafe fn` modifier on function declarations: only `unsafe { ... }`
  blocks are recognised.
- Attribute bodies (`#[external("public")]`) are a single `(content)`
  terminal, so the string / identifier inside cannot be individually
  highlighted without a grammar change.

The plugin keeps regex syntax active when the parser reports errors, so these
grammar gaps do not replace the existing highlighting path for affected
buffers. Tree-sitter still starts in that case and can provide captures for
imports, attributes, and other nodes that parsed cleanly.

Carried forward to the companion-plugin / grammar-upstream tracks.
