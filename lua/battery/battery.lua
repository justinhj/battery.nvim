local M = {}

local job = require("plenary.job")

local battery_count = nil
local battery_percent = nil
local initialized = false
local function temp()
  -- Create a timer handle (implementation detail: uv_timer_t).
  local timer = vim.loop.new_timer()
  local i = 0
  -- Waits 1000ms, then repeats every 750ms until timer:close().
  timer:start(1000, 750, function()
    print("timer invoked! i=" .. tostring(i))
    if i > 4 then
      timer:close() -- Always close handles to avoid leaks.
    end
    i = i + 1
  end)
  print("sleeping")
end
--TODO config
local update_period_seconds = 10

-- https://powershell.one/wmi/root/cimv2/win32_battery

-- TODO this returns the average if multiple batteries, it would be cool to handle the array
local windows_get_battery_percent_job = job:new({
  command = "powershell",
  args = {
    "Get-CimInstance -ClassName Win32_Battery | Measure-Object -Property EstimatedChargeRemaining -Average | Select-Object -ExpandProperty Average",
  },
  on_exit = function(r, return_value)
    if return_value == 0 then
      local bc = r:result()[1]
      battery_percent = bc
    else
      vim.notify("Unable to count batteries")
    end
  end,
})

local windows_sleep_job = job:new({
  command = "powershell",
  args = { "sleep", update_period_seconds },
})

local function windows_get_battery_percent(wait, rep)
  windows_get_battery_percent_job:after_success(function()
    print("Battery charge " .. battery_percent)
    if rep then
      windows_sleep_job:after(function()
        windows_get_battery_percent(wait, rep)
      end)
      windows_sleep_job:start()
    end
  end)
  windows_get_battery_percent_job:start()
  if wait then
    windows_get_battery_percent_job:wait()
  end
  return battery_percent
end

local windows_count_batteries_job = job:new({
  command = "powershell",
  args = { "@(Get-CimInstance win32_battery).Count" },
  on_exit = function(r, return_value)
    if return_value == 0 then
      local bc = r:result()[1]
      battery_count = bc
    else
      vim.notify("Unable to count batteries")
    end
  end,
})

local function windows_count_batteries(wait)
  windows_count_batteries_job:after_success(function()
    print("Battery count " .. battery_count)
  end)
  windows_count_batteries_job:start()
  if wait then
    windows_count_batteries_job:wait()
  end
  return battery_count
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
    -- initialize the things
    if vim.fn.has("win32") == 1 then
      windows_count_batteries(false)
      -- windows_get_battery_percent(false, true)
    end
    initialized = true
  else
  end
end

local function get_status_line()
  return battery_count
end

M.count_batteries = count_batteries
M.get_charge_percent = get_charge_percent
M.init = init
M.get_status_line = get_status_line

return M
