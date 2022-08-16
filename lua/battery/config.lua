-- Manage configuration options

local M = {}

-- Some future options
-- vertical_icons (if false show horizontal)
-- show_charging_batter_icons

local default_config = {
  update_rate_seconds = 30,
  show_status_when_no_battery = true,
  show_plugged_icon = true,
  show_unplugged_icon = true,
  show_percent = true,
}

M.current = default_config

M.from_user_opts = function(user_opts)
  M.current = user_opts and vim.tbl_deep_extend("force", default_config, user_opts) or default_config
end

return M
