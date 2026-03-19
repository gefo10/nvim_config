require('markview').setup({
    preview = {
        enable = true,
        modes = { 'n', 'no', 'c' },
        hybrid_modes = { 'i' },
    },
})

local function follow_md_link()
    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2] + 1

    local start = 1
    while true do
        local s, e, url = line:find('%[.-%]%((.-)%)', start)
        if not s then break end
        if col >= s and col <= e then
            if url:match('^https?://') then
                vim.fn.jobstart({ 'open', url }, { detach = true })
            else
                vim.cmd('edit ' .. vim.fn.fnameescape(url))
            end
            return
        end
        start = e + 1
    end
    -- fallback: try gx for bare URLs, gf for paths
    vim.cmd('normal! gf')
end

local function copy_code_block()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local row = vim.api.nvim_win_get_cursor(0)[1]

    -- Scan from top, tracking open/close pairs to avoid mistaking
    -- a closing fence for an opening one
    local in_block = false
    local start_row = nil

    for i = 1, #lines do
        if lines[i]:match('^```') then
            if not in_block then
                in_block = true
                start_row = i
            else
                if start_row and row >= start_row and row <= i then
                    local snippet = table.concat(lines, '\n', start_row + 1, i - 1)
                    vim.fn.setreg('+', snippet)
                    vim.notify('Code block copied to clipboard', vim.log.levels.INFO)
                    return
                end
                in_block = false
                start_row = nil
            end
        end
    end

    vim.notify('Not inside a code block', vim.log.levels.WARN)
end

vim.api.nvim_create_autocmd('FileType', {
    pattern = 'markdown',
    callback = function()
        vim.keymap.set('n', '<leader>mp', function()
            vim.cmd('Markview toggle')
        end, { buffer = true, desc = 'Toggle Markdown Preview' })

        vim.keymap.set('n', 'gd', follow_md_link, { buffer = true, desc = 'Follow markdown link' })

        vim.keymap.set('n', '<leader>mc', copy_code_block, { buffer = true, desc = 'Copy markdown code block' })
    end,
})
