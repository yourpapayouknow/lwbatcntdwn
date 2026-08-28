SHELL := /bin/zsh

APP := LowBat
BUILD := build
APP_DIR := $(BUILD)/Payload/$(APP).app
TIPA := $(BUILD)/LowBatCountdown-1.0.0.tipa
SDK := $(shell xcrun --sdk iphoneos --show-sdk-path)
CC := xcrun --sdk iphoneos clang
HOST_CC := xcrun --sdk macosx clang

M_SOURCES := Sources/main.m Sources/LBShared.m Sources/LBApp.m Sources/LBHud.m
C_SOURCES := Sources/LBState.c
OBJECTS := $(patsubst Sources/%.m,$(BUILD)/%.o,$(M_SOURCES)) $(patsubst Sources/%.c,$(BUILD)/%.o,$(C_SOURCES))

CFLAGS := -arch arm64 -isysroot $(SDK) -miphoneos-version-min=15.0 -O2 -fvisibility=hidden -Wall -Wextra -Werror -ISources
OBJCFLAGS := $(CFLAGS) -fobjc-arc -fmodules
LDFLAGS := -arch arm64 -isysroot $(SDK) -miphoneos-version-min=15.0 -Wl,-dead_strip -framework Foundation -framework UIKit -framework CoreGraphics -framework QuartzCore

.PHONY: all package test clean inspect

all: test package

$(BUILD):
	mkdir -p $(BUILD)

$(BUILD)/%.o: Sources/%.m | $(BUILD)
	$(CC) $(OBJCFLAGS) -c $< -o $@

$(BUILD)/%.o: Sources/%.c | $(BUILD)
	$(CC) $(CFLAGS) -c $< -o $@

$(APP_DIR)/$(APP): $(OBJECTS) Resources/Info.plist Resources/entitlements.plist
	mkdir -p $(APP_DIR)
	$(CC) $(OBJECTS) $(LDFLAGS) -o $@
	cp Resources/Info.plist $(APP_DIR)/Info.plist
	ldid -SResources/entitlements.plist $@

package: $(APP_DIR)/$(APP)
	cd $(BUILD) && rm -f $(notdir $(TIPA)) && zip -qry $(notdir $(TIPA)) Payload
	@print -r -- "Built $(TIPA)"

test: | $(BUILD)
	$(HOST_CC) -std=c11 -Wall -Wextra -Werror -ISources Tests/test_state.c Sources/LBState.c -o $(BUILD)/test_state
	$(BUILD)/test_state

inspect: package
	file $(APP_DIR)/$(APP)
	plutil -lint $(APP_DIR)/Info.plist Resources/entitlements.plist
	ldid -e $(APP_DIR)/$(APP)
	unzip -l $(TIPA)

clean:
	rm -rf $(BUILD)

