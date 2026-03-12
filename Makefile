config ?= release
static ?= false

PACKAGE := zulip_action
GET_DEPENDENCIES_WITH := corral fetch
CLEAN_DEPENDENCIES_WITH := corral clean
COMPILE_WITH := corral run -- ponyc

BUILD_DIR ?= build/$(config)
SRC_DIR := $(PACKAGE)
tests_binary := $(BUILD_DIR)/$(PACKAGE)
action_binary := $(BUILD_DIR)/action

ifdef config
	ifeq (,$(filter $(config),debug release))
		$(error Unknown configuration "$(config)")
	endif
endif

ifeq ($(config),release)
	PONYC = $(COMPILE_WITH)
else
	PONYC = $(COMPILE_WITH) --debug
endif

ifeq (,$(filter $(MAKECMDGOALS),clean TAGS))
  ifeq ($(ssl), 3.0.x)
          SSL = -Dopenssl_3.0.x
  else ifeq ($(ssl), 1.1.x)
          SSL = -Dopenssl_1.1.x
  else ifeq ($(ssl), libressl)
          SSL = -Dlibressl
  else
    $(error Unknown SSL version "$(ssl)". Must set using 'ssl=FOO')
  endif
endif

PONYC := $(PONYC) $(SSL)

ifeq ($(static),true)
	PONYC += --static
endif

SOURCE_FILES := $(shell find $(SRC_DIR) -name *.pony)
ACTION_SOURCE_FILES := $(shell find action -name *.pony) $(SOURCE_FILES)

test: unit-tests

unit-tests: $(tests_binary)
	$^ --exclude=integration --sequential

$(tests_binary): $(SOURCE_FILES) | $(BUILD_DIR)
	$(GET_DEPENDENCIES_WITH)
	$(PONYC) -o $(BUILD_DIR) $(SRC_DIR)

build-action: $(action_binary)

$(action_binary): $(ACTION_SOURCE_FILES) | $(BUILD_DIR)
	$(GET_DEPENDENCIES_WITH)
	$(PONYC) -o $(BUILD_DIR) action

clean:
	$(CLEAN_DEPENDENCIES_WITH)
	rm -rf $(BUILD_DIR)

TAGS:
	ctags --recurse=yes $(SRC_DIR)

all: test

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

IMAGE := ponylang/zulip-action

ifndef tag
  IMAGE_TAG := $(shell cat VERSION)
else
  IMAGE_TAG := $(tag)
endif

docker: action.yml Dockerfile Makefile $(ACTION_SOURCE_FILES)
	docker build --pull -t "ghcr.io/$(IMAGE):$(IMAGE_TAG)" .
	docker build --pull -t "ghcr.io/$(IMAGE):latest" .
	touch $@

push: docker
	docker push "ghcr.io/$(IMAGE):$(IMAGE_TAG)"
	docker push "ghcr.io/$(IMAGE):latest"

.PHONY: all clean TAGS test unit-tests build-action push
