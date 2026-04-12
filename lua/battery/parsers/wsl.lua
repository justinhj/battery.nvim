-- Get battery info using PowerShell in WSL. Requires Windows Subsystem for Linux (WSL)

local M = {}

local log = require('util.log')

local get_battery_info_powershell_command = 'Get-WmiObject -Class Win32_Battery | Select-Object -ExpandProperty EstimatedChargeRemaining'

---Parse the response from the battery info job and update
---the battery status
---@param result string | string[]
---@param battery_status BatteryStatus
local function parse_wsl_battery_info(result, battery_status)
    log.debug("WSL Battery Info Result: ", result)
    local line = type(result) == 'table' and result[1] or result
    local battery_info = line and line:match('%d+')
    if battery_info then
      battery_status.percent_charge_remaining = tonumber(battery_info)
      battery_status.ac_power = false
      battery_status.battery_count = 1
    else
      battery_status.percent_charge_remaining = 100
      battery_status.ac_power = true
      battery_status.battery_count = 0
    end
end

---@param battery_status BatteryStatus
function M.get_battery_info_job(battery_status)
  return vim.system({
    '/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe',
    '-Command',
    get_battery_info_powershell_command,
  }, { text = true }, function(obj)
    if obj.code == 0 then
      parse_wsl_battery_info(obj.stdout, battery_status)
      log.debug(battery_status)
    else
      log.error(obj.stderr)
    end
  end)
end

---Check if this parser would work in the current environment
---@return boolean
function M.check()
  return vim.fn.has 'wsl' == 1
end

return M