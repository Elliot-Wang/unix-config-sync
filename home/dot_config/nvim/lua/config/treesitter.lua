local utils = require("utils")

local ensure_installed_lang = {
  "python",
  "lua",
  "vim",
  "json",
  "markdown",
  "markdown_inline",
}

if utils.executable('go') then
  table.insert(ensure_installed_lang, 'go')
end

if utils.executable('java') then
  table.insert(ensure_installed_lang, 'java')
end

require("nvim-treesitter.configs").setup {
  ensure_installed = ensure_installed_lang,
  ignore_install = {}, -- List of parsers to ignore installing
  highlight = {
    enable = true,     -- false will disable the whole extension
    disable = function(lang, buf)
      local max_filesize = 100 * 1024   -- 100 KB
      local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
      if ok and stats and stats.size > max_filesize then
        return true
      end

      return false
    end,
  },
}
