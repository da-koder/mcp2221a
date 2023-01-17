const libusb = @import("../libusb.zig");
const DeviceHandle = libusb.DeviceHandle;
const Interface = libusb.Interface;
const Endpoint = libusb.Endpoint;
const Context = libusb.Context;
const Config = libusb.Config;

const std = @import("std");
const info = std.log.info;
const alloc = std.heap.raw_c_allocator;



pub const HID = struct {
    handle: *DeviceHandle,
    i_number: Interface.Number,
    in: Endpoint.Address,
    out: Endpoint.Address,
    ctx: *Context,

    fn setHIDInterfaceEndpoint(self: *HID) !void {
        var device = self.handle.getDevice() orelse return error.InvalidDevice;
        var opt_interface: ?Interface.Descriptor = null;

        var cfg_desc = try device.getActiveConfigDescriptor();
        //defer cfg_desc.free();

        info("About to start getting the array.", .{});
        for (cfg_desc.getInterfaceArray()) |interface| {
            for (interface.getAltSettingArray()) |interface_desc| {
                if (interface_desc.bInterfaceClass == libusb.ClassCode.HID) {
                    info("HID interface found.", .{});
                    opt_interface = interface_desc;
                    self.i_number = interface_desc.bInterfaceNumber;

                    for (interface_desc.getEndpointArray()) |ep_desc| {
                        if (ep_desc.bmAttributes.transferType == libusb.TransferType.INTERRUPT) {
                            if (ep_desc.bEndpointAddress.direction == Endpoint.Direction.IN) {
                                self.in = ep_desc.bEndpointAddress;
                            } else {
                                self.out = ep_desc.bEndpointAddress;
                            }
                        }
                    }                    
                }
            }
        }

        if(opt_interface == null) return error.HIDNotFound;
    }

    pub fn open(vid: u16, pid: u16) !*HID {
        var ctx = try Context.init();
        var handle = try ctx.openDeviceWithVidPid(vid, pid);
        
        
        var hid: *HID = try alloc.create(HID);
        hid.handle = handle;
        hid.ctx = ctx;
        try (hid).setHIDInterfaceEndpoint();
        
        //Enable driver autodetach if availeble.
        if (libusb.hasCapability(libusb.Capability.SUPPORTS_DETACH_KERNEL_DRIVER)) {
            info("Kernel driver detach supported.", .{});
            try hid.handle.setAutoDetachKernelDriver(true);
        }

        info("About to attempt claiming an interface.", .{});
        hid.handle.claimInterface(hid.i_number) catch |err| info("Failed to claim: {s}.", .{libusb.toString(err)});

        return hid;
    }

    pub fn write(self: *HID, bytes: []u8) !usize {
        var count = try self.handle.interruptTransfer(self.out, bytes[0..64], 10);
        return count;
    }

    pub fn read(self: *HID, bytes: []u8) !usize {
        var count = try self.handle.interruptTransfer(self.in, bytes[0..64], 10);
        return count;
    }

    pub fn close(self: *HID) void {
        if (libusb.hasCapability(libusb.Capability.SUPPORTS_DETACH_KERNEL_DRIVER)) {
            self.handle.setAutoDetachKernelDriver(false) catch {};
        }
        self.handle.close();
        self.ctx.deinit();
    }
};
