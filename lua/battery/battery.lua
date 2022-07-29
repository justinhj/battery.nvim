local M = {}

local job = require("plenary.job")

local battery_count = nil
local battery_percent = nil
local initialized = false
-- 1 is battery, 2 is power
local battery_status = nil

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

local windows_get_battery_percent_job = job:new({
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

local windows_get_battery_status_job = job:new({
  command = "powershell",
  args = { "(Get-CimInstance -ClassName Win32_Battery).BatteryStatus" },
  on_exit = function(r, return_value)
    print(vim.inspect(r))
    battery_status = tonumber(r:result()[1])
    print("battery status " .. battery_status)
  end,
})

local function get_battery_status_sync()
  windows_get_battery_status_job:start()
end

local windows_count_batteries_job = job:new({
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

local function windows_count_batteries(wait)
  windows_count_batteries_job:start()
  if wait then
    windows_count_batteries_job:wait()
  end
  return battery_count
end

local function windows_start_timer_job()
  -- TODO validate period is sane
  --    don't allow more than once per minute
  local wait_millis = update_period_seconds * 1000
  local timer = vim.loop.new_timer()
  timer:start(0, wait_millis, function()
    windows_count_batteries_job:after_success(function()
      print("batteries counted: " .. battery_count)
      if battery_count > 0 then
        print("got battery so...")
        windows_get_battery_status_job:and_then(windows_get_battery_percent_job)
        windows_get_battery_status_job:start()
      else
        print("no batter so no job")
      end
    end)
    windows_count_batteries_job:start()
  end)
end

local function get_charge_percent()
  return battery_percent
end

-- Discover and return the battery count
local function count_batteries()
  return battery_count
end

local function init(config)
  if not initialized then
    if vim.fn.has("win32") == 1 then
      -- Start a timer and do all of the battery discovery
      windows_start_timer_job()
    else
      vim.notify("No battery implementation for this platform")
    end
    initialized = true
  else
  end
end

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

M.count_batteries = count_batteries
M.get_charge_percent = get_charge_percent
M.init = init
M.get_status_line = get_status_line
M.get_battery_status_sync = get_battery_status_sync
return M
