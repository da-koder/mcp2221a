const std = @import("std");
const libusb = @import("usb/libusb.zig");

const info = std.log.info;

//STATUS/SET PARAMETERS command and response.
pub const Command = enum(u8) { GetStatus = 0x10, ReadFlashData = 0xB0 };
pub const CommandStatus = enum(u8) { Completed, NotSupported };

pub const StatusPacket = extern struct {
    pub const I2C = extern struct {
        const ACK_flag: u32 = 1 << 22;
        transfer_length: u16, //8,0
        transfered_length: u16, //10,2
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

    command_code: Command, //0
    is_completed: CommandStatus, //1
    cancel_transfer: CancelProgress, //2
    set_speed: SetI2CSpeedProgress, //3
    i2c_speed_devider: u8, //4
    dontcare_1: [3]u8, //5
    i2c_data: I2C, //8
    dontcare_3: [6]u8, //40
    hw_rev: [2]u8, //46
    fw_rev: [2]u8, //48
    adc_channel_value: [3]u16, //50
    dontcare_4: [8]u8, //56

    pub fn init() StatusPacket {
        var sp: StatusPacket = undefined;
        mem.set(u8, mem.asBytes(&sp), 0);
        return sp;
    }
};

const HID = libusb.HID;
const mem = std.mem;

pub fn getStatus(hid: *HID) !StatusPacket {
    var packet = StatusPacket.init();
    packet.command_code = Command.GetStatus;
    _ = try hid.write(mem.asBytes(&packet));
    _ = try hid.read(mem.asBytes(&packet));
    return if (packet.command_code == Command.GetStatus and packet.is_completed == CommandStatus.Completed)
        packet
    else
        error.InvalidCommand;
}

pub const FlashDataTag = enum(u8) { chip_settings = 0, gp_settings, manufacture_string, product_string, serial_number_string, chip_factory_serial_number };

pub const FlashData = union(FlashDataTag) { chip_settings: ChipSettingsPacket, gp_settings: GPSettingsPacket, manufacture_string: StringPacket, product_string: StringPacket, serial_number_string: StringPacket, chip_factory_serial_number: ChipFactorySerialNumberPacket };

pub const ChipSettingsPacket = extern struct {
    pub const EnumerationWithSerial = enum(u1) {
        // No serial number descriptor will be presented during the USB enumeration.
        Disable,
        // The USB serial number will be used during the USB enumeration of the CDC interface.
        Enable,
    };

    pub const ChipConfigSecurity = enum(u2) { Unsecured, PasswordProceted, PermanentlyLocked };

    pub const ClockDevider = packed struct {
        // Clock Output divider value — If the GP pin (exposing the clock output) is enabled for clock output operation,
        // the divider value will be used on the 48 MHz USB internal clock and its divided output will be sent to this pin.
        devider: u5,
        dont_care_2: u3,
    };
    pub const CDC = packed struct {

        // Chip Configuration security option
        chip_security: ChipConfigSecurity,
        // Initial value for USBCFG pin option
        //  — This value represents the logic level signaled when the device is not USB configured.
        //  When the device will be USB configured, the USBCFG pin (if enabled) will take the negated value of this bit.
        usbcfg: u1,
        // Initial value for SSPND pin option
        // — This value represents the logic level signaled when the device is not in Suspend mode.
        // Upon entering Suspend mode, the SSPND pin (if enabled) will take the negated value of this bit.
        sspnd: u1,
        // Initial value for LEDI2C pin option
        // — This value represents the logic level signaled when no I2C traffic occurs.
        // When the I2 C traffic is active, the LEDI2C pin (if enabled) will take the negated value of this bit.
        led_i2c: u1,
        // Initial value for LEDUARTTX pin option
        // — This value represents the logic level signaled when no UART T X transmission takes place.
        // When the UART T X (of the MCP2221A) is sending data, the LEDUARTTX pin will take the negated value of this bit.
        led_uart_tx: u1,
        //Initial value for LEDUARTRX pin option.
        //This value represents the logic level signaled when no UART RX activity takes places.
        //When the UART RX (of the MCP2221A) is receiving data, the LEDUARTRX pin will take the negated value of this bit.
        led_uart_rx: u1,
        // CDC Serial Number Enumeration Enable
        enumeration_enable: EnumerationWithSerial,
    };

    pub const VrmOption = enum(u2) { OFF = 0, v1_024, v2_048, v4_096 };
    pub const ReferenceVoltageOption = enum(u1) { Vdd = 0, Vrm };
    pub const DAC = packed struct { startup_value: u5, reference_option: ReferenceVoltageOption, reference_voltage: VrmOption };

    pub const ADC = packed struct { dont_care_3: u2, reference_option: ReferenceVoltageOption, reference_voltage: VrmOption, positive_edge_interrupt: bool, negative_edge_interrupt: bool, dont_care_4: u1 };

    command_code: Command,
    is_completed: CommandStatus,
    length: u8,
    dont_care1: u8,
    pin_config: CDC,
    clock_output: ClockDevider,
    dac_config: DAC,
    adc_config: ADC,
    vid: u16,
    pid: u16,
    // USB power attributes(1) — This value will be used by the MCP2221A’s USB Configuration Descriptor (power attributes value) during the USB enumeration.
    power_attributes: u8,
    // USB requested number of mA(s)(1) — The requested mA value during the USB enumeration will represent the value at this index multiplied by 2.
    requested_mA: u8,
    donct_care5: [50]u8,

    pub fn init() ChipSettingsPacket {
        var cs_packet: ChipSettingsPacket = undefined;
        mem.set(u8, mem.asBytes(&cs_packet), 0);
        return cs_packet;
    }
};

pub fn GP(comptime i: u8) type {
    return packed struct {
        pub fn Functions(comptime a: u8) type {
            return switch (a) {
                0 => enum(u3) { gpio, sspnd, uart_rx_led },
                1 => enum(u3) { gpio, clk_output, adc1, uart_tx_led, int_detect },
                2 => enum(u3) { gpio, usb, adc2, dac1 },
                3 => enum(u3) { gpio, i2c_led, adc3, dac2 },
                else => enum(u3) { gpio },
            };
        }

        pub const Direction = enum(u1) { output, input };
        pub const Logic = enum(u1) { low, high };
        const PinFunctions = Functions(i);
        designation: PinFunctions,
        direction: Direction,
        value: Logic,
        dont_care: u3,
    };
}

pub const GPSettingsPacket = extern struct {
    command: Command,
    is_complete: CommandStatus,
    length: u8,
    dont_care: u8,

    gp0: GP(0),
    gp1: GP(1),
    gp2: GP(2),
    gp3: GP(3),

    dont_care2: [56]u8,
};

const CODE_IDX = 0;
const SUBCODE_IDX = 1;
const IS_COMPLETED_IDX = 1;

pub const StringPacket = extern struct {
    command: Command,
    is_complete: CommandStatus,
    length: u8,
    dont_cate: u8,
    utf16_string: [30]u16,

    pub fn toString(self: @This()) ![]u8 {
        var str: [60]u8 = undefined;
        _ = try std.unicode.utf16leToUtf8(&str, &self.utf16_string);
        return str[0..((self.length / 2) - 1)];
    }
};

pub const ChipFactorySerialNumberPacket = extern struct {
    data: [64]u8 = [_]u8{0} ** 64,
};

pub fn readFlashData(hid: *HID, flash_type: FlashDataTag) !FlashData {
    var packet = switch (flash_type) {
        .chip_settings => FlashData{ .chip_settings = undefined },
        .gp_settings => FlashData{ .gp_settings = undefined },
        .manufacture_string => FlashData{ .manufacture_string = undefined },
        .product_string => FlashData{ .product_string = undefined },
        .serial_number_string => FlashData{ .serial_number_string = undefined },
        .chip_factory_serial_number => FlashData{ .chip_factory_serial_number = undefined },
    };
    var bytes = mem.asBytes(&packet);
    bytes[CODE_IDX] = @enumToInt(Command.ReadFlashData);
    bytes[SUBCODE_IDX] = @enumToInt(flash_type);
    _ = try hid.write(bytes);
    _ = try hid.read(bytes);
    return if (bytes[CODE_IDX] == @enumToInt(Command.ReadFlashData) and bytes[IS_COMPLETED_IDX] == @enumToInt(CommandStatus.Completed))
        packet
    else
        error.InvalidCommand;
}

pub fn readChipSettings(hid: *HID) !ChipSettingsPacket {
    return (try readFlashData(hid, FlashDataTag.chip_settings)).chip_settings;
}

pub fn readGPSettings(hid: *HID) !GPSettingsPacket {
    return (try readFlashData(hid, FlashDataTag.gp_settings)).gp_settings;
}

pub fn readManufactorString(hid: *HID) !StringPacket {
    return (try readFlashData(hid, FlashDataTag.manufacture_string)).manufacture_string;
}

pub fn main() anyerror!void {
    var hid = try HID.open(0x04d8, 0x00dd);
    defer hid.close();
    // info("{hid = {}", .{hid});

    var status = try getStatus(hid);
    var chip_settings = try readChipSettings(hid);
    var gp_settings = try readGPSettings(hid);
    var manufacture = try readManufactorString(hid);

    info("Revision = {s}-{s}", .{ status.hw_rev, status.fw_rev });
    info("VID, PID = [{X}, {X}]", .{ chip_settings.vid, chip_settings.pid });
    info("DAC and ADC configs = {}\n{}.", .{ chip_settings.dac_config, chip_settings.adc_config });
    info("gp0 and gp1 configs = {}\n{}.", .{ gp_settings.gp0, gp_settings.gp1 });
    info("Manufacture = {s}", .{try (&manufacture).toString()});
}

const expect = std.testing.expect;
const print = std.debug.print;

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
}

test "ChipSettings sizes" {
    print("Size of ChipSettingsPacket = {d}\n", .{@sizeOf(ChipSettingsPacket)});
    print("Offset of DAC = {d}\n", .{@offsetOf(ChipSettingsPacket, "dac_config")});
    print("Offset of vid = {d}\n", .{@offsetOf(ChipSettingsPacket, "vid")});
}
