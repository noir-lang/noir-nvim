# Test fixtures

Reference corpus used to validate Tree-sitter queries, regex-syntax fallback, and
LSP attach behavior. Each subdirectory is a self-contained set of `.nr` files.

| Fixture          | Purpose                                                                 |
| ---------------- | ----------------------------------------------------------------------- |
| `plain/`         | Pure Noir lib: functions, traits, generics, modules, `unsafe`, tests.    |
| `aztec-token/`   | Trimmed token contract: attributes, contract block, state-var generics.  |
| `aztec-storage/` | Storage variety: `Map`, `PublicMutable`, `PrivateMutable`, custom note.  |
| `aztec-authwit/` | Authwit flows: `#[authorize_once]`, manual private/public assertions.    |
| `malformed/`     | Deliberately broken `.nr` files to verify parser/regex fallback.         |

## Sources

The Aztec fixtures are trimmed adaptations of contracts in
`aztec-packages/noir-projects/noir-contracts/contracts/app/` (Apache-2.0 / MIT
under the aztec-packages license). They are kept here purely as syntax reference
material. They are **not** built by this plugin's CI and may not compile
standalone. The `Nargo.toml` files include illustrative `path = ` dependencies
that assume `aztec-packages` lives next to this repo; adjust if you want to
actually run `nargo check` against them.

`plain/` includes enum and match syntax, which currently requires
`nargo check -Zenums` and is not fully parsed by the pinned grammar. Keep it in
the corpus so the plugin's regex fallback is exercised for valid Noir syntax
that Tree-sitter cannot yet handle.

## Adding a fixture

When a new Noir or Aztec construct lands that isn't covered by existing fixtures,
add a minimal example here rather than amending an existing file. Fixtures should
stay readable end-to-end. Favor clarity over compactness.
