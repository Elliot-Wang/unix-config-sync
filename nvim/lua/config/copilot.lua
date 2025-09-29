vim.keymap.set('i', '<C-J>', 'copilot#Accept("\\<CR>")', {
  expr = true,
  replace_keycodes = false
})
vim.g.copilot_no_tab_map = true

vim.cmd [[
let g:copilot_filetypes = {
  \ '*': v:false,
  \ 'javascript': v:true,
  \ 'json': v:true,
  \ 'lua': v:true,
  \ 'python': v:true,
  \ 'go': v:true,
  \ 'java': v:true,
  \ 'ruby': v:true,
  \ 'shell': v:true,
  \ 'sql': v:true,
  \ 'vim': v:true,
  \ }
]]

vim.api.nvim_create_autocmd('ColorScheme', {
  pattern = 'solarized',
  -- group = ...,
  callback = function()
    vim.api.nvim_set_hl(0, 'CopilotSuggestion', {
      fg = '#555555',
      ctermfg = 8,
      force = true
    })
  end
})
