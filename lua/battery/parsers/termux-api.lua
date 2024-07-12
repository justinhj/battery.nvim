-- Getting battery info with termux-battery-status. Requires Termux and Termux:API.
local M = {}

local J = require('plenary.job')
local L = require('plenary.log')

local log = L.new({ plugin = 'battery' })

local function parse_termux_battery_info(result, battery_status)
  local status = vim.json.decode(table.concat(result, ''))

  battery_status.percent_charge_remaining = status.percent
  battery_status.battery_count = 1 -- WARN: This might not always be true
  battery_status.ac_power = status.plugged:find("^PLUGGED_") -- String starts with "PLUGGED_"
end

-- Create a plenary job to get the battery info
-- battery_status is a table to store the results in
function M.get_battery_info_job(battery_status)
  return J:new({
    command = 'termux-battery-status',
    on_exit = function(r, return_value)
      if return_value == 0 then
        parse_termux_battery_info(r:result(), battery_status)
        log.debug(vim.inspect(battery_status))
      else
        vim.schedule(function()
          vim.notify('battery.nvim: Error getting battery info with termux-battery-status', vim.log.levels.ERROR)
        end)
      end
    end,
  })
end

---Check if this parser would work in the current environment
---@return boolean
function M.check()
  return vim.fn.executable('termux-battery-status') == 1
end

return M
