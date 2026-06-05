# battery.nvim
Neovim plugin to collect and view information on battery power in your status line.

<p>
<img width="40%" src="https://justinhj.github.io/images/battery/statuslineexample.png"/>
</p>

## What?
This is a cross-platform Neovim plugin to provide battery information including percent charge remaining, number of batteries and whether the power cable is connected or not.
The information is then provided as a programmatic API you can call from Lua and also suitable to add to your status line.

## Why?
I was working on a small 12" laptop and there's not a lot of screen real estate, so I tended to maximize my terminal window when editing code. Unfortunately, that means I can't see the battery status, and don't know how long I've got without switching windows. I decided to fix that by adding it to the the statusline and this plugin was born.

## How?
The plugin is written in Lua. When you start the plugin (by calling `require"battery".setup({})`) it runs a job (Using an async call `vim.system`) in the background every 5 minutes (or however often you want, see config) and updates the battery status. Then you can call `require"battery".get_status_line()` in your statusline plugin to show the battery percentage and an appropriate icon.

## Features
- Handles no battery (either remove battery info from the status line or just show a desktop icon)
- Show charge level and whether there is a power cable attached or not
- Configurable update rate
- Support for Microsoft Windows, Linux, Apple macOS, Termux (Android) and WSL.

## Required dependencies
### Neovim version
- **Neovim v0.10.0 or later** is required (uses `vim.system`).
- The plugin will gracefully fail to load on older versions of Neovim with a descriptive error message.

### OS dependencies
On Windows and macOS, PowerShell and pmset are used to obtain battery status respectively.
For Linux `acpi` is used, and may not be installed by default on your distribution. See [How to handle acpi events on Linux](https://linuxconfig.org/how-to-handle-acpi-events-on-linux). The package must be correctly installed and in your executable path.
On Termux, the `termux-api` package and Android app are required.

## Installation
Use your package manager to add the dependencies and the plugin. 

### vim.pack - Neovim built-in

```lua
vim.pack.add({
  {
    src = 'https://github.com/justinhj/battery.nvim',
    version = 'main',
  },
})
require('configs/battery')
```

Example contents of `configs/battery`:

```lua
require('battery').setup({
  update_rate_seconds = 60,
  show_status_when_no_battery = false,
  show_plugged_icon = true,
  show_unplugged_icon = false,
  show_percent = true,
  vertical_icons = true,
  multiple_battery_selection = 1,
})
```

### [Plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'justinhj/battery.nvim'
```

### [LazyVim](https://www.lazyvim.org)

Thank you to @DuendeInexistente for the contribution.

Add a file `lua/plugins/battery.lua`

```lua
return {

  {
    "justinhj/battery.nvim",

    opts = {
      update_rate_seconds = 60,
      show_status_when_no_battery = false,
      show_plugged_icon = false,
      show_unplugged_icon = true,
      show_percent = true,
      vertical_icons = false,
    },
  },
  {
    "nvim-lualine/lualine.nvim",
    opts = {
      sections = {
        lualine_z = {
          function()
            return " " .. os.date("%R")
          end,
          function()
            return require("battery").get_status_line()
          end,
        },
      },
    },
  },
}
```

### [Packer](https://github.com/wbthomason/packer.nvim)

```lua
use { 'justinhj/battery.nvim' }
```

## Configuration
Once installed you need to run the setup function and pass in an optional config. This starts the internal timer so that the battery status is updated periodically. Since the process to get the battery can take a second or two, even though it happens in the background, I don't recommend setting it below about 10 seconds, and several minutes should be fine for most purposes. Running `setup` will always refresh the battery status.

There are some configuration options.

```vim
lua << END
local battery = require("battery")
battery.setup({
    update_rate_seconds = 30,           -- Number of seconds between checking battery status
    show_status_when_no_battery = true, -- Don't show any icon or text when no battery found (desktop for example)
    show_plugged_icon = true,           -- If true show a cable icon alongside the battery icon when plugged in
    show_unplugged_icon = true,         -- When true show a disconnected cable icon when not plugged in
    show_percent = true,                -- Whether or not to show the percent charge remaining in digits
    vertical_icons = true,              -- When true icons are vertical, otherwise shows horizontal battery icon
    multiple_battery_selection = 1,     -- Which battery to choose when multiple found. "max" or "maximum", "avg" or "average" or a number to pick the nth battery found (currently linux acpi only)
})
END
```

## Adding to [lualine](https://github.com/nvim-lualine/lualine.nvim)
Ensure minimal setup in your config.
```vim
lua require"battery".setup({})
```

In your lualine config add the following.
```lua
local nvimbattery = {
  function()
    return require("battery").get_status_line()
  end,
  color = { fg = colors.violet, bg = colors.bg },
}
```
Add it where you want it, something like below.
```lua
sections = { lualine_a = nvimbattery }
```

## Adding to [galaxyline](https://github.com/glepnir/galaxyline.nvim)
Add this to your galaxy line config in the section you want:

```lua
local gl = require 'galaxyline'
local gls = gl.section

-- in this example 5th section on the right, change as needed!
gls.right[5] = {
  BatteryNvim = {
    provider = function()
      -- note that battery.nvim uses format specifiers such as %% instead of %
      -- which is needed for other status line plugins like lualine and staline.
      -- galaxy line expects a formatted string so we must format it here...
      local status = require("battery").get_status_line()
      local formatted = string.format(status)
      return formatted
    end,
    separator = '',
    separator_highlight = { colors.bg, colors.purple },
    highlight = { colors.grey, colors.purple },
  },
}
```

## Diagnostics and debugging
If something breaks you should see a standard Vim error telling you what the problem is. There is some info logging you will find wherever your Neovim cache is `:h stdpath`.

For more than just info, warn and error logging you can enable debug logs which show a more verbose behaviour of the plugin using the following command to launch nvim.

`BATTERY_DEBUG=true nvim`

## Development
To develop the plugin, you may find it useful to use the dev-shell script to
run in a consistent, minimal Neovim instance.

For Linux/MacOS (bash):
```sh
. ./scripts/dev-shell.sh
```

For Windows (PowerShell):
```ps1
. ./scripts/DevShell.ps1
```

> [!NOTE]
>
> You may need to enable [Developer Mode](https://learn.microsoft.com/en-us/windows/advanced-settings/developer-mode)
> if you are on Windows, since `DevShell.ps1` creates a symlink.

Now, you can run Neovim using the `dev_init.lua` init script:
```sh
nvim -u ./scripts/dev_init.lua
```

This loads battery.nvim as a plugin, runs the `setup()` function and assigns
some convenience functions for interactive testing.

The following functions are available:
```lua
BatteryStatus = require('battery').get_battery_status
BatteryStatusLine = require('battery').get_status_line
```

And they can be used like so:
```vim
" Get current battery status (table)
= BatteryStatus()
```
```vim
" Get formatted current battery status (string)
= BatteryStatusLine()
```

> [!NOTE]
>
> Read through [CONTRIBUTING.md](./CONTRIBUTING.md) before creating a PR.

## Notes
Inspired by [lambdalisue/battery.vim](https://github.com/lambdalisue/battery.vim), which in turn uses code from [b4b4r07/dotfiles](https://github.com/b4b4r07/dotfiles/blob/66dddda6803ada50a0ab879e5db784afea72b7be/.tmux/bin/battery#L10).

Copyright (c) 2022-2026 Justin Heyes-Jones
