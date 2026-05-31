# Flashing Firmware

The GD32F303 does **not** support standard USB DFU flashing. Use serial bootloader mode or ST-Link.

## Serial Bootloader (Recommended)

### Put device into bootload mode

1. Power off device
2. Hold left button (near Port 1 / power switch)
3. Power on device
4. Release button after white screen appears

### Flash from build output

Using CMake target:

```bash
cmake --build build --target bootload_firmware
```

Or using make compatibility target:

```bash
make BOOTLOAD_PORT=/dev/ttyACM0 bootload_firmware
```

Direct script usage:

```bash
python3 tools/bootload_firmware.py --file build/binary.bin --serial /dev/ttyACM0
```

## ST-Link Flashing

⚠️ Back up full GD32 flash before using ST-Link, because some units include factory calibration in flash regions.

Use:

```bash
cmake --build build --target flash
```

or

```bash
make flash
```

The default `flash` target writes `build/binary.hex` through `./st-flash`.
