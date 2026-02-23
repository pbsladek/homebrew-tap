SHELL := /bin/bash

HOMEBREW_NO_AUTO_UPDATE ?= 1
export HOMEBREW_NO_AUTO_UPDATE

RUBY_SCRIPT_FILES := $(shell find .github/scripts -type f -name '*.rb' | sort)

.PHONY: help lint fmt test ruby-script-lint ruby-lint ruby-fmt-check ruby-fmt

help:
	@echo "Targets:"
	@echo "  make lint            Run Ruby lint and format checks"
	@echo "  make fmt             Apply Ruby formatting"
	@echo "  make test            Run RSpec unit tests"
	@echo "  make ruby-script-lint Check Ruby script syntax"
	@echo "  make ruby-lint       Run Ruby lint (brew style / rubocop)"
	@echo "  make ruby-fmt-check  Check Ruby formatting"
	@echo "  make ruby-fmt        Apply Ruby formatting"

lint: ruby-script-lint ruby-fmt-check ruby-lint

fmt: ruby-fmt

test:
	bundle exec rspec

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
