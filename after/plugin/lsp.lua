local lsp = require("lsp-zero")

-- Prevent mason-lspconfig and lspconfig from auto-setup
local lspconfig = require('lspconfig')
local configs = require('lspconfig.configs')

require('mason').setup({})
local home = os.getenv("HOME")
local jdtls_pkg = vim.fn.stdpath('data') .. '/mason/packages/jdtls'
local lombok_jar = jdtls_pkg .. '/lombok.jar'
local lombok_path_new = home .. "/.local/share/lombok/lombok.jar"

-- JDTLS Configuration
local function get_jdtls_config()
  local jdtls = require('jdtls')
  
  -- Find root directory starting from current buffer's file
  local root_markers = {'.git', 'mvnw', 'gradlew', 'pom.xml', 'build.gradle'}
  local root_dir = require('jdtls.setup').find_root(root_markers)

    -- Fallback to current working directory if no root found
  if not root_dir then
    root_dir = vim.fn.getcwd()
  end
  -- Determine OS
  local home = os.getenv('HOME')
  local workspace_dir = home .. '/.cache/nvim/jdtls-workspace/' .. vim.fn.fnamemodify(root_dir, ':p:h:t')
  
  -- Ensure workspace directory exists
  vim.fn.mkdir(workspace_dir, 'p')
  
  local config = {
    cmd = {
      'java',
      '-Declipse.application=org.eclipse.jdt.ls.core.id1',
      '-Dosgi.bundles.defaultStartLevel=4',
      '-Declipse.product=org.eclipse.jdt.ls.core.product',
      '-Dlog.protocol=true',
      '-Dlog.level=ALL',
      '-Xmx2g', -- Increased from 1g
      '--add-modules=ALL-SYSTEM',
      '--add-opens', 'java.base/java.util=ALL-UNNAMED',
      '--add-opens', 'java.base/java.lang=ALL-UNNAMED',
      '-javaagent:' .. lombok_path_new,
      '-jar', vim.fn.glob(home .. '/.local/share/nvim/mason/packages/jdtls/plugins/org.eclipse.equinox.launcher_*.jar'),
      '-configuration', home .. '/.local/share/nvim/mason/packages/jdtls/config_mac',
      '-data', workspace_dir,
    },
    
    root_dir = root_dir,
   
    settings = {
      java = {
        autobuild = {
          enabled = true
        },
        project = {
            referencedLibraries = {
                "lib/**/*.jar",
            },
            -- filters out directories to be excluded from watching
            resourceFilters = {
                "node_modules",
                ".metadata",
                "bin",
                "build",
                "target",
                ".gradle",
                ".git"
            },
        },
        eclipse = {
          downloadSources = true,
        },
        configuration = {
          updateBuildConfiguration = "automatic", -- Changed from interactive
        },
        maven = {
          downloadSources = true,
        },
        implementationsCodeLens = {
          enabled = true,
        },
        referencesCodeLens = {
          enabled = true,
        },
        references = {
          includeDecompiledSources = true,
        },
        format = {
          enabled = true,
          settings = {
            url = vim.fn.stdpath "config" .. "/lang-servers/intellij-java-google-style.xml",
            profile = "GoogleStyle",
          },
        },
        signatureHelp = { 
          enabled = true 
        },
        completion = {
          enabled = true,
          guessMethodArguments = true,
          favoriteStaticMembers = {
            "org.hamcrest.MatcherAssert.assertThat",
            "org.hamcrest.Matchers.*",
            "org.hamcrest.CoreMatchers.*",
            "org.junit.jupiter.api.Assertions.*",
            "java.util.Objects.requireNonNull",
            "java.util.Objects.requireNonNullElse",
            "org.mockito.Mockito.*",
          },
          importOrder = {
            "java",
            "javax",
            "com",
            "org"
          },
        },
        sources = {
          organizeImports = {
            starThreshold = 9999,
            staticStarThreshold = 9999,
          },
        },
        codeGeneration = {
          toString = {
            template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}",
          },
          useBlocks = true,
        },
        -- ADDED: File import exclusions
        import = {
          gradle = {
            enabled = true,
            wrapper = {
              enabled = true,
            },
          },
          exclusions = {
            "**/node_modules/**",
            "**/.metadata/**",
            "**/archetype-resources/**",
            "**/META-INF/maven/**",
            "**/.git/**",
            "**/build/**",
            "**/target/**",
            "**/.gradle/**",
            "**/bin/**",
            "**/uploads/**",
          },
        },
      },
    },
    
    -- Capabilities with disabled dynamic file watching
    capabilities = {
      workspace = {
        didChangeWatchedFiles = {
          dynamicRegistration = true, -- Disable to prevent ENOENT errors
        },
        configuration = true,
        workspaceFolders = true,
      },
      textDocument = {
        completion = {
          completionItem = {
            snippetSupport = true,
          },
        },
      },
    },
    
    flags = {
      allow_incremental_sync = true,
      debounce_text_changes = 150, -- Added debounce
    },
    
    init_options = {
      bundles = {},
      extendedClientCapabilities = require('jdtls').extendedClientCapabilities,
    },
    
    on_attach = function(client, bufnr)
        -- Disable semantic tokens to avoid conflict with treesitter
        client.server_capabilities.semanticTokensProvider = nil

    end,
  }
  
  return config
