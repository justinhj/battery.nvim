-- Getting battery info with termux-battery-status. Requires Termux and Termux:API.
local M = {}

local log = require('util.log')

---@param result string | string[]
---@param battery_status BatteryStatus
local function parse_termux_battery_info(result, battery_status)
  local json_str = type(result) == 'table' and table.concat(result, '') or result
  local status = vim.json.decode(json_str)
  log.debug(status)

  battery_status.percent_charge_remaining = status.percentage
  battery_status.battery_count = 1 -- WARN: This might not always be true
  battery_status.ac_power = status.plugged:find("^PLUGGED_") -- String starts with "PLUGGED_"
  log.debug(battery_status)
end

---Create a job to get the battery info
---battery_status is a table to store the results in
---@param battery_status BatteryStatus
function M.get_battery_info_job(battery_status)
  return vim.system({ 'termux-battery-status' }, { text = true }, function(obj)
    if obj.code == 0 then
      parse_termux_battery_info(obj.stdout, battery_status)
      log.debug(battery_status)
    else
      vim.schedule(function()
        vim.notify('battery.nvim: Error getting battery info with termux-battery-status', vim.log.levels.ERROR)
      end)
    end
  end)
end

---Check if this parser would work in the current environment
---@return boolean
function M.check()
  return vim.fn.executable('termux-battery-status') == 1
end

return M
