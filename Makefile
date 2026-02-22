SHELL := /bin/bash

HOMEBREW_NO_AUTO_UPDATE ?= 1
export HOMEBREW_NO_AUTO_UPDATE

BASH_FILES := $(shell find .github/scripts -type f -name '*.sh' | sort)
RUBY_SCRIPT_FILES := $(shell find .github/scripts -type f -name '*.rb' | sort)
SHFMT_FLAGS := -i 2 -ci -sr

.PHONY: help lint fmt bash-lint bash-fmt-check bash-fmt ruby-script-lint ruby-lint ruby-fmt-check ruby-fmt

help:
	@echo "Targets:"
	@echo "  make lint            Run Bash + Ruby lint and format checks"
	@echo "  make fmt             Apply Bash + Ruby formatting"
	@echo "  make bash-lint       Run bash -n and shellcheck"
	@echo "  make bash-fmt-check  Check Bash formatting with shfmt"
	@echo "  make bash-fmt        Apply Bash formatting with shfmt"
	@echo "  make ruby-script-lint Check Ruby script syntax"
	@echo "  make ruby-lint       Run Ruby lint (brew style)"
	@echo "  make ruby-fmt-check  Check Ruby formatting"
	@echo "  make ruby-fmt        Apply Ruby formatting"

lint: bash-lint bash-fmt-check ruby-script-lint ruby-fmt-check ruby-lint

fmt: bash-fmt ruby-fmt

bash-lint:
	@test -n "$(BASH_FILES)" || (echo "No bash files found in .github/scripts"; exit 1)
	@for f in $(BASH_FILES); do \
		bash -n "$$f"; \
	done
	@command -v shellcheck >/dev/null 2>&1 || (echo "shellcheck is required"; exit 1)
	@shellcheck $(BASH_FILES)

bash-fmt-check:
	@test -n "$(BASH_FILES)" || (echo "No bash files found in .github/scripts"; exit 1)
	@command -v shfmt >/dev/null 2>&1 || (echo "shfmt is required"; exit 1)
	@shfmt -d $(SHFMT_FLAGS) $(BASH_FILES)

bash-fmt:
	@test -n "$(BASH_FILES)" || (echo "No bash files found in .github/scripts"; exit 1)
	@command -v shfmt >/dev/null 2>&1 || (echo "shfmt is required"; exit 1)
	@shfmt -w $(SHFMT_FLAGS) $(BASH_FILES)

ruby-script-lint:
	@if [ -z "$(RUBY_SCRIPT_FILES)" ]; then \
		echo "No Ruby script files found in .github/scripts"; \
	else \
		for f in $(RUBY_SCRIPT_FILES); do \
			ruby -c "$$f" >/dev/null; \
		done; \
	fi

ruby-lint:
	@.github/scripts/ruby-lint.rb

ruby-fmt-check:
	@.github/scripts/ruby-fmt.rb check

ruby-fmt:
	@.github/scripts/ruby-fmt.rb write
