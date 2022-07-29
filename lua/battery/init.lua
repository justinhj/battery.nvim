local M = {}

local job = require("plenary.job")
local battery = require("battery.battery")

local config = {}

local function setup(args)
  -- TODO validate the config and have config variables
  config = args
  battery.init(config)
end

M.setup = setup
M.count_batteries = battery.count_batteries
M.get_status_line = battery.get_status_line
M.get_battery_status_sync = battery.get_battery_status_sync

return M
