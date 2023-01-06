const std = @import("std");
const libusb = @import("usb/libusb.zig");
const Context = libusb.Context;
const Device = libusb.Device;
const Config = libusb.Config;
const DeviceHandle = libusb.DeviceHandle;
const Interface = libusb.Interface;
const Endpoint = libusb.Endpoint;
const info = std.log.info;

pub const StatusPacket = packed struct {
    pub const I2C = packed struct {
        const ACK_flag: u32 = 1 << 22;
        transfer_length: u16 align(1), //8,0
        transfered_length: u16 align(1), //10,2
        buffer_counter: u8, //12,4
        speed_devider: u8, //13,5
        timeout: u8, //14,6
        address: u16 align(1), //15,7
        ack_status: u32 align(1), //17,9
        scl: u8, //21,13
        sda: u8, //22,14
        interrup_edge_det: u8, //23,15
        read_pending: u8, //24,16
        dontcare_2: [15]u8, //25,17
    };

    const CancelProgress = enum(u8) { Cancel = 0x00, Marked = 0x10, Idleing = 0x11 };
    const SetI2CSpeedProgress = enum(u8) { CommandNotIssued = 0x00, Considered = 0x20, NotSet = 0x21 };
    pub const ADC = enum(u8) { CH0, CH1, CH3 };

    command_code: u8, //0
    is_completed: u8, //1
    cancel_transfer: CancelProgress, //2
    set_speed: SetI2CSpeedProgress, //3
    i2c_speed_devider: u8, //4
    dontcare_1: [3]u8, //5
    i2c_data: I2C align(1), //8
    dontcare_3: [6]u8, //40
    hw_rev: [2]u8, //46
    fw_rev: [2]u8, //48
    adc_channel_value: [3]u16 align(1), //50
    dontcare_4: [8]u8, //56

    pub fn init() StatusPacket {
        var sp: StatusPacket = undefined;
        mem.set(u8, mem.asBytes(&sp), 0);
        return sp;
    }
};

const HID = libusb.HID;
const mem = std.mem;
const ascii = std.ascii;
pub fn main() anyerror!void {
    var hid = try HID.open(0x04d8, 0x00dd);
    defer hid.close();
    info("{hid = {}", .{hid});

    var status = StatusPacket.init();
    status.command_code = 0x10;
    _ = try hid.write(mem.asBytes(&status));
    _ = try hid.read(mem.asBytes(&status));

    info("Revision = {s}-{s}", .{ status.hw_rev, status.fw_rev });
}

const expect = std.testing.expect;
const print = std.debug.print;

fn changeArray(arr: []u8) void {
    arr[3] = 1;
}

test "chnange parameter" {
    var all_zeros = [_]u8{0} ** 8;
    changeArray(all_zeros[0..]);
    try expect(all_zeros[3] == 1);
}

test "basic test" {
    // const packet: StatusPacket = undefined;
    print("Size of *StatusPacket = {d}*, I2C = {d}.\n", .{ @sizeOf(StatusPacket), @sizeOf(StatusPacket.I2C) });
    const data_ofs = @offsetOf(StatusPacket, "i2c_data");
    print("Offset of i2c_data = {d}.\n", .{data_ofs});
    print("Offset of hw_rev = {d}.\n", .{@offsetOf(StatusPacket, "hw_rev")});

    const tl_sz = @offsetOf(StatusPacket.I2C, "transfer_length");
    print("Offset of transfer_length = {d}, {d}.\n", .{ data_ofs + tl_sz, tl_sz });
    print("Offset of scl = {d}.\n", .{@offsetOf(StatusPacket.I2C, "scl")});
    print("Offset of dontcare_4 = {d}.\n", .{@offsetOf(StatusPacket, "dontcare_4")});

    var packet = [_]u8{0} ** @sizeOf(StatusPacket);
    packet[46] = 'A';
    packet[47] = '6';

    // var status = std.mem.bytesAsValue(StatusPacket, &packet);
    // print("Hardware rev = {c}{c}.\n", .{ status.hw_rev[0], status.hw_rev[1] });
    //    print("Size of dontcare_4 = {d}.\n", .{@sizeOf(StatusPacket.dontcare_4)});
}
