# Project Structure

## Top-level Layout

- `CMakeLists.txt` — primary build definition
- `Makefile` — compatibility wrapper for legacy workflow (invokes CMake)
- `cmake/` — toolchain and build helper templates
- `docs/` — project documentation
- `firmware/` — main firmware code organized by role
- `ldscripts/` — linker scripts
- `tools/` — developer scripts (build helpers, generators, upload script)
- `bootloader/` — bootloader firmware sources
- `mculib/` — MCU utility library (submodule)
- `libopencm3/` — low-level MCU library (submodule)

## Firmware Layout

- `firmware/include/` — firmware headers
- `firmware/src/` — firmware C/C++ implementation files
- `firmware/boards/` — board-specific implementations
  - `board_v2_0/`
  - `board_v2_1/`
  - `board_v2_2/`
  - `board_v2_plus/`
  - `board_v2_plus4/`

## Build Artifacts

By default:

- CMake outputs in `build/`
- `make` compatibility wrapper additionally copies final artifacts to repository root

Primary produced artifacts:

- `binary.elf`
- `binary.hex`
- `binary.bin`
