cmake_minimum_required(VERSION 3.20)

project(NanoVNA2Firmware LANGUAGES C CXX ASM)

set(BOARDNAME "board_v2_plus4" CACHE STRING "Target board directory under firmware/boards")
set(EXTRA_CFLAGS "-DDISPLAY_ST7796" CACHE STRING "Additional compiler flags (legacy Makefile style)")
set(LDSCRIPT "${CMAKE_SOURCE_DIR}/ldscripts/gd32f303cc_with_bootloader_plus4.ld" CACHE FILEPATH "Linker script path")
set(BOOTLOAD_PORT "/dev/ttyACM0" CACHE STRING "Serial port used by bootload_firmware target")

set(OPENCM3_DIR "${CMAKE_SOURCE_DIR}/libopencm3")
set(OPENCM3_LIB "${OPENCM3_DIR}/lib/libopencm3_gd32f3_nofpu.a")

if(NOT EXISTS "${CMAKE_SOURCE_DIR}/firmware/boards/${BOARDNAME}/board.cpp")
  message(FATAL_ERROR "Invalid BOARDNAME='${BOARDNAME}'. Expected a board under firmware/boards")
endif()

if(NOT EXISTS "${LDSCRIPT}")
  message(FATAL_ERROR "LDSCRIPT does not exist: ${LDSCRIPT}")
endif()

execute_process(
  COMMAND git -C "${CMAKE_SOURCE_DIR}" log -n 1 --pretty=format:git-%ad%h --date=format:%Y%m%d-
  OUTPUT_VARIABLE GITVERSION
  OUTPUT_STRIP_TRAILING_WHITESPACE
  ERROR_QUIET
)
if(GITVERSION STREQUAL "")
  set(GITVERSION "git-unknown")
endif()

execute_process(
  COMMAND git -C "${CMAKE_SOURCE_DIR}" config --get remote.origin.url
  OUTPUT_VARIABLE GITURL
  OUTPUT_STRIP_TRAILING_WHITESPACE
  ERROR_QUIET
)
if(GITURL STREQUAL "")
  set(GITURL "unknown")
endif()

file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/generated")
configure_file(
  "${CMAKE_SOURCE_DIR}/cmake/gitversion.hpp.in"
  "${CMAKE_BINARY_DIR}/generated/gitversion.hpp"
  @ONLY
)

add_custom_target(libopencm3_build
  COMMAND make -C "${OPENCM3_DIR}" SRCLIBDIR="${OPENCM3_DIR}/lib" TARGETS=gd32/f3_nofpu
  BYPRODUCTS "${OPENCM3_LIB}"
  COMMENT "Building libopencm3"
)

add_library(libopencm3 STATIC IMPORTED GLOBAL)
set_target_properties(libopencm3 PROPERTIES IMPORTED_LOCATION "${OPENCM3_LIB}")
add_dependencies(libopencm3 libopencm3_build)

set(FIRMWARE_SOURCES
  firmware/boards/${BOARDNAME}/board.cpp
  firmware/src/Font5x7.c
  firmware/src/Font7x13b.c
  firmware/src/command_parser.cpp
  firmware/src/common.cpp
  firmware/src/fft.cpp
  firmware/src/flash.cpp
  firmware/src/gain_cal.cpp
  firmware/src/globals.cpp
  firmware/src/ili9341.cpp
  firmware/src/main2.cpp
  firmware/src/numfont20x22.c
  firmware/src/plot.cpp
  firmware/src/sin_rom.cpp
  firmware/src/stream_fifo.cpp
  firmware/src/synthesizers.cpp
  firmware/src/ui.cpp
  firmware/src/uihw.cpp
  firmware/src/vna_measurement.cpp
  firmware/src/xpt2046.cpp
  mculib/dma_adc.cpp
  mculib/dma_driver.cpp
  mculib/fastwiring.cpp
  mculib/message_log.cpp
  mculib/printf.cpp
  mculib/si5351.cpp
  mculib/usbserial.cpp
)

add_executable(binary.elf ${FIRMWARE_SOURCES})

set(extra_flags "${EXTRA_CFLAGS}")
separate_arguments(extra_flags UNIX_COMMAND "${extra_flags}")

set(common_flags
  -mcpu=cortex-m4
  -mthumb
  -msoft-float
  -O2
  -g
  -ffast-math
  -fstack-protector-strong
  -Wall
  -Wno-unused-function
  -Werror=implicit-fallthrough
  -ffunction-sections
  -fdata-sections
  -funsigned-char
  -fwrapv
  -fno-delete-null-pointer-checks
  -fno-strict-aliasing
)

target_compile_options(binary.elf PRIVATE ${common_flags} ${extra_flags})
target_compile_definitions(binary.elf PRIVATE
  GD32F3_NOFPU
  GD32F303CC_NOFPU
  MCULIB_DEVICE_STM32F103
  STM32F103
  STM32F1
  _XOPEN_SOURCE=600
)

target_compile_features(binary.elf PRIVATE cxx_std_17)
target_compile_options(binary.elf PRIVATE
  $<$<COMPILE_LANGUAGE:CXX>:-fno-exceptions>
  $<$<COMPILE_LANGUAGE:CXX>:-fno-rtti>
)

target_include_directories(binary.elf PRIVATE
  "${CMAKE_BINARY_DIR}/generated"
  "${CMAKE_SOURCE_DIR}/firmware/include"
  "${CMAKE_SOURCE_DIR}/firmware/boards/${BOARDNAME}"
  "${CMAKE_SOURCE_DIR}/mculib/include"
  "${CMAKE_SOURCE_DIR}/libopencm3/include"
)

target_link_options(binary.elf PRIVATE
  -mcpu=cortex-m4
  -mthumb
  -msoft-float
  -T${LDSCRIPT}
  -static
  -nostartfiles
  -Wl,--exclude-libs,libssp
  -Wl,--print-memory-usage
  -Wl,--gc-sections
  -Wl,--start-group
  -lgcc
  -lnosys
  -Wl,--end-group
  -lm
)

target_link_libraries(binary.elf PRIVATE libopencm3)

add_custom_command(
  TARGET binary.elf POST_BUILD
  COMMAND ${CMAKE_OBJCOPY} -O ihex $<TARGET_FILE:binary.elf> ${CMAKE_BINARY_DIR}/binary.hex
  COMMAND ${CMAKE_OBJCOPY} -O binary $<TARGET_FILE:binary.elf> ${CMAKE_BINARY_DIR}/binary.bin
  COMMENT "Generating binary.hex and binary.bin"
)

add_custom_target(flash
  COMMAND ./st-flash --reset --format ihex write ${CMAKE_BINARY_DIR}/binary.hex
  DEPENDS binary.elf
  WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
  COMMENT "Flashing firmware with st-flash"
)

add_custom_target(bootload_firmware
  COMMAND python3 "${CMAKE_SOURCE_DIR}/tools/bootload_firmware.py" --file "${CMAKE_BINARY_DIR}/binary.bin" --serial "${BOOTLOAD_PORT}"
  DEPENDS binary.elf
  WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
  COMMENT "Uploading firmware over serial bootloader"
)

add_custom_target(dfu DEPENDS bootload_firmware)
