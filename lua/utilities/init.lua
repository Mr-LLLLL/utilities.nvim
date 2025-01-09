local m                           = {}

local spetial_filetype            = {
    "git",
    "qf",
    "spectre_panel",
    "git",
    "fugitive",
    "oil",
    "httpResult",
    "fugitiveblame",
    "translator",
    "checkhealth",
    "help",
    "guihua",
    "notify",
    "tsplayground",
    "query",
    "harpoon",
    "DressingInput",
    "sagaoutline",
    "Avante",
    "AvanteInput",
    "codecompanion"
}

m.autocmd_group                   = vim.api.nvim_create_augroup("Utilities-nvim", { clear = true })

m.init_auto_disable_inlayhint     = function()
    vim.api.nvim_create_autocmd("InsertEnter", {
        callback = function()
            m.inlayhint_enable = vim.lsp.inlay_hint.is_enabled({ bufnr = 0 })
            if m.inlayhint_enable then
                vim.lsp.inlay_hint.enable(false, { bufnr = 0 })
            end
        end,
        group = m.autocmd_group,
    })
    vim.api.nvim_create_autocmd("InsertLeave", {
        callback = function()
            if m.inlayhint_enable then
                vim.lsp.inlay_hint.enable(m.inlayhint_enable, { bufnr = 0 })
            end
        end,
        group = m.autocmd_group,
    })
end

m.init_auto_change_conceallevel   = function()
    vim.api.nvim_create_autocmd("InsertEnter", {
        callback = function()
            m.conceallevel = vim.o.conceallevel
            vim.o.conceallevel = 0
        end,
        group = m.autocmd_group,
    })
    vim.api.nvim_create_autocmd("InsertLeave", {
        callback = function()
            vim.o.conceallevel = m.conceallevel or vim.o.conceallevel
        end,
        group = m.autocmd_group,
    })
end

m.init_auto_change_cwd_to_project = function()
    vim.api.nvim_create_autocmd("BufEnter", {
        callback = function(ctx)
            if vim.tbl_contains(spetial_filetype, vim.bo.ft) then
                return
            end
            local root = vim.fs.root(ctx.buf,
                { "package.json", "go.mod", "Cargo.toml", ".git", ".svn", "Makefile", "mvnw" })
            if root and root ~= "." and root ~= vim.fn.getcwd() then
                vim.fn.chdir(root)
            end
        end,
        group = m.autocmd_group,
    })
end

m.init_no_match_paren             = function()
    local match_paren_hl = vim.api.nvim_get_hl(0, { name = "MatchParen" })
    vim.api.nvim_create_autocmd(
        { "InsertEnter" },
        {
            pattern = "*",
            callback = function()
                vim.api.nvim_set_hl(0, "MatchParen", {})
            end,
            group = m.autocmd_group,
        }
    )
    vim.api.nvim_create_autocmd(
        { "InsertLeave" },
        {
            pattern = "*",
            callback = function()
                vim.api.nvim_set_hl(0, "MatchParen", match_paren_hl)
            end,
            group = m.autocmd_group,
        }
    )
end

