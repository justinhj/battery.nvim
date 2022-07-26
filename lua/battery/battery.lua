local M = {}

local job = require("plenary.job")

local battery_count = nil
local initialized = false

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

-- Discover and return the battery count
local function count_batteries()
  return battery_count
end

local function init(config)
  if not initialized then
    -- initialize the things
    if vim.fn.has("win32") == 1 then
      windows_count_batteries(false)
    end
    initialized = true
  else
  end
end

local function get_status_line()
  return battery_count
end

M.count_batteries = count_batteries
M.init = init
M.get_status_line = get_status_line

return M
