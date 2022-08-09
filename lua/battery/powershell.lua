-- Getting battery info with Powershell. Requires Windows.
local J = require("plenary.job")
local L = require("plenary.log")

local log = L.new({ plugin = "battery.powershell" })

-- Info about battery based on Status field of win32 Battery
-- see https://powershell.one/wmi/root/cimv2/win32_battery#battery-status
-- 3rd field is whether AC is attached or not. nil for "who knows?"
-- Note that I'm guessing here.
local win32_battery_status_info = {
  { "Battery Power", false },
  { "AC Power", true },
  { "Fully Charged", true },
  { "Low", true },
  { "Critical", false },
  { "Charging", true },
  { "Charging and High", true },
  { "Charging and Low", true },
  { "Charging and Critical", true },
  { "Undefined", nil },
  { "Partially Charged", true },
}

local get_battery_info_powershell_command = {
  "Get-CimInstance -ClassName Win32_Battery | Select-Object -Property EstimatedChargeRemaining,BatteryStatus",
}

-- TODO would be nice to unit test the parser
--[[ Sample output:
{ "",
  "EstimatedChargeRemaining BatteryStatus",
  "------------------------ -------------",
  "                      92             1",
  "",
  "" }
]]
--

-- Parse the response from the batter info job and update
-- the battery status
local function parse_powershell_battery_info(result, battery_status)
  local count = 0
  local charge_total = 0
  local ac_power = nil

  for _, line in ipairs(result) do
    local found, _, charge, status = line:find("(%d+)%s+(%d+)")
    if found then
      count = count + 1
      charge_total = charge_total + tonumber(charge)
      -- only the first battery is used to determine charging or not
      -- since they should all be the same
      if not ac_power then
        local info = win32_battery_status_info[status]
        if info ~= nil and info[2] ~= nil then
          ac_power = info[2]
        else
          ac_power = false -- we don't know so let's guess no
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
    battery_status.ac_power = true
  end
end

-- Create a plenary job to get the battery info
-- battery_status is a table to store the results in
local function get_battery_info_job(battery_status)
  return J:new({
    command = "powershell",
    args = get_battery_info_powershell_command,
    on_exit = function(r, return_value)
      if return_value == 0 then
        parse_powershell_battery_info(r:result(), battery_status)
        log.debug(vim.inspect(battery_status))
      else
        vim.schedule(function()
          vim.notify("battery.nvim: Error getting battery info", vim.log.levels.ERROR)
        end)
      end
    end,
  })
end

return {
  get_battery_info_job = get_battery_info_job,
}
