-- Get battery info using PowerShell in WSL. Requires Windows Subsystem for Linux (WSL)

local M = {}

local J = require('plenary.job')
local L = require('plenary.log')
local log = L.new({ plugin = 'battery' })

-- Convert status code from PowerShell to whether AC power is connected
local status_code_to_ac_power = {
  [1] = false, -- Battery Power
  [2] = true, -- AC Power
  [3] = true, -- Fully Charged
  [4] = false, -- Low
  [5] = false, -- Critical
  [6] = true, -- Charging
  [7] = true, -- Charging and High
  [8] = true, -- Charging and Low
  [9] = true, -- Charging and Critical
  [10] = false, -- Undefined, we don't know so let's assume false
  [11] = true, -- Partially Charged
}
local get_battery_info_powershell_command = {
    'Get-CimInstance -ClassName Win32_Battery | \
 Select-Object -Property EstimatedChargeRemaining,BatteryStatus',
}

---Parse the response from the battery info job and update
---the battery status
---@param result string[]
---@param battery_status BatteryStatus
local function parse_wsl_battery_info(result, battery_status)
  local battery_info = result[1]:match('%d+')
  if battery_info then
    battery_status.percent_charge_remaining = tonumber(battery_info)
    battery_status.ac_power = status_code_to_ac_power[tonumber(battery_info)]
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
    args = get_battery_info_powershell_command,
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