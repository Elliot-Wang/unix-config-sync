require('telescope').setup{
  defaults = {
    -- Default configuration for telescope goes here:
    -- config_key = value,
    mappings = {
      i = {
        -- map actions.which_key to <C-h> (default: <C-/>)
        -- actions.which_key shows the mappings for your picker,
        -- [actions](https://github.com/nvim-telescope/telescope.nvim/blob/master/lua/telescope/actions/init.lua#L227)

        -- scroll results
        ["<C-h>"] = "results_scrolling_left",
        ["<C-l>"] = "results_scrolling_right",
        -- scroll preview
        ["<M-j>"] = "results_scrolling_down",
        ["<M-k>"] = "results_scrolling_up",
        ["<M-h>"] = "preview_scrolling_left",
        ["<M-l>"] = "preview_scrolling_right",
      }
    }
  },
  pickers = {
    find_files = {
      theme = "ivy",
    },
    -- lsp_references = {
    --   theme = "cursor",
    -- },
    current_buffer_fuzzy_find = {
      theme = "dropdown",
    },
    live_grep = {
      theme = "dropdown",
    },
    buffers = {
      theme = "cursor",
      preview = {
        hide_on_startup = true,
      },
      -- layout_strategy = "vertical",
    },
    oldfiles = {
      theme = "dropdown",
    },
  },
  extensions = {
    -- Your extension configuration goes here:
    -- extension_name = {
    --   extension_config_key = value,
    -- }
    -- please take a look at the readme of the extension you want to configure
  }
}

local builtin = require('telescope.builtin')

-- vim.keymap.set('n', 'gf', builtin.find_files, { desc = 'Telescope find files' })
vim.keymap.set('n', 'gf', ':Telescope frecency workspace=CWD path_display={"shorten"} theme=ivy<CR>', { desc = 'Telescope recently files', noremap = true })


vim.keymap.set('n', '<space>se', builtin.live_grep, { desc = 'Telescope live grep' })

vim.keymap.set('n', '<C-f>', builtin.current_buffer_fuzzy_find, { desc = 'Telescope current buffer fuzzy find' })

-- vim.keymap.set('n', 'gm', builtin.help_tags, { desc = 'Telescope help tags' })

vim.keymap.set('n', 'ge', builtin.buffers, { desc = 'Telescope buffers' })

vim.keymap.set('n', 'gd', builtin.lsp_references, { desc = 'Telescope LSP references' })

vim.keymap.set('n', '<C-p>', builtin.commands, { desc = 'Telescope commands' })

-- addition
-- vim.keymap.set('n', '<C-p>', ":lua require'telescope'.extensions.project.project{ display_type = 'full' }<CR>", { desc = 'Telescope projects', noremap = true })

-- vim.keymap.set('n', 'gz', ":Telescope z<CR>", { desc = 'Telescope z command', noremap = true })
