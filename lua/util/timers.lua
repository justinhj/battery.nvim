local M = {}

local timer_seq_num = 0

---@return integer
function M.get_current()
  return timer_seq_num
end

---@return integer
function M.get_next()
  timer_seq_num = timer_seq_num + 1
  return timer_seq_num
end

return M
