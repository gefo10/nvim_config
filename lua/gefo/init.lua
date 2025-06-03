require("gefo.remap")
require("gefo.set")
vim.api.nvim_create_user_command("LspAttached", function()
    local clients = vim.lsp.get_clients({ bufnr = 0 })
    if next(clients) == nil then
        print("No LSP clients attached to this buffer.")
    else
        for _, client in ipairs(clients) do
            print("LSP attached: " .. client.name)
        end
    end
end, {})
