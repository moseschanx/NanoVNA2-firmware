# Building NanoVNA2 Firmware

## Requirements

- CMake >= 3.20
- GNU Make
- ARM Embedded GCC toolchain (`arm-none-eabi-*`)
- Python 3 (for bootloader upload helper)
- Git with submodule support

On Debian/Ubuntu:

```bash
sudo apt update
sudo apt install -y cmake make gcc-arm-none-eabi python3 python3-serial git
```

## Repository Setup

```bash
git clone --recursive https://github.com/nanovna/NanoVNA-V2-firmware.git
cd NanoVNA-V2-firmware
```

If cloned without `--recursive`:

```bash
git submodule update --init --recursive
```

## CMake Configuration Parameters

The project keeps legacy build habits by exposing familiar variables as CMake cache options:

- `BOARDNAME` (default: `board_v2_plus4`)
- `EXTRA_CFLAGS` (default: `-DDISPLAY_ST7796`)
- `LDSCRIPT` (default: `ldscripts/gd32f303cc_with_bootloader_plus4.ld`)
- `BOOTLOAD_PORT` (default: `/dev/ttyACM0`)

## Build With CMake

```bash
cmake -S . -B build \
  -DCMAKE_TOOLCHAIN_FILE=cmake/toolchain-arm-none-eabi.cmake \
  -DBOARDNAME=board_v2_plus \
  -DEXTRA_CFLAGS="-DSWEEP_POINTS_MAX=201 -DSAVEAREA_MAX=7" \
  -DLDSCRIPT=$PWD/ldscripts/gd32f303cc_with_bootloader.ld

cmake --build build --target binary.elf -- -j$(nproc)
```

Generated files:

- `build/binary.elf`
- `build/binary.hex`
- `build/binary.bin`

## Build With Legacy `make` Entry Point

```bash
make -j4 BOARDNAME=board_v2_plus4 \
  EXTRA_CFLAGS="-DSWEEP_POINTS_MAX=201 -DSAVEAREA_MAX=7 -DDISPLAY_ST7796" \
  LDSCRIPT=$PWD/ldscripts/gd32f303cc_with_bootloader_plus4.ld
```

This wrapper:

1. Configures CMake in `build/`
2. Builds target `binary.elf`
3. Copies `binary.elf`, `binary.hex`, and `binary.bin` to repository root

## Board and Linker Script Mapping

- `board_v2_2`  -> `ldscripts/gd32f303cc_with_bootloader.ld`
- `board_v2_plus` -> `ldscripts/gd32f303cc_with_bootloader.ld`
- `board_v2_plus4` -> `ldscripts/gd32f303cc_with_bootloader_plus4.ld`

## Build Matrix Script

To generate multiple firmware variants, use:

```bash
./tools/buildall
```

Outputs are produced in repository root as:

- `v2_2-ili9341.bin`
- `v2_2-st7796.bin`
- `v2plus-ili9341.bin`
- `v2plus-st7796.bin`
- `v2plus4.bin`

## Cleaning

```bash
make clean
make dist-clean
```

Equivalent CMake direct clean:

```bash
cmake --build build --target clean
rm -rf build
```
