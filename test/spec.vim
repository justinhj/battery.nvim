set rtp^=./vendor/plenary.nvim/
set rtp^=./vendor/matcher_combinators.lua/
set rtp^=../

runtime plugin/plenary.vim

lua require('plenary.busted')
lua require('matcher_combinators.luassert')

" configuring the plugin
runtime plugin/battery_plugin.lua
lua require('battery').setup({})
