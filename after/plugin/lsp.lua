local lsp = require("lsp-zero")
require('mason').setup({})


local home = os.getenv("HOME")
local jdtls_pkg = vim.fn.stdpath('data') .. '/mason/packages/jdtls'
local lombok_jar = jdtls_pkg .. '/lombok.jar'
local lombok_path_new = home .. "/.local/share/lombok/lombok.jar"

require("mason-lspconfig").setup({
  ensure_installed = {
    --"ts_ls", 
    "pyright",
    "rust_analyzer",
    "clangd",
    "eslint",
    "jdtls",
  },
  automatic_installation = true,  -- optional: auto-install missing LSPs
})


vim.api.nvim_create_autocmd("FileType", {
  pattern = "java",
  callback = function()
    local jdtls = require('jdtls')

    local config = {
      cmd = {
        'java',
        '-Declipse.application=org.eclipse.jdt.ls.core.id1',
        '-Dosgi.bundles.defaultStartLevel=4',
        '-Declipse.product=org.eclipse.jdt.ls.core.product',
        '-Dlog.level=ALL',
        '-noverify',
        '-Xmx1G',
        '-javaagent:' .. lombok_path_new,
        '-jar', vim.fn.glob(jdtls_pkg .. '/plugins/org.eclipse.equinox.launcher_*.jar'),
        '-configuration', jdtls_pkg .. '/config_mac',
        '-data', vim.fn.stdpath('cache') .. '/jdtls-workspace' .. vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t')
      },
      root_dir = require('jdtls.setup').find_root({'.git', 'mvnw', 'gradlew', 'pom.xml', 'build.gradle'}),
      settings = {
        java = {},
      },
    }

    jdtls.start_or_attach(config)
  end
})

-- lsp.preset("recommended")

--lsp.ensure_installed({
--  'rust_analyzer',
--  'pyright',
--  --'jdtls', ---> maybe causing conflicts lsp-zero vs nvim-jdtls
--  'eslint',
--  'clangd',
--})
-- Reserve a space in the gutter
-- This will avoid an annoying layout shift in the screen
vim.opt.signcolumn = 'yes'
-- Fix Undefined global 'vim'
lsp.nvim_workspace()
-- Add cmp_nvim_lsp capabilities settings to lspconfig
-- This should be executed before you configure any language server
local lspconfig_defaults = require('lspconfig').util.default_config
lspconfig_defaults.capabilities = vim.tbl_deep_extend(
    'force',
    lspconfig_defaults.capabilities,
    require('cmp_nvim_lsp').default_capabilities()
)

-- This is where you enable features that only work
-- if there is a language server active in the file
vim.api.nvim_create_autocmd('LspAttach', {
    desc = 'LSP actions',
    callback = function(event)
        local opts = { buffer = event.buf }

        vim.keymap.set('n', 'K', '<cmd>lua vim.lsp.buf.hover()<cr>', opts)
        vim.keymap.set('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<cr>', opts)
        vim.keymap.set('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<cr>', opts)
        vim.keymap.set('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<cr>', opts)
        vim.keymap.set('n', 'go', '<cmd>lua vim.lsp.buf.type_definition()<cr>', opts)
        vim.keymap.set('n', 'gr', '<cmd>lua vim.lsp.buf.references()<cr>', opts)
        vim.keymap.set('n', 'gs', '<cmd>lua vim.lsp.buf.signature_help()<cr>', opts)
        vim.keymap.set('n', '<F2>', '<cmd>lua vim.lsp.buf.rename()<cr>', opts)
        vim.keymap.set({ 'n', 'x' }, '<F3>', '<cmd>lua vim.lsp.buf.format({async = true})<cr>', opts)
        vim.keymap.set('n', '<F4>', '<cmd>lua vim.lsp.buf.code_action()<cr>', opts)
    end,
})

-- interferes with treesitter -> disable semantic highlights
vim.api.nvim_create_autocmd('LspAttach', {
    callback = function(event)
        local id = vim.tbl_get(event, 'data', 'client_id')
        local client = id and vim.lsp.get_client_by_id(id)
        if client == nil then
            return
        end

        -- Disable semantic highlights
        client.server_capabilities.semanticTokensProvider = nil
    end
})
local cmp = require('cmp')
local cmp_select = { behavior = cmp.SelectBehavior.Select }

