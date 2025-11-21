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

-- Register keybindings
wk.register({
    -- LSP goto mappings
    g = {
        name = "goto",
        d = { "<cmd>Telescope lsp_definitions<CR>", "Go to definition" },
        D = { "<cmd>Telescope lsp_type_definitions<CR>", "Go to type definition" },
        i = { "<cmd>Glance implementations<CR>", "Peek implementations" },
        I = { "<cmd>Telescope lsp_implementations<CR>", "Jump to implementations" },
        p = { "<cmd>Glance definitions<CR>", "Peek definition" },
        P = { "<cmd>Glance type_definitions<CR>", "Peek type definition" },
        r = { "<cmd>Telescope lsp_references<CR>", "Find references" },
        R = { "<cmd>Glance references<CR>", "Peek references" },
    },
})

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
    },
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
    D = { "<cmd>Telescope diagnostics<CR>", "All diagnostics" },
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


wk.register({
    p = {
        name = "peek",
        d = "Peek definition",
        I = "Peek implementations",
        R = "Peek references",
        T = "Peek type definitions",
    },
})
