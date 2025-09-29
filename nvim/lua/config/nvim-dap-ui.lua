
local dap, dapui = require("dap"), require("dapui")

dapui.setup()

dap.listeners.before.attach.dapui_config = function()
  dapui.open()
end
dap.listeners.before.launch.dapui_config = function()
  dapui.open()
end

vim.keymap.set({ "n" }, "<leader>dd", "<cmd>lua require'dapui'.toggle()<CR>", {desc = "DapUI Toggle"})

-- dap.listeners.before.event_terminated.dapui_config = function()
--   dapui.close()
-- end

-- dap.listeners.before.event_exited.dapui_config = function()
--   dapui.close()
-- end
