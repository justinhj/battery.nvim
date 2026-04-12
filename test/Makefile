SPEC=

RUN=nvim --headless --noplugin -u spec.vim

.PHONY: all nvim test watch prepare check clean

check:
	luacheck ../lua/ ./spec/

prepare:
	luarocks install luacheck --local

nvim:
	@nvim --noplugin -u spec.vim

test:
ifeq ($(strip $(SPEC)),) # a.k.a. $(SPEC) is empty
	@$(RUN) -l run.lua "spec/"
else
	@$(RUN) -l run.lua "$(SPEC)"
endif

watch:
	@echo -e '\nRunning tests on "spec/**/*_spec.lua" when any Lua file on "../lua/" and "spec/" changes\n'
	@find spec/ ../lua/ -name '*.lua' \
	  | entr make test SPEC=$(SPEC)

clean:
	rm -rf vendor/

all: prepare test