cmp.setup({
    sources = {
        { name = 'nvim_lsp' },
    },
    mapping = cmp.mapping.preset.insert({
        ['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
        ['<C-n>'] = cmp.mapping.select_next_item(cmp_select),
        ['<C-Space>'] = cmp.mapping.confirm({ select = true }),
        ["<C-c>"] = cmp.mapping.complete(),
    }),
    snippet = {
        expand = function(args)
            vim.snippet.expand(args.body)
        end,
    },
})



lsp.set_preferences({
    suggest_lsp_servers = false,

    sign_icons = {
        error = 'E',
        warn = 'W',
        hint = 'H',
        info = 'I'
    }
})

lsp.on_attach(function(client, bufnr)
    local opts = { buffer = bufnr, remap = false }

    --
    --
    --
    --
    -- vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, opts)
    vim.keymap.set("n", "K", function() vim.lsp.buf.hover() end, opts)
    vim.keymap.set("n", "<leader>ws", function() vim.lsp.buf.workspace_symbol() end, opts)
    vim.keymap.set("n", "<leader>d", function() vim.diagnostic.open_float() end, opts)
    vim.keymap.set("n", "[d", function() vim.diagnostic.goto_next() end, opts)
    vim.keymap.set("n", "]d", function() vim.diagnostic.goto_prev() end, opts)
    vim.keymap.set("n", "<leader>ca", function() vim.lsp.buf.code_action() end, opts)
    vim.keymap.set("n", "<leader>rr", function() vim.lsp.buf.references() end, opts)
    vim.keymap.set("n", "<leader>rn", function() vim.lsp.buf.rename() end, opts)
    vim.keymap.set("i", "<leader>vsh", function() vim.lsp.buf.signature_help() end, opts)
end)

--local java_path = home .. '/.sdkman/candidates/java/21.0.4.tem'
--
local jdtls_dir = vim.fn.stdpath('data') .. '/mason/packages/jdtls'


lsp.format_on_save({
    format_opts = {
        async = false,
        timeout_ms = 10000,
    },
    servers = {
        ['biome'] = { 'javascript', 'typescript' },
        ['rust_analyzer'] = { 'rust' },
        ['pyright'] = { 'python' },
        ['jdtls'] = { 'java' },
        ['clangd'] = { 'c', 'cpp' },
    }
})

vim.api.nvim_create_autocmd('LspAttach', {
    callback = function(event)
        local id = vim.tbl_get(event, 'data', 'client_id')
        local client = id and vim.lsp.get_client_by_id(id)
        if client == nil then
            return
        end

        -- make sure there is at least one client with formatting capabilities
        if client.supports_method('textDocument/formatting') then
            require('lsp-zero').buffer_autoformat()
        end
    end
})

local lsp_configurations = require('lspconfig.configs')

local workspace_path = home .. '/.local/share/nvim/jdtls-workspace/'
local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t')
local workspace_dir = workspace_path .. project_name
--require('lspconfig').jdtls.setup({
--    cmd = {
--        'java',
--        '-Declipse.application=org.eclipse.jdt.ls.core.id1',
--        '-Dosgi.bundles.defaultStartLevel=4',
--        '-Declipse.product=org.eclipse.jdt.ls.core.product',
--        '-Dlog.protocol=true',
--        '-Dlog.level=ALL',
--        '-Xmx1g',
--        '--add-modules=ALL-SYSTEM',
--        '--add-opens',
--        'java.base/java.util=ALL-UNNAMED',
--        '--add-opens',
--        'java.base/java.lang=ALL-UNNAMED',
--        '-javaagent:' .. home .. '/.local/share/nvim/mason/packages/jdtls/lombok.jar',
--        '-jar',
--        vim.fn.glob(home .. '/.local/share/nvim/mason/packages/jdtls/plugins/org.eclipse.equinox.launcher_*.jar'),
--        '-configuration',
--        home .. '/.local/share/nvim/mason/packages/jdtls/config_mac_arm',
--        '-data',
--        workspace_dir,
--    },
--    filetypes = { 'java' },
--    root_dir = vim.fs.dirname(vim.fs.find({ 'gradlew', '.git', 'mvnw', 'build.gradle', 'pom.xml' }, { upward = true })
--        [1]), --require('lspconfig.util').root_pattern({ '.git', 'mvnw', 'gradlew', 'pom.xml', 'build.gradle' }),
--    settings = {
--        java = {
--            server = {
--                semanticHighlighting = {
--                    enabled = false,
--                }
--            }
--        }
--    },
--})
--
--require('lspconfig').pyright.setup({
--    settings = {
--        python = {
--            analysis = {
--                typeCheckingMode = 'on',
--            }
--        }
--    }
--})

