-- Manage the update battery status timer_seq_nums.
-- Note that these are not reloaded by design when you do:
--   require("plenary.reload").reload_module("battery")
-- The timer_seq_nums keep going and will be stopped if you start a new one.
-- TODO stop_timer_seq_num function should get the next timer_seq_num number and that will
-- force stop the old timer_seq_num.

local timer_seq_num = 0

return {
  get_current = function()
    return timer_seq_num
  end,
  get_next = function()
    timer_seq_num = timer_seq_num + 1
    return timer_seq_num
  end,
}
