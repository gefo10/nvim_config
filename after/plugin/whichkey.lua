-- Check if which-key is installed
local status_ok, wk = pcall(require, "which-key")
if not status_ok then
    vim.notify("which-key not found!", vim.log.levels.ERROR)
    return
end

-- Setup which-key
wk.setup({
    plugins = {
        marks = true,
        registers = true,
        spelling = {
            enabled = true,
            suggestions = 20,
        },
        presets = {
            operators = true,
            motions = true,
            text_objects = true,
            windows = true,
            nav = true,
            z = true,
            g = true,
        },
    },
    icons = {
        breadcrumb = "»",
        separator = "➜",
        group = "+",
    },
    window = {
        border = "rounded",
        position = "bottom",
        margin = { 1, 0, 1, 0 },
        padding = { 1, 2, 1, 2 },
    },
    layout = {
        height = { min = 4, max = 25 },
        width = { min = 20, max = 50 },
        spacing = 3,
        align = "left",
    },
    show_help = true,
    triggers = "auto",
})

-- Leader mappings
wk.register({
    c = {
        name = "code",
        a = { vim.lsp.buf.code_action, "Code action" },
    },
    r = {
        name = "refactor",
        n = { vim.lsp.buf.rename, "Rename" },
    },
    j = {
        name = "java",
        i = { "<cmd>lua vim.lsp.buf.execute_command({ command = 'java.project.import' })<CR>", "Import project" },
        r = { "<cmd>lua vim.lsp.buf.execute_command({ command = 'java.project.import' })<CR>", "Refresh project" },
        c = { "<cmd>lua vim.lsp.buf.execute_command({ command = 'java.clean.workspace' })<CR>", "Clean workspace" },
    },
    d = { vim.diagnostic.open_float, "Line diagnostics" },
    q = { vim.diagnostic.setloclist, "Diagnostics to loclist" },
}, { prefix = "<leader>" })

-- Diagnostic navigation
wk.register({
    ["[d"] = { vim.diagnostic.goto_prev, "Previous diagnostic" },
    ["]d"] = { vim.diagnostic.goto_next, "Next diagnostic" },
    ["[e"] = {
        function()
            vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.ERROR })
        end,
        "Previous error"
    },
    ["]e"] = {
        function()
            vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.ERROR })
        end,
        "Next error"
    },
})

-- Single key mappings
wk.register({
    K = { vim.lsp.buf.hover, "Hover documentation" },
})


-- Register with which-key
wk.register({
    p = {
        name = "buffer",
        b = "Toggle previous buffer",
    },
    j = {
        name = "jump",
        b = "Jump back",
        f = "Jump forward",
    },
}, { prefix = "<leader>" })


---------- ORIGINAL MAPPINGS ----------
--wk.register({
--    ["<C-o>"] = "Jump to older position",
--    ["<C-i>"] = "Jump to newer position",
--    ["g;"] = "Go to previous change",
--    ["g,"] = "Go to next change",
--    ["'"] = {
--        name = "marks",
--        a = "Jump to mark a",
--        b = "Jump to mark b",
--        -- etc
--    },
--})
