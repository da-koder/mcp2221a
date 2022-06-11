const std = @import("std");
const libusb = @import("usb/libusb.zig");
const Context = libusb.Context;
const Device = libusb.Device;
const DeviceHandle = libusb.DeviceHandle;
const Interface = libusb.Interface;
const Endpoint = libusb.Endpoint;
const info = std.log.info;

pub const ADC_valueIndex = enum(u16) { CH0, CH1, CH3 };

pub const StatusPacket = packed struct {
    pub const I2C = packed struct {
        dontcare_2: [3]u8, //9
        transfer_length: u16, //2
        transfered_length: u16, //4
        buffer_counter: u8, //5
        speed_deviver: u8, //6
        timeout: u8, //7
        address: u16, //9
        dontcare_1: u32, //13
        scl: u8, //14
        sda: u8, //15
        interrup_edge_det: u8, //16
        read_pending: u8, //17
    };

    const CancelProgress = enum(u8) { Cancel = 0x00, Marked = 0x10, Idleing = 0x11 };
    const SetI2CSpeedProgress = enum(u8) { CommandNotIssued = 0x00, Considered = 0x20, NotSet = 0x21 };

    command_code: u8, //1
    is_completed: u8, //2
    cancel_transfer: CancelProgress, //3
    set_speed: SetI2CSpeedProgress, //4
    i2c_speed_devider: u8, //5
    dc_1: u8,
    i2c_data: I2C, //26
    dontcare_3: [20]u8, //46
    hw_rev: [2]u8, //48
    fw_rev: [2]u8, //50
    adc_value: [3]u16, //56
    dontcare_4: [2]u32, //63

};

pub fn getStatus(handle: *DeviceHandle, in_endpoint: Endpoint.Address, out_endpoint: Endpoint.Address) !StatusPacket {
    var packet: [@sizeOf(StatusPacket)]u8 = [_]u8{0} ** @sizeOf(StatusPacket);

    packet[0] = 0x10; //Status Parameter command.
    _ = try handle.interruptTransfer(out_endpoint, packet[0..], 1000);

    _ = try handle.interruptTransfer(in_endpoint, packet[0..], 1000);
    return std.mem.bytesAsValue(StatusPacket, packet[0..]);
    //  if (packet[0] == 0x10 and packet[1] == 0x0)
    //     return std.mem.bytesAsValue(StatusPacket, &packet)
    // else
    //     return error.CommandFailed;
}

pub fn getHIDInterfaceDescriptor(handle: *DeviceHandle) !Interface.Descriptor {

    //var device
    _ = handle.getDevice() orelse return error.InvalidDevice;
    var opt_interface: ?Interface.Descriptor = null;

    // var cfg_desc = try device.getActiveConfigDescriptor();
    // errdefer info("Failed to get active configuaration.", .{});
    // defer cfg_desc.free();

    // for(cfg_desc.getInterfaceArray()) |interface| {
    //     for(interface.getAltSettingArray()) |interface_desc| {
    //         if (interface_desc.bInterfaceClass == libusb.ClassCode.HID) {
    //             info("HID interface found.", .{});
    //             opt_interface = interface_desc;
    //             break;
    //         }
    //     }
    // }

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
    for (interface_desc.getEndpointArray()) |endpoint_desc| {
        if (endpoint_desc.bEndpointAddress.direction == Endpoint.Direction.IN)
            in_endpoint = endpoint_desc.bEndpointAddress
        else
            out_endpoint = endpoint_desc.bEndpointAddress;
    }

    var status = try getStatus(handle, in_endpoint, out_endpoint);
    errdefer info("Failed to get status.", .{});

    info("Revision = {c}.{c}.{c}.{c}", .{ status.hw_rev[0], status.hw_rev[1], status.fw_rev[0], status.fw_rev[1] });
}

const expect = std.testing.expect;
const print = std.debug.print;

test "basic test" {
    // const packet: StatusPacket = undefined;
    print("Size of *StatusPacket = {d}*, I2C = {d}.\n", .{ @sizeOf(StatusPacket), @sizeOf(StatusPacket.I2C) });
    print("Offset of dontcare_4 = {d}.\n", .{@offsetOf(StatusPacket, "dontcare_4")});
    print("Offset of i2c_data = {d}.\n", .{@offsetOf(StatusPacket, "i2c_data")});
    print("Size of dontcare_4 = {d}.\n", .{@sizeOf(StatusPacket)});
    print("Type of StatusPacket = {s}.\n", .{@typeName(StatusPacket)});

    var packet = [_]u8{0} ** @sizeOf(StatusPacket);
    packet[46] = 'A';
    packet[47] = '6';

    var status = std.mem.bytesAsValue(StatusPacket, &packet);
    print("Hardware rev = {c}{c}.\n", .{ status.hw_rev[0], status.hw_rev[1] });
    //    print("Size of dontcare_4 = {d}.\n", .{@sizeOf(StatusPacket.dontcare_4)});
    try expect(@sizeOf(StatusPacket) == 64);
}
