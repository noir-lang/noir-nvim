-- Setting the filetype here instead of in ftdetect helps with some plugin interop
-- E.g. 'telescope' should correctly syntax highlight noir files in previews with this
vim.filetype.add({ extension = { nr = "noir" } })
