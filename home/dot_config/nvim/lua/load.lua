local utils = require "utils"

local function get_config_dir()
  local lvim_config_dir = os.getenv "LUNARVIM_CONFIG_DIR"
  if not lvim_config_dir then
    return vim.call("stdpath", "config")
  end
  return lvim_config_dir
end

local user_config_dir = get_config_dir()
local user_config_file = utils.join_paths(user_config_dir, "config.lua")

local config_path = user_config_file
local ok, err = pcall(dofile, config_path)

if not ok then
  if utils.is_file(user_config_file) then
    vim.schedule(function()
      vim.notify_once(
      string.format("Invalid configuration: ", err)
      )
    end)
  else
    vim.schedule(function()
      vim.notify_once(
      string.format("User-configuration not found. Creating an example configuration in %s", config_path)
      )
    end)
  end
end

if not _G.obsidian_opt_workspace then
  _G.obsidian_opt_workspace = {}
  _G.enable_obsidian = false
end

if not _G.enable_transparent then
  _G.enable_transparent = false
end

if not _G.colorschema then
  _G.colorschema = 'onedark'
end
