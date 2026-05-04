local battery = require('battery.battery')

print("Running battery specs")

local v = vim.version()
local is_supported = v.major > 0 or v.minor >= 10
local result = battery.check_version()

print(string.format("Neovim version: %d.%d.%d", v.major, v.minor, v.patch))
print(string.format("Expected support: %s, Actual result: %s", tostring(is_supported), tostring(result)))

assert(result == is_supported, "check_version result does not match expected support for this Neovim version")

print("All battery specs passed!")
