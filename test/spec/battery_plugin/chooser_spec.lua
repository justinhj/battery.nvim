local BC = require('util.chooser')

print("Running chooser specs")

local function assert_eq(expected, actual, msg)
  if expected ~= actual then
    error(string.format("%s: Expected %s, got %s", msg or "Assertion failed", vim.inspect(expected), vim.inspect(actual)), 2)
  end
end

-- maximum
assert_eq(30, BC.battery_chooser({ 10, 20, 30, 10 }, 'maximum'), 'maximum 1')
assert_eq(10, BC.battery_chooser({ 10 }, 'maximum'), 'maximum 2')
assert_eq(50, BC.battery_chooser({ 50, 1 }, 'maximum'), 'maximum 3')
assert_eq(50, BC.battery_chooser({ 1, 50 }, 'maximum'), 'maximum 4')
assert_eq(50, BC.battery_chooser({ 50, 50, 50, -1, 50 }, 'maximum'), 'maximum 5')
assert_eq(-1, BC.battery_chooser({ -50, -1, -10 }, 'maximum'), 'maximum 6')

-- average
assert_eq(3, BC.battery_chooser({ 1, 2, 3, 4, 5 }, 'average'), 'average 1')
assert_eq(3, BC.battery_chooser({ 1, 2, 3, 4, 5, 6 }, 'average'), 'average 2')
assert_eq(4, BC.battery_chooser({ 1, 2, 3, 4, 5, 6, 8 }, 'average'), 'average 3')
assert_eq(2, BC.battery_chooser({ 1, 1, 4, 5 }, 'average'), 'average 4')

-- index
assert_eq(30, BC.battery_chooser({ 10, 20, 30, 40, 50 }, 3), 'index 1')
assert_eq(10, BC.battery_chooser({ 10, 20, 30, 40, 50 }, 6), 'index 2')
assert_eq(10, BC.battery_chooser({ 10, 20, 30, 40, 50 }, -1), 'index 3')

-- invalid
assert_eq(0, BC.battery_chooser({}, 3), 'invalid 1')
assert_eq(0, BC.battery_chooser(nil, 3), 'invalid 2')

print("All chooser specs passed!")
