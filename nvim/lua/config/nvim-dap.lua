
vim.keymap.set({ "n" }, "<leader>bk", "<cmd>lua require'dap'.toggle_breakpoint()<CR>", {desc = "Dap Toggle Breakpoint"})
vim.keymap.set({ "n" }, "<leader>de", "<cmd>lua require'dap'.eval()<CR>", {desc = "Dap Eval"})
vim.keymap.set({ "n" }, "<leader>dl", "<cmd>lua require'dap'.run_last()<CR>", {desc = "Dap Run Last"})

vim.keymap.set({ "n" }, "<leader>d9", "<cmd>lua require'dap'.continue()<CR>", {desc = "Dap Continue"})
vim.keymap.set({ "n" }, "<leader>d8", "<cmd>lua require'dap'.step_over()<CR>", {desc = "Dap Step Over"})
vim.keymap.set({ "n" }, "<leader>d7", "<cmd>lua require'dap'.step_into()<CR>", {desc = "Dap Step Into"})
vim.keymap.set({ "n" }, "<leader>ds8", "<cmd>lua require'dap'.step_out()<CR>", {desc = "Dap Step Out"})

