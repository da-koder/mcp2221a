const toError = @import("errors.zig").toError;
const Endpoint = @import("endpoint.zig").Endpoint;
const DeviceHandle = @import("devicehandle.zig").DeviceHandle;
const Config = @import("config.zig").Config;
const Interface = @import("config.zig").Interface;
const enums = @import("enums.zig");

pub const Device = opaque {
    const Descriptor = extern struct {
        bLength: u8,
        bDescriptorType: enums.Descriptor.Type,
        bcdUSB: u16,
        bDeviceClass: u8,
        bDeviceSubClass: u8,
        bDeviceProtocol: u8,
        bMaxPacketSize0: u8,
        idVendor: u16,
        idProduct: u16,
        bcdDevice: u16,
        iManufacturer: u8,
        iProduct: u8,
        iSerialNumber: u8,
        bNumConfigurations: u8,
    };

// extern fn libusb_ref_device(dev: *Device) *Device;
    pub const refDevice = libusb_ref_device;
    
// extern fn libusb_unref_device(dev: *Device) void;
    pub const unrefDevice = libusb_unref_device;
    
// extern fn libusb_get_device_descriptor(dev: *Device, desc: ?*Device.Descriptor) c_int;
    pub fn  getDeviceDescriptor(dev: *Device) !Device.Descriptor {
        var descriptor: Device.Descriptor = undefined;
        var res = libusb_get_device_descriptor(dev, &descriptor);
        return if (res < 0) toError(res) else descriptor;
        
    }

// extern fn libusb_get_active_config_descriptor(dev: *Device, config: *?*Config.Descriptor) c_int;
    pub fn getActiveConfigDescriptor(dev: *Device) !*Config.Descriptor {
        var config_desc: *Config.Descriptor = undefined;
        var res = libusb_get_active_config_descriptor(dev, &config_desc);
        return if (res < 0) toError(res)  else config_desc;
    }

// extern fn libusb_get_config_descriptor(dev: *Device, config_index: u8, config: *?*Config.Descriptor) c_int;
    pub fn getConfigDescriptor(dev: *Device, config_index: u8) !*Config.Descriptor {
        var config_desc: *Config.Descriptor = undefined;
        var res = libusb_get_config_descriptor(dev, config_index, &config_desc);
        return if (res < 0) toError(res)  else config_desc;
    }
    
// extern fn libusb_get_config_descriptor_by_value(dev: *Device, bConfigurationValue: u8, config: [*c][*c]Config.Descriptor) c_int;
    pub fn getConfigDescriptorByValue(dev: *Device, bConfigurationValue: u8) !*Config.Descriptor {
        var config_desc: *Config.Descriptor = undefined;
        var res = libusb_get_config_descriptor_by_value(dev, bConfigurationValue, &config_desc);
        return if (res < 0) toError(res) else config_desc;
    }
    
// extern fn libusb_get_bus_number(dev: *Device) u8;
    pub const getBusNumber = libusb_get_bus_number;
// extern fn libusb_get_port_number(dev: *Device) u8;
    pub const getPortNumber = libusb_get_port_number;
// extern fn libusb_get_port_numbers(dev: *Device, port_numbers: [*c]u8, port_numbers_len: c_int) c_int;
    pub fn getPortNumbers(dev: *Device) ![]u8 {
        var port_numbers: []u8 = undefined;
        var res = libusb_get_port_numbers(dev, port_numbers.ptr, port_numbers.len);
        return if (res < 0) toError(res) else port_numbers;
    }

// extern fn libusb_get_parent(dev: *Device) *Device;
    pub const getParent = libusb_get_parent;
// extern fn libusb_get_device_address(dev: *Device) u8;
    pub const getDeviceAddress = libusb_get_device_address;
// extern fn libusb_get_device_speed(dev: *Device) Speed;
    pub const getDeviceSpeed = libusb_get_device_speed;
// extern fn libusb_get_max_packet_size(dev: *Device, endpoint: u8) c_int;
    pub fn getMaxPacketSize(dev: *Device, endpoint: *Endpoint) !i32 {
        var res = libusb_get_max_packet_size(dev, endpoint.Descriptor.bEndpointAddress);
        return if (res < 0) toError(res) else res;
    }
    
// extern fn libusb_get_max_iso_packet_size(dev: *Device, endpoint: u8) c_int;
    pub fn getMaxIsoPacketSize (dev: *Device, endpoint: *Endpoint) !i32 {
        var res = libusb_get_max_iso_packet_size(dev, endpoint.Descriptor.bEndpointAddress);
        return if (res < 0) toError(res) else res;
    }
// extern fn libusb_open(dev: *Device, dev_handle: **DeviceHandle) c_int;
    pub fn open(dev: *Device) !*DeviceHandle {
        var dev_handle: *DeviceHandle = undefined;
        var res = libusb_open(dev, &dev_handle);
        return if (res < 0) toError(res) else dev_handle;
    }
};



pub const Speed = enum(c_uint) {
    UNKNOWN = 0,
    LOW = 1,
    FULL = 2,
    HIGH = 3,
    SUPER = 4,
    SUPER_PLUS = 5,
};

extern fn libusb_ref_device(dev: *Device) *Device;
extern fn libusb_unref_device(dev: *Device) void;
extern fn libusb_get_device_descriptor(dev: *Device, desc: *Device.Descriptor) c_int;
extern fn libusb_get_active_config_descriptor(dev: *Device, config: **Config.Descriptor) c_int;
extern fn libusb_get_config_descriptor(dev: *Device, config_index: u8, config: **Config.Descriptor) c_int;
extern fn libusb_get_config_descriptor_by_value(dev: *Device, bConfigurationValue: u8, config: **Config.Descriptor) c_int;
extern fn libusb_get_bus_number(dev: *Device) u8;
extern fn libusb_get_port_number(dev: *Device) u8;
extern fn libusb_get_port_numbers(dev: *Device, port_numbers: [*]u8, port_numbers_len: c_int) c_int;
extern fn libusb_get_parent(dev: *Device) *Device;
extern fn libusb_get_device_address(dev: *Device) u8;
extern fn libusb_get_device_speed(dev: *Device) Speed;
extern fn libusb_get_max_packet_size(dev: *Device, endpoint: u8) c_int;
extern fn libusb_get_max_iso_packet_size(dev: *Device, endpoint: u8) c_int;
extern fn libusb_open(dev: *Device, dev_handle: **DeviceHandle) c_int; //dev_handle can't be null since it is populated only on successful return.


const expect = @import("std").testing.expect;
const print = @import("std").debug.print;
test "Interface offsets" {
    print("\nstring index........", .{});
        try expect( @offsetOf(Interface.Descriptor, "iInterface") == 8 );
    print("Ok\n", .{});
    print("enpoint array........", .{});
        try expect( @offsetOf(Interface.Descriptor, "endpoint") == 9 );
    print("Ok\n", .{});
}

test "Config offsects" {
    print("\nMaxPower........", .{});
        try expect( @offsetOf(Config.Descriptor, "MaxPower") == 8 );
    print("Ok\n", .{});

     print("bNumInterfaces........", .{});
        try expect( @offsetOf(Config.Descriptor, "bNumInterfaces") == 4 );
    print("Ok\n", .{});

    print("interface........", .{});
        try expect( @offsetOf(Config.Descriptor, "interface") == 9 );
    print("Ok\n", .{});
}
   
