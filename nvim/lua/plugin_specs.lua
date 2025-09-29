local utils = require("utils")

local plugin_dir = vim.fn.stdpath("data") .. "/lazy"
local lazypath = plugin_dir .. "/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
  vim.fn.system {
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  }
end
vim.opt.rtp:prepend(lazypath)

local plugin_specs = {}

local function addPlugins(plugs)
  for k, v in pairs(plugs) do
    table.insert(plugin_specs, v)
  end
end

-- plugins define
local function syntaxPlugs()
  addPlugins({
    -- beancount
    { "nathangrigg/vim-beancount", ft = { "beancount" } },
    -- toml
    { "cespare/vim-toml",          ft = { "toml" },     branch = "main" },
    {
      "romgrk/nvim-treesitter-context",
      config = function()
        require("treesitter-context").setup {
          enable = true,   -- Enable this plugin (Can be enabled/disabled later via commands)
          throttle = true, -- Throttles plugin updates (may improve performance)
          max_lines = 0,   -- How many lines the window should span. Values <= 0 mean no limit.
          patterns = {     -- Match patterns for TS nodes. These get wrapped to match at word boundaries.
            -- For all filetypes
            -- Note that setting an entry here replaces all other patterns for this entry.
            -- By setting the 'default' entry below, you can control which nodes you want to
            -- appear in the context window.
            default = {
              'class',
              'function',
              'method',
            },
          },
        }
      end
    },
    -- common
    {
      "nvim-treesitter/nvim-treesitter",
      enabled = function()
        if vim.g.is_mac then
          return true
        end
        -- Windows support
        -- https://github.com/nvim-treesitter/nvim-treesitter/wiki/Windows-support
        return false
      end,
      event = "VeryLazy",
      build = ":TSUpdate",
      config = function()
        require("config.treesitter")
      end,
    },
  })
end

local function colorschemePlugs()
  addPlugins({
    -- A list of colorscheme plugin you may want to try. Find what suits you.
    { "navarasu/onedark.nvim",       lazy = true },
    { "sainnhe/edge",                lazy = true },
    { "sainnhe/sonokai",             lazy = true },
    { "sainnhe/gruvbox-material",    lazy = true },
    { "sainnhe/everforest",          lazy = true },
    { "EdenEast/nightfox.nvim",      lazy = true },
    { "catppuccin/nvim",             name = "catppuccin", lazy = true },
    { "olimorris/onedarkpro.nvim",   lazy = true },
    { "marko-cerovac/material.nvim", lazy = true },
    { "dracula/vim",                 name = "dracula",    lazy = true },
    {
      "rockyzhang24/arctic.nvim",
      dependencies = { "rktjmp/lush.nvim" },
      name = "arctic",
      branch = "v2",
    },
    { "rebelot/kanagawa.nvim", lazy = true },
  })
end

local function gitPlugs()
  addPlugins({
    -- Git command inside vim
    {
      "tpope/vim-fugitive",
      event = "User InGitRepo",
      config = function()
        require("config.fugitive")
      end,
    },

    -- Better git log display
    { "rbong/vim-flog",            cmd = { "Flog" } },
    { "akinsho/git-conflict.nvim", version = "*",   config = true },
    {
      "ruifm/gitlinker.nvim",
      event = "User InGitRepo",
      config = function()
        require("config.git-linker")
      end,
    },

    -- Show git change (change, delete, add) signs in vim sign column
    {
      "lewis6991/gitsigns.nvim",
      config = function()
        require("config.gitsigns")
      end,
    },

    {
      "sindrets/diffview.nvim",
    },
    {
      "kdheepak/lazygit.nvim",
      lazy = true,
      cmd = {
        "LazyGit",
        "LazyGitConfig",
        "LazyGitCurrentFile",
        "LazyGitFilter",
        "LazyGitFilterCurrentFile",
      },
      -- optional for floating window border decoration
      dependencies = {
        "nvim-lua/plenary.nvim",
      },
      -- setting the keybinding for LazyGit with 'keys' is recommended in
      -- order to load the plugin when the command is run for the first time
      keys = {
        { "<leader>gg", "<cmd>LazyGit<cr>", desc = "LazyGit" }
      }
    },
  })
