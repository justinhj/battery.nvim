local M = {}

local J = require("plenary.job")
local L = require("plenary.log")

--WIP config
-- TODO check for icons and if not available fallback to text
-- TODO allow user to select no icons
-- TODO maybe autodetect icons?
-- TODO why is battery percent lower than vim version?
local update_rate_seconds = 30

local log = L.new({ plugin = "battery" })

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
battery percent job which runs every update_rate_seconds

TODO mac os version
TODO linux version
TODO handle multiple batteries properly
]]
--

local function get_charge_percent()
  print("deprecated")
end

local function is_charging()
  print("deprecated")
end

-- Discover and return the battery count
local function count_batteries()
  print("deprecated")
end

local timer = nil
local stop = nil

local function timer_loop()
  vim.defer_fn(function()
    log.debug(timer .. " is running now")

    -- Two ways to stop the timer ... setting the stop variable to true
    -- or if the code is reloaded the user has no access to the timer
    -- it will stop if the timer var doesn't match the global one
    -- in timers

    if require("util.timers").get_current() ~= timer then
      stop = true
      log.info("stopping as someone else is using timer")
    end

    if stop == true then
      log.debug("Stopping")
      stop = false
    else
      timer_loop()
    end
  end, update_rate_seconds * 1000)
end

local function stop_timer()
  log.debug("Stop timer. timer number is " .. timer)
  stop = true
end

local function start_timer()
  timer = require("util.timers").get_next()
  timer_loop()
  log.debug("start timer seq no " .. timer)
end

local function setup(config)
  if config then
    local config_update_rate_seconds = tonumber(config.update_rate_seconds)
    if config_update_rate_seconds then
      if config_update_rate_seconds < 10 then
        vim.notify("Update rate less than 10 seconds is not recommended", vim.log.levels.WARN)
      end
      update_rate_seconds = config_update_rate_seconds
    end
  end

  start_timer()
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
  -- -- TODO implement some options
  -- --    allow toggle of whether to show something when no battery present
  -- if battery_percent then
  --   if battery_status == 2 then
  --     return discharging_battery_icon_for_percent(battery_percent) .. plugged_icon .. " " .. battery_percent .. "%%"
  --   else
  --     return discharging_battery_icon_for_percent(battery_percent) .. " " .. battery_percent .. "%%"
  --   end
  -- else
  --   return "?" -- TODO maybe an hourglass or spinner
  -- end
  return "?"
end

M.setup = setup
M.count_batteries = count_batteries
M.get_charge_percent = get_charge_percent
M.is_charging = is_charging
M.get_status_line = get_status_line
return M
