local status_ok, wk = pcall(require, "which-key")
if not status_ok then
    vim.notify("which-key not found!", vim.log.levels.ERROR)
    return
end


-- Keybindings
local keymap = vim.keymap.set

-- Peek with Glance (stays in current file)
keymap('n', '<leader>pd', '<cmd>Glance definitions<CR>', { desc = 'Peek definition' })
keymap('n', '<leader>pI', '<cmd>Glance implementations<CR>', { desc = 'Peek implementations' })
keymap('n', '<leader>pR', '<cmd>Glance references<CR>', { desc = 'Peek references' })
keymap('n', '<leader>pT', '<cmd>Glance type_definitions<CR>', { desc = 'Peek type definitions' })
--
-- Register keybindings

wk.register({
    p = {
        name = "peek",
        d = "Peek definition",
        I = "Peek implementations",
        R = "Peek references",
        T = "Peek type definitions",
    },
}, { prefix = "<leader>" })
