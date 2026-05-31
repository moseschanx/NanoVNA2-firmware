BOARDNAME ?= board_v2_plus4
EXTRA_CFLAGS ?= -DDISPLAY_ST7796
LDSCRIPT ?= $(CURDIR)/ldscripts/gd32f303cc_with_bootloader_plus4.ld
BOOTLOAD_PORT ?= /dev/ttyACM0
BUILD_DIR ?= $(CURDIR)/build
CMAKE_TOOLCHAIN_FILE ?= $(CURDIR)/cmake/toolchain-arm-none-eabi.cmake

.PHONY: all configure build artifacts clean dist-clean flash bootload_firmware dfu

all: configure build artifacts

configure:
cmake -S $(CURDIR) -B $(BUILD_DIR) \
-DCMAKE_TOOLCHAIN_FILE=$(CMAKE_TOOLCHAIN_FILE) \
-DBOARDNAME=$(BOARDNAME) \
-DEXTRA_CFLAGS="$(EXTRA_CFLAGS)" \
-DLDSCRIPT=$(LDSCRIPT) \
-DBOOTLOAD_PORT=$(BOOTLOAD_PORT)

build:
cmake --build $(BUILD_DIR) --target binary.elf -- -j$${JOBS:-$$(nproc)}

artifacts:
cp $(BUILD_DIR)/binary.elf $(CURDIR)/binary.elf
cp $(BUILD_DIR)/binary.hex $(CURDIR)/binary.hex
cp $(BUILD_DIR)/binary.bin $(CURDIR)/binary.bin

flash: configure
cmake --build $(BUILD_DIR) --target flash

bootload_firmware: configure
cmake --build $(BUILD_DIR) --target bootload_firmware

dfu: bootload_firmware

clean:
rm -f $(CURDIR)/binary.elf $(CURDIR)/binary.hex $(CURDIR)/binary.bin
if [ -d "$(BUILD_DIR)" ]; then cmake --build $(BUILD_DIR) --target clean; fi

dist-clean: clean
rm -rf $(BUILD_DIR)
