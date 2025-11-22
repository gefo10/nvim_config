local saga = require('lspsaga')

-- Initialize LSPSaga with default settings
saga.setup({
    ui = {
        border = 'rounded', -- Nicer looking borders
        code_action = '💡', -- Icon for code actions
    },
    lightbulb = {
        enable = true,
        sign = true,
        virtual_text = false, -- Less intrusive
    },
    symbol_in_winbar = {
        enable = true, -- Shows current symbol in winbar
    },
    code_action = {
        keys = {
            quit = 'q',    -- To quit the code action window
            exec = '<CR>', -- Use Ctrl-Space to confirm the code action
        }
    },
    finder_action = {
        keys = {
            open = '<C-Space>', -- Open finder selection with Ctrl-Space
            vsplit = 'v',
            split = 's',
            quit = 'q',
            shuttle = '[w', -- Move between results
        }
    },
    definition = {
        keys = {
            edit = '<CR>', -- Open definition in current window
            vsplit = 'v',  -- Open in vertical split
            split = 's',   -- Open in horizontal split
            tabe = 't',    -- Open in new tab
            quit = 'q',
            close = '<Esc>',
        }
    },
    hover = {
        open = '<C-Space>', -- Open hover documentation with Ctrl-Space
    },
    rename_action = {
        keys = {
            quit = '<Esc>',
            exec = 'q', -- Confirm rename with Ctrl-Space
        }
    },
    diagnostic = {
        keys = {
            exec_action = '<CR>',
            quit = 'q',
        }
    },
})

------------------------- PREVIOUS KEYBINDINGS -----------------------------------
-- Key binding for peek definition (you can change <leader>pd to any key you prefer)
--vim.keymap.set('n', '<leader>spd', '<cmd>Lspsaga peek_definition<CR>', { noremap = true, silent = true })
--
---- Optional: Add other useful LSPSaga bindings like hover docs, show signature, etc.
--vim.keymap.set('n', '<leader>sca', '<cmd>Lspsaga code_action<CR>', { noremap = true, silent = true })
--vim.keymap.set('n', '<leader>srn', '<cmd>Lspsaga rename<CR>', { noremap = true, silent = true })
--
--vim.keymap.set({ 'n', 't' }, '<leader>TT', '<cmd>Lspsaga term_toggle<CR>')
--vim.keymap.set('n', '<leader>SK', '<cmd>Lspsaga hover_doc<CR>')
----------------------------------------------------------------------------------

-- Better organized keybindings with descriptions
local keymap = vim.keymap.set

-- Definition & References
--keymap('n', 'gd', '<cmd>Lspsaga goto_definition<CR>', { desc = 'Go to definition' })
--keymap('n', 'gp', '<cmd>Lspsaga peek_definition<CR>', { desc = 'Peek definition' })

--keymap('n', 'gi', '<cmd>Lspsaga goto_implementation<CR>', { desc = 'Go to implementation' })
--keymap('n', 'gI', '<cmd>Lspsaga peek_implementation<CR>', { desc = 'Peek implementation' })

--keymap('n', 'gt', '<cmd>Lspsaga goto_type_definition<CR>', { desc = 'Go to type definition' })
--keymap('n', 'gr', '<cmd>Lspsaga finder<CR>', { desc = 'Find references' })


-- TODO: switch using telescope maybe
-- Hover & Documentation
keymap('n', 'K', '<cmd>Lspsaga hover_doc<CR>', { desc = 'Hover documentation' })
keymap('n', '<leader>K', '<cmd>Lspsaga hover_doc ++keep<CR>', { desc = 'Hover documentation (keep open)' })

-- Code Actions & Refactoring
keymap('n', '<leader>ca', '<cmd>Lspsaga code_action<CR>', { noremap = true, silent = true, desc = 'Code action' })
--keymap('v', '<leader>ca', '<cmd>Lspsaga code_action<CR>', { desc = 'Code action (visual)' })
keymap('n', '<leader>rn', '<cmd>Lspsaga rename<CR>', { desc = 'Rename' })
keymap('n', '<leader>rN', '<cmd>Lspsaga rename ++project<CR>', { desc = 'Rename (project-wide)' })

-- Diagnostics
keymap('n', '[d', '<cmd>Lspsaga diagnostic_jump_prev<CR>', { desc = 'Previous diagnostic' })
keymap('n', ']d', '<cmd>Lspsaga diagnostic_jump_next<CR>', { desc = 'Next diagnostic' })
keymap('n', '[e', function()
    require('lspsaga.diagnostic'):goto_prev({ severity = vim.diagnostic.severity.ERROR })
end, { desc = 'Previous error' })
keymap('n', ']e', function()
    require('lspsaga.diagnostic'):goto_next({ severity = vim.diagnostic.severity.ERROR })
end, { desc = 'Next error' })
keymap('n', '<leader>d', '<cmd>Lspsaga show_line_diagnostics<CR>', { desc = 'Line diagnostics' })
keymap('n', '<leader>D', '<cmd>Lspsaga show_buf_diagnostics<CR>', { desc = 'Buffer diagnostics' })

-- Outline
keymap('n', '<leader>o', '<cmd>Lspsaga outline<CR>', { desc = 'Toggle outline' })

-- Callhierarchy
keymap('n', '<leader>ci', '<cmd>Lspsaga incoming_calls<CR>', { desc = 'Incoming calls' })
keymap('n', '<leader>co', '<cmd>Lspsaga outgoing_calls<CR>', { desc = 'Outgoing calls' })

-- Terminal
keymap({ 'n', 't' }, '<A-t>', '<cmd>Lspsaga term_toggle<CR>', { desc = 'Toggle terminal' })
