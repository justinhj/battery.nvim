local M = {}

local L = require('plenary.log')
local config = require('battery.config')
local parsers = require('battery.parsers')
local icons = require('battery.icons')

-- TODO: check for icons and if not available fallback to text
-- TODO: allow user to select no icons
-- TODO: maybe autodetect icons?

local log = L.new({ plugin = 'battery' })

-- TODO: maybe store the update time here?

---@class BatteryStatus
---@field percent_charge_remaining? integer
---@field battery_count? integer
---@field ac_power? boolean
---@field method? string
local battery_status = {
  battery_count = nil,
  ac_power = nil,
  method = nil,
  percent_charge_remaining = nil,
}

---Gets the last updated battery information
---TODO: may add the ability to ask for it to be updated right now
---@return BatteryStatus
function M.get_battery_status()
  return battery_status
end

---This maps to a timer sequence number in the utils module so the user
---can reload the battery module and we can detect the old job is still running.
---@type integer?
local timer = nil

---Select the battery info job to run based on platform and what programs
---are available
---@return (fun(battery_status: BatteryStatus): any)?
---@return string?
local function select_job()
  for method, parser_module in pairs(parsers.parsers) do
    if parser_module.check() then
      log.debug('using '..method..' method')
      return parser_module.get_battery_info_job, method
    end
  end

  -- No suitable parser was found.
  log.debug('no parser found')
  return nil, nil
end

---This is used for the health check
---@return string?
function M.get_method()
  local method = battery_status.method
  if method == nil then
    _, method = select_job()
  end
  return method
end

local function timer_loop()
  vim.defer_fn(function()
    log.debug(timer .. ' is running now')
    local job_function, method = select_job()
    battery_status.method = method
    log.debug('using method ' .. (method or 'nil'))

    if job_function then
      job_function(battery_status):start()
    end

    -- When the user reloads the battery module the job can just keep running. In order to stop it
    -- the user must call stop_timer. All this does is increments the timer sequence number. Whenever
    -- the running job knows that the sequence number no longer matches it will stop running,
    -- regardless of whether the user made a new job or not.

    if require('util.timers').get_current() ~= timer then
      log.info('Update job stopping due to newer timer.')
    else
      timer_loop()
    end
  end, config.current.update_rate_seconds * 1000)
end

-- local function stop_timer()
--   timer = require("util.timers").get_next()
--   log.debug("Incremented timer to " .. timer .. " to stop the battery update job")
-- end

local function start_timer()
  timer = require('util.timers').get_next()

  -- Always call the job immediately before starting the timed loop
  local job_function, method = select_job()
  battery_status.method = method
  log.debug('using method: ' .. (method or 'nil'))

  if job_function then
    job_function(battery_status):start()
  end

  timer_loop()
  log.debug('start timer seq no ' .. timer)
end

---@param user_opts Config
function M.setup(user_opts)
  config.from_user_opts(user_opts)

  local config_update_rate_seconds = tonumber(config.current.update_rate_seconds)
  if config_update_rate_seconds then
    if config_update_rate_seconds < 10 then
      vim.notify('Update rate less than 10 seconds is not recommended', vim.log.levels.WARN)
    end
  end

  start_timer()
end

---@return string
function M.get_status_line()
  if battery_status.battery_count == nil then
    return icons.specific.unknown
  else
    if battery_status.battery_count == 0 then
      if config.current.show_status_when_no_battery == true then
        return icons.specific.no_battery
      else
        return ''
      end
    else
      local ac_power = battery_status.ac_power
      local battery_percent = battery_status.percent_charge_remaining
      if not battery_percent then
        log.error(
'battery_status.percent_charge_remaining is nil, \
there is probably something wrong with the current \
parser implementation.'
        )
        battery_percent = 100
      end

      local plug_icon = ''
      if ac_power and config.current.show_plugged_icon then
        plug_icon = icons.specific.plugged
      elseif not ac_power and config.current.show_unplugged_icon then
        plug_icon = icons.specific.unplugged
      end

      local percent = ''
      if config.current.show_percent == true then
        percent = ' ' .. battery_percent .. '%%'
      end

      local icon
      if config.current.vertical_icons == true then
        icon = icons.discharging_battery_icon_for_percent(battery_percent)
      else
        icon = icons.horizontal_battery_icon_for_percent(battery_percent)
      end

      return icon .. plug_icon .. percent
    end
  end
end

return M