end

local function textObjectPlugs()
  addPlugins({
    -- Python-related text object
    { "jeetsukumaran/vim-pythonsense",   ft = { "python" } },

    -- Add indent object for vim (useful for languages like Python)
    { "michaeljsmith/vim-indent-object", event = "VeryLazy" },
  })
end

local function linkPlugs()
  addPlugins({
    -- Highlight URLs inside vim
    { "itchyny/vim-highlighturl", event = "VeryLazy" },

    -- For Windows and Mac, we can open an URL in the browser. For Linux, it may
    -- not be possible since we maybe in a server which disables GUI.
    {
      "chrishrb/gx.nvim",
      keys = { { "gx", "<cmd>Browse<cr>", mode = { "n", "x" } } },
      cmd = { "Browse" },
      init = function()
        vim.g.netrw_nogx = 1 -- disable netrw gx
      end,
      enabled = function()
        if vim.g.is_win or vim.g.is_mac then
          return true
        else
          return false
        end
      end,
      dependencies = { "nvim-lua/plenary.nvim" },
      config = true,      -- default settings
      submodules = false, -- not needed, submodules are required only for tests
    },

  })
end

local function helperPlugs()
  addPlugins({
    -- fancy start screen
    {
      "nvimdev/dashboard-nvim",
      config = function()
        require("config.dashboard-nvim")
      end,
    },

    -- fold
    {
      "kevinhwang91/nvim-ufo",
      dependencies = "kevinhwang91/promise-async",
      event = "VeryLazy",
      opts = {},
      init = function()
        vim.o.foldcolumn = "1" -- '0' is not bad
        vim.o.foldlevel = 99   -- Using ufo provider need a large value, feel free to decrease the value
        vim.o.foldlevelstart = 99
        vim.o.foldenable = true
      end,
      config = function()
        require("config.nvim_ufo")
      end,
    },

    -- fold sign is clickable
    {
      "luukvbaal/statuscol.nvim",
      opts = {},
      config = function()
        require("config.nvim-statuscol")
      end,
    },

    -- Modern matchit implementation
    {
      "andymass/vim-matchup",
      event = "CursorMoved",
      config = function()
        vim.g.matchup_matchparen_offscreen = { method = "popup" }
      end,
    },

    -- Autosave files on certain events
    { "907th/vim-auto-save", event = "InsertEnter" },

    -- Manage your yank history
    {
      "gbprod/yanky.nvim",
      config = function()
        require("config.yanky")
      end,
      event = "VeryLazy",
    },

    -- Session management plugin
    { "tpope/vim-obsession", cmd = "Obsession" },

    -- yank history manager for linux
    {
      "ojroques/vim-oscyank",
      enabled = function()
        if vim.g.is_linux then
          return true
        end
        return false
      end,
      cmd = { "OSCYank", "OSCYankReg" },
    },

    -- showing keybindings
    {
      "folke/which-key.nvim",
      enabled = false,
      event = "VeryLazy",
      config = function()
        require("config.which-key")
      end,
    },
    {
      "smoka7/hop.nvim",
      event = "BufRead",
      config = function()
        require("config.nvim_hop")
      end,
    },

    -- show global result while edit command
    {
      "smjonas/live-command.nvim",
      -- live-command supports semantic versioning via Git tags
      -- tag = "2.*",
      cmd = "Preview",
      config = function()
        require("config.live-command")
      end,
      event = "VeryLazy",
    },

    -- Asynchronous command execution
    { "skywind3000/asyncrun.vim", lazy = true, cmd = { "AsyncRun" } },

    {
      "keaising/im-select.nvim",
      enabled = function()
        if utils.executable('im-select') then
          return true
        else
          return false
        end
      end,
      config = function()
        require("im_select").setup({
          -- IM will be set to `default_im_select` in `normal` mode
          default_im_select   = "com.apple.keylayout.ABC",

          -- Restore the default input method state when the following events are triggered
          set_default_events  = { "VimEnter", "FocusGained", "InsertLeave", "CmdlineLeave" },

          -- Restore the previous used input method state when the following events
          -- are triggered, if you don't want to restore previous used im in Insert mode,
          -- just let it empty
          set_previous_events = { "InsertEnter" },

          -- Async run `default_command` to switch IM or not
          async_switch_im     = true,
        })
      end,
    },

    {
      "lyokha/vim-xkbswitch",
      enabled = function()
        if vim.g.is_mac and utils.executable("xkbswitch") then
          return true
        end
        return false
      end,
      event = { "InsertEnter" },
    },

  })
