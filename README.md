# mcp2221a
[MCP2221A](http://ww1.microchip.com/downloads/en/devicedoc/20005565b.pdf) interface library using the usb repo for zig lang.
I know I can just wrap the c library they provide, but this is for practicing usb IO datasheet -> code and zig.

**Example usage**
1. `git clone https://github.com/da-koder/mcp2221a.git`
2. `cd mcp2221a`
3. `zig build`
4. `sudo zig build run`

**Current**
- Commands: getstatus, readFlashdata( chipsettings, gpsettings, manufacturer, product, serial_number, factory_serial).
- Now works with zig 0.10.

**TODO v1.0**
- 0.5: Add the rest of the commands. 
- 1.0: Then implement an arduino like interface for it.
