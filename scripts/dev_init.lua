if vim.env.DEV_SHELL ~= 'battery.nvim' then
  local script = 'dev-shell.sh'
  if vim.fn.has('win32') == 1 then
    script = 'DevShell.ps1'
  end
  vim.notify(
    '  Not in battery.nvim dev-shell, exiting dev_init.lua early.\n'
      .. ('  Source scripts/%s to enter dev-shell.'):format(script),
    vim.log.levels.ERROR
  )
  return
end

vim.cmd.packadd('battery.nvim')

require('battery').setup({})

BatteryStatus = require('battery').get_battery_status
BatteryStatusLine = require('battery').get_status_line