end

local function stringManipulatePlugs()
  addPlugins({
    -- Comment plugin
    { "tpope/vim-commentary", event = "VeryLazy" },

    -- Multiple cursor plugin like Sublime Text?
    -- 'mg979/vim-visual-multi'

    -- Repeat vim motions
    { "tpope/vim-repeat",     event = "VeryLazy" },

    -- Vim tabular plugin for manipulate tabular, required by markdown plugins
    { "godlygeek/tabular",    cmd = { "Tabularize" } },

    "tpope/vim-surround",

    -- Automatic insertion and deletion of a pair of characters
    {
      "windwp/nvim-autopairs",
      event = "InsertEnter",
      config = true,
    },

    "terryma/vim-multiple-cursors",

    {
      "junegunn/vim-easy-align",
      keys = {
        { "ga", "<Plug>(EasyAlign)", mode = { "n", "x" } }
      },
    }
  })
end

local function sidebarPlugs()
  addPlugins({
    -- file explorer
    -- {
    --   "nvim-tree/nvim-tree.lua",
    --   enabled = false,
    --   event = "VeryLazy",
    --   dependencies = { "nvim-tree/nvim-web-devicons" },
    --   config = function()
    --     require("config.nvim-tree")
    --   end,
    --   attach = function(bufnr)
    --     local api = require "nvim-tree.api"

    --     local function opts(desc)
    --       return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
    --     end

    --     -- default mappings
    --     api.config.mappings.default_on_attach(bufnr)

    --     -- custom mappings
    --     -- vim.keymap.set('n', '<C-t>', api.tree.change_root_to_parent,        opts('Up'))
    --     vim.keymap.set('n', '?', api.tree.toggle_help, opts('Help'))
    --   end,
    -- },

    {
      "nvim-neo-tree/neo-tree.nvim",
      branch = "v2.x",
      dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-tree/nvim-web-devicons",
        "MunifTanjim/nui.nvim",
      },
      config = function()
        require("config.neotree")
      end
    },

    -- Only install these plugins if ctags are installed on the system
    -- show file tags in vim window
    {
      "liuchengxu/vista.vim",
      enabled = function()
        if utils.executable("ctags") then
          return true
        else
          return false
        end
      end,
      cmd = "Vista",
    },

    -- Show undo history visually
    { "simnalamburt/vim-mundo", cmd = { "MundoToggle", "MundoShow" } },

    {
      "kevinhwang91/nvim-bqf",
      event = { "BufRead", "BufNew" },
      ft = "qf",
      config = function()
        require("bqf").setup({
          auto_enable = true,
          preview = {
            win_height = 12,
            win_vheight = 12,
            delay_syntax = 80,
            border_chars = { "┃", "┃", "━", "━", "┏", "┓", "┗", "┛", "█" },
          },
          func_map = {
            vsplit = "",
            ptogglemode = "z,",
            stoggleup = "",
          },
          filter = {
            fzf = {
              action_for = { ["ctrl-s"] = "split" },
              extra_opts = { "--bind", "ctrl-o:toggle-all", "--prompt", "> " },
            },
          },
        })
      end,
    },

    -- minimap
    {
      "wfxr/minimap.vim",
      enabled = function()
        if utils.executable("code-minimap") then
          return true
        else
          return false
        end
      end,
      config = function()
        vim.cmd [[
          let g:minimap_width = 10
          let g:minimap_auto_start = 1
          let g:minimap_auto_start_win_enter = 1
        ]]
      end,
    },

  })
