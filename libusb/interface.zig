const enums = @import("enums.zig");
const Endpoint = @import("endpoint.zig").Endpoint;

pub const Interface = extern struct {
    altsetting: [*]Interface.Descriptor,
    num_altsetting: c_int,

    pub const Number = u8;

    pub fn getAltSettingArray(interface: *const Interface) []Interface.Descriptor {
        return interface.altsetting[0..@bitCast(c_uint, interface.num_altsetting)];
    }

    pub const Descriptor = extern struct {
        bLength: u8,
        bDescriptorType: enums.Descriptor.Type,
        bInterfaceNumber: Interface.Number,
        bAlternateSetting: u8,
        bNumEndpoints: u8,
        bInterfaceClass: enums.ClassCode,
        bInterfaceSubClass: enums.ClassCode,
        bInterfaceProtocol: u8,
        iInterface: u8,
        endpoint:[*] Endpoint.Descriptor,
        extra: [*] u8,
        extra_length: c_int,

        pub fn getEndpointArray(interface_desc: *const Interface.Descriptor) []Endpoint.Descriptor {
            return interface_desc.endpoint[0..interface_desc.bNumEndpoints];
        }
    };
};
