vim.lsp.start({ cmd = {'nargo', 'lsp'}, root_dir = vim.fs.dirname(vim.fs.find({'Nargo.toml'}, {stop = vim.env.HOME})[1]), })

-- Attempt Tree-sitter highlighting; keep regex syntax as the visual fallback.
local ok, treesitter = pcall(require, 'noir.treesitter')
if ok then
    local attached, err = treesitter.setup_buffer(0)
    if not attached and err then
        vim.notify_once(err, vim.log.levels.WARN, { title = 'noir-nvim' })
    end
end
