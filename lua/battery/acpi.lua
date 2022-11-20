-- Support for linux via acpi
-- Requires apci to be installed, for example:
--   apt install acpi

local J = require("plenary.job")
local L = require("plenary.log")
local BC = require("util.chooser")
local config = require("battery.config")
local log = L.new({ plugin = "battery" })

-- TODO would be nice to unit test the parser
--[[ Sample output:

Without ac power connected you see...

Battery 0: Discharging, 48%, 02:21:28 remaining

When ac power is connected you see...

Battery 0: Charging, 47%, 01:09:53 until charged

]]
--

-- Parse the response from the battery info job and update
-- the battery status
-- To fix this issue I have removed the average battery calculation
-- and instead will report the first battery found. Users are finding
-- that their peripheral batteries are included by acpi which makes
-- the plugin useless.
-- https://github.com/justinhj/battery.nvim/issues/12
local function parse_acpi_battery_info(result, battery_status)
  local count = 0
  local ac_power = nil

  local percents = {}

  for _, line in ipairs(result) do
    local found, _, charge = line:find("(%d+)%%")
    local discharge = line:find("Discharging")
    if found then
      count = count + 1
      table.insert(percents, tonumber(charge))
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
    local chosen_percent = BC.battery_chooser(percents, config.current.multiple_battery_selection)
    battery_status.percent_charge_remaining = chosen_percent
    battery_status.battery_count = count
    battery_status.ac_power = ac_power
  else
    battery_status.percent_charge_remaining = 100
    battery_status.battery_count = count
    battery_status.ac_power = false
  end
end

-- Create a plenary job to get the battery info
-- battery_status is a table to store the results in
local function get_battery_info_job(battery_status)
  return J:new({
    command = "acpi",
    on_exit = function(r, return_value)
      if return_value == 0 then
        parse_acpi_battery_info(r:result(), battery_status)
        log.debug(vim.inspect(battery_status))
      else
        log.error(vim.inspect(r:result()))
        vim.schedule(function()
          vim.notify("battery.nvim: Error getting battery info with acpi", vim.log.levels.ERROR)
        end)
      end
    end,
  })
end

return {
  get_battery_info_job = get_battery_info_job,
}
