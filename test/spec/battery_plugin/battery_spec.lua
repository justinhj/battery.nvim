local battery = require('battery.battery')
local log = require('util.log')

print("Running battery specs")

local v = vim.version()
local is_supported = v.major > 0 or v.minor >= 10

-- Mock log.error to prevent it from showing notifications during tests
local error_called = false
local original_error = log.error
log.error = function(msg)
  error_called = true
  print("Captured expected log.error: " .. tostring(msg))
end

local result = battery.check_version()

-- Restore original error function
log.error = original_error

print(string.format("Neovim version: %d.%d.%d", v.major, v.minor, v.patch))
print(string.format("Expected support: %s, Actual result: %s", tostring(is_supported), tostring(result)))

assert(result == is_supported, "check_version result does not match expected support for this Neovim version")

if not is_supported then
  assert(error_called == true, "log.error should have been called for unsupported version")
end

print("All battery specs passed!")
