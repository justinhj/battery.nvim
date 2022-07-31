# battery.nvim
Neovim plugin to collect and view information on battery power in your status line.

## Features
- Gracefully handle no battery (either remove battery info from the status line or just show a desktop icon)
- Show charge level and whether there is a power cable attached or not via icons (requires [kyazdani42/nvim-web-devicons](https://github.com/kyazdani42/nvim-web-devicons))
- Configurable update rate
- Powershell for Windows battery information
- pmset and ioreg for Apple Mac OSx battery information
- Linux distributions TBD

## Notes
Inspired by [lambdalisue/battery.vim](https://github.com/lambdalisue/battery.vim), which in turn uses code from [b4b4r07/dotfiles](https://github.com/b4b4r07/dotfiles/blob/66dddda6803ada50a0ab879e5db784afea72b7be/.tmux/bin/battery#L10).

## Roadmap
* TODO install instructions via plug etc
* TODO add screen shot(s)
* WIP mac support
* TODO linux support
* TODO horizontal icon option
* TODO possibly show charge remaining (bonus points for on mouse hover)

Copyright (c) 2022 Justin Heyes-Jones
