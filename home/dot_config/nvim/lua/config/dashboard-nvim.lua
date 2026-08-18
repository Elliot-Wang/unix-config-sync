local api = vim.api
local keymap = vim.keymap
local dashboard = require("dashboard")

local conf = {}

conf.header = {
  "                                                       ",
  "                                                       ",
  "                                                       ",
  " ███╗   ██╗ ███████╗ ██████╗  ██╗   ██╗ ██╗ ███╗   ███╗",
  " ████╗  ██║ ██╔════╝██╔═══██╗ ██║   ██║ ██║ ████╗ ████║",
  " ██╔██╗ ██║ █████╗  ██║   ██║ ██║   ██║ ██║ ██╔████╔██║",
  " ██║╚██╗██║ ██╔══╝  ██║   ██║ ╚██╗ ██╔╝ ██║ ██║╚██╔╝██║",
  " ██║ ╚████║ ███████╗╚██████╔╝  ╚████╔╝  ██║ ██║ ╚═╝ ██║",
  " ╚═╝  ╚═══╝ ╚══════╝ ╚═════╝    ╚═══╝   ╚═╝ ╚═╝     ╚═╝",
  "                                                       ",
  "                                                       ",
  "                                                       ",
  "                                                       ",
}

-- for doom type
conf.center = {
  {
    icon = "󰈞  ",
    desc = "Find  File                              ",
    action = "Leaderf file --popup",
    key = "gf",
  },
  {
    icon = "󰈢  ",
    desc = "Recently opened files                   ",
    action = "Leaderf mru --popup",
    key = "go",
  },
  {
    icon = "󰈬  ",
    desc = "Project grep                            ",
    action = "Leaderf rg --popup",
    key = "<C-f>",
  },
  {
    icon = "  ",
    desc = "Open Nvim config                        ",
    action = "tabnew $MYVIMRC | tcd %:p:h",
    key = " ",
  },
  {
    icon = "  ",
    desc = "New file                                ",
    action = "enew",
    key = "e",
  },
  {
    icon = "󰗼  ",
    desc = "Quit Nvim                               ",
    -- desc = "Quit Nvim                               ",
    action = "qa",
    key = "q",
  },
}

-- for hyper type
conf.shortcut = {
  { desc = '󰊳 Update', group = '@property', action = 'Lazy update', key = 'u' },
  {
    icon = ' ',
    icon_hl = '@variable',
    desc = 'Files',
    group = 'Label',
    action = 'Telescope find_files',
    key = 'f',
  },
  {
    desc = ' Config',
    group = 'DiagnosticHint',
    action = 'tabnew ~/.config/nvim/lua/plugin_specs.lua | tcd %:p:h',
    key = 'c',
  },
  {
    desc = '󰈢 Recently',
    group = 'Number',
    action = 'Telescope oldfiles',
    key = 'o',
  },
}

dashboard.setup({
  theme = 'hyper',
  shortcut_type = 'number',
  config = conf
})

api.nvim_create_autocmd("FileType", {
  pattern = "dashboard",
  group = api.nvim_create_augroup("dashboard_enter", { clear = true }),
  callback = function ()
    keymap.set("n", "q", ":qa<CR>", { buffer = true, silent = true })
    keymap.set("n", "e", ":enew<CR>", { buffer = true, silent = true })
  end
})
