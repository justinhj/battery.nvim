# battery.nvim
Neovim plugin to collect and view information on battery power in your status line.

## What?
This is a cross platform Neovim plugin to provide battery information including percent charge remaining, number of batteries and whether the power cable is connected or not.
The information is then provided as a programmatic API you can call from Lua and also suitable to add to your status line.

## Why?
When I'm working on a small 12" laptop there's not a lot of screen real estate, so I tend to maximize my terminal window when editing code. Unfortunately, that means I can't see the battery status, and don't know how long I've got without switching windows. I decided to fix that by adding it to the the statusline.

## How?
The plugin is written in Lua and depends heavily on the Plenary library for its excellent support for processes (Jobs). When you start the plugin (by calling `require"battery".setup({})`) it runs a job in the background every 5 minutes (or however often you want, see config) and updates the battery status. Then you can call `require"battery".get_status_line()` in your statusline plugin to show the battery percentage and an appropriate icon.

## Features
- Gracefully handle no battery (either remove battery info from the status line or just show a desktop icon)
- Show charge level and whether there is a power cable attached or not via icons (requires [kyazdani42/nvim-web-devicons](https://github.com/kyazdani42/nvim-web-devicons))
- Configurable update rate
- Powershell for Windows battery information
- pmset Apple Mac OSx battery information
- Linux not yet supported

## Required dependencies

- [nvim-lua/plenary.nvim](https://github.com/nvim-lua/plenary.nvim)
- [kyazdani42/nvim-web-devicons](https://github.com/kyazdani42/nvim-web-devicons)

## Installation
Use your package manager to add the dependencies and the plugin. I use [Plug](https://github.com/junegunn/vim-plug).

```
Plug 'nvim-lua/plenary.nvim'
Plug 'kyazdani42/nvim-web-devicons'
Plug 'justinhj/battery.nvim'
```

## Configuration


## Notes
Inspired by [lambdalisue/battery.vim](https://github.com/lambdalisue/battery.vim), which in turn uses code from [b4b4r07/dotfiles](https://github.com/b4b4r07/dotfiles/blob/66dddda6803ada50a0ab879e5db784afea72b7be/.tmux/bin/battery#L10).

## Roadmap
* TODO install instructions via plug etc
* TODO add screen shot(s)
* DONE mac support
* TODO Option for what to show when no battery 
* TODO linux support
* TODO horizontal icon option
* TODO possibly show charge remaining (bonus points for on mouse hover)
* DONE rewrite based on learnings
* DONE make a non-reloading module for time uniqueness 
* DONE add debug only logging and remove prints
* TODO WISHLIST react to system events in realtime (somehow)
* TODO test suite for status line

Copyright (c) 2022 Justin Heyes-Jones
