-- nvim-treesitter v1.0+: the 'configs' module was removed.
-- Setup only handles install_dir; highlighting is native to neovim.
require('nvim-treesitter').setup()

-- Auto-install parser and enable highlighting when opening a file
vim.api.nvim_create_autocmd('FileType', {
    callback = function(args)
        local lang = vim.treesitter.language.get_lang(args.match)
        if lang then
            local ok = pcall(vim.treesitter.language.inspect, lang)
            if not ok then
                require('nvim-treesitter.install').install({ lang })
            else
                pcall(vim.treesitter.start, args.buf, lang)
            end
        end
    end,
})
