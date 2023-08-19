# battery.nvim
Neovim plugin to collect and view information on battery power in your status line.

<p>
<img width="40%" src="https://justinhj.github.io/images/battery/statuslineexample.png"/>
</p>

## What?
This is a cross platform Neovim plugin to provide battery information including percent charge remaining, number of batteries and whether the power cable is connected or not.
The information is then provided as a programmatic API you can call from Lua and also suitable to add to your status line.

## Why?
When I'm working on a small 12" laptop there's not a lot of screen real estate, so I tend to maximize my terminal window when editing code. Unfortunately, that means I can't see the battery status, and don't know how long I've got without switching windows. I decided to fix that by adding it to the the statusline.

## How?
The plugin is written in Lua and depends heavily on the Plenary library for its excellent support for processes (Jobs). When you start the plugin (by calling `require"battery".setup({})`) it runs a job in the background every 5 minutes (or however often you want, see config) and updates the battery status. Then you can call `require"battery".get_status_line()` in your statusline plugin to show the battery percentage and an appropriate icon.

## Features
- Gracefully handle no battery (either remove battery info from the status line or just show a desktop icon)
- Show charge level and whether there is a power cable attached or not via icons (requires [nvim-tree/nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons))
- Configurable update rate
- Powershell for Windows battery information
- pmset Apple Mac OSx battery information
- Linux support via acpi

## Required dependencies

- [nvim-lua/plenary.nvim](https://github.com/nvim-lua/plenary.nvim)
- [nvim-tree/nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons)
- acpi installed on your system and in your PATH

## Installation
Use your package manager to add the dependencies and the plugin. 

### [Plug](https://github.com/junegunn/vim-plug)

```
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-tree/nvim-web-devicons'
Plug 'justinhj/battery.nvim'
```

### [Packer](https://github.com/wbthomason/packer.nvim)

```
use { 'justinhj/battery.nvim', requires = {{'nvim-tree/nvim-web-devicons'}, {'nvim-lua/plenary.nvim'}}}
```

## Configuration
Once installed you need to run the setup function and pass in an optional config. This starts the internal timer so that the battery status is updated periodically. Since the process to get the battery can take a second or two, even though it happens in the background, I don't recommend setting it below about 10 seconds, and several minutes should be fine for most purposes. Running `setup` will always refresh the battery status.

There are some configuration options.

```
lua << END
local battery = require("battery")
battery.setup({
	update_rate_seconds = 30,           -- Number of seconds between checking battery status
	show_status_when_no_battery = true, -- Don't show any icon or text when no battery found (desktop for example)
	show_plugged_icon = true,           -- If true show a cable icon alongside the battery icon when plugged in
	show_unplugged_icon = true,         -- When true show a diconnected cable icon when not plugged in
	show_percent = true,                -- Whether or not to show the percent charge remaining in digits
    vertical_icons = true,              -- When true icons are vertical, otherwise shows horizontal battery icon
    multiple_battery_selection = 1,     -- Which battery to choose when multiple found. "max" or "maximum", "min" or "minimum" or a number to pick the nth battery found (currently linux acpi only)
})
END
```

## Adding to [lualine](https://github.com/nvim-lualine/lualine.nvim)
Ensure minimal setup in your config.
```
lua require"battery".setup({})
```

In your lualine config add the following.
```
local nvimbattery = {
  function()
    return require("battery").get_status_line()
  end,
  color = { fg = colors.violet, bg = colors.bg },
}
```
Add it where you want it, something like below.
```
sections = { lualine_a = nvimbattery }
```

## Adding to [galaxyline](https://github.com/glepnir/galaxyline.nvim)

Add this to your galaxy line config in the section you want:

```
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

For more than just info,warn and error logging you can enable debug logs which show a more verbose behaviour of the plugin using the following command to launch nvim.

`PLENARY_DEBUG=true nvim`

## Notes
Inspired by [lambdalisue/battery.vim](https://github.com/lambdalisue/battery.vim), which in turn uses code from [b4b4r07/dotfiles](https://github.com/b4b4r07/dotfiles/blob/66dddda6803ada50a0ab879e5db784afea72b7be/.tmux/bin/battery#L10).

Copyright (c) 2022 Justin Heyes-Jones
