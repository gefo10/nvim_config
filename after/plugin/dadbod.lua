-- ✏️  Add your actual PostgreSQL database names here (not table names)
local predefined_dbs = {}

-- ─── Connection ──────────────────────────────────────────────────────────────

-- Fetch the production DB URL from AWS Secrets Manager and connect via tunnel
local function connect_production()
    local cmd = "aws secretsmanager get-secret-value" ..
        " --secret-id 'voiceline-api/production/database/url'" ..
        " --region eu-central-1" ..
        " --query 'SecretString'" ..
        " --output text 2>/dev/null"
    local url = vim.fn.system(cmd)
    if vim.v.shell_error ~= 0 or url == '' then
        vim.notify('Failed to fetch DB URL from AWS. Are you logged in?', vim.log.levels.ERROR)
        return
    end
    url = url:gsub('%s+$', '')
    local dbname   = url:match('/([^/?]+)') or ''
    local rewritten = url:gsub('@[^/]+/', '@localhost:5432/')
    vim.g.db  = rewritten
    vim.g.dbs = { { name = 'production (' .. dbname .. ')', url = rewritten } }
    vim.notify('✅ Connected to production: ' .. dbname, vim.log.levels.INFO)
end

local function connect_to_db(dbname)
    local password = os.getenv('DB_PASSWORD')
    if not password or password == '' then
        vim.notify('❌ DB_PASSWORD not set. Run dbenv in terminal first.', vim.log.levels.ERROR)
        return
    end
    local base = 'postgresql://postgres:' .. password .. '@localhost:5432'
    local url, label
    if dbname and dbname ~= '' then
        url   = base .. '/' .. dbname
        label = dbname
    else
        url   = base
        label = 'postgres'
    end
    vim.g.db  = url
    vim.g.dbs = { { name = label, url = url } }
    vim.notify('✅ Connected to: ' .. label, vim.log.levels.INFO)
end

vim.keymap.set('n', '<leader>dc', function()
    local choices = vim.list_extend(
        { '(no database)', '(type manually...)', 'production (via tunnel)' },
        predefined_dbs
    )
    vim.ui.select(choices, { prompt = 'Select database:' }, function(choice)
        if not choice then return end
        if choice == '(no database)' then
            connect_to_db(nil)
        elseif choice == 'production (via tunnel)' then
            connect_production()
        elseif choice == '(type manually...)' then
            vim.ui.input({
                prompt     = 'Database name: ',
                completion = 'customlist,v:lua.dadbod_db_complete',
            }, function(input)
                connect_to_db(input)
            end)
        else
            connect_to_db(choice)
        end
    end)
end, { desc = 'Connect vim-dadbod to DB' })

-- Live completion for manual DB name input
_G.dadbod_db_complete = function(arglead)
    local password = os.getenv('DB_PASSWORD')
    if not password or password == '' then return predefined_dbs end
    local cmd = string.format(
        "PGPASSWORD='%s' psql -U postgres -h localhost -tAc 'SELECT datname FROM pg_database WHERE datistemplate = false;' 2>/dev/null",
        password
    )
    local result = vim.fn.systemlist(cmd)
    if vim.v.shell_error ~= 0 or #result == 0 then return predefined_dbs end
    if arglead == '' then return result end
    return vim.tbl_filter(function(db) return db:find(arglead, 1, true) ~= nil end, result)
end

vim.keymap.set('n', '<leader>db', ':DBUIToggle<CR>', { desc = 'Toggle DB UI' })

-- ─── Floating window helpers ─────────────────────────────────────────────────

local function open_float(buf, title)
    local width  = math.floor(vim.o.columns * 0.82)
    local height = math.floor(vim.o.lines   * 0.75)
    local row    = math.floor((vim.o.lines   - height) / 2)
    local col    = math.floor((vim.o.columns - width)  / 2)

    local win = vim.api.nvim_open_win(buf, true, {
        relative  = 'editor',
        width     = width,
        height    = height,
        row       = row,
        col       = col,
        style     = 'minimal',
        border    = 'rounded',
        title     = ' ' .. (title or 'Query') .. ' ',
        title_pos = 'center',
    })

    local close = function()
        if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, true)
        end
    end
    vim.keymap.set('n', 'q',     close, { buffer = buf, nowait = true, desc = 'Close float' })
    vim.keymap.set('n', '<C-c>', close, { buffer = buf, nowait = true, desc = 'Close float' })
    return win
end

-- Before executing, register a one-shot autocmd that catches dadbod's result
-- split and moves it into a float instead.
local function intercept_dbout()
    vim.api.nvim_create_autocmd('FileType', {
        pattern  = 'dbout',
        once     = true,
        callback = function(args)
            local rbuf = args.buf
            vim.schedule(function()
                -- close the plain split dadbod opened for this buffer
                for _, w in ipairs(vim.api.nvim_list_wins()) do
                    local cfg = vim.api.nvim_win_get_config(w)
                    if vim.api.nvim_win_get_buf(w) == rbuf and cfg.relative == '' then
                        vim.api.nvim_win_close(w, true)
                        break
                    end
                end
                open_float(rbuf, 'Results')
            end)
        end,
    })
end