end


local function snippetPlugs()
  addPlugins({
    -- Snippet engine and snippet template
    {
      "SirVer/ultisnips",
      dependencies = {
        "honza/vim-snippets",
      },
      event = "InsertEnter",
      ft = "snippets",
      config = function()
        vim.api.nvim_create_autocmd("BufWritePost", {
          pattern = "*.snippets",
          group = vim.api.nvim_create_augroup("ultisnips", { clear = true }),
          desc = "autoresize windows on resizing operation",
          callback = function()
            vim.cmd("CmpUltisnipsReloadSnippets")
            vim.notify("Ultisnips reloaded.", vim.log.levels.INFO, { title = "nvim-config" })
          end
        })
      end
    },
  })
end

local function completionPlugs()
  addPlugins({
    -- auto-completion engine
    {
      "iguanacucumber/magazine.nvim",
      name = "nvim-cmp",
      -- event = 'InsertEnter',
      event = "VeryLazy",
      dependencies = {
        "hrsh7th/cmp-nvim-lsp",
        "onsails/lspkind-nvim",
        "hrsh7th/cmp-path",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-omni",
        "quangnguyen30192/cmp-nvim-ultisnips",
      },
      config = function()
        require("config.nvim-cmp")
      end,
    },
    -- The missing auto-completion for cmdline!
    {
      "gelguy/wilder.nvim",
      build = ":UpdateRemotePlugins",
    },
  })
end

local function lspPlugs()
  addPlugins({
    -- debugger
    {
      'mfussenegger/nvim-dap',
      config = function()
        require("config.nvim-dap")
      end
    },
    {
      "rcarriga/nvim-dap-ui",
      dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
      config = function()
        require("config.nvim-dap-ui")
      end
    },
    {
      "leoluz/nvim-dap-go",
      dependencies = { "mfussenegger/nvim-dap" },
      enabled = function()
        if utils.executable('go') then
          return true
        else
          return false
        end
      end,
      config = function()
        require("config.dap.nvim-dap-go")
      end
    },
    {
      "mfussenegger/nvim-dap-python",
      dependencies = { "mfussenegger/nvim-dap" },
      enabled = function()
        if utils.executable('debugpy') then
          return true
        else
          return false
        end
      end,
      config = function()
        require("config.dap.nvim-dap-python")
      end
    },

    -- lsp config
    {
      "neovim/nvim-lspconfig",
      event = { "BufRead", "BufNewFile" },
      config = function()
        require("config.lsp")
      end,
    },

    -- coc
    -- {
    --   "neoclide/coc.nvim",
    --   branch = "release",
    --   config = function()
    --     require("config.coc")
    --   end,
    -- },

    -- copilot
    {
      "github/copilot.vim",
      config = function()
        require("config.copilot")
      end,
    },

    -- Auto format tools
    -- supports https://github.com/sbdchd/neoformat?tab=readme-ov-file#supported-filetypes
    { "sbdchd/neoformat", cmd = { "Neoformat" } },

    {
      -- show hint for code actions, the user can also implement code actions themselves,
      -- see discussion here: https://github.com/neovim/neovim/issues/14869
      "kosayoda/nvim-lightbulb",
      config = function()
        require("nvim-lightbulb").setup { autocmd = { enabled = true } }
      end,
    },

    -- lsp servers --
    {
      "folke/lazydev.nvim",
      ft = "lua", -- only load on lua files
      opts = {},
    },

    {
      "ray-x/go.nvim",
      enabled = function()
        if utils.executable('go') then
          return true
        else
          return false
        end
      end,
      dependencies = { -- optional packages
        "ray-x/guihua.lua",
        "neovim/nvim-lspconfig",
        "nvim-treesitter/nvim-treesitter",
      },
      config = function()
        require("go").setup()
      end,
      event = { "CmdlineEnter" },
      ft = { "go", 'gomod' },
      build = ':lua require("go.install").update_all_sync()' -- if you need to install/update all binaries
    }
  })
