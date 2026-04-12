set rtp^=../

" configuring the plugin
runtime plugin/battery_plugin.lua
lua require('battery').setup({})
