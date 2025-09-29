local keymap = vim.keymap
local uv = vim.uv

-- Save key strokes (now we do not need to press shift to enter command mode).
keymap.set({ "n", "x" }, ";", ":")

-- Navigation in the location and quickfix list
keymap.set("n", "[l", "<cmd>lprevious<cr>zv", { silent = true, desc = "previous location item" })
keymap.set("n", "]l", "<cmd>lnext<cr>zv", { silent = true, desc = "next location item" })

keymap.set("n", "[L", "<cmd>lfirst<cr>zv", { silent = true, desc = "first location item" })
keymap.set("n", "]L", "<cmd>llast<cr>zv", { silent = true, desc = "last location item" })

keymap.set("n", "[q", "<cmd>cprevious<cr>zv", { silent = true, desc = "previous qf item" })
keymap.set("n", "]q", "<cmd>cnext<cr>zv", { silent = true, desc = "next qf item" })

keymap.set("n", "[Q", "<cmd>cfirst<cr>zv", { silent = true, desc = "first qf item" })
keymap.set("n", "]Q", "<cmd>clast<cr>zv", { silent = true, desc = "last qf item" })

-- Close location list or quickfix list if they are present, see https://superuser.com/q/355325/736190
-- keymap.set("n", [[\x]], "<cmd>windo lclose <bar> cclose <cr>", {
--   silent = true,
--   desc = "close qf and location list",
-- })

-- Delete a buffer, without closing the window, see https://stackoverflow.com/q/4465095/6064933
-- keymap.set("n", [[\d]], "<cmd>bprevious <bar> bdelete #<cr>", {
--   silent = true,
--   desc = "delete current buffer",
-- })

-- keymap.set("n", [[\D]], function()
--   local buf_ids = vim.api.nvim_list_bufs()
--   local cur_buf = vim.api.nvim_win_get_buf(0)

--   for _, buf_id in pairs(buf_ids) do
--     -- do not Delete unlisted buffers, which may lead to unexpected errors
--     if vim.api.nvim_get_option_value("buflisted", { buf = buf_id }) and buf_id ~= cur_buf then
--       vim.api.nvim_buf_delete(buf_id, { force = true })
--     end
--   end
-- end, {
--   desc = "delete other buffers",
-- })

-- Move the cursor based on physical lines, not the actual lines.
keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true })
keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true })
keymap.set("n", "^", "g^")
keymap.set("n", "0", "g0")

-- Tabs of Windows
keymap.set("n", "tn", "<cmd>tabe<CR>", { desc = "打开新选项卡" })
keymap.set("n", "td", "<cmd>tabclose<CR>", { desc = "关闭选项卡" })
keymap.set("n", "th", "<cmd>bprevious<CR>", { desc = "上一个页面" })
keymap.set("n", "tl", "<cmd>bnext<CR>", { desc = "下一个页面" })
keymap.set("n", "tH", "<cmd>-tabnext<CR>", { desc = "到左边的选项卡" })
keymap.set("n", "tL", "<cmd>+tabnext<CR>", { desc = "到右边的选项卡" })

-- Do not include white space characters when using $ in visual mode,
-- see https://vi.stackexchange.com/q/12607/15292
keymap.set("x", "$", "g_")

-- Go to start or end of line easier
keymap.set({ "n", "x" }, "H", "^")
keymap.set({ "n", "x" }, "L", "g_")

-- Continuous visual shifting (does not exit Visual mode), `gv` means
-- to reselect previous visual area, see https://superuser.com/q/310417/736190
keymap.set("x", "<", "<gv")
keymap.set("x", ">", ">gv")

-- Edit and reload nvim config file quickly
keymap.set("n", "<leader>ev", "<cmd>tabnew $MYVIMRC <bar> tcd %:h<cr>", {
  silent = true,
  desc = "open init.lua",
})

keymap.set("n", "<leader>rc", function()
  vim.cmd([[
      update $MYVIMRC
      source $MYVIMRC
    ]])
  vim.notify("Nvim config successfully reloaded!", vim.log.levels.INFO, { title = "nvim-config" })
end, {
  silent = true,
  desc = "reload init.lua",
})

-- Always use very magic mode for searching
keymap.set("n", "/", [[/\v]])

-- Search in selected region
-- xnoremap / :<C-U>call feedkeys('/\%>'.(line("'<")-1).'l\%<'.(line("'>")+1)."l")<CR>

