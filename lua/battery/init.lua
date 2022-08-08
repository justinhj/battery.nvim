local M = {}

local battery = require("battery.battery")

M.setup = battery.setup
M.count_batteries = battery.count_batteries
M.get_status_line = battery.get_status_line
M.get_charge_percent = battery.get_charge_percent
M.is_charging = battery.is_charging

return M
