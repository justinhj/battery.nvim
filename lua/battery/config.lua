-- Manage configuration options

local M = {}

---@class Config
---@field update_rate_seconds integer
---@field show_status_when_no_battery boolean
---@field show_plugged_icon boolean
---@field show_unplugged_icon boolean
---@field show_percent boolean
---@field vertical_icons boolean
---@field multiple_battery_selection "max" | "maximum" | "min" | "minimum" | integer

-- TODO: Some future options
-- vertical_icons (if false show horizontal)
-- show_charging_battery_icons

---@type Config
local default_config = {
  update_rate_seconds = 30,
  show_status_when_no_battery = true,
  show_plugged_icon = true,
  show_unplugged_icon = true,
  show_percent = true,
  vertical_icons = true,
  multiple_battery_selection = 1,
}

M.current = default_config

---@param user_opts Config
function M.from_user_opts(user_opts)
  M.current = user_opts and vim.tbl_deep_extend('force', default_config, user_opts) or default_config
end

return M
