# utilities.nvim
> The repository is collect some little utility in Neovim

## Installation

With [lazy.nvim](https://github.com/folk/lazy.nvim):

``` lua
    {
        "Mr-LLLLL/utilities.nvim",
        event = "VeryLazy",
        opts = {
            -- always use `q` to quit preview windows 
            quit_with_q = true,
            -- in qf window, use <cr> jump to
            jump_quickfix_item = true,
            -- define some useful keymap for generic. details see init_keymap function
            map_with_useful = true,
            -- when hit <ctrl-t> will pop stack and centerize
            -- if want to centerize for jump definition, implementation, references, you can used like:
            -- vim.keymap.set(
            --      'n',
            --      '<c-]>', 
            --      function() 
            --          require("utilities.nvim").
            --              list_or_jump("textDocument/definition", require("telescope.builtin").lsp_definitions)
            --      end,
            --      {})
            -- but this is need telescope when result is greater one
            ctrl_t_with_center = true,

            -- NOTE: require nvim-treesitter-textobjects
            -- smart move behavior only support languages {Lua, Golang, Rust, Http}
            -- others language will moved like nvim-treesitter-textobjects
            smart_move_textobj = {
                disabled = false,
                -- disabled filetype, default support all language just like nvim-treesitter-textobjects behavior
                disabled_filetypes = { "git" },
                -- if you want to only support some filetypes, uncomment it and fill your language
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
```
