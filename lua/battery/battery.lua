local M = {}

local job = require("plenary.job")

local battery_count = nil
local battery_percent = nil
local initialized = false
local battery_is_charging = nil

-- On init these are set based on installed programs
local count_batteries_job = nil
local get_charge_percent_job = nil
local is_charging_job = nil -- TODO power or not

-- https://www.nerdfonts.com/cheat-sheet
local no_battery_icon = "" -- "ﲾ"
local charging_battery_icons = {
  { "", 20 },
  { "", 30 },
  { "", 40 },
  { "", 60 },
  { "", 80 },
  { "", 90 },
  { "", 100 },
}
local plugged_icon = "ﮣ"
local unplugged_icon = "ﮤ"
local discharging_battery_icons = {
  { "", 10 },
  { "", 20 },
  { "", 30 },
  { "", 40 },
  { "", 50 },
  { "", 60 },
  { "", 70 },
  { "", 80 },
  { "", 90 },
  { "", 100 },
}
--[[
battery_count and battery_percent are variables that get updated by jobs on a timer.
When the plugin is setup it starts the battery count job, which runs once, and the
battery percent job which runs every update_period_seconds

TODO mac os version
TODO linux version
TODO handle multiple batteries properly
]]
--

--TODO config
-- TODO check for icons and if not available fallback to text
-- TODO allow user to select no icons
-- TODO maybe autodetect icons?
-- TODO why is battery percent lower than vim version?
local update_period_seconds = 30

-- get battery status. 1 is battery and 2 is AC power (there are others)
-- Get-CimInstance -ClassName Win32_Battery | Select-Object -Property BatteryStatus

-- https://powershell.one/wmi/root/cimv2/win32_battery

-- Get battery percent using powershell
local function powershell_get_battery_percent_job()
  return job:new({
    command = "powershell",
    args = {
      "Get-CimInstance -ClassName Win32_Battery | Measure-Object -Property EstimatedChargeRemaining -Average | Select-Object -ExpandProperty Average",
    },
    on_exit = function(r, return_value)
      if return_value == 0 then
        local bc = r:result()[1]
        battery_percent = bc
        print("percent " .. battery_percent)
      else
        vim.notify("Get battery percent failed. Code:" .. return_value, vim.log.levels.WARN)
      end
    end,
  })
end

-- Create a job that can get the battery status using powershell
local function powershell_get_battery_status_job()
  return job:new({
    command = "powershell",
    args = { "(Get-CimInstance -ClassName Win32_Battery).BatteryStatus" },
    on_exit = function(r, return_value)
      local status = tonumber(r:result()[1])
      if status == 2 then
        battery_is_charging = true
      else
        battery_is_charging = false -- TODO some device drivers may have more complex behaviour, see docs
      end
      print("battery status " .. vim.inspect(battery_is_charging))
    end,
  })
end

local function get_battery_status()
  if not initialized then
    vim.notify("battery.nvm not initialized... run setup", vim.log.levels.ERROR)
  else
    is_charging_job:sync()
    return battery_is_charging
  end
end

local function powershell_count_batteries_job()
  return job:new({
    command = "powershell",
    args = { "@(Get-CimInstance win32_battery).Count" },
    on_exit = function(r, return_value)
      if return_value == 0 then
        local bc = r:result()[1]
        battery_count = tonumber(bc)
      else
        vim.notify("Unable to count batteries")
      end
    end,
  })
end

local function pmset_count_batteries_in_result(results)
  local count = 0
  for _, line in ipairs(results) do
    if line:match("InternalBattery") then
      count = count + 1
    end
  end
  return count
end

--[[
To count the batteries run pmset to get the output below then count the number of
occurences of InternalBattery

Note that the percentage change is also found here so it's probably a later move to
cache this result and simply parse it when getting the percentage.

> pmset -g ps
Now drawing from 'Battery Power'
 -InternalBattery-0 (id=6094947)	48%; discharging; 3:53 remaining present: true
]]
--
local function pmset_count_batteries_job()
  return job:new({
    command = "pmset",
    args = { "-g", "ps" },
    on_exit = function(r, return_value)
      if return_value == 0 then
        battery_count = pmset_count_batteries_in_result(r:result())
      else
        print("Unable to count batteries: " .. return_value)
      end
    end,
  })
