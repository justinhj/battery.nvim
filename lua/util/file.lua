local M = {}

---Check if there is a readable directory at the given file path.
---Warning: the `path` is substituted onto the command line, so the
---input _must_ be trusted.
---@param path string
---@return boolean
function M.is_readable_directory(path)
  return os.execute('test -d \''..path..'\' && test -r \''..path..'\'') == 0
end

return M