m.init_quit                       = function()
    local exclude_ft = {
        "markdown"
    }
    vim.api.nvim_create_autocmd(
        { "Filetype" },
        {
            pattern = "*",
            callback = function(opts)
                if vim.tbl_contains(spetial_filetype, vim.bo.ft) then
                    return
                end
                if vim.tbl_contains(exclude_ft, vim.bo.ft) then
                    return
                end

                for _, v in pairs(vim.api.nvim_buf_get_keymap(opts.buf, "n")) do
                    if v.lhs == "q" then
                        return
                    end
                end
                vim.keymap.set("n", "qq", "q", { noremap = true, silent = true, buffer = opts.buf })
                vim.keymap.set("n", "q", function() end, { noremap = true, silent = true, buffer = opts.buf })
            end,
            group = m.autocmd_group,
        }
    )
    vim.api.nvim_create_autocmd(
        { "Filetype" },
        {
            pattern = spetial_filetype,
            callback = function(opts)
                vim.keymap.set('n', 'q', '<cmd>quit!<cr>', { noremap = true, silent = true, buffer = opts.buf })
            end,
            group = m.autocmd_group,
        }
    )

    vim.api.nvim_create_autocmd(
        { "CmdwinEnter" },
        {
            pattern = { "*" },
            callback = function(opts)
                vim.keymap.set('n', 'q', '<cmd>quit!<cr>', { noremap = true, silent = true, buffer = opts.buf })
                for _, v in pairs(vim.api.nvim_buf_get_keymap(opts.buf, "n")) do
                    if v.lhs == "qq" then
                        vim.keymap.del('n', "qq", { buffer = opts.buf })
                        break
                    end
                end
            end,
            group = m.autocmd_group,
        }
    )
end

m.init_qf_cr                      = function()
    vim.api.nvim_create_autocmd(
        { "Filetype" },
        {
            pattern = { "qf" },
            callback = function(opts)
                vim.keymap.set(
                    'n',
                    '<cr>',
                    function()
                        local pos = vim.api.nvim_win_get_cursor(0)
                        vim.cmd("cr " .. pos[1])
                    end,
                    { noremap = true, silent = true, buffer = true }
                )
            end,
            group = m.autocmd_group,
        }
    )
end

m.init_keymap                     = function()
    vim.keymap.set({ 'n' }, ">", "zl", { noremap = true, silent = true, desc = "scroll right" })
    vim.keymap.set({ 'n' }, "<", "zh", { noremap = true, silent = true, desc = "scroll left" })
    vim.keymap.set({ 'n' }, "<m-k>", "O<esc>", { noremap = true, silent = true, desc = "insert line above current line" })
    vim.keymap.set({ 'n' }, "<m-j>", "o<esc>",
        { noremap = true, silent = true, desc = "insert line follow current line" })
    vim.keymap.set({ 'i' }, "<A-j>", "<esc>o", { noremap = true, silent = true, desc = "insert in next line" })
    vim.keymap.set({ 'i' }, "<A-k>", "<esc>O", { noremap = true, silent = true, desc = "insert in prev line" })
    vim.keymap.set({ 'n' }, "<cr>", "i<cr><esc>", { noremap = true, silent = true, desc = "split line" })
end

m.list_or_jump                    = function(action, f, param)
    local tele_action = require("telescope.actions")
    local lspParam = vim.lsp.util.make_position_params(vim.fn.win_getid())
    lspParam.context = { includeDeclaration = false }
    vim.lsp.buf_request(vim.api.nvim_get_current_buf(), action, lspParam, function(err, result, ctx, _)
        if err then
            vim.api.nvim_err_writeln("Error when executing " .. action .. " : " .. err.message)
            return
        end
        local flattened_results = {}
        if result then
            -- textDocument/definition can return Location or Locatiom.config.smart_move_textobj.mapping.prev_func_end
            if not vim.tbl_islist(result) then
                flattened_results = { result }
            end

            vim.list_extend(flattened_results, result)
        end

        local offset_encoding = vim.lsp.get_client_by_id(ctx.client_id).offset_encoding

        if #flattened_results == 0 then
            return
            -- definitions will be two result in lua, i think first is pretty goods
        elseif #flattened_results == 1 or action == "textDocument/definition" then
            if type(param) == "table" then
                if param.jump_type == "vsplit" then
                    vim.cmd("vsplit")
                elseif param.jump_type == "tab" then
                    vim.cmd("tab split")
                end
            end
            vim.lsp.util.jump_to_location(flattened_results[1], offset_encoding)
            tele_action.center()
        else
            f(param)
        end
    end)
end

