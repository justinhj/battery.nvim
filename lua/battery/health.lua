local M = {}

local start = vim.health.start or vim.health.report_start
local ok = vim.health.ok or vim.health.report_ok
local error = vim.health.error or vim.health.report_error

local B = require("battery.battery")

local function check_method()
  return B.get_method() ~= nil
end

M.check = function()
  start("Checking method to get battery status")
  if check_method() then
    ok("Using " .. B.get_method() ..  "")
  else
    error("No method found.")
  end
end

return M
