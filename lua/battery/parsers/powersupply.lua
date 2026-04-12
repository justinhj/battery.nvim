-- Get battery info using /sys/class/power_supply/* files. Requires Linux

local M = {}

local log = require('util.log')
local BC = require('util.chooser')
local config = require('battery.config')
local file = require('util.file')

-- Convert lowercase status from `/sys/class/power_supply/BAT?/status`
-- to whether AC power is connected
local status_to_ac_power = {
  ['full'] = true,
  ['charging'] = true,
  ['discharging'] = false,
  ['unknown'] = false, -- We don't know, so assume false
}

---Parse the response from the battery info job and update
---the battery status
---@param result string | string[]
---@param battery_status BatteryStatus
local function parse_powersupply_battery_info(result, battery_status)
  local battery_paths = type(result) == 'string' and vim.split(result, '\n', { trimempty = true }) or result
  local path_count = #battery_paths
  local battery_count = 0

  if path_count > 0 then
    -- Read capacities of each battery
    local percents = {}
    for _, path in ipairs(battery_paths) do
      local f = io.open(path .. '/capacity', 'r')
      if f then
        local charge = f:read('n')
        if charge then
          battery_count = battery_count + 1
          table.insert(percents, charge)
        end
        f:close()
      end
    end

    -- Read status file of first battery
    local f = io.open(battery_paths[1] .. '/status', 'r')
    local status
    if f then
      -- Read line (without newline character, with a default of unknown), to lowercase
      status = (f:read('l') or 'unknown'):lower()
      f:close()
    else
      status = 'unknown'
    end
    battery_status.ac_power = status_to_ac_power[status]
    -- Choose a percent
    local chosen_percent = BC.battery_chooser(percents, config.current.multiple_battery_selection)
    battery_status.percent_charge_remaining = chosen_percent
    -- Set battery count
    battery_status.battery_count = battery_count
  else
    battery_status.ac_power = true
    battery_status.percent_charge_remaining = 100
    battery_status.battery_count = path_count
  end
end

---@param battery_status BatteryStatus
function M.get_battery_info_job(battery_status)
  return vim.system({
    'find',
    '/sys/class/power_supply/',
    '-type',
    'l',
    '-name',
    'BAT*',
  }, { text = true }, function(obj)
    if obj.code == 0 then
      parse_powersupply_battery_info(obj.stdout, battery_status)
      log.debug(battery_status)
    else
      log.error(obj.stderr)
    end
  end)
end

---Check if this parser would work in the current environment
---@return boolean
function M.check()
  return file.is_readable_directory('/sys/class/power_supply/') and vim.fn.has('wsl') == 0
end

return M