end

local function pmset_get_charge_percent_from_result(results)
  local batteries = 0
  local percent_sum = 0
  for _, line in ipairs(results) do
    print("line " .. line)
    local _, _, p = line:find("([0-9]+)%%")
    if p then
      print("p " .. p)
      batteries = batteries + 1
      percent_sum = percent_sum + tonumber(p)
    end
  end
  if batteries == 0 then
    return 0
  else
    return math.floor(percent_sum / batteries)
  end
end

local function pmset_get_charge_percent_job()
  return job:new({
    command = "pmset",
    args = { "-g", "ps" },
    on_exit = function(r, return_value)
      if return_value == 0 then
        battery_percent = pmset_get_charge_percent_from_result(r:result())
      else
        print("Unable to count batteries: " .. return_value)
      end
    end,
  })
end

local function pmset_get_battery_status_job()
  print("oh no!")
end

local function start_timer_job()
  -- TODO validate period is sane
  --    don't allow more than once per minute
  local wait_millis = update_period_seconds * 1000
  local timer = vim.loop.new_timer()

  local count_batteries_job = powershell_count_batteries_job()
  local battery_status_job = powershell_get_battery_status_job()
  local battery_percentage_job = powershell_get_battery_percent_job()

  timer:start(0, wait_millis, function()
    count_batteries_job:after_success(function()
      print("batteries counted: " .. battery_count)
      if battery_count > 0 then
        print("got battery so...")
        battery_status_job:and_then(battery_percentage_job)
        battery_status_job:start()
      else
        print("no batter so no job")
      end
    end)
    count_batteries_job:start()
  end)
end

local function get_charge_percent()
  if not initialized then
    vim.notify("battery.nvm not initialized... run setup", vim.log.levels.ERROR)
  else
    get_charge_percent_job:sync()
    return battery_percent
  end
end

local function is_charging()
  if not initialized then
    vim.notify("battery.nvm not initialized... run setup", vim.log.levels.ERROR)
  else
    is_charging_job:sync()
    return battery_is_charging
  end
end

-- Discover and return the battery count
local function count_batteries()
  if not initialized then
    vim.notify("battery.nvm not initialized... run setup", vim.log.levels.ERROR)
  else
    count_batteries_job:sync()
    return battery_count
  end
end

-- TODO for pmset consider consolidate to one job or
-- cache result of job and use for rest
local function init(config)
  if not initialized then
    if vim.fn.executable("powershell") == 1 then
      count_batteries_job = powershell_count_batteries_job()
      get_charge_percent_job = powershell_get_battery_percent_job()
      is_charging_job = powershell_get_battery_status_job() -- TODO naming consistency
    elseif vim.fn.executable("pmset") == 1 then
      count_batteries_job = pmset_count_batteries_job()
      get_charge_percent_job = pmset_get_charge_percent_job()
      is_charging_job = pmset_get_battery_status_job()
    end

    -- if vim.fn.has("win32") == 1 then
    --   -- Start a timer and do all of the battery discovery
    --   start_timer_job()
    -- else
    --   vim.notify("battery.nvim - No battery implementation for this platform", vim.log.levels.WARN)
    -- end
    initialized = true
  else
  end
end

-- Convert percentage change to discharging icon
local function discharging_battery_icon_for_percent(p)
  for _, icon in ipairs(discharging_battery_icons) do
    if tonumber(p) <= tonumber(icon[2]) then
      return icon[1]
    end
  end
  vim.notify("No icon found for percentage " .. p)
  return "!"
end

local function get_status_line()
  -- TODO implement some options
  --    allow toggle of whether to show something when no battery present
  if battery_percent then
    if battery_status == 2 then
      return discharging_battery_icon_for_percent(battery_percent) .. plugged_icon .. " " .. battery_percent .. "%%"
    else
      return discharging_battery_icon_for_percent(battery_percent) .. " " .. battery_percent .. "%%"
    end
  else
    return "?" -- TODO maybe an hourglass or spinner
  end
end

M.init = init
M.count_batteries = count_batteries
M.get_charge_percent = get_charge_percent
M.is_charging = is_charging
M.get_status_line = get_status_line
return M