m.init_ctr_t                      = function()
    vim.keymap.set('n', "<c-t>", function()
        if vim.fn.gettagstack().curidx == 1 then
            vim.notify("tags is empty", vim.log.levels.INFO)
            return
        end
        vim.cmd("pop")
        vim.cmd("normal! zz")
    end, { noremap = true, silent = true, desc = "stack pop and centerize cursor" })
end

m.init_smart_move_textobj         = function()
    local default_map = {
        [m.config.smart_move_textobj.mapping.prev_func_start] = {
            desc = "Goto Previous Function Start",
            map = "<cmd>TSTextobjectGotoPreviousStart @function.outer<cr>",

        },
        [m.config.smart_move_textobj.mapping.next_func_start] = {
            desc = "Goto Next Function Start",
            map = "<cmd>TSTextobjectGotoNextStart @function.outer<cr>",

        },
        [m.config.smart_move_textobj.mapping.prev_func_end] = {
            desc = "Goto Previous Function End",
            map = "<cmd>TSTextobjectGotoPreviousEnd @function.outer<cr>",

        },
        [m.config.smart_move_textobj.mapping.next_func_end] = {
            desc = "Goto Next Function End",
            map = "<cmd>TSTextobjectGotoNextEnd @function.outer<cr>",

        },
        [m.config.smart_move_textobj.mapping.prev_class_start] = {
            desc = "Goto Previous Class Start",
            map = "<cmd>TSTextobjectGotoPreviousStart @class.outer<cr>",

        },
        [m.config.smart_move_textobj.mapping.next_class_start] = {
            desc = "Goto Next Class Start",
            map = "<cmd>TSTextobjectGotoNextStart @class.outer<cr>",

        },
        [m.config.smart_move_textobj.mapping.prev_class_end] = {
            desc = "Goto Previous Class End",
            map = "<cmd>TSTextobjectGotoPreviousEnd @class.outer<cr>",

        },
        [m.config.smart_move_textobj.mapping.next_class_end] = {
            desc = "Goto Next Class End",
            map = "<cmd>TSTextobjectGotoNextEnd @class.outer<cr>",
        },
    }

    local jumped_by_ts_move = function(backward, obj)
        local prev_pos = vim.api.nvim_win_get_cursor(0)
        local current_pos
        local text_move = require("nvim-treesitter.textobjects.move")
        if backward then
            text_move.goto_previous_start(obj)
            current_pos = vim.api.nvim_win_get_cursor(0)
            if current_pos[1] == prev_pos[1] then
                text_move.goto_previous_start(obj)
            end
        else
            text_move.goto_next_start(obj)
            current_pos = vim.api.nvim_win_get_cursor(0)
            if current_pos[1] == prev_pos[1] then
                text_move.goto_next_start(obj)
            end
        end

        current_pos = vim.api.nvim_win_get_cursor(0)
        if prev_pos[1] == current_pos[1] and prev_pos[2] == current_pos[2] then
            return false
        end

        return true
    end

    local func_jump = {
        go = function(backward)
            if not jumped_by_ts_move(backward, "@function.outer") then
                return false
            end

            local pos = vim.api.nvim_win_get_cursor(0)
            local lines = vim.api.nvim_buf_get_lines(0, pos[1] - 1, pos[1], false)
            if lines[1]:sub(pos[2] + 5, pos[2] + 5) == "(" then
                if lines[1]:sub(pos[2] - 1, pos[2] - 1) == "=" then
                    vim.fn.search("\\h\\+ :\\?=", "b")
                else
                    return true
                end
            else
                vim.fn.search("func\\( (.\\{-})\\)\\? \\h", "e")
            end

            return true
        end,
        rust = function(backward)
            if not jumped_by_ts_move(backward, "@function.outer") then
                return false
            end

            vim.fn.search("\\(pub \\)\\?fn \\h", "e")

            return true
        end,
        lua = function(backward)
            if not jumped_by_ts_move(backward, "@function.outer") then
                return false
            end

            local pos = vim.api.nvim_win_get_cursor(0)
            local lines = vim.api.nvim_buf_get_lines(0, pos[1] - 1, pos[1], false)
            if lines[1]:sub(pos[2] + 9, pos[2] + 9) == "(" then
                if lines[1]:sub(pos[2] - 1, pos[2] - 1) == "=" then
                    vim.fn.search("\\h\\+\\s\\+=", "b")
                else
                    return true
                end
            else
                vim.fn.search("function \\(\\h\\+[\\.\\:]\\)\\?\\h", "e")
            end

            return true
        end,
        http = function(backward)
            if backward then
                vim.fn.search("^\\(GET\\|POST\\|DELETE\\|PUT\\) ", "b")
            else
                vim.fn.search("^\\(GET\\|POST\\|DELETE\\|PUT\\) ")
            end

            return true
        end
    }

    local class_jump = {
        rust = function(backward)
            if not jumped_by_ts_move(backward, "@class.outer") then
                return false
            end

            vim.fn.search("\\(pub \\)\\?[\\(struct\\)\\(impl\\)\\(mod\\)] \\h", "e")

            return true
        end,
        go = function(backward)
            if not jumped_by_ts_move(backward, "@class.outer") then
                return false
            end

            local pos = vim.api.nvim_win_get_cursor(0)
            local text = vim.api.nvim_buf_get_text(0, pos[1] - 1, pos[2], pos[1] - 1, pos[2] + 5, {})
            if text[1] == "type " then
                vim.cmd("normal! W")
            else
                vim.fn.search("[:=]\\+\\s", "b")
                vim.cmd("normal! B")
            end

            return true
        end
    }

    local function wrap_jump(jumps, ft, backward)
        if jumps[ft] then
            if jumps[ft](backward) then
                vim.cmd("normal! zz")
            end
        end
    end

    local map = {
        go = {
            [m.config.smart_move_textobj.mapping.prev_func_start] = {
                map = function()
                    wrap_jump(func_jump, "go", true)
                end,
            },
            [m.config.smart_move_textobj.mapping.next_func_start] = {
                map = function()
                    wrap_jump(func_jump, "go", false)
                end,
            },
            [m.config.smart_move_textobj.mapping.prev_class_start] = {
                map = function()
                    wrap_jump(class_jump, "go", true)
                end,
            },
            [m.config.smart_move_textobj.mapping.next_class_start] = {
                map = function()
                    wrap_jump(class_jump, "go", false)
                end,
            },
        },
        rust = {
            [m.config.smart_move_textobj.mapping.prev_func_start] = {
                map = function()
                    wrap_jump(func_jump, "rust", true)
                end,
            },
            [m.config.smart_move_textobj.mapping.next_func_start] = {
                map = function()
                    wrap_jump(func_jump, "rust", false)
                end,
            },
            [m.config.smart_move_textobj.mapping.prev_class_start] = {
                map = function()
                    wrap_jump(class_jump, "rust", true)
                end,
            },
            [m.config.smart_move_textobj.mapping.next_class_start] = {
                map = function()
                    wrap_jump(class_jump, "rust", false)
                end,
            },
        },
        lua = {
            [m.config.smart_move_textobj.mapping.prev_func_start] = {
                map = function()
                    wrap_jump(func_jump, "lua", true)
                end
            },
            [m.config.smart_move_textobj.mapping.next_func_start] = {
                map = function()
                    wrap_jump(func_jump, "lua", false)
                end,
            },
        },
        http = {
            [m.config.smart_move_textobj.mapping.prev_func_start] = {
                map = function()
                    wrap_jump(func_jump, "http", true)
                end,
                desc = "Goto Previous HTTP Item"
            },
            [m.config.smart_move_textobj.mapping.next_func_start] = {
                map = function()
                    wrap_jump(func_jump, "http", false)
                end,
                desc = "Goto Next HTTP Item"
            },
        }
    }

    vim.api.nvim_create_autocmd(
        { "Filetype" },
        {
            pattern = { "*" },
            callback = function(opts)
                local ft = vim.api.nvim_buf_get_option(0, 'filetype')
                if m.config.smart_move_textobj.enabled_filetypes then
                    if not vim.tbl_contains(m.config.smart_move_textobj.enabled_filetypes, ft) then
                        return
                    end
                else
                    if vim.tbl_contains(m.config.smart_move_textobj.disabled_filetypes, ft) then
                        return
                    end
                end
                for k, v in pairs(vim.tbl_deep_extend('force', default_map, map[ft] or {})) do
                    vim.keymap.set(
                        { 'x', 'n', 'o' },
                        k,
                        v.map,
                        {
                            noremap = true,
                            silent = true,
                            buffer = opts.buf,
                            desc = v.desc,
                        }
                    )
                end
            end,
            group = m.autocmd_group,
        }
    )
