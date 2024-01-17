vim.lsp.start({ cmd = {'nargo', 'lsp'}, root_dir = vim.fs.dirname(vim.fs.find({'Nargo.toml'}, {stop = vim.env.HOME})[1]), })
