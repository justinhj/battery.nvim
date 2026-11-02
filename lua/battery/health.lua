local M = {}

local start = vim.health.start or vim.health.report_start
local ok = vim.health.ok or vim.health.report_ok
local error = vim.health.error or vim.health.report_error

local B = require('battery.battery')

---@return boolean
local function check_method()
  return B.get_method() ~= nil
end

function M.check()
  start('Checking method to get battery status')
  if check_method() then
    ok('Using ' .. B.get_method() .. '')
  else
    local parsers = require('battery.parsers')
    local advice = {}
    for method, parser_module in pairs(parsers.parsers) do
      local success, reason = parser_module.check()
      if not success and reason then
        table.insert(advice, #advice + 1, ('%s: %s'):format(method, reason))
      end
    end
    error('No method found.', advice)
  end
end

return M
