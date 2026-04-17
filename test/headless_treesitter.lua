local repo = vim.uv.cwd()
vim.opt.runtimepath:prepend(repo)

local treesitter_dir = vim.env.NVIM_TREESITTER_DIR
    or (vim.fn.stdpath("data") .. "/lazy/nvim-treesitter")
if vim.uv.fs_stat(treesitter_dir) then
    vim.opt.runtimepath:prepend(treesitter_dir)
end

vim.cmd("runtime plugin/filetype.lua")
vim.cmd("runtime plugin/noir_treesitter.lua")
vim.cmd("filetype on")

local fixture = repo .. "/test/fixtures/aztec-token/src/main.nr"
vim.cmd.edit(vim.fn.fnameescape(fixture))

local noir = require("noir.treesitter")
local ok, err = noir.setup_buffer(0)
assert(ok, err or "Noir Tree-sitter setup failed")

assert(vim.bo.filetype == "noir", "expected filetype=noir")
assert(vim.bo.syntax == "noir", "expected regex syntax fallback to remain active")
assert(vim.b.noir_ts_attached == true, "expected Tree-sitter to be attached")
assert(vim.b.noir_regex_fallback == true, "expected regex fallback flag")

local parser_files = vim.api.nvim_get_runtime_file("parser/noir.so", true)
assert(#parser_files > 0, "missing parser/noir.so; run :TSInstall noir first")

local function capture_names(row, col)
    local captures = vim.treesitter.get_captures_at_pos(0, row, col)
    local names = {}
    for _, capture in ipairs(captures) do
        names[capture.capture] = true
    end
    return names
end

local function assert_capture(label, row, col, capture)
    local names = capture_names(row, col)
    assert(names[capture], string.format("missing %s capture at %s", capture, label))
end

assert_capture("#[event]", 28, 6, "attribute")
assert_capture("#[storage]", 35, 6, "attribute")
assert_capture("#[no_predicates]", 122, 6, "attribute")
assert_capture("#[contract_library_method]", 123, 6, "attribute")
assert_capture("#[only_self]", 132, 6, "attribute")
assert_capture("import leaf", 15, 24, "namespace")
assert_capture("import type", 20, 21, "type")

local event_stack = vim.fn.synstack(29, 7)
assert(#event_stack > 0, "expected regex syntax group on #[event]")
assert(vim.fn.synIDattr(event_stack[1], "name") == "nrAttribute", "expected nrAttribute syntax group")

print("noir-nvim Tree-sitter headless test passed")