end

-- Auto-start JDTLS for Java files
vim.api.nvim_create_autocmd("FileType", {
  pattern = "java",
  callback = function()
    local config = get_jdtls_config()
    require('jdtls').start_or_attach(config)
  end,
})

-- Reserve a space in the gutter
vim.opt.signcolumn = 'yes'

-- Fix Undefined global 'vim'
lsp.nvim_workspace()

-- Autocmd to automatically update the project configuration when you save a build file
local jdtls_project_management = vim.api.nvim_create_augroup('jdtls_project_management', { clear = true })


-- Auto-refresh project on build file changes
vim.api.nvim_create_autocmd('BufWritePost', {
  group = jdtls_project_management,
  pattern = { 'build.gradle', 'pom.xml', 'settings.gradle', '*.gradle.kts' },
  callback = function(args)
    local clients = vim.lsp.get_active_clients({ bufnr = args.buf })

    for _, client in ipairs(clients) do
      if client.name == 'jdtls' then
        vim.notify('[jdtls] Build file changed. Refreshing project...', vim.log.levels.INFO)

        vim.lsp.buf_request(
          args.buf,
          'workspace/executeCommand',
          {
            command = 'java.project.import',
            arguments = { vim.uri_from_bufnr(args.buf) },
          },
          function(err, result)
            if err then
              vim.notify('[jdtls] Project import failed: ' .. tostring(err.message), vim.log.levels.ERROR)
            else
              vim.notify('[jdtls] Project refresh successful!', vim.log.levels.INFO)
            end
          end
        )
        break
      end
    end
  end,
  desc = 'JDTLS: Refresh project on build file save.',
})

-- Update source paths when Java files are saved
--vim.api.nvim_create_autocmd('BufWritePost', {
--  group = jdtls_project_management,
--  pattern = "*.java",
--  callback = function()
--    local clients = vim.lsp.get_active_clients({ name = 'jdtls' })
--    if #clients > 0 then
--      vim.defer_fn(function()
--        pcall(function()
--          vim.lsp.buf.execute_command({
--            command = 'java.project.updateSourcePaths',
--            arguments = { vim.uri_from_bufnr(0) }
--          })
--        end)
--      end, 300)
--    end
--  end,
--  desc = 'JDTLS: Update paths after saving Java file'
--})