--local config_dir = jdtls_dir .. '/config_mac_arm'
--local plugins_dir = jdtls_dir .. '/plugins'
---- local path_to_jar = plugins_dir .. '/org.eclipse.equinox.launcher_*.jar'
--
--local path_to_plugins = jdtls_dir .. "/plugins/"
----local path_to_lsp_server = jdtls_dir .. "/config_mac"
--
--local lombok_path = jdtls_dir .. "/lombok.jar"
--
--local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t')
--local workspace_dir = home .. "/.cache/jdtls/workspace"

--local home = vim.fn.expand('$HOME')
--local lombok_path = jdtls_dir .. '/lombok.jar'
--local plugins_dir = jdtls_dir .. '/plugins'
--local config_dir = jdtls_dir .. '/plugins/jdtls/config_mac'
---- Custom setup for JDTLS
--local jdtls_config = {
--  cmd = {
--    -- Path to JDTLS binary provided by Mason
--    vim.fn.stdpath("data") .. "/mason/bin/jdtls",
--    --home .. "/.local/share/nvim/mason/bin/jdtls",  -- Path to the jdtls binary installed via Mason
--   '-Declipse.application=org.eclipse.jdt.ls.core.id1',
--   '-Dosgi.bundles.defaultStartLevel=4',
--   '-Declipse.product=org.eclipse.jdt.ls.core.product',
--   '-Dlog.protocol=true',
--   '-Dlog.level=ALL',
--    '-javaagent:' .. lombok_path,
--    '-Xbootclasspath/a:' .. lombok_path,
--   '-Xmx1g',
--   '--add-modules=ALL-SYSTEM',
--   '--add-opens', 'java.base/java.util=ALL-UNNAMED',
--   '--add-opens', 'java.base/java.lang=ALL-UNNAMED',
--   '-jar', vim.fn.glob(plugins_dir .. '/org.eclipse.equinox.launcher_*.jar'), --home .. '/.local/share/nvim/mason/packages/jdtls/plugins/org.eclipse.equinox.launcher_*.jar',  -- Use the correct path to the launcher JAR
--   '-configuration', config_dir, -- home .. '/.local/share/nvim/mason/packages/jdtls/config_linux',  -- Path to the JDTLS configuration folder for your OS
--   '-data', workspace_dir, -- home .. '/jdtls_workspace',  -- Directory for project data
--    -- Additional JDTLS arguments
----    "-data", vim.fn.stdpath("cache") .. "/jdtls_workspace/" .. vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t"),
--  },
--  root_dir = require('lspconfig.util').root_pattern('.git', 'pom.xml', 'gradlew'),
--  settings = {
--    java = {
--      eclipse = {
--        downloadSources = true
--      },
--      configuration = {
--        updateBuildConfiguration = "interactive"
--      },
--      maven = {
--        downloadSources = true
--      },
--      implementationsCodeLens = {
--        enabled = true
--      },
--      referencesCodeLens = {
--        enabled = true
--      },
--      references = {
--        includeDecompiledSources = true
--      },
--      format = {
--        enabled = true,
--        settings = {
--          url = vim.fn.stdpath("config") .. "/eclipse-java-google-style.xml",
--          profile = "GoogleStyle"
--        }
--      }
--    }
--  },
--  init_options = {
--    bundles = {}
--  },
--  on_attach = function(client, bufnr)
--    -- Attach the general on_attach configuration
--    lsp.on_attach(client, bufnr)
--  end,
--}
--
---- Attach JDTLS using the custom configuration
--require('lspconfig').jdtls.setup(jdtls_config)

-- Set up all other LSPs with lsp-zero
lsp.setup()
--require("lspconfig").tsserver.setup({})
vim.diagnostic.config({
    virtual_text = true,
})


--
--lspconfig.jdtls.setup({
--  cmd = { vim.fn.expand('~/.local/share/nvim/mason/bin/jdtls') },  -- Correct path to jdtls
--  root_dir = lspconfig.util.root_pattern('.git', 'gradlew', 'pom.xml', 'build.gradle'),
--})
