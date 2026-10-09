local M = {}

local log = require('battery.util.log')
local config = require('battery.config')
local parsers = require('battery.parsers')
local icons = require('battery.icons')

-- TODO: check for icons and if not available fallback to text
-- TODO: allow user to select no icons
-- TODO: maybe autodetect icons?

---@class battery.Status
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

---Tracks the most severe battery level already notified about, so each
---threshold crossing notifies exactly once until the level resets
---(charged back above the thresholds, plugged into AC, or no battery).
---@type 'none'|'low'|'critical'
local notified_level = 'none'

---Evaluate the latest battery status against the configured low/critical
---thresholds and notify once per threshold crossing.
---Called once per timer tick. The parser jobs fill `battery_status`
---asynchronously via vim.system, so this reads the most recently completed
---poll and can lag a real crossing by at most one poll interval.
local function check_low_battery_notification()
  local cfg = config.current
  if not cfg.notify_on_low_battery then
    return
  end

  local percent = battery_status.percent_charge_remaining

  -- Nothing to warn about: no data yet, no battery, or on AC power.
  -- Reset so notifications re-arm for the next discharge.
  if battery_status.battery_count == nil or battery_status.battery_count == 0 or battery_status.ac_power or percent == nil then
    notified_level = 'none'
    return
  end

  local level = 'none'
  if percent <= cfg.critical_battery_threshold then
    level = 'critical'
  elseif percent <= cfg.low_battery_threshold then
    level = 'low'
  end

  local rank = { none = 0, low = 1, critical = 2 }
  if rank[level] > rank[notified_level] then
    -- Escalation: notify exactly once for this crossing.
    notified_level = level
    local notify = cfg.notify_function or vim.notify
    -- floor: some parsers (termux-api) can report fractional percents
    local pct = math.floor(percent)
    if level == 'critical' then
      notify(string.format('battery.nvim: critical battery level (%d%% remaining)', pct), vim.log.levels.ERROR)
    else
      notify(string.format('battery.nvim: low battery (%d%% remaining)', pct), vim.log.levels.WARN)
    end
  elseif rank[level] < rank[notified_level] then
    -- De-escalation (charged back above a threshold): re-arm.
    notified_level = level
  end
end

---Gets the last updated battery information
---TODO: may add the ability to ask for it to be updated right now
---@return battery.Status
function M.get_battery_status()
  return battery_status
end

---This maps to a timer sequence number in the utils module so the user
---can reload the battery module and we can detect the old job is still running.
---@type integer?
local timer = nil

---Select the battery info job to run based on platform and what programs
---are available
---@return (fun(battery_status: battery.Status): any)?
---@return string?
local function select_job()
  for method, parser_module in pairs(parsers.parsers) do
    if parser_module.check() then
      log.debug('using ' .. method .. ' method')
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

    -- Evaluate notifications against the most recently completed poll
    -- before launching the next job.
    check_low_battery_notification()

    local job_function, method = select_job()
    battery_status.method = method
    log.debug('using method ' .. (method or 'nil'))

    if job_function then
      job_function(battery_status)
    end

    -- When the user reloads the battery module the job can just keep running. In order to stop it
    -- the user must call stop_timer. All this does is increments the timer sequence number. Whenever
    -- the running job knows that the sequence number no longer matches it will stop running,
    -- regardless of whether the user made a new job or not.

    if require('battery.util.timers').get_current() ~= timer then
      log.info('Update job stopping due to newer timer.')
    else
      timer_loop()
    end
  end, config.current.update_rate_seconds * 1000)
end

-- local function stop_timer()
--   timer = require("battery.util.timers").get_next()
--   log.debug("Incremented timer to " .. timer .. " to stop the battery update job")
-- end

local function start_timer()
  timer = require('battery.util.timers').get_next()

  -- Always call the job immediately before starting the timed loop
  local job_function, method = select_job()
  battery_status.method = method
  log.debug('using method: ' .. (method or 'nil'))

  if job_function then
    job_function(battery_status)
  end

  timer_loop()
  log.debug('start timer seq no ' .. timer)
end

---Check if the current Neovim version supports the required features
---@return boolean
function M.check_version()
  if not vim.system then
    local v = vim.version()
    local version_str = string.format('%d.%d.%d', v.major, v.minor, v.patch)
    log.error(
      string.format(
        'Required function vim.system not available (Neovim v%s). Please upgrade Neovim or use version v0.9.1 or earlier.',
        version_str
      )
    )
    return false
  end
  return true
end

---@param user_opts battery.Config
function M.setup(user_opts)
  if not M.check_version() then
    return
  end

  config.from_user_opts(user_opts)

  local config_update_rate_seconds = tonumber(config.current.update_rate_seconds)
  if config_update_rate_seconds then
    if config_update_rate_seconds < 10 then
      vim.notify('Update rate less than 10 seconds is not recommended', vim.log.levels.WARN)
    end
  end

  if config.current.notify_on_low_battery then
    local low = config.current.low_battery_threshold
    local critical = config.current.critical_battery_threshold
    if type(low) ~= 'number' or type(critical) ~= 'number' or critical >= low then
      vim.notify(
        'battery.nvim: critical_battery_threshold must be a number less than low_battery_threshold; notifications disabled',
        vim.log.levels.WARN
      )
      config.current.notify_on_low_battery = false
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
        log.error('battery_status.percent_charge_remaining is nil, \
there is probably something wrong with the current \
parser implementation.')
        battery_percent = 100
      end

      local plug_icon = ''
      if ac_power and config.current.show_plugged_icon then
        plug_icon = icons.specific.plugged
      elseif not ac_power and config.current.show_unplugged_icon then
        plug_icon = icons.specific.unplugged
      end

      -- extra space to separate horizontal battery from plug symbol
      if not config.vertical_icons then
        if plug_icon ~= '' then
          plug_icon = ' ' .. plug_icon
        end
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
