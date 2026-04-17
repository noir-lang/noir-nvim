-- Tree-sitter integration for Noir.
--
-- Registers the parser with nvim-treesitter (when available) and attaches
-- a highlighter on demand. Parser registration is lazy and idempotent so
-- this module is safe to require from ftplugin.

local M = {}

local GRAMMAR_URL = "https://github.com/tsujp/tree_sitter_noir"
local GRAMMAR_BRANCH = "master"
-- Pinned to the commit validated in the grammar evaluation matrix
-- (14/14 fixtures incl. 524-line token, 485-line AMM, 442-line test contract).
local GRAMMAR_REVISION = "dab407a80d69195ffa87426606198fb60a3d0c45"

local registered = false

local function set_default_highlights()
    vim.api.nvim_set_hl(0, "NoirAttribute", { fg = "#C678DD", ctermfg = "Magenta", default = true })
    vim.api.nvim_set_hl(0, "NoirNamespace", { fg = "#56B6C2", ctermfg = "Cyan", default = true })

    local links = {
        ["@attribute.noir"] = "NoirAttribute",
        ["@namespace.noir"] = "NoirNamespace",
        ["@module.noir"] = "NoirNamespace",
    }

    for group, target in pairs(links) do
        vim.api.nvim_set_hl(0, group, { link = target })
    end
end

local function register_parser()
    local ok, parsers = pcall(require, "nvim-treesitter.parsers")
    if not ok then
        return false, "nvim-treesitter is not installed"
    end

    local parser_config = {
        install_info = {
            url = GRAMMAR_URL,
            files = { "src/parser.c", "src/scanner.c" },
            branch = GRAMMAR_BRANCH,
            revision = GRAMMAR_REVISION,
            generate_requires_npm = false,
            requires_generate_from_grammar = false,
        },
        filetype = "noir",
        maintainers = { "@tsujp" },
    }

    if type(parsers.get_parser_configs) == "function" then
        local configs = parsers.get_parser_configs()
        if configs.noir == nil then
            configs.noir = parser_config
        end
    elseif parsers.noir == nil then
        parsers.noir = parser_config
    end
    set_default_highlights()
    registered = true
    return true
end

local function parser_has_errors(bufnr)
    local ok, parser = pcall(vim.treesitter.get_parser, bufnr, "noir")
    if not ok then
        return true
    end

    local parse_ok, trees = pcall(parser.parse, parser)
    if not parse_ok or not trees or not trees[1] then
        return true
    end

    return trees[1]:root():has_error()
end

-- Try to attach Tree-sitter highlighting to `bufnr`. Returns true when the
-- highlighter starts. Keep regex syntax active as a visual fallback; Tree-sitter
-- adds captures for parsed nodes, while the existing syntax file keeps stable
-- colors for constructs/colorschemes that do not style a TS capture visibly.
function M.setup_buffer(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    local registered_ok, register_err = register_parser()
    if not registered_ok then
        return false, register_err
    end

    if not pcall(vim.treesitter.language.add, "noir") then
        return false, "Noir Tree-sitter parser is not installed; run :TSInstall noir"
    end

    local ok = pcall(vim.treesitter.start, bufnr, "noir")
    if not ok then
        return false, "failed to start Noir Tree-sitter highlighter"
    end

    vim.api.nvim_buf_call(bufnr, function()
        vim.cmd("setlocal syntax=noir")
    end)

    if parser_has_errors(bufnr) then
        vim.b[bufnr].noir_ts_attached = true
        vim.b[bufnr].noir_regex_fallback = true
        return true
    end

    vim.b[bufnr].noir_ts_attached = true
    vim.b[bufnr].noir_regex_fallback = true
    return true
end

function M.register()
    return register_parser()
end

return M
