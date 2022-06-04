const std = @import("std");
const libusb = @import("../usb/libusb.zig");
const Context = libusb.Context;
const Device = libusb.Device;
const DeviceHandle = libusb.DeviceHandle;
const Interface = libusb.Interface;
const info = std.log.info;

pub const ADC_valueIndex = enum(u16) {
    CH0,
    CH1,
    CH3
};

pub const StatusPacket = packed struct {
    pub const I2C = extern struct {
        transfer_length: u16,
        transfered_length: u16,
        buffer_counter: u8,
        speed_deviver: u8,
        timeout: u8,
        address: u16,
        dontcare_1: u32,
        scl: u8,
        sda: u8,
        interrup_edge_det: u8,
        read_pending: u8,
    };

    i2c_data: I2C,
    dontcare_2: [15]u8,
    hw_rev: [2]u8,
    fw_rev: [2]u8,
    adc_value: [3]u16,
    dontcare_3: [8]u8
    
};

pub fn getStatus(handle: *DeviceHandle, in_endpoint: Endpoint.Address, out_endpoint: Endpoint.Address) !StatusPacket {
   var packet: [64]u8 = [_]u8{0} ** 64;

   packet[0] = 0x10;  //Status Parameter command.
   try handle.interruptTransfer(out_endpoint, packet, 1000);

   try handle.interruptTransfer(in_endpoint, packet, 1000);

   if (packet[0] == 0x10 and packet[1] == 0x0)
       return std.mem.bytesAsValue(StatusPacket, packet[9..64].ptr)
   else
       return error.CommandFailed; 
}

pub fn getHIDInterfaceDescriptor(handle: *DeviceHandle) !Interface.Descriptor {
 
    var device = handle.getDevice() orelse return error.InvalidDevice;
    var opt_interface: ?Interface.Descriptor = null;
    
    var cfg_desc = try device.getActiveConfigDescriptor();
    errdefer info("Failed to get active configuaration.", .{});
    defer cfg_desc.free();

    for (cfg_desc.getInterfaceArray()) |interface| {
        for (interface.getAltSettingArray()) |interface_desc| {
            if (interface_desc.bInterfaceClass == libusb.ClassCode.HID) {
                info("HID interface found.", .{});
                opt_interface = interface_desc;
                break;
            }
        }
    }
        
    return if (opt_interface) |interface| interface else error.InterfaceNotFound;
}

pub fn main() anyerror!void {
    //Let's find the microchip usb-serial.
    var ctx = try Context.init();
    errdefer info("Failed to initialize library.", .{});
    defer ctx.deinit();

    var handle = try ctx.openDeviceWithVidPid(0x04d8, 0x00dd);
    errdefer info("Failed to open device with the vid/pid", .{});
    defer handle.close();

    //Find HID interface.
    var interface_desc = try getHIDInterfaceDescriptor(handle);
    errdefer info("HID interface not found.", .{});
    var interface = interface_desc.bInterfaceNumber; 

    try handle.claimInterface(interface);
    errdefer info("Failed to claim interface.\n", .{});
    defer handle.releaseInterface(interface);

    var in_endpoint: Endpoint.Address = undefined;
    var out_endpoint: Endpoint.Address = undefined;
    for(interface_desc.getEndpointArray()) |endpoint_desc| {
        if(endpoint_desc.bEndpointAddress.direction == Endpoint.Direction.IN)
            in_endpoint = endpoint_desc.bEndpointAddress
        else
            out_endpoint = endpoint_desc.bEndpointAddress;
    }


    var status = try getStatus(handle, in_endpoint, out_endpoint);
    errdefer info("Failed to get status.", .{});
    
}

test "basic test" {
    try std.testing.expectEqual(10, 3 + 7);
}
