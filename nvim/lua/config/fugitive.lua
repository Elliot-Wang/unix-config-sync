local keymap = vim.keymap

-- status
keymap.set("n", "<leader>gs", "<cmd>Git<cr>", { desc = "Git: show status" })
-- add files
keymap.set("n", "<leader>ga", "<cmd>Gwrite<cr>", { desc = "Git: add file" })
-- commit
keymap.set("n", "<leader>gc", "<cmd>Git commit<cr>", { desc = "Git: commit changes" })
-- pull
keymap.set("n", "<leader>gl", "<cmd>Git pull<cr>", { desc = "Git: pull changes" })
-- push
keymap.set("n", "<leader>gp", "<cmd>15 split|term git push<cr>", { desc = "Git: push changes" })
-- fetch
keymap.set("n", "<leader>gf", ":Git fetch ", { desc = "Git: prune branches" })

-- blame
keymap.set("n", "<leader>gbl", ":Git blame<cr>", { desc = "Git: blame current file" })

-- switch branch or create one
keymap.set("n", "<leader>gbn", function()
  vim.ui.input({ prompt = "Enter a new branch name" }, function(user_input)
    if user_input == nil or user_input == "" then
      return
    end

    local cmd_str = string.format("G checkout -b %s", user_input)
    vim.cmd(cmd_str)
  end)
end, {
  desc = "Git: create new branch",
})

-- delete branch
keymap.set("n", "<leader>gbd", ":Git branch -D ", { desc = "Git: delete branch" })