end

local function markdownPlugs()
  addPlugins({
    {
      "MeanderingProgrammer/markdown.nvim",
      main = "render-markdown",
      opts = {},
      dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    },
    -- Another markdown plugin
    { "preservim/vim-markdown", ft = { "markdown" } },

    -- Faster footnote generation
    -- { "vim-pandoc/vim-markdownfootnotes", ft = { "markdown" } },

    -- Markdown previewing (only for Mac and Windows)
    {
      "iamcco/markdown-preview.nvim",
      enabled = function()
        if vim.g.is_win or vim.g.is_mac then
          return true
        end
        return false
      end,
      build = "cd app && npm install",
      config = function()
        vim.cmd [[
          let g:mkdp_browser = '/Applications/Safari.app'

          " Do not close the preview tab when switching to other buffers
          let g:mkdp_auto_close = 0

          " Shortcuts to start and stop markdown previewing
          nnoremap <silent> <M-m> :<C-U>MarkdownPreview<CR>
        ]]
      end,
      ft = { "markdown" },
    },
    {
      "rhysd/vim-grammarous",
      enabled = function()
        -- if vim.g.is_mac then
        --   return true
        -- end
        return false
      end,
      ft = { "markdown" },
    },
    {
      "epwalsh/obsidian.nvim",
      version = "*", -- recommended, use latest release instead of latest commit
      enabled = function()
        return _G.enable_obsidian
      end,
      config = function()
        require("config.obsidian")
      end,
      ft = "markdown",
      dependencies = {
        "nvim-lua/plenary.nvim",
      },
    },
  })
end

local function ungroupPlugs()
  addPlugins({
    -- show and trim trailing whitespaces
    { "jdhao/whitespace.nvim", enabled = false,                               event = "VeryLazy" },

    -- Handy unix command inside Vim (Rename, Move etc.)
    { "tpope/vim-eunuch",      cmd = { "Rename", "Delete" } },

    -- a Vim plugin for making Vim plugins
    { "tpope/vim-scriptease",  cmd = { "Scriptnames", "Messages", "Verbose" } },

  })
end

local function searchPlugs()
  addPlugins({
    -- Show match number and index for searching
    {
      "kevinhwang91/nvim-hlslens",
      branch = "main",
      keys = { "*", "#", "n", "N" },
      config = function()
        require("config.hlslens")
      end,
    },
    {
      "folke/todo-comments.nvim",
      dependencies = { "nvim-lua/plenary.nvim" },
    },
    {
      "Yggdroot/LeaderF",
      cmd = "Leaderf",
      build = function()
        local leaderf_path = plugin_dir .. "/LeaderF"
        vim.opt.runtimepath:append(leaderf_path)
        vim.cmd("runtime! plugin/leaderf.vim")

        if not vim.g.is_win then
          vim.cmd("LeaderfInstallCExtension")
        end
      end,
    },
    {
      "nvim-telescope/telescope.nvim",
      -- cmd = "Telescope",
      dependencies = {
        "nvim-telescope/telescope-symbols.nvim",
        "nvim-lua/plenary.nvim",
      },
      config = function()
        require("config.telescope")
      end,
    },
    {
      "nvim-telescope/telescope-frecency.nvim",
      config = function()
        require("telescope").load_extension("frecency")
      end,
    },
    {
      'nvim-telescope/telescope-project.nvim',
      dependencies = {
        'nvim-telescope/telescope.nvim',
      },
      config = function()
        require("config.telescope-project")
      end
    },
    {
      -- :Telescope media_files
      'nvim-telescope/telescope-media-files.nvim',
      enabled = false,
      config = function()
        require('telescope').load_extension('media_files')
      end
    },
    {
      'dhruvmanila/browser-bookmarks.nvim',
      version = '*',
      -- Only required to override the default options
      opts = {
        -- Override default configuration values
        selected_browser = 'arc'
      },
    },
    'crispgm/telescope-heading.nvim',
    {
      {
        "FeiyouG/commander.nvim",
        config = function()
          require('config.commander')
        end
      },
      -- dependencies = {
      --   -- Only if your selected browser is Firefox, Waterfox or buku
      --   'kkharji/sqlite.lua',
      --
      --   -- Only if you're using the Telescope extension
      --   'nvim-telescope/telescope.nvim',
      -- }
    },
    -- {
    --   "ibhagwan/fzf-lua",
    --   -- optional for icon support
    --   dependencies = { "nvim-tree/nvim-web-devicons" },
    --   config = function()
    --     -- calling `setup` is optional for customization
    --     require("fzf-lua").setup {}
    --   end,
    -- },
  })
