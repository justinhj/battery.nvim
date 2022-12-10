require("matcher_combinators.luassert")

local version_module = require("battery.version")

describe("greeting", function()
  it("0.7.0", function()
    return version_module.version
  end)
end)