end

m.config                          = {
    -- always use `q` to quit preview windows
    quit_with_q = true,
    -- in qf window, use <cr> jump to
    jump_quickfix_item = true,
    -- define some useful keymap for generic. details see init_keymap function
    map_with_useful = true,
    -- when hit <ctrl-t> will pop stack and centerize
    -- if want to centerize for jump definition, implementation, references, you can used like:
    -- ``` lua
    -- vim.keymap.set('n', '<c-]>', function() require("utilities.nvim").list_or_jump("textDocument/definition", require("telescope.builtin").lsp_definitions) end, {})
    -- ```
    -- but this is need telescope when result is greater one
    ctrl_t_with_center = true,

    -- NoMatchParen in insert mode, DoMatchParen when leave insert mode
    no_match_paren_in_insert_mode = false,

    -- auto change cwd directory to project root directory
    auto_change_cwd_to_project = false,

    -- auto change conceallevel, when InsertEnter or InsertLeave event
    auto_change_conceallevel = false,
    --
    -- auto disabled inlayhint when InsertEnter envet trigger
    auto_disable_inlayhint = false,

    -- NOTE: require [nvim-treesitter/nvim-treesitter-textobjects](https://github.com/nvim-treesitter/nvim-treesitter-textobjects)
    -- smart move behavior only support languages {Lua, Golang, Rust, Http}
    -- others language will moved like treesitter-textobj
    smart_move_textobj = {
        disabled = false,
        -- disabled filetype, default support all language just like treesitter-textobj behavior
        disabled_filetypes = spetial_filetype,
        -- if you want to support some filetypes, uncomment it and fill your language
        -- enabled_filetypes = {},
        mapping = {
            prev_func_start = "[[",
            next_func_start = "]]",
            prev_func_end = "[]",
            next_func_end = "][",

            prev_class_start = "[m",
            next_class_start = "]m",
            prev_class_end = "[M",
            next_class_end = "]M",
        }
    }
}

local get_default_config          = function()
    return m.config
end

m.setup                           = function(opts)
    opts = opts or {}
    m.config = vim.tbl_deep_extend('force', get_default_config(), opts)

    if m.config.quit_with_q then
        m.init_quit()
    end
    if m.config.jump_quickfix_item then
        m.init_qf_cr()
    end
    if m.config.map_with_useful then
        m.init_keymap()
    end
    if m.config.ctrl_t_with_center then
        m.init_ctr_t()
    end
    if not m.config.smart_move_textobj.disabled then
        m.init_smart_move_textobj()
    end
    if m.config.no_match_paren_in_insert_mode then
        m.init_no_match_paren()
    end
    if m.config.auto_change_cwd_to_project then
        m.init_auto_change_cwd_to_project()
    end
    if m.config.auto_change_conceallevel then
        m.init_auto_change_conceallevel()
    end
    if m.config.auto_disable_inlayhint then
        m.init_auto_disable_inlayhint()
    end
end

return m