-- Open SQL in an editable float; <leader>S executes and shows results in a float
local function open_buf(sql, title, filepath)
    local buf = vim.api.nvim_create_buf(true, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(sql, '\n'))
    vim.b[buf].db = vim.g.db
    open_float(buf, title or 'Query')   -- makes buf current first
    vim.bo[buf].filetype = 'sql'        -- ftplugin now runs with buf as current
    vim.bo[buf].modifiable = true       -- ensure nothing above locked it

    vim.keymap.set('n', '<leader>S', function()
        intercept_dbout()
        vim.cmd('%DB')
    end, { buffer = buf, desc = 'Execute SQL' })

    vim.keymap.set('v', '<leader>S', function()
        intercept_dbout()
        vim.cmd("'<,'>DB")
    end, { buffer = buf, desc = 'Execute SQL selection' })

    vim.keymap.set('n', '<C-s>', function()
        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        if filepath then
            vim.fn.writefile(lines, filepath)
            vim.notify('Saved to ' .. vim.fn.fnamemodify(filepath, ':t'), vim.log.levels.INFO)
        else
            vim.ui.input({
                prompt  = 'Save as (in db_queries/): ',
                default = (title or 'query'):gsub('%s+', '_') .. '.sql',
            }, function(name)
                if not name or name == '' then return end
                if not name:match('%.sql$') then name = name .. '.sql' end
                local dest = vim.g.db_ui_save_location .. '/' .. name
                vim.fn.writefile(lines, dest)
                filepath = dest  -- update so subsequent saves go to same file
                vim.notify('Saved to ' .. name, vim.log.levels.INFO)
            end)
        end
    end, { buffer = buf, desc = 'Save query' })
end

-- ─── Saved queries ───────────────────────────────────────────────────────────

vim.g.db_ui_save_location = vim.fn.expand('~/.config/nvim/db_queries')

local function open_query_with_params(filepath)
    local lines   = vim.fn.readfile(filepath)
    local content = table.concat(lines, '\n')
    local title   = vim.fn.fnamemodify(filepath, ':t:r')

    local params, seen = {}, {}
    for param in content:gmatch('{{([%w_]+)}}') do
        if not seen[param] then
            table.insert(params, param)
            seen[param] = true
        end
    end

    local function apply_and_open(values)
        local result = content
        for param, value in pairs(values) do
            result = result:gsub('{{' .. param .. '}}', value)
        end
        -- don't pass filepath for substituted queries — params are baked in
        open_buf(result, title)
    end

    if #params == 0 then
        open_buf(content, title, filepath)
        return
    end

    local values = {}
    local function prompt_next(i)
        if i > #params then
            apply_and_open(values)
            return
        end
        vim.ui.input({ prompt = params[i] .. ': ' }, function(value)
            if value == nil then return end
            values[params[i]] = value
            prompt_next(i + 1)
        end)
    end

    prompt_next(1)
end

local function query_picker(opts)
    local actions      = require('telescope.actions')
    local action_state = require('telescope.actions.state')

    opts = vim.tbl_extend('force', {
        prompt_title = opts.prompt_title,
        cwd          = vim.g.db_ui_save_location,
        attach_mappings = function(prompt_bufnr)
            actions.select_default:replace(function()
                local sel = action_state.get_selected_entry()
                actions.close(prompt_bufnr)
                vim.schedule(function()
                    local filepath = sel.path or (vim.g.db_ui_save_location .. '/' .. sel.filename)
                    open_query_with_params(filepath)
                end)
            end)
            return true
        end,
    }, opts)

    return opts
end

vim.keymap.set('n', '<leader>dq', function()
    require('telescope.builtin').find_files(query_picker({
        prompt_title = 'DB Queries (by name)',
        find_command = { 'find', '.', '-name', '*.sql', '-type', 'f' },
    }))
end, { desc = 'Find saved DB query by filename' })

vim.keymap.set('n', '<leader>dQ', function()
    require('telescope.builtin').live_grep(query_picker({
        prompt_title = 'DB Queries (by content)',
        search_dirs  = { vim.g.db_ui_save_location },
        glob_pattern = '*.sql',
    }))
end, { desc = 'Grep saved DB queries by content' })

-- ─── Table picker ────────────────────────────────────────────────────────────

vim.keymap.set('n', '<leader>dt', function()
    if not vim.g.db or vim.g.db == '' then
        vim.notify('No DB connection active. Run <leader>dc first.', vim.log.levels.WARN)
        return
    end

    local password = os.getenv('DB_PASSWORD') or ''
    local cmd = string.format(
        "PGPASSWORD='%s' psql -U postgres -h localhost -tAc \"SELECT schemaname || '.' || tablename FROM pg_tables WHERE schemaname NOT IN ('pg_catalog','information_schema') ORDER BY schemaname, tablename;\" 2>/dev/null",
        password
    )
    local tables = vim.fn.systemlist(cmd)
    if vim.v.shell_error ~= 0 or #tables == 0 then
        vim.notify('Could not fetch tables. Is the tunnel up?', vim.log.levels.ERROR)
        return
    end

    vim.ui.select(tables, { prompt = 'Select table:' }, function(choice)
        if not choice then return end
        local sql = string.format('SELECT *\nFROM %s\nLIMIT 100;', choice)
        open_buf(sql, choice)
    end)
end, { desc = 'Pick table → SELECT query' })

-- ─── Completion ──────────────────────────────────────────────────────────────

vim.api.nvim_create_autocmd('FileType', {
    pattern  = { 'sql', 'mysql', 'plsql' },
    callback = function()
        require('cmp').setup.buffer({
            sources = {
                { name = 'vim-dadbod-completion' },
                { name = 'buffer' },
            },
        })
    end,
})
