local M = {}

local battery = require("battery.battery")

M.setup = battery.setup
M.get_battery_status = battery.get_battery_status
M.get_status_line = battery.get_status_line
return M
