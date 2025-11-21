-- Keybindings
local keymap = vim.keymap.set

-- Peek with Glance (stays in current file)
keymap('n', 'gp', '<cmd>Glance definitions<CR>', { desc = 'Peek definition' })
keymap('n', 'gI', '<cmd>Glance implementations<CR>', { desc = 'Peek implementations' })
keymap('n', 'gR', '<cmd>Glance references<CR>', { desc = 'Peek references' })
keymap('n', 'gT', '<cmd>Glance type_definitions<CR>', { desc = 'Peek type definitions' })
