# usb
Wrapper for libusb-1.0 for zig and interface with MCP2221A usb-serial chip.

#Goals
- Learn to program usb
- Learn zig language
- Interface with a chip via usb MCP2221A in this case
- How to user git

#Install
Just clone the repo to your project folder and import.
Checkout the mcp2221a repo as an example.

#TODO
- HID is specifically made for the MCP2221A i.e 64 btye reports. Next goal is to have it use CONTROL endpoint for proper HID IO setup.
- No Documentation, hopefully those familiar with libusb can easily tell what's what, Will add docs after HID.
- If i'm still interested later might complete it for other features i haven't used i.e Streams and Transfers.


