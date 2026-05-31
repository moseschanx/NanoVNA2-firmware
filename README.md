## NanoVNA V2 Firmware

This repository contains firmware sources for NanoVNA V2 devices (S-A-A-2 family), now migrated to a **CMake-based build system** with a reorganized project layout.

- Project website: https://nanorfe.com/nanovna-v2.html
- Firmware downloads: https://nanorfe.com/nanovna-versions.html
- Developers chat room: https://discord.gg/DUH5Xk5

## Documentation Index

- [/docs/BUILDING.md](/docs/BUILDING.md) — complete build and configuration guide
- [/docs/PROJECT_STRUCTURE.md](/docs/PROJECT_STRUCTURE.md) — repository and firmware layout
- [/docs/FLASHING.md](/docs/FLASHING.md) — firmware upload workflows

## Quick Start

### 1) Clone with submodules

```bash
git clone --recursive https://github.com/nanovna/NanoVNA-V2-firmware.git
cd NanoVNA-V2-firmware
```

If already cloned without submodules:

```bash
git submodule update --init --recursive
```

### 2) Build using CMake directly

```bash
cmake -S . -B build \
  -DCMAKE_TOOLCHAIN_FILE=cmake/toolchain-arm-none-eabi.cmake \
  -DBOARDNAME=board_v2_plus4 \
  -DEXTRA_CFLAGS="-DSWEEP_POINTS_MAX=201 -DSAVEAREA_MAX=7 -DDISPLAY_ST7796" \
  -DLDSCRIPT=$PWD/ldscripts/gd32f303cc_with_bootloader_plus4.ld

cmake --build build --target binary.elf
```

Artifacts are generated in `build/`:

- `binary.elf`
- `binary.hex`
- `binary.bin`

### 3) Legacy habit preserved (`make` wrapper)

`make` is still supported as a compatibility wrapper and preserves `BOARDNAME`, `EXTRA_CFLAGS`, `LDSCRIPT`, and `BOOTLOAD_PORT` variables:

```bash
make -j4 BOARDNAME=board_v2_plus4 \
  EXTRA_CFLAGS="-DSWEEP_POINTS_MAX=201 -DSAVEAREA_MAX=7 -DDISPLAY_ST7796" \
  LDSCRIPT=$PWD/ldscripts/gd32f303cc_with_bootloader_plus4.ld
```

This runs CMake under the hood and copies final artifacts to repository root for compatibility.
