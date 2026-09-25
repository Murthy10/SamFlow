APP        := SamFlow
CONFIG     ?= debug
BUILD_DIR  := .build/$(CONFIG)
BUNDLE     := .build/$(APP).app
CONTENTS   := $(BUNDLE)/Contents
# Session length in minutes, e.g. `make run DURATION=45`. Empty keeps the
# built-in default (25).
DURATION   ?=

.DEFAULT_GOAL := run

## build: compile the executable
.PHONY: build
build:
	swift build -c $(CONFIG)

## test: run the SamFlowKit test suite
.PHONY: test
test:
	swift test

## app: assemble and ad-hoc sign SamFlow.app
.PHONY: app
app: build
	@rm -rf $(BUNDLE)
	@mkdir -p $(CONTENTS)/MacOS $(CONTENTS)/Resources
	@cp $(BUILD_DIR)/$(APP) $(CONTENTS)/MacOS/$(APP)
	@cp Resources/Info.plist $(CONTENTS)/Info.plist
	@printf 'APPL????' > $(CONTENTS)/PkgInfo
	@codesign --force --sign - $(BUNDLE) 2>/dev/null || true
	@echo "built $(BUNDLE)"

## run: build the bundle and launch it with logs in the terminal. DURATION=<minutes> overrides the default session length.
.PHONY: run
run: app
	@pkill -x $(APP) 2>/dev/null || true
	$(CONTENTS)/MacOS/$(APP) $(if $(DURATION),--duration $(DURATION),)

## launch: same, but detached via LaunchServices. DURATION=<minutes> overrides the default session length.
.PHONY: launch
launch: app
	@pkill -x $(APP) 2>/dev/null || true
	open $(BUNDLE) $(if $(DURATION),--args --duration $(DURATION),)

## clean: remove all build products
.PHONY: clean
clean:
	rm -rf .build

## help: list targets
.PHONY: help
help:
	@grep -E '^## ' $(MAKEFILE_LIST) | sed 's/## /  /'
