SPEC=

RUN=nvim --headless --noplugin -u spec.vim

.PHONY: all nvim test watch prepare check

check:
	luacheck ../lua/ ./spec/

./vendor/matcher_combinators.lua:
	git clone https://github.com/m00qek/matcher_combinators.lua.git --depth 1 ./vendor/matcher_combinators.lua

./vendor/plenary.nvim:
	git clone https://github.com/nvim-lua/plenary.nvim.git --depth 1 ./vendor/plenary.nvim

prepare:
	luarocks install luacheck --local

nvim:
	@nvim --noplugin -u spec.vim

test: ./vendor/matcher_combinators.lua ./vendor/plenary.nvim
ifeq ($(strip $(SPEC)),) # a.k.a. $(SPEC) is empty
	@$(RUN) -c "PlenaryBustedDirectory spec/ { minimal_init = 'spec.vim' }"
else
	@$(RUN) -c "PlenaryBustedFile $(SPEC)"
endif

watch:
	@echo -e '\nRunning tests on "spec/**/*_spec.lua" when any Lua file on "../lua/" and "spec/" changes\n'
	@find spec/ ../lua/ -name '*.lua' \
	  | entr make test SPEC=$(SPEC)

all: prepare test
