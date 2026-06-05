local M = {}

---@module 'battery.battery'

---@class battery.ParserModule
---@field check fun(): boolean
---@field get_battery_info_job fun(battery_status: battery.Status): any

---@type table<string, battery.ParserModule>
M.parsers = {
  powershell = require('battery.parsers.powershell'),
  pmset = require('battery.parsers.pmset'),
  powersupply = require('battery.parsers.powersupply'),
  acpi = require('battery.parsers.acpi'),
  termux_api = require('battery.parsers.termux-api'),
}

return M
