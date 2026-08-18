
require("telescope").load_extension("project")

local project_actions = require("telescope._extensions.project.actions")

require('telescope').setup ({
  extensions = {
    project = {
      -- base_dirs = {
      --   '~/dev/src',
      --   {'~/dev/src2'},
      --   {'~/dev/src3', max_depth = 4},
      --   {path = '~/dev/src4'},
      --   {path = '~/dev/src5', max_depth = 2},
      -- },
      hidden_files = false, -- default: false
      theme = "dropdown",
      order_by = "asc",
      search_by = "title",
      sync_with_nvim_tree = false, -- default false
      -- default for on_project_selected = find project files
      -- on_project_selected = function(prompt_bufnr)
      --   -- Do anything you want in here. For example:
      --   project_actions.change_working_directory(prompt_bufnr, false)
      --   require("harpoon.ui").nav_file(1)
      -- end,
      mappings = {
        n = {
          ['d'] = project_actions.delete_project,
          ['r'] = project_actions.rename_project,
          ['c'] = project_actions.add_project,
          ['C'] = project_actions.add_project_cwd,
          ['f'] = project_actions.find_project_files,
          ['b'] = project_actions.browse_project_files,
          ['s'] = project_actions.search_in_project_files,
          ['R'] = project_actions.recent_project_files,
          ['w'] = project_actions.change_working_directory,
          ['o'] = project_actions.next_cd_scope,
        },
        i = {
          ['<c-d>'] = project_actions.delete_project,
          ['<c-v>'] = project_actions.rename_project,
          ['<c-a>'] = project_actions.add_project,
          ['<c-A>'] = project_actions.add_project_cwd,
          ['<c-f>'] = project_actions.find_project_files,
          ['<c-b>'] = project_actions.browse_project_files,
          ['<c-s>'] = project_actions.search_in_project_files,
          ['<c-r>'] = project_actions.recent_project_files,
          ['<c-l>'] = project_actions.change_working_directory,
          ['<c-o>'] = project_actions.next_cd_scope,
          ['<c-w>'] = project_actions.change_workspace,
        }
      }
    }
  }
})
