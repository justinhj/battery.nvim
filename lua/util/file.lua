local M = {}

local bit = require('bit')

---Check if there is a readable directory at the given file path.
---Warning: the `path` may be substituted onto the command line,
---so the input _must_ be trusted.
---@param path string
---@return boolean
function M.is_readable_directory(path)
  if not os.getenv('TERMUX_VERSION') then
    -- When not running in Termux
    local s = vim.loop.fs_stat(path)
    return (
      s ~= nil -- File exists
      and s.type == 'directory' -- File is a directory
      and bit.band(s.mode, 4) == 4 -- File is readable (Minimum permissions: ------r--)
    )
  else
    -- In Termux, use the `test` command
    return os.execute('test -d \''..path..'\' && test -r \''..path..'\'') == 0
  end
end

return M
