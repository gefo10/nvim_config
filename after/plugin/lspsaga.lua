local saga = require('lspsaga')

-- Initialize LSPSaga with default settings
saga.setup({
    code_action = {
        keys = {
            quit = 'q', -- To quit the code action window
            exec = '<C-Space>',  -- Use Ctrl-Space to confirm the code action
        }
    },
  finder_action = {
        keys = {
            open = '<C-Space>',   -- Open finder selection with Ctrl-Space
            vsplit = 'v',
            split = 's',
            quit = 'q',
        }
  },
  hover = {
    open = '<C-Space>',   -- Open hover documentation with Ctrl-Space
  },
  rename_action = {
        keys = { 
            quit = '<Esc>',
            exec = 'q', -- Confirm rename with Ctrl-Space
        }
  },
})

-- Key binding for peek definition (you can change <leader>pd to any key you prefer)
vim.keymap.set('n', '<leader>pd', '<cmd>Lspsaga peek_definition<CR>', { noremap = true, silent = true })

-- Optional: Add other useful LSPSaga bindings like hover docs, show signature, etc.
vim.keymap.set('n', '<leader>ca', '<cmd>Lspsaga code_action<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<leader>rn', '<cmd>Lspsaga rename<CR>', { noremap = true, silent = true })

