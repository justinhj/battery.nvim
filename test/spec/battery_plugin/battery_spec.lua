require("matcher_combinators.luassert")

local version_module = require("battery.version")

describe("battery", function()
  it("version works", function()
    local v = version_module.version
    assert.equals(type(v), "string")
    assert.is_true(#v > 0)
  end)
end)
