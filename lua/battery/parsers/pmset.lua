-- For those with pmset (Mac users) to get battery information
local M = {}

local log = require('util.log')

local get_battery_info_pmset_args = {
  '-g',
  'ps',
}

-- TODO: would be nice to unit test the parser
--[[ Sample output:

Without ac power connected you see...

Now drawing from 'Battery Power'
 -InternalBattery-0 (id=6094947)        86%; discharging; 4:29 remaining present: true

When ac power is connected you see...

Now drawing from 'AC Power'
 -InternalBattery-0 (id=6094947)	92%; charging; 0:44 remaining present: true
]]
--

---Parse the response from the battery info job and update
---the battery status
---@param result string | string[]
---@param battery_status BatteryStatus
local function parse_pmset_battery_info(result, battery_status)
  local count = 0
  local charge_total = 0
  local ac_power = nil

  local lines = type(result) == 'string' and vim.split(result, '\n') or result

  for _, line in ipairs(lines) do
    local found, _, charge = line:find('(%d+)%%')
    local discharge = line:find('discharging')
    if found then
      count = count + 1
      charge_total = charge_total + tonumber(charge)
      -- only the first battery is used to determine charging or not
      -- since they should all be the same
      if not ac_power then
        if discharge == nil then
          ac_power = true
        else
          ac_power = false
        end
      end
    end
  end
  if count > 0 then
    battery_status.percent_charge_remaining = math.floor(charge_total / count)
    battery_status.battery_count = count
    battery_status.ac_power = ac_power
  else
    battery_status.percent_charge_remaining = 100
    battery_status.battery_count = count
    battery_status.ac_power = false
  end
end

---Create a job to get the battery info
---battery_status is a table to store the results in
---@param battery_status BatteryStatus
function M.get_battery_info_job(battery_status)
  local cmd = { 'pmset' }
  for _, arg in ipairs(get_battery_info_pmset_args) do
    table.insert(cmd, arg)
  end
  return vim.system(cmd, { text = true }, function(obj)
    if obj.code == 0 then
      parse_pmset_battery_info(obj.stdout, battery_status)
      log.debug(battery_status)
    else
      log.error(obj.stderr)
      vim.schedule(function()
        vim.notify('battery.nvim: Error getting battery info with pmset', vim.log.levels.ERROR)
      end)
    end
  end)
end

---Check if this parser would work in the current environment
---@return boolean
function M.check()
  return vim.fn.executable('pmset') == 1
end

return M
