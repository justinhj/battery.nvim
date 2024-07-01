local bit = require('bit')

local function is_readable_directory(file)
  local s = vim.loop.fs_stat(file)
  return s ~= nil and s.type == 'directory' and bit.band(s.mode, 4) == 4
end

return {
  is_readable_directory = is_readable_directory,
}
