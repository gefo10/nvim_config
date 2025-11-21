local builtin = require('telescope.builtin')

local status_ok, wk = pcall(require, "which-key")
if not status_ok then
    vim.notify("which-key not found!", vim.log.levels.ERROR)
    return
end


vim.keymap.set('n', '<leader>pf', builtin.find_files, {})
vim.keymap.set('n', '<C-p>', builtin.git_files, {})
vim.keymap.set('n', '<leader>ps', function()
    builtin.grep_string({ search = vim.fn.input(" Grep > ") });
end)
--vim.keymap.set('n', '<leader>gd', '<cmd>Telescope lsp_definitions<CR>', { noremap = true, silent = true })
--vim.keymap.set('n', '<leader>gr', '<cmd>Telescope lsp_references<CR>', { noremap = true, silent = true })

local keymap = vim.keymap.set

keymap('n', '<leader>.', function() builtin.find_files({ cwd = vim.fn.expand('%:p:h') }) end)


keymap('n', '<leader>gd', '<cmd>Telescope lsp_definitions<CR>', { desc = 'Go to definition' })
keymap('n', '<leader>gi', '<cmd>Telescope lsp_implementations<CR>', { desc = 'Go to implementations' })
keymap('n', '<leader>gr', '<cmd>Telescope lsp_references<CR>', { desc = 'Find references' })
keymap('n', '<leader>gt', '<cmd>Telescope lsp_type_definitions<CR>', { desc = 'Go to type definition' })
keymap('n', '<leader>fj', '<cmd>Telescope jumplist<CR>', { desc = 'Jump list' })


-- Register keybindings
wk.register({
    -- LSP goto mappings
    g = {
        name = "goto",
        d = { "<cmd>Telescope lsp_definitions<CR>", "Go to definition" },
        D = { "<cmd>Telescope lsp_type_definitions<CR>", "Go to type definition" },
        I = { "<cmd>Telescope lsp_implementations<CR>", "Jump to implementations" },
        r = { "<cmd>Telescope lsp_references<CR>", "Find references" },
    },
}, { prefix = "<leader>" })

-- Leader mappings
wk.register({
    f = {
        name = "find",
        f = { "<cmd>Telescope find_files<CR>", "Find files" },
        g = { "<cmd>Telescope live_grep<CR>", "Live grep" },
        b = { "<cmd>Telescope buffers<CR>", "Buffers" },
        h = { "<cmd>Telescope help_tags<CR>", "Help tags" },
        s = { "<cmd>Telescope lsp_document_symbols<CR>", "Document symbols" },
        S = { "<cmd>Telescope lsp_dynamic_workspace_symbols<CR>", "Workspace symbols" },
        r = { "<cmd>Telescope oldfiles<CR>", "Recent files" },
        j = "Jump list",
    },
    D = { "<cmd>Telescope diagnostics<CR>", "All diagnostics" },
}, { prefix = "<leader>" })
