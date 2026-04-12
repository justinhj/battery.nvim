local M = {}

-- Replacement for plenary log

local log_path = vim.fn.stdpath("state") .. "/battery.log"

local function log(msg, level)
  local time = os.date("%Y-%m-%d %H:%M:%S")

  local line = string.format("[%s][%s] %s\n", level, time, vim.inspect(msg))

  local fd = vim.uv.fs_open(log_path, "a", 438)
  if fd then
    vim.uv.fs_write(fd, line)
    vim.uv.fs_close(fd)
  end

  if level == "ERROR" then
    vim.notify(tostring(msg), vim.log.levels.ERROR)
  end
end

M.info = function(msg) log(msg, "INFO") end
M.debug = function(msg) log(msg, "DEBUG") end
M.error = function(msg) log(msg, "ERROR") end

return M

