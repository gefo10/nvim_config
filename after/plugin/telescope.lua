local builtin = require('telescope.builtin')

vim.keymap.set('n', '<leader>pf', builtin.find_files, {})
vim.keymap.set('n', '<C-p>', builtin.git_files, {})
vim.keymap.set('n', '<leader>ps', function()
    builtin.grep_string({ search = vim.fn.input(" Grep > ") });
end)
--vim.keymap.set('n', '<leader>gd', '<cmd>Telescope lsp_definitions<CR>', { noremap = true, silent = true })
--vim.keymap.set('n', '<leader>gr', '<cmd>Telescope lsp_references<CR>', { noremap = true, silent = true })

local keymap = vim.keymap.set

keymap('n', '<leader>.', function() builtin.find_files({ cwd = vim.fn.expand('%:p:h') }) end)


keymap('n', 'gd', '<cmd>Telescope lsp_definitions<CR>', { desc = 'Go to definition' })
keymap('n', 'gi', '<cmd>Telescope lsp_implementations<CR>', { desc = 'Go to implementations' })
keymap('n', 'gr', '<cmd>Telescope lsp_references<CR>', { desc = 'Find references' })
keymap('n', 'gt', '<cmd>Telescope lsp_type_definitions<CR>', { desc = 'Go to type definition' })
