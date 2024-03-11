local m                  = {}

m.init_quit              = function()
    local group = vim.api.nvim_create_augroup("UtilitiesQuit", { clear = true })
    vim.api.nvim_create_autocmd(
        { "Filetype" },
        {
            pattern = {
                "qf",
                "spectre_panel",
                "git",
                "fugitive",
                "fugitiveblame",
                "help",
                "guihua",
                "notify",
                "tsplayground",
            },
            callback = function(_)
                vim.keymap.set('n', 'q', '<cmd>quit!<cr>', { noremap = true, silent = true, buffer = true })
            end,
            group = group,
        }
    )

    vim.api.nvim_create_autocmd(
        { "CmdwinEnter" },
        {
            pattern = { "*" },
            callback = function()
                vim.keymap.set('n', 'q', '<cmd>quit!<cr>', { noremap = true, silent = true, buffer = true })
            end,
            group = group,
        }
    )
end

m.init_qf_cr             = function()
    local group = vim.api.nvim_create_augroup("UtilitiesQfCR", { clear = true })
    vim.api.nvim_create_autocmd(
        { "Filetype" },
        {
            pattern = { "qf" },
            callback = function()
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
            group = group,
        }
    )
end

m.init_keymap            = function()
    vim.keymap.set({ 'n' }, ">", "zl", { noremap = true, silent = true, desc = "scroll right" })
    vim.keymap.set({ 'n' }, "<", "zh", { noremap = true, silent = true, desc = "scroll left" })
    vim.keymap.set({ 'n' }, "<m-k>", "O<esc>", { noremap = true, silent = true, desc = "insert line above current line" })
    vim.keymap.set({ 'n' }, "<m-j>", "o<esc>",
        { noremap = true, silent = true, desc = "insert line follow current line" })
    vim.keymap.set({ 'i' }, "<A-j>", "<esc>o", { noremap = true, silent = true, desc = "insert in next line" })
    vim.keymap.set({ 'i' }, "<A-k>", "<esc>O", { noremap = true, silent = true, desc = "insert in prev line" })
    vim.keymap.set({ 'n' }, "<cr>", "i<cr><esc>", { noremap = true, silent = true, desc = "split line" })
end

m.list_or_jump           = function(action, f, param)
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
            -- textDocument/definition can return Location or Location[]
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

m.init_ctr_t             = function()
    vim.keymap.set('n', "<c-t>", function()
        if vim.fn.gettagstack().curidx == 1 then
            vim.notify("tags is empty", vim.log.levels.INFO)
            return
        end
        vim.cmd("pop")
        vim.cmd("normal! zz")
    end, { noremap = true, silent = true, desc = "stack pop and centerize cursor" })
end

m.config                 = {
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
}

local get_default_config = function()
    return m.config
end

m.setup                  = function(opts)
    opts = opts or {}
    m.config = vim.tbl_deep_extend('force', get_default_config(), opts)

    if m.quit_with_q then
        m.init_quit()
    end
    if m.jump_quickfix_item then
        m.init_qf_cr()
    end
    if m.map_with_useful then
        m.init_keymap()
    end
    if m.ctrl_t_with_center then
        m.init_ctr_t()
    end
end

return m
