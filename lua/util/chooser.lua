-- Handles choosing a battery from an array based on config options

local function average(t)
  local sum = 0
  for _, v in pairs(t) do
    sum = sum + v
  end

  return sum / #t
end

-- Given a an array of battery percentages and a selection config
-- return the one that should be displayed
-- Valid values for multiple_battery_selection are
--  "max" or "maximum" chooses the largest one
--  1,2,3 .. chooses the nth battery found (defaulting to the last found if there are not enough)
--  "avg" or "average" returns the average
-- invalid or nil config will default to 1, the first found battery
-- Given an empty list will return 0
local function battery_chooser(battery_percents, multiple_battery_selection)
  if type(battery_percents) ~= "table" or battery_percents[1] == nil then
    return 0
  end
  local config = multiple_battery_selection or 1

  if config == "max" or config == "maximum" then
    return math.max(unpack(battery_percents))
  elseif config == "avg" or config == "average" then
    return math.floor(average(battery_percents))
  else
    local index = 1
    if type(config) == "number" and config >= 1 and config <= #battery_percents then
      index = config
    end
    return battery_percents[index]
  end
end

return {
  battery_chooser = battery_chooser,
}
