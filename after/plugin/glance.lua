-- Keybindings
local keymap = vim.keymap.set

-- Peek with Glance (stays in current file)
keymap('n', '<leader>pd', '<cmd>Glance definitions<CR>', { desc = 'Peek definition' })
keymap('n', '<leader>pI', '<cmd>Glance implementations<CR>', { desc = 'Peek implementations' })
keymap('n', '<leader>pR', '<cmd>Glance references<CR>', { desc = 'Peek references' })
keymap('n', '<leader>pT', '<cmd>Glance type_definitions<CR>', { desc = 'Peek type definitions' })
