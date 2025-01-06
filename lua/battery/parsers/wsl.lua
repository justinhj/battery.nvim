-- Get battery info using PowerShell in WSL. Requires Windows Subsystem for Linux (WSL)

local M = {}

local J = require('plenary.job')
local L = require('plenary.log')
local log = L.new({ plugin = 'battery' })

local get_battery_info_powershell_command = {
  'Get-WmiObject -Class Win32_Battery | Select-Object -ExpandProperty EstimatedChargeRemaining',
}

---Parse the response from the battery info job and update
---the battery status
---@param result string[]
---@param battery_status BatteryStatus
local function parse_wsl_battery_info(result, battery_status)
    log.debug("WSL Battery Info Result: ", vim.inspect(result))
    local battery_info = result[1] and result[1]:match('%d+')
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
---@return unknown # Plenary job
function M.get_battery_info_job(battery_status)
  return J:new({
    command = '/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe',
    args = { '-Command', table.concat(get_battery_info_powershell_command, ' ') },
    on_exit = function(j, return_value)
      if return_value == 0 then
        parse_wsl_battery_info(j:result(), battery_status)
        log.debug(vim.inspect(battery_status))
      else
        log.error(vim.inspect(j:result()))
      end
    end,
  })
end

---Check if this parser would work in the current environment
---@return boolean
function M.check()
  return vim.fn.has 'wsl' == 1
end

return M