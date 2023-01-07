const enums = @import("enums.zig");
const Interface = @import("interface.zig").Interface;

pub const Config = extern struct {

    pub const Value = u8;
    
    pub const Descriptor = extern struct {
        bLength: u8,
        bDescriptorType: enums.Descriptor.Type,
        wTotalLength: u16,
        bNumInterfaces: u8,
        bConfigurationValue: Config.Value,
        iConfiguration: u8,
        bmAttributes: u8,
        maxPower: u8,
        interface: [*]Interface,
        extra: [*]u8,
        extra_length: c_int,

    // extern fn libusb_free_config_descriptor(config_desc: *Config.Descriptor) void;
        pub const free = libusb_free_config_descriptor;

        pub fn getInterfaceArray(desc: *Config.Descriptor) []Interface {
            return desc.interface[0..desc.bNumInterfaces];
        }
    };

};

extern fn libusb_free_config_descriptor(config_desc: *Config.Descriptor) void;
