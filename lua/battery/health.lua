local M = {}

local start = vim.health.start or vim.health.report_start
local ok = vim.health.ok or vim.health.report_ok
local error = vim.health.error or vim.health.report_error

-- TODO should check if the plugin is initialized and the setup is valid
-- TODO should check what method is being used for battery information

local function check_setup()
  return true
end

M.check = function()
  start("battery report")
  -- make sure setup function parameters are ok
  if check_setup() then
    ok("Setup function is correct")
  else
    error("Setup function is incorrect")
  end
  -- do some more checking
  -- ...
end

return M
