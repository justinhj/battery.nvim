-- Getting battery info with Powershell. Requires Windows.
local M = {}

local log = require('battery.util.log')

-- Whether the AC power is connected based on Status field of win32 Battery
-- see https://powershell.one/wmi/root/cimv2/win32_battery#battery-status
-- Note that I'm guessing here.
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

-- For a laptop with two batteries, the returned json would be in this format:
-- [
--   {
--     "EstimatedChargeRemaining": 93,
--     "BatteryStatus": 2
--   },
--   {
--     "EstimatedChargeRemaining": 93,
--     "BatteryStatus": 2
--   }
-- ]
local get_battery_info_powershell_command =
  'ConvertTo-Json @(Get-CimInstance -ClassName Win32_Battery | Select-Object -Property EstimatedChargeRemaining,BatteryStatus)'

---Parse the response json from the battery info job and update
---the battery status
---@param result string | string[]
---@param battery_status battery.Status
local function parse_powershell_battery_info(result, battery_status)
  -- Decode the json response into a list of batteries

  local json_str = type(result) == 'table' and table.concat(result, '') or result

  -- Attempt to decode the JSON safely
  local success, batteries = pcall(vim.json.decode, json_str)

  -- If decoding fails, batteries will be nil, and we can handle it gracefully
  if not success or batteries == nil then
    batteries = {} -- Default to an empty table
  end

  local count = #batteries
  local charge_total = 0

  -- Add up total charge
  for _, b in ipairs(batteries) do
    charge_total = charge_total + b['EstimatedChargeRemaining']
  end

  -- only the first battery is used to determine charging or not
  -- since they should all be the same
  local status = (
    batteries[1] and batteries[1]['BatteryStatus'] -- Get BatteryStatus if present
    or 2 -- Default to 2 ("AC Power")
  )
  local ac_power = status_code_to_ac_power[status]

  if count > 0 then
    battery_status.percent_charge_remaining = math.floor(charge_total / count)
    battery_status.battery_count = count
    battery_status.ac_power = ac_power
  else
    battery_status.percent_charge_remaining = 100
    battery_status.battery_count = count
    battery_status.ac_power = true
  end
end

---Create a job to get the battery info
---battery_status is a table to store the results in
---@param battery_status battery.Status
function M.get_battery_info_job(battery_status)
  return vim.system({ 'powershell', get_battery_info_powershell_command }, { text = true }, function(obj)
    if obj.code == 0 then
      parse_powershell_battery_info(obj.stdout, battery_status)
      log.debug(battery_status)
    else
      vim.schedule(function()
        vim.notify('battery.nvim: Error getting battery info with Powershell', vim.log.levels.ERROR)
      end)
    end
  end)
end

---Check if this parser is supported in the current environment.
---Additionally returns a `reason` if the OS is correct, but it isn't supported for another reason.
---@return boolean supported
---@return string? reason
function M.check()
  if vim.fn.has('win32') == 0 then
    return false
  elseif vim.fn.executable('powershell') == 0 then
    return false, '`powershell` is not executable. There may be a problem with your $PATH.'
  else
    return true
  end
end

return M