-- Change current working directory locally and print cwd after that,
-- see https://vim.fandom.com/wiki/Set_working_directory_to_the_current_file
keymap.set("n", "<leader>cd", "<cmd>lcd %:p:h<cr><cmd>pwd<cr>", { desc = "change cwd" })

-- Use Esc to quit builtin terminal
-- conflict with lazygit windows
-- keymap.set("t", "<Esc>", [[<c-\><c-n>]])

-- Toggle spell checking
keymap.set("n", "<F11>", "<cmd>set spell!<cr>", { desc = "toggle spell" })
keymap.set("i", "<F11>", "<c-o><cmd>set spell!<cr>", { desc = "toggle spell" })

-- Change text without putting it into the vim register,
-- see https://stackoverflow.com/q/54255/6064933
keymap.set("n", "c", '"_c')
keymap.set("n", "C", '"_C')
keymap.set("x", "c", '"_c')

-- Remove trailing whitespace characters
keymap.set("n", [[ \<space> ]], "<cmd>StripTrailingWhitespace<cr>", { desc = "remove trailing space" })

-- check the syntax group of current cursor position
keymap.set("n", "<leader>st", "<cmd>call utils#SynGroup()<cr>", { desc = "check syntax group" })

-- Toggle cursor column
keymap.set("n", "<leader>cl", "<cmd>call utils#ToggleCursorCol()<cr>", { desc = "toggle cursor column" })

-- Move current line up and down
keymap.set("n", "<A-k>", '<cmd>call utils#SwitchLine(line("."), "up")<cr>', { desc = "move line up" })
keymap.set("n", "<A-j>", '<cmd>call utils#SwitchLine(line("."), "down")<cr>', { desc = "move line down" })

-- Move current visual-line selection up and down
keymap.set("x", "<A-k>", '<cmd>call utils#MoveSelection("up")<cr>', { desc = "move selection up" })
keymap.set("x", "<A-j>", '<cmd>call utils#MoveSelection("down")<cr>', { desc = "move selection down" })

-- Replace visual selection with text in register, but not contaminate the register,
-- see also https://stackoverflow.com/q/10723700/6064933.
keymap.set("x", "p", '"_c<Esc>p')

-- Switch windows
keymap.set("n", "sh", "<C-W>h", {desc = "切换到左分屏"})
keymap.set("n", "sl", "<C-W>l", {desc = "切换到右分屏"})
keymap.set("n", "sk", "<C-W>k", {desc = "切换到上分屏"})
keymap.set("n", "sj", "<C-W>j", {desc = "切换到下分屏"})

keymap.set("n", "ss", "<C-w><C-w>", {desc = "切换分屏"})

-- Split Windows
keymap.set("n", "sK", ":set splitbelow<CR>:split<CR>", {desc = "下分屏"})
keymap.set("n", "sJ", ":set nosplitbelow<CR>:split<CR>", {desc = "上分屏"})
keymap.set("n", "sL", ":set nosplitright<CR>:vsplit<CR>", {desc = "右分屏"})
keymap.set("n", "sH", ":set splitright<CR>:vsplit<CR>", {desc = "左分屏"})

keymap.set("n", "sc", "<C-w>c", {desc = "关闭当前分屏"})

-- cmdline abbrev
-- vim.fn["utils#Cabbrev"]("git", "Git")
-- vim.fn["utils#Cabbrev"]("snip", "call UltiSnips#RefreshSnippets()")

-- Break inserted text into smaller undo units when we insert some punctuation chars.
local undo_ch = { ",", ".", "!", "?", ";", ":" }
for _, ch in ipairs(undo_ch) do
  keymap.set("i", ch, ch .. "<c-g>u")
end

-- Go to the beginning and end of current line in insert mode quickly
keymap.set("i", "<C-A>", "<HOME>")
keymap.set("i", "<C-E>", "<END>")

-- Go to beginning of command in command-line mode
keymap.set("c", "<C-A>", "<HOME>")

-- Delete the character to the right of the cursor
keymap.set("i", "<C-D>", "<DEL>")

-- 闪烁光标
keymap.set("n", "<leader>cb", function()
  local cnt = 0
  local blink_times = 7
  local timer = uv.new_timer()
  if timer == nil then
    return
  end

  timer:start(
    0,
    100,
    vim.schedule_wrap(function()
      vim.cmd([[
      set cursorcolumn!
      set cursorline!
    ]])

      if cnt == blink_times then
        timer:close()
      end

      cnt = cnt + 1
    end)
  )
end, { desc = "show cursor" })
