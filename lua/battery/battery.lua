local M = {}

local L = require("plenary.log")
local powershell = require("battery.powershell")
-- TODO pmset

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

-- TODO maybe store the update time here?
local battery_status = {
  percent_charge_remaining = nil,
  battery_count = nil,
  ac_power = nil,
}

-- Gets the last updated battery information
-- TODO may add the ability to ask for it to be updated right now
local function get_battery_status()
  return battery_status
end

-- This maps to a timer sequence number in the utils module so the user
-- can reload the battery module and we can detect the old job is still running.
local timer = nil

-- Select the battery info job to run based on platform and what programs
-- are available
local function select_job()
  if vim.fn.has("win32") and vim.fn.executable("powershell") == 1 then
    log.debug("windows powershell battery job")
    return powershell.get_battery_info_job
  elseif vim.fn.executable("pmset") == 1 then
    log.debug("pmset battery job")
  else
    log.debug("no battery job")
  end
end

local function timer_loop()
  vim.defer_fn(function()
    log.debug(timer .. " is running now")
    local job_function = select_job()

    if job_function then
      job_function(battery_status):start()
    end

    -- When the user reloads the battery module the job can just keep running. In order to stop it
    -- the user must call stop_timer. All this does is increments the timer sequence number. Whenever
    -- the running job knows that the sequence number no longer matches it will stop running,
    -- regardless of whether the user made a new job or not.

    if require("util.timers").get_current() ~= timer then
      log.info("Update job stopping due to newer timer.")
    else
      timer_loop()
    end
  end, update_rate_seconds * 1000)
end

local function stop_timer()
  timer = require("util.timers").get_next()
  log.debug("Incremented timer to " .. timer .. " to stop the battery update job")
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
M.get_battery_status = get_battery_status
M.get_status_line = get_status_line
return M