-- LSP Attach Configuration
vim.api.nvim_create_autocmd('LspAttach', {
    desc = 'LSP actions and configuration',
    callback = function(event)
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if not client then return end

        -- Disable semantic highlights (to avoid conflict with treesitter)
        client.server_capabilities.semanticTokensProvider = nil

        -- Setup format on save (using lsp-zero's helper)
        if client.supports_method('textDocument/formatting') then
            require('lsp-zero').buffer_autoformat()
        end

        -- Set keymaps
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

        -- Add jdtls-specific keymaps
        if client.name == 'jdtls' then
            vim.keymap.set('n', '<leader>ji', function()
                vim.lsp.buf.execute_command({ command = 'java.project.import' })
                vim.notify('[jdtls] Manually triggered project import.', vim.log.levels.INFO)
            end, { buffer = event.buf, desc = 'JDTLS: Import Project' })

            vim.keymap.set('n', '<leader>jr', function()
                vim.lsp.buf.execute_command({ command = 'java.project.import' })
                vim.notify('[jdtls] Refreshing project...', vim.log.levels.INFO)
            end, { buffer = event.buf, desc = 'JDTLS: Full Refresh' })

            vim.keymap.set('n', '<leader>jc', function()
                vim.lsp.buf.execute_command({ command = 'java.clean.workspace' })
                vim.notify('[jdtls] Cleaning workspace. Please restart Neovim.', vim.log.levels.WARN)
            end, { buffer = event.buf, desc = 'JDTLS: Clean Workspace' })
        end
    end,
})

-- CMP Configuration
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

-- LSP-Zero Preferences
lsp.set_preferences({
    suggest_lsp_servers = false,
    sign_icons = {
        error = 'E',
        warn = 'W',
        hint = 'H',
        info = 'I'
    }
})

-- LSP-Zero on_attach
lsp.on_attach(function(client, bufnr)
    local opts = { buffer = bufnr, remap = false }

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

-- Format on Save Configuration
lsp.format_on_save({
    format_opts = {
        async = false,
        timeout_ms = 10000,
    },
    servers = {
        ['biome'] = { 'javascript', 'typescript' },
        ['rust_analyzer'] = { 'rust' },
        ['pyright'] = { 'python' },
        ['clangd'] = { 'c', 'cpp' },
    }
})

-- Auto-format on save
vim.api.nvim_create_autocmd('LspAttach', {
    callback = function(event)
        local id = vim.tbl_get(event, 'data', 'client_id')
        local client = id and vim.lsp.get_client_by_id(id)
        if client == nil then
            return
        end

        if client.supports_method('textDocument/formatting') then
            require('lsp-zero').buffer_autoformat()
        end
    end
})

-- LSP Setup (excluding jdtls as it's manually configured)
lsp.setup({ 
    servers = {
        jdtls = false -- Manual setup above
    }
})

-- Diagnostic Configuration
vim.diagnostic.config({
    virtual_text = true,
})

-- Additional Keymaps
vim.keymap.set('n', '<space>e', vim.diagnostic.open_float, { desc = "Show diagnostic in float" })
--local lsp = require("lsp-zero")
--
---- Prevent mason-lspconfig and lspconfig from auto-setup
--local lspconfig = require('lspconfig')
--
--local configs = require('lspconfig.configs')
--
--require('mason').setup({})
--local home = os.getenv("HOME")
--local jdtls_pkg = vim.fn.stdpath('data') .. '/mason/packages/jdtls'
--local lombok_jar = jdtls_pkg .. '/lombok.jar'
--local lombok_path_new = home .. "/.local/share/lombok/lombok.jar"
--
---- ~/.config/nvim/lua/plugins/lsp.lua or similar
--
--local function get_jdtls_config()
--  local jdtls = require('jdtls')
--  
--  -- Determine OS
--  local home = os.getenv('HOME')
--  local workspace_dir = home .. '/.cache/nvim/jdtls-workspace/' .. vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t')
--  
--  -- Ensure workspace directory exists
--  vim.fn.mkdir(workspace_dir, 'p')
--
--  local config = {
--    cmd = {
--      'java',
--      '-Declipse.application=org.eclipse.jdt.ls.core.id1',
--      '-Dosgi.bundles.defaultStartLevel=4',
--      '-Declipse.product=org.eclipse.jdt.ls.core.product',
--      '-Dlog.protocol=true',
--      '-Dlog.level=ALL',
--      '-Xmx2g', -- Increased from 1g
--      '--add-modules=ALL-SYSTEM',
--      '--add-opens', 'java.base/java.util=ALL-UNNAMED',
--      '--add-opens', 'java.base/java.lang=ALL-UNNAMED',
--      '-javaagent:' .. lombok_path_new,
--      '-jar', vim.fn.glob(home .. '/.local/share/nvim/mason/packages/jdtls/plugins/org.eclipse.equinox.launcher_*.jar'),
--      '-configuration', home .. '/.local/share/nvim/mason/packages/jdtls/config_mac',
--      '-data', workspace_dir,
--    },
--
--    root_dir = require('jdtls.setup').find_root({'.git', 'mvnw', 'gradlew', 'pom.xml', 'build.gradle'}),
--    
--    settings = {
--      java = {
--      },
--      signatureHelp = { enabled = true },
--      completion = {
--        favoriteStaticMembers = {
--          "org.hamcrest.MatcherAssert.assertThat",
--          "org.hamcrest.Matchers.*",
--          "org.hamcrest.CoreMatchers.*",
--          "org.junit.jupiter.api.Assertions.*",
--          "java.util.Objects.requireNonNull",
--          "java.util.Objects.requireNonNullElse",
--          "org.mockito.Mockito.*",
--        },
--        importOrder = {
--          "java",
--          "javax",
--          "com",
--          "org"
--        },
--      },
--      extendedClientCapabilities = jdtls.extendedClientCapabilities,
--      sources = {
--        organizeImports = {
--          starThreshold = 9999,
--          staticStarThreshold = 9999,
--        },
--      },
--      codeGeneration = {
--        toString = {
--          template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}",
--        },
--        useBlocks = true,
--      },
--    },
--    
--    flags = {
--      allow_incremental_sync = true,
--    },
--    
--    init_options = {
--      bundles = {},
--    },
--    on_attach = function(client, bufnr)
--      -- Enable automatic compilation on save
--      vim.api.nvim_create_autocmd("BufWritePost", {
--        buffer = bufnr,
--        callback = function()
--          -- Trigger full source action to refresh diagnostics
--          vim.defer_fn(function()
--            vim.lsp.buf.code_action({
--              context = {
--                only = { "source" },
--                diagnostics = {},
--              },
--              apply = false,
--            })
--          end, 100)
--        end,
--      })
--      
--      -- Your other on_attach stuff
--    end,
--  }
--  
--  return config
--end
--
---- Auto-start JDTLS for Java files
--vim.api.nvim_create_autocmd("FileType", {
--  pattern = "java",
--  callback = function()
--    local config = get_jdtls_config()
--    require('jdtls').start_or_attach(config)
--  end,
--})
--
--
---- OLD CONFIG (workse relatively well)
----vim.api.nvim_create_autocmd("FileType", {
----  pattern = "java",
----  callback = function()
----    local jdtls = require('jdtls')
----
----    -- Find the root of the Java project
----    local java_root_markers = { 'pom.xml', 'build.gradle', 'mvnw', 'gradlew' }
----    local java_project_dir = require('lspconfig.util').root_pattern(unpack(java_root_markers))(vim.fn.expand('%:p'))
----
----    if not java_project_dir then
----      print("[jdtls] No Java project root found. Skipping jdtls.")
----      return
----    end
----
----    -- Find the REAL project root (where .git is)
----    local root_markers = { '.git' }
----    local root_dir = require('lspconfig.util').root_pattern(unpack(root_markers))(java_project_dir)
----
----    local home = os.getenv("HOME")
----    local jdtls_pkg = vim.fn.stdpath('data') .. '/mason/packages/jdtls'
----    local lombok_path_new = home .. "/.local/share/lombok/lombok.jar"
----    
----    -- Create a consistent workspace name based on the true root directory
----    local workspace_dir = vim.fn.stdpath('cache') .. '/jdtls-workspace/' .. vim.fn.fnamemodify(root_dir, ':p:h:t')
----
----    local config = {
----      cmd = {
----        'java',
----        '-Declipse.application=org.eclipse.jdt.ls.core.id1',
----        '-Dosgi.bundles.defaultStartLevel=4',
----        '-Declipse.product=org.eclipse.jdt.ls.core.product',
----        '-Dlog.level=ALL',
----        '-noverify',
----        '-Xms1G',
----        '-Xmx2G',
----        '-javaagent:' .. lombok_path_new,
----        '-jar', vim.fn.glob(jdtls_pkg .. '/plugins/org.eclipse.equinox.launcher_*.jar'),
----        '-configuration', jdtls_pkg .. '/config_mac',
----        '-data', workspace_dir
----      },
----      root_dir = root_dir,
----      
----      -- ✅ ADD THIS: Proper initialization options
----      init_options = {
----        bundles = {},
----        extendedClientCapabilities = {
----          progressReportProvider = false,
----        },
----      },
----      
----      settings = {
----        java = {
----          -- ✅ ADD THIS: Enable automatic source actions
----          project = {
----              sourcePaths = nil,
----          },
----          configuration = {
----              updateBuildConfiguration = "automatic",
----          },
----          signatureHelp = { enabled = true },
----          contentProvider = { preferred = 'fernflower' },
----          completion = {
----            favoriteStaticMembers = {
----              "org.junit.jupiter.api.Assertions.*",
----              "org.junit.Assert.*",
----              "org.mockito.Mockito.*",
----            },
----            filteredTypes = {
----              "com.sun.*",
----              "io.micrometer.shaded.*",
----              "java.awt.*",
----              "jdk.*",
----              "sun.*",
----            },
----          },
----          sources = {
----            organizeImports = {
----              starThreshold = 9999,
----              staticStarThreshold = 9999,
----            },
----          },
----          -- ✅ IMPORTANT: Enable autobuild
----          autobuild = { enabled = true },
----          -- ✅ Enable import on save
----          saveActions = {
----            organizeImports = true,
----          },
----        },
----      },
----      
----      -- ✅ ADD THIS: Proper capabilities including workspace folders
----      capabilities = vim.tbl_deep_extend(
----        'force',
----        vim.lsp.protocol.make_client_capabilities(),
----        require('cmp_nvim_lsp').default_capabilities(),
----        {
----          workspace = {
----            configuration = true,
----            didChangeWatchedFiles = {
----              dynamicRegistration = true,
----            },
----          },
----        }
----      ),
----      
----      -- ✅ ADD THIS: Flags for better file watching
----      flags = {
----        allow_incremental_sync = true,
----        debounce_text_changes = 150,
----      },
----    }
----
----    print('[JDTLS] Attaching with consistent root:', root_dir)
----    print('[JDTLS] Java project dir:', java_project_dir)
----    print('[JDTLS] Workspace dir:', workspace_dir)
----
----    jdtls.start_or_attach(config)
----    
----    -- Format on save just for Java
----    vim.api.nvim_create_autocmd("BufWritePre", {
----      buffer = vim.api.nvim_get_current_buf(),
----      callback = function()
----        vim.lsp.buf.format({ async = false, timeout_ms = 5000 })
----      end,
----    })
----    
----    -- ✅ ADD THIS: Force a workspace refresh after attaching
----    vim.defer_fn(function()
----      vim.lsp.buf.execute_command({
----        command = 'java.project.import',
----        arguments = { vim.uri_from_bufnr(0) }
----      })
----    end, 1000)
----  end
----})
--
----vim.api.nvim_create_autocmd("LspAttach", {
----  callback = function(args)
----    local client = vim.lsp.get_client_by_id(args.data.client_id)
----    print("[LSP ATTACH]", client.name, "on buffer", args.buf)
----  end
----})
----
---- Reserve a space in the gutter
---- This will avoid an annoying layout shift in the screen
--vim.opt.signcolumn = 'yes'
---- Fix Undefined global 'vim'
--lsp.nvim_workspace()
--
---- Autocmd to automatically update the project configuration when you save a build file.
---- This prevents the "cannot be resolved" error after adding a new dependency.
---- Autocmd to automatically update the project configuration when you save a build file.
--local jdtls_project_management = vim.api.nvim_create_augroup('jdtls_project_management', { clear = true })
--
--
---- automatically refresh JDTLS when new Java files are created
--vim.api.nvim_create_autocmd({"BufNewFile", "BufRead"}, {
--  pattern = "*.java",
--  callback = function()
--    local clients = vim.lsp.get_active_clients({ name = 'jdtls' })
--    if #clients > 0 then
--      vim.defer_fn(function()
--        vim.lsp.buf.execute_command({
--          command = 'java.project.pdateSourcePaths',
--          arguments = { vim.uri_from_bufnr(0) }
--        })
--      end, 500)
--    end
--  end,
--  desc = 'JDTLS: Update source paths on new file'
--})
--
--
--vim.api.nvim_create_autocmd('BufWritePost', {
--  group = jdtls_project_management,
--  pattern = { 'build.gradle', 'pom.xml', 'settings.gradle', '*.gradle.kts' },
--  callback = function(args)
--    -- Get all active clients for the current buffer
--    local clients = vim.lsp.get_active_clients({ bufnr = args.buf })
--
--    -- Iterate through the clients to find 'jdtls'
--    for _, client in ipairs(clients) do
--      if client.name == 'jdtls' then
--        vim.notify('[jdtls] Build file changed. Refreshing project...', vim.log.levels.INFO)
--
--        -- Use the modern, non-deprecated function to send the command
--        vim.lsp.buf_request(
--          args.buf,
--          'workspace/executeCommand',
--          {
--            command = 'java.project.import',
--            arguments = { vim.uri_from_bufnr(args.buf) },
--          },
--          function(err, result) -- Optional: callback to handle response
--            if err then
--              vim.notify('[jdtls] Project import failed: ' .. tostring(err.message), vim.log.levels.ERROR)
--            else
--              vim.notify('[jdtls] Project refresh successful!', vim.log.levels.INFO)
--            end
--          end
--        )
--        -- Stop searching once we've found and commanded jdtls
--        break
--      end
--    end
--  end,
--  desc = 'JDTLS: Refresh project on build file save.',
--})
--
--
--vim.api.nvim_create_autocmd('LspAttach', {
--    desc = 'LSP actions and configuration',
--    callback = function(event)
--        local client = vim.lsp.get_client_by_id(event.data.client_id)
--        if not client then return end
--
--        -- 1. Disable semantic highlights (to avoid conflict with treesitter)
--        client.server_capabilities.semanticTokensProvider = nil
--
--        -- 2. Setup format on save (using lsp-zero's helper)
--        if client.supports_method('textDocument/formatting') then
--            require('lsp-zero').buffer_autoformat()
--        end
--
--        -- 3. Set keymaps
--        local opts = { buffer = event.buf }
--        vim.keymap.set('n', 'K', '<cmd>lua vim.lsp.buf.hover()<cr>', opts)
--        vim.keymap.set('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<cr>', opts)
--        vim.keymap.set('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<cr>', opts)
--        vim.keymap.set('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<cr>', opts)
--        vim.keymap.set('n', 'go', '<cmd>lua vim.lsp.buf.type_definition()<cr>', opts)
--        vim.keymap.set('n', 'gr', '<cmd>lua vim.lsp.buf.references()<cr>', opts)
--        vim.keymap.set('n', 'gs', '<cmd>lua vim.lsp.buf.signature_help()<cr>', opts)
--        vim.keymap.set('n', '<F2>', '<cmd>lua vim.lsp.buf.rename()<cr>', opts)
--        vim.keymap.set({ 'n', 'x' }, '<F3>', '<cmd>lua vim.lsp.buf.format({async = true})<cr>', opts)
--        vim.keymap.set('n', '<F4>', '<cmd>lua vim.lsp.buf.code_action()<cr>', opts)
--
--        -- 4. Add jdtls-specific keymaps
--        if client.name == 'jdtls' then
--            vim.keymap.set('n', '<leader>ji', function()
--                vim.lsp.buf.execute_command({ command = 'java.project.import' })
--                vim.notify('[jdtls] Manually triggered project import.', vim.log.levels.INFO)
--            end, { buffer = event.buf, desc = 'JDTLS: Import Project' })
--
--             vim.keymap.set('n', '<leader>jr', function()
--                 vim.lsp.buf.execute_command({ 
--                     command = 'java.project.updateSourcePaths',
--                     arguments = { vim.uri_from_bufnr(0) }
--                 })
--                 vim.defer_fn(function()
--                     vim.lsp.buf.execute_command({ command = 'java.project.import' })
--                 end, 500)
--                 vim.notify('[jdtls] Refreshing source paths and project...', vim.log.levels.INFO)
--             end, { buffer = event.buf, desc = 'JDTLS: Full Refresh' })
--
--            vim.keymap.set('n', '<leader>jc', function()
--                vim.lsp.buf.execute_command({ command = 'java.clean.workspace' })
--                vim.notify('[jdtls] Cleaning workspace. Please restart Neovim.', vim.log.levels.WARN)
--            end, { buffer = event.buf, desc = 'JDTLS: Clean Workspace' })
--        end
--    end,
--})
---- Add cmp_nvim_lsp capabilities settings to lspconfig
---- This should be executed before you configure any language server
----local lspconfig_defaults = require('lspconfig').util.default_config
----lspconfig_defaults.capabilities = vim.tbl_deep_extend(
----    'force',
----    lspconfig_defaults.capabilities,
----    require('cmp_nvim_lsp').default_capabilities()
----)
--
---- This is where you enable features that only work
---- if there is a language server active in the file
----vim.api.nvim_create_autocmd('LspAttach', {
----    desc = 'LSP actions',
----    callback = function(event)
----        local opts = { buffer = event.buf }
----
----        vim.keymap.set('n', 'K', '<cmd>lua vim.lsp.buf.hover()<cr>', opts)
----        vim.keymap.set('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<cr>', opts)
----        vim.keymap.set('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<cr>', opts)
----        vim.keymap.set('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<cr>', opts)
----        vim.keymap.set('n', 'go', '<cmd>lua vim.lsp.buf.type_definition()<cr>', opts)
----        vim.keymap.set('n', 'gr', '<cmd>lua vim.lsp.buf.references()<cr>', opts)
----        vim.keymap.set('n', 'gs', '<cmd>lua vim.lsp.buf.signature_help()<cr>', opts)
----        vim.keymap.set('n', '<F2>', '<cmd>lua vim.lsp.buf.rename()<cr>', opts)
----        vim.keymap.set({ 'n', 'x' }, '<F3>', '<cmd>lua vim.lsp.buf.format({async = true})<cr>', opts)
----        vim.keymap.set('n', '<F4>', '<cmd>lua vim.lsp.buf.code_action()<cr>', opts)
----    end,
----})
----
------ interferes with treesitter -> disable semantic highlights
----vim.api.nvim_create_autocmd('LspAttach', {
----    callback = function(event)
----        local id = vim.tbl_get(event, 'data', 'client_id')
----        local client = id and vim.lsp.get_client_by_id(id)
----        if client == nil then
----            return
----        end
----
----        -- Disable semantic highlights
----        client.server_capabilities.semanticTokensProvider = nil
----    end
----})
--local cmp = require('cmp')
--local cmp_select = { behavior = cmp.SelectBehavior.Select }
--
--cmp.setup({
--    sources = {
--        { name = 'nvim_lsp' },
--    },
--    mapping = cmp.mapping.preset.insert({
--        ['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
--        ['<C-n>'] = cmp.mapping.select_next_item(cmp_select),
--        ['<C-Space>'] = cmp.mapping.confirm({ select = true }),
--        ["<C-c>"] = cmp.mapping.complete(),
--    }),
--    snippet = {
--        expand = function(args)
--            vim.snippet.expand(args.body)
--        end,
--    },
--})
--
--
--
--lsp.set_preferences({
--    suggest_lsp_servers = false,
--
--    sign_icons = {
--        error = 'E',
--        warn = 'W',
--        hint = 'H',
--        info = 'I'
--    }
--})
--
--lsp.on_attach(function(client, bufnr)
--    local opts = { buffer = bufnr, remap = false }
--
--    --
--    --
--    --
--    --
--    -- vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, opts)
--    vim.keymap.set("n", "K", function() vim.lsp.buf.hover() end, opts)
--    vim.keymap.set("n", "<leader>ws", function() vim.lsp.buf.workspace_symbol() end, opts)
--    vim.keymap.set("n", "<leader>d", function() vim.diagnostic.open_float() end, opts)
--    vim.keymap.set("n", "[d", function() vim.diagnostic.goto_next() end, opts)
--    vim.keymap.set("n", "]d", function() vim.diagnostic.goto_prev() end, opts)
--    vim.keymap.set("n", "<leader>ca", function() vim.lsp.buf.code_action() end, opts)
--    vim.keymap.set("n", "<leader>rr", function() vim.lsp.buf.references() end, opts)
--    vim.keymap.set("n", "<leader>rn", function() vim.lsp.buf.rename() end, opts)
--    vim.keymap.set("i", "<leader>vsh", function() vim.lsp.buf.signature_help() end, opts)
--end)
--
----local java_path = home .. '/.sdkman/candidates/java/21.0.4.tem'
----
--local jdtls_dir = vim.fn.stdpath('data') .. '/mason/packages/jdtls'
--
--
--lsp.format_on_save({
--    format_opts = {
--        async = false,
--        timeout_ms = 10000,
--    },
--    servers = {
--        ['biome'] = { 'javascript', 'typescript' },
--        ['rust_analyzer'] = { 'rust' },
--        ['pyright'] = { 'python' },
--        --['jdtls'] = { 'java' },
--        ['clangd'] = { 'c', 'cpp' },
--    }
--})
--
--vim.api.nvim_create_autocmd('LspAttach', {
--    callback = function(event)
--        local id = vim.tbl_get(event, 'data', 'client_id')
--        local client = id and vim.lsp.get_client_by_id(id)
--        if client == nil then
--            return
--        end
--
--        -- make sure there is at least one client with formatting capabilities
--        if client.supports_method('textDocument/formatting') then
--            require('lsp-zero').buffer_autoformat()
--        end
--    end
--})
--
--local lsp_configurations = require('lspconfig.configs')
--
---- Set up all other LSPs with lsp-zero
--lsp.setup({ 
--    servers = {
--    -- Prevent lsp-zero from starting jdtls
--    -- Your manual setup will handle it
--    jdtls = false
--  }
--})
----require("lspconfig").tsserver.setup({})
--vim.diagnostic.config({
--    virtual_text = true,
--})
--
----vim.api.nvim_set_keymap('n', '<space>e', '<cmd>lua vim.diagnostic.open_float()<CR>', opts)
--vim.keymap.set('n', '<space>e', vim.diagnostic.open_float, { desc = "Show diagnostic in float" })
--
--
