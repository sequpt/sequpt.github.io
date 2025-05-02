BUILD_ENV ?= dev

ifeq ($(BUILD_ENV),dev)
  BUILD_PATH ?= ./.local/build
  export POSIXLY_CORRECT ?= 1
else ifeq ($(BUILD_ENV),prod)
  BUILD_PATH ?= ./build
  export POSIXLY_CORRECT ?= 0
else
  $(error [ERROR] `BUILD_ENV`(==`$(BUILD_ENV)`) must be one of [`dev`, `prod`])
endif

.PHONY: all
all:
	./scripts/build.sh $(BUILD_PATH)

.PHONY: clean
clean:
	rm -rf $(BUILD_PATH)
