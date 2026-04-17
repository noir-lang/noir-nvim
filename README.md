# noir-nvim

A NeoVim plugin providing syntax highlighting and LSP support for Noir.

## Installation

Install with your plugin manager of choice, e.g. with
[lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
    "noir-lang/noir-nvim",
    ft = "noir",
    dependencies = { "nvim-treesitter/nvim-treesitter" }, -- optional, see below
}
```

The plugin works standalone (regex-based syntax + LSP) with zero configuration.
Tree-sitter highlighting is opt-in and requires `nvim-treesitter`.

## LSP

Ensure `nargo` is reachable in your `PATH` and that `nargo lsp` runs in a
terminal. The LSP is started automatically when a `*.nr` file is opened;
the project root is resolved by walking upward for a `Nargo.toml`.

## Tree-sitter highlighting (optional)

If [`nvim-treesitter`](https://github.com/nvim-treesitter/nvim-treesitter) is
installed, the plugin registers the Noir parser automatically. Install the
parser once with:

```vim
:TSInstall noir
```

Then reopen any `.nr` buffer. On buffer load the plugin attempts to attach a
Tree-sitter highlighter. If Tree-sitter isn't available or the parser isn't
installed, the buffer transparently falls back to the regex syntax. When
Tree-sitter does attach, regex syntax remains active as a visual fallback while
Tree-sitter provides captures for the nodes it parsed.

Grammar: [`tsujp/tree_sitter_noir`](https://github.com/tsujp/tree_sitter_noir),
pinned to a validated commit. Bumping the pin is a deliberate change in
`lua/noir/treesitter.lua` - not a floating `master` reference.

### Standard capture groups

The shipped `queries/noir/highlights.scm` uses only the standard
`nvim-treesitter` capture set (`@keyword`, `@type`, `@function`, `@string`,
`@attribute`, etc.), so it composes with any stock colorscheme without
additional `:hi link` lines.

### Troubleshooting

If `:Inspect` reports `No items found at cursor`, Tree-sitter is not attached
to the buffer. Check:

```vim
:lua print(vim.b.noir_ts_attached, vim.api.nvim_get_runtime_file("parser/noir.so", true)[1])
```

If the parser path is missing, run:

```vim
:TSInstall noir
```

For plugin development, the headless regression check is:

```sh
NVIM_APPNAME=noir-dev nvim --headless -l test/headless_treesitter.lua
```
