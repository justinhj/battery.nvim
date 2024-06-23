-- Get battery info using /sys/class/power_supply/* files. Requires Linux

local J = require("plenary.job")
local L = require("plenary.log")
local log = L.new({ plugin = "battery" })

-- Convert lowercase status from `/sys/class/power_supply/BAT?/status`
-- to whether AC power is connected
local status_to_ac_power = {
    ["full"] = true,
    ["charging"] = true,
    ["discharging"] = false,
    ["unknown"] = false,
}

-- Parse the response from the battery info job and update
-- the battery status
local function parse_powersupply_battery_info(battery_paths, battery_status)
  local count = #battery_paths

  if count > 0 then
    -- Set battery count
    battery_status.battery_count = count

    -- Read capacity file of first battery
    local f = io.open(battery_paths[1] .. "/capacity", "r")
    if not f then
      return -- File doesn't exist
    end
    battery_status.percent_charge_remaining = f:read("n")
    f:close()

    -- Read status file of first battery
    f = io.open(battery_paths[1] .. "/status", "r")
    if not f then
      return -- File doesn't exist
    end
    local status = f:read("l"):lower() -- Read line (without newline character), to lowercase
    battery_status.ac_power = status_to_ac_power[status]
    f:close()
  else
    battery_status.percent_charge_remaining = 100
    battery_status.battery_count = count
    battery_status.ac_power = true
  end
end

local function get_battery_info_job(battery_status)
  return J:new({
    -- Find symbolic links in /sys/class/power_supply that start with BAT
    -- These are the directories containing information files for each battery
    command = "find",
    args = {
      "/sys/class/power_supply/",
      "-type", "l",
      "-name", "BAT*",
    },
    on_exit = function (j, return_value)
      if return_value == 0 then
        parse_powersupply_battery_info(j:result(), battery_status)
        log.debug(vim.inspect(battery_status))
      else
        log.error(vim.inspect(j:result()))
      end
    end
  })
end

return {
  get_battery_info_job = get_battery_info_job
}
