
--jdtls = require('jdtls')
-- Enable LSP debugging logs
--vim.lsp.set_log_level("debug")
--
---- Optionally, set a custom log file location
--vim.cmd('let $NVIM_LSP_LOG_FILE = "../nvim_lsp.log"')
--
--local home = os.getenv('HOME')  -- Get the home directory path dynamically
--
--local java_path = home .. '/.sdkman/candidates/java/21.0.4.tem'
--
--local jdtls_dir = vim.fn.stdpath('data') .. '/mason/packages/jdtls'
--
--local config_dir = jdtls_dir .. '/config_mac'
--local plugins_dir = jdtls_dir .. '/plugins'
---- local path_to_jar = plugins_dir .. '/org.eclipse.equinox.launcher_*.jar'
--
----local path_to_lsp_server = jdtls_dir .. "/config_mac"
--
--local lombok_path = jdtls_dir .. "/lombok.jar"
--
--local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t')
--local workspace_dir = home .. "/.cache/jdtls/workspace/" .. project_name
--
----local lombok_jar = vim.fn.stdpath('config') ..  '/plugins/jdtls/lombok.jar' 
--
----print(vim.fn.glob(plugins_dir .. '/org.eclipse.equinox.launcher_*.jar'))
----print(config_dir)
----print(lombok_path)
----print(workspace_dir)
--
--local command = {
--    home .. "/.local/share/nvim/mason/bin/jdtls",  -- Path to the jdtls binary installed via Mason
--    '-Declipse.application=org.eclipse.jdt.ls.core.id1',
--    '-Dosgi.bundles.defaultStartLevel=4',
--    '-Declipse.product=org.eclipse.jdt.ls.core.product',
--    '-Dlog.protocol=true',
--    '-Dlog.level=ALL',
--    --'-Xms1g',
--    '-Xmx2g',
--     '-javaagent:' .. lombok_path,
--     '-Xbootclasspath/a:' .. lombok_path,
--     '-jar', vim.fn.glob(plugins_dir .. '/org.eclipse.equinox.launcher_*.jar'), --home .. '/.local/share/nvim/mason/packages/jdtls/plugins/org.eclipse.equinox.launcher_*.jar',  -- Use the correct path to the launcher JAR
--     '-configuration', config_dir, -- home .. '/.local/share/nvim/mason/packages/jdtls/config_linux',  -- Path to the JDTLS configuration folder for your OS
--     '-data', workspace_dir, -- home .. '/jdtls_workspace',  -- Directory for project data
--    '--add-modules=ALL-SYSTEM',
--    '--add-opens', 'java.base/java.util=ALL-UNNAMED',
--    '--add-opens', 'java.base/java.lang=ALL-UNNAMED',
--  }
--local config = {
--     -- cmd = {vim.fn.expand('~/.local/share/nvim/mason/bin/jdtls')},
--     cmd = command,
--     root_dir =  vim.fs.dirname(vim.fs.find({'gradlew', '.git', 'mvnw'}, { upward = true })[1]), --}require('jdtls.setup').find_root({'.git', 'mvnw', 'gradlew', 'pom.xml'}),--vim.fs.dirname(vim.fs.find({'gradlew', '.git', 'mvnw', "pom.xml", "build.gradle"}, { upward = true })[1]),
--     settings = {
--      java = {
--        signatureHelp = { enabled = true },
--        contentProvider = { preferred = 'fernflower' },
--        home = java_path,
--        eclipse = {
--          downloadSources = true,
--        },
--        maven = {
--          downloadSources = true,
--        },
--        implementationsCodeLens = {
--          enabled = true,
--        },
--        referencesCodeLens = {
--          enabled = true,
--        },
--        references = {
--          includeDecompiledSources = true,
--        },
--        format = {
--          settings = {
--            url = home .. "/.local/share/eclipse/eclipse-java-google-style.xml",
--            profile = "GoogleStyle",
--          }
--        }
--      }
--    }
-- }
--
-- local lspconfig = require('lspconfig')
--
--lspconfig.jdtls.setup(config)
--vim.diagnostic.config({
--    virtual_text = true,
--})
--    --autostart = false
----lspconfig.jdtls.setup {
----    autostart = false
----}
----lspconfig.jdtls.setup({
----    cmd = command,
----    root_dir = lspconfig.util.root_pattern('.git', 'gradlew', 'pom.xml', 'build.gradle')
----})
----
----jdtls.start_or_attach(config)
--  
