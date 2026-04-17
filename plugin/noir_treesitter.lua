-- Register the optional nvim-treesitter parser early so `:TSInstall noir`
-- works before a Noir buffer has been opened.
vim.api.nvim_create_autocmd("User", {
    pattern = "TSUpdate",
    callback = function()
        pcall(function()
            require("noir.treesitter").register()
        end)
        for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].filetype == "noir" then
                pcall(function()
                    require("noir.treesitter").setup_buffer(bufnr)
                end)
            end
        end
    end,
})

vim.api.nvim_create_autocmd("ColorScheme", {
    callback = function()
        pcall(function()
            require("noir.treesitter").register()
        end)
    end,
})

pcall(function()
    require("noir.treesitter").register()
end)
