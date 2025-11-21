local status_ok, comment = pcall(require, "Comment")
if not status_ok then
    return
end

local status_ok, wk = pcall(require, "which-key")
if not status_ok then
    vim.notify("which-key not found!", vim.log.levels.ERROR)
    return
end



comment.setup({
    -- Add a space b/w comment and the line
    padding = true,
    -- Whether the cursor should stay at its position
    sticky = true,
    -- Lines to be ignored while (un)comment
    ignore = nil,
    -- LHS of toggle mappings in NORMAL mode
    toggler = {
        line = 'gcc',  -- Line-comment toggle keymap
        block = 'gbc', -- Block-comment toggle keymap
    },
    -- LHS of operator-pending mappings in NORMAL and VISUAL mode
    opleader = {
        line = 'gc',  -- Line-comment keymap
        block = 'gb', -- Block-comment keymap
    },
    -- LHS of extra mappings
    extra = {
        above = 'gcO', -- Add comment on the line above
        below = 'gco', -- Add comment on the line below
        eol = 'gcA',   -- Add comment at the end of line
    },
    -- Enable keybindings
    mappings = {
        basic = true,
        extra = true,
    },
})


wk.register({
    ["/"] = "Toggle comment",
    ["?"] = "Toggle block comment",
}, { prefix = "<leader>" })

wk.register({
    g = {
        name = "goto/comment",
        c = {
            name = "comment",
            c = "Toggle line comment",
            O = "Add comment above",
            o = "Add comment below",
            A = "Add comment at EOL",
        },
        b = {
            name = "block comment",
            c = "Toggle block comment",
        },
    },
})
