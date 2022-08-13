local M = {}
local health = require("health")

-- TODO should check if the plugin is initialized and the setup is valid
-- TODO should check what method is being used for battery information

local function check_setup()
  return true
end

M.check = function()
  health.report_start("battery.nvim report")
  -- make sure setup function parameters are ok
  if check_setup() then
    health.report_ok("Setup function is correct")
  else
    health.report_error("Setup function is incorrect")
  end
  -- do some more checking
  -- ...
end

return M
