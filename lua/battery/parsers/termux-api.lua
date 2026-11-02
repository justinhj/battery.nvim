-- Getting battery info with termux-battery-status. Requires Termux and Termux:API.
local M = {}

local log = require('battery.util.log')

---@param result string | string[]
---@param battery_status battery.Status
local function parse_termux_battery_info(result, battery_status)
  local json_str = type(result) == 'table' and table.concat(result, '') or result
  local status = vim.json.decode(json_str)
  log.debug(status)

  battery_status.percent_charge_remaining = status.percentage
  battery_status.battery_count = 1 -- WARN: This might not always be true
  battery_status.ac_power = status.plugged:find('^PLUGGED_') -- String starts with "PLUGGED_"
  log.debug(battery_status)
end

---Create a job to get the battery info
---battery_status is a table to store the results in
---@param battery_status battery.Status
function M.get_battery_info_job(battery_status)
  return vim.system({ 'termux-battery-status' }, { text = true }, function(obj)
    if obj.code == 0 then
      parse_termux_battery_info(obj.stdout, battery_status)
      log.debug(battery_status)
    else
      vim.schedule(function()
        vim.notify('battery.nvim: Error getting battery info with termux-battery-status', vim.log.levels.ERROR)
      end)
    end
  end)
end

---Check if this parser is supported in the current environment.
---Additionally returns a `reason` if the OS is correct, but it isn't supported for another reason.
---@return boolean supported
---@return string? reason
function M.check()
  if vim.fn.has('nvim-0.12') == 1 then
    -- In Neovim >= 0.12, use the built-in `has(...)` check
    if vim.fn.has('termux') == 0 then
      return false
    end
  else
    -- In Neovim < 0.12, check for the presence of an environment variable
    if not vim.env.TERMUX_VERSION then
      return false
    end
  end

  if vim.fn.executable('termux-battery-status') == 0 then
    return false,
      '`termux-battery-status` is not executable. Install the Termux:API package (see: https://wiki.termux.com/wiki/Termux-battery-status).'
  else
    return true
  end
end

return M
