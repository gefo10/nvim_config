require("cloak").setup({
    enabled = true,
    cloak_character = "*",
    -- The applied highlight group (colors) on the cloaking, see `:h highlight`.
    highlight_group = "Comment",
    patterns = {
        {
            -- Match any file starting with ".env".
            -- This can be a table to match multiple file patterns.
            file_pattern = {
                ".env*",
                "wrangler.toml",
                ".dev.vars",
            },
            -- Match an equals sign and any character after it.
            -- This can also be a table of patterns to cloak,
            -- example: cloak_pattern = { ":.+", "-.+" } for yaml files.
            cloak_pattern = "=.+"
        },
    },
})

vim.keymap.set("n", "<leader>uc", "<cmd>CloakToggle<CR>", { desc = "Toggle cloaking" })

local status_ok, wk = pcall(require, "which-key")
if not status_ok then
    vim.notify("which-key not found!", vim.log.levels.ERROR)
    return
end

wk.register({
    { "<leader>uc", desc = "Toggle Cloak" }
})