end

local function uiPlugs()
  addPlugins({
    { "nvim-tree/nvim-web-devicons", event = "VeryLazy" },

    {
      "nvim-lualine/lualine.nvim",
      event = "VeryLazy",
      config = function()
        require("config.lualine")
      end,
    },

    {
      "akinsho/bufferline.nvim",
      event = { "BufEnter" },
      config = function()
        require("config.bufferline")
      end,
    },

    -- Extensible UI for Neovim notifications and LSP progress messages.
    {
      "j-hui/fidget.nvim",
      enabled = false,
      event = "VeryLazy",
      tag = "legacy",
      config = function()
        require("config.fidget-nvim")
      end,
    },

    -- notification plugin
    {
      "rcarriga/nvim-notify",
      -- event = "VeryLazy",
      config = function()
        require("config.nvim-notify")
      end,
    },

    -- better UI for some nvim actions
    { "stevearc/dressing.nvim" },

    {
      "lukas-reineke/indent-blankline.nvim",
      event = "VeryLazy",
      main = "ibl",
      config = function()
        require("config.indent-blankline")
      end,
    },

    {
      "tribela/transparent.nvim",
      enabled = _G.enable_transparent,
    },
  })
end

local function fileBrowserPlugs()
  addPlugins({
    -- yazi <C-c> to close
    {
      "mikavilpas/yazi.nvim",
      event = "VeryLazy",
      keys = {
        {
          -- NOTE: this requires a version of yazi that includes
          -- https://github.com/sxyazi/yazi/pull/1305 from 2024-07-18
          "gy",
          "<cmd>Yazi toggle<cr>",
          desc = "Open yazi at the current file",
        },
        {
          -- Open in the current working directory
          "<leader>cw",
          "<cmd>Yazi cwd<cr>",
          desc = "Open the file manager in nvim's working directory",
        },
      },
      opts = {
        -- if you want to open yazi instead of netrw, see below for more info
        open_for_directories = false,
        keymaps = {
          show_help = '<f1>',
          open_file_in_vertical_split = '<c-v>',
          open_file_in_horizontal_split = '<c-x>',
          open_file_in_tab = '<c-t>',
          grep_in_directory = '<c-s>',
          replace_in_directory = '<c-g>',
          cycle_open_buffers = '<tab>',
          copy_relative_path_to_selected_files = '<c-y>',
          send_to_quickfix_list = '<c-q>',
          change_working_directory = "<c-\\>",
        },
      },
    },
  })
end

local function tmplatePlugs()
  addPlugins({
  })
end

-- apply plugins --
syntaxPlugs()
colorschemePlugs()
gitPlugs()
textObjectPlugs()
linkPlugs()
helperPlugs()
stringManipulatePlugs()
snippetPlugs()
sidebarPlugs()
completionPlugs()
lspPlugs()
markdownPlugs()
searchPlugs()
uiPlugs()
fileBrowserPlugs()
ungroupPlugs()

require("lazy").setup {
  spec = plugin_specs,
  ui = {
    border = "rounded",
    title = "Plugin Manager",
    title_pos = "center",
  },
  rocks = {
    enabled = false,
  },
}
