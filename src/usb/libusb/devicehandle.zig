//!DeviceHandle wrapper.

const toError = @import("errors.zig").toError;
const Device = @import("device.zig").Device;
const Endpoint = @import("endpoint.zig").Endpoint;
const Interface = @import("interface.zig").Interface;

const enums = @import("enums.zig");
const RequestType = enums.RequestType;
const StandardRequest = enums.StandardRequest;
// const Descriptor = enums.Descriptor;

//Opened device structure.
pub const DeviceHandle = opaque {


    // extern fn libusb_get_configuration(dev: DeviceHandle, config: [*c]c_int) c_int;
    pub fn getConfiguration(dev: *DeviceHandle) !i16 {
        var config_value: i16 = undefined;
        var res = libusb_get_configuration(dev, &config_value);
        return if ( res < 0 ) toError(res) else config_value;
    }
        
    // extern fn libusb_get_bos_descriptor(dev_handle: *DeviceHandle, bos: *?*BOS.Descriptor) c_int;
    pub fn getBosDescriptor(dev_handle: *DeviceHandle) !*BOS.Descriptor {
        var bos: ?*BOS.Descriptor = undefined;
        var res = libusb_get_bos_descriptor(dev_handle, &bos);
        return if ( res < 0 ) toError(res)
            else if (bos) |desc| desc else error.InvalidBOS;
    }
        
    // extern fn libusb_close(dev_handle: *DeviceHandle) void;
    pub const close = libusb_close;
        
    // extern fn libusb_get_device(dev_handle: *DeviceHandle) ?*Device;
    pub const getDevice = libusb_get_device;
        
    // extern fn libusb_set_configuration(dev_handle: *DeviceHandle, configuration: c_int) c_int;
    pub fn setConfiguration(dev_handle: *DeviceHandle, config_value: c_int) !void {
        var res = libusb_set_configuration(dev_handle, config_value);
        return if ( res < 0 ) toError(res);
    }
        
    // extern fn libusb_claim_interface(dev_handle: *DeviceHandle, interface_number: Interface.Number) c_int;
    pub fn claimInterface(dev_handle: *DeviceHandle, interface_number: Interface.Number) !void {
        var res = libusb_claim_interface(dev_handle, interface_number);
        return if ( res < 0 ) toError(res);
    }
        
    // extern fn libusb_release_interface(dev_handle: *DeviceHandle, interface_number: Interface.Number) c_int;
    pub fn releaseInterface(dev_handle: *DeviceHandle, interface_number: Interface.Number) !void {
        var res = libusb_release_interface(dev_handle, interface_number);
        return if ( res < 0 ) toError(res);
    }
        
    // extern fn libusb_set_interface_alt_setting(dev_handle: *DeviceHandle, interface_number: Interface.Number, alternate_setting: c_int) c_int;
    pub fn setInterfaceAltSetting(dev_handle: *DeviceHandle, interface_number: Interface.Number, alternate_setting: c_int) !void {
        var res = libusb_set_interface_alt_setting(dev_handle, interface_number, alternate_setting);
        return if ( res < 0 ) toError(res);
    }
        
    // extern fn libusb_clear_halt(dev_handle: *DeviceHandle, endpoint: u8) c_int;
    pub fn clearHalt(dev_handle: *DeviceHandle, endpoint: Endpoint.Address) !void {
        var res = libusb_clear_halt(dev_handle, endpoint);
        return if ( res < 0 ) toError(res);
    }
        
    // extern fn libusb_reset_device(dev_handle: *DeviceHandle) c_int;
    pub fn resetDevice(dev_handle: *DeviceHandle) !void {
        var res = libusb_reset_device(dev_handle);
        return if ( res < 0) toError(res);
    }

    // extern: fn libusb_alloc_streams(dev_handle: *DeviceHandle, num_streams: u32, endpoints: [*c]u8, num_endpoints: c_int) c_int;
    pub fn allocStreams(dev_handle: *DeviceHandle, num_streams: u32, endpoints: []Endpoint.Address) !void {
        var res = libusb_alloc_streams(dev_handle, num_streams, endpoints.ptr, @as(c_int,endpoints.len));
        return if ( res < 0 ) toError(res);
   }
        
    // extern fn libusb_free_stream(dev_handle: *DeviceHandle, endpoints: [*c]u8, num_endpoints: c_int) c_int;
    pub fn freeStreams(dev_handle: *DeviceHandle, endpoints: []Endpoint.Address) !void {
        var res = libusb_free_streams(dev_handle, endpoints.ptr, @as(c_int,endpoints.len));
        return if ( res < 0 ) toError(res);
    }
        
    // extern fn libusb_dev_mem_alloc(dev_handle: *DeviceHandle, length: usize) [*c]u8;
    pub const devMemAlloc = libusb_dev_mem_alloc;
        
    // extern fn libusb_dev_mem_free(dev_handle: *DeviceHandle, buffer: [*c]u8, length: usize) c_int;
    pub fn devMemFree(dev_handle: *DeviceHandle, buffer: []u8) !void {
        var res = libusb_dev_mem_free(dev_handle, buffer.ptr, buffer.len);
        return if ( res < 0 ) toError(res);
    }
        
    // extern fn libusb_kernel_driver_active(dev_handle: *DeviceHandle, interface_number: Interface.Number) c_int;
    pub fn isKernelDriverActive(dev_handle: *DeviceHandle, interface_number: Interface.Number) !bool {
        var res = libusb_kernel_driver_active(dev_handle, interface_number);
        return if ( res < 0 ) toError(res) else if(res == 0) false else true;
    }
        
    // extern fn libusb_detach_kernel_driver(dev_handle: *DeviceHandle, interface_number: Interface.Number) c_int;
    pub fn detachKernelDriver(dev_handle: *DeviceHandle, interface_number: Interface.Number) !void {
        var res = libusb_detach_kernel_driver(dev_handle, interface_number);
        return if ( res < 0 ) toError(res);
    }
        
    // extern fn libusb_attach_kernel_driver(dev_handle: *DeviceHandle, interface_number: Interface.Number) c_int;
    pub fn attachKernelDriver(dev_handle: *DeviceHandle, interface_number: Interface.Number) !void {
        var res = libusb_attach_kernel_driver(dev_handle, interface_number);
        return if ( res < 0 ) toError(res);
    }
        
    // extern fn libusb_set_auto_detach_kernel_driver(dev_handle: *DeviceHandle, enable: c_int) c_int;
    pub fn setAutoDetachKernelDriver(dev_handle: *DeviceHandle, enable: bool) !void {
        var res = libusb_set_auto_detach_kernel_driver(dev_handle, if(enable) 1 else 0);
        if ( res < 0 ) return toError(res);
    }
        
    // extern fn libusb_control_transfer(dev_handle: *DeviceHandle, request_type: RequestType, bRequest: u8, wValue: u16, wIndex: u16, data: [*]u8, wLength: u16, timeout: c_uint) c_int;
    pub fn controlTransfer(dev_handle: *DeviceHandle, request_type: RequestType, bRequest: u8, wValue: u16, wIndex: u16, data: []u8, timeout: c_uint) !usize {
        var res = libusb_control_transfer(dev_handle, request_type, bRequest, wValue, wIndex, data.ptr, @truncate(u16,data.len), timeout);
        return if ( res < 0 ) toError(res) else @bitCast(usize,res);
    }
        
    // extern fn libusb_bulk_transfer(dev_handle: *DeviceHandle, endpoint: u8, data: [*]u8, length: c_int, actual_length: [*]c_int, timeout: c_uint) c_int;
    pub fn bulkTransfer(dev_handle: *DeviceHandle, endpoint: Endpoint.Address, data: []u8, timeout: c_uint) !usize {
        var actual_length: c_int = undefined;
        var length = @bitCast(c_int, @truncate(c_uint, data.len));
        var res = libusb_bulk_transfer(dev_handle, endpoint, data.ptr, length, &actual_length, timeout);
        return if ( res < 0 ) toError(res) else @bitCast(usize, actual_length);
    }
        
    // extern fn libusb_interrupt_transfer(dev_handle: *DeviceHandle, endpoint: u8, data: [*]u8, length: c_int, actual_length: *c_int, timeout: c_uint) c_int;
    pub fn interruptTransfer(dev_handle: *DeviceHandle, endpoint: Endpoint.Address, data: []u8, timeout: c_uint) !usize {
        var actual_length: c_int = undefined;
        var length = @bitCast(c_int, @truncate(c_uint, data.len));
        var res = libusb_interrupt_transfer(dev_handle, @bitCast(u8,endpoint), data.ptr, length, &actual_length, timeout);
        return if ( res < 0 ) toError(res) else @bitCast(c_uint,res);
    }
        
    // extern fn libusb_get_string_descriptor_ascii(dev_handle: ?DeviceHandle, desc_index: u8, data: [*c]u8, length: c_int) c_int;
    pub fn getStringDescriptorAscii(dev_handle: *DeviceHandle, desc_index: u8, buffer: []u8) !usize {
        var res = libusb_get_string_descriptor_ascii(dev_handle, desc_index, buffer.ptr, buffer.len);
        return if ( res < 0 ) toError(res) else @bitCast(usize,res);
    }

    pub const getDescriptor = libusb_get_descriptor;
    inline fn libusb_get_descriptor(arg_dev_handle: *DeviceHandle, arg_desc_type: u8, arg_desc_index: u8, arg_data: []u8) c_int {
        var data = arg_data.ptr;
        var wValue = (@as(c_ushort, arg_desc_type) <<  8) | @as(c_ushort, arg_desc_index);
        var wIndex = @as(c_ushort, 0);
        var wLength = @truncate(u16, arg_data.len);
        return libusb_control_transfer(arg_dev_handle, Endpoint.Direction.IN, StandardRequest.GET_DESCRIPTOR, wValue, wIndex, data, wLength,  1000);
    }

    pub const getStringDescriptor = libusb_get_string_descriptor;
    inline fn libusb_get_string_descriptor(arg_dev_handle: *DeviceHandle, arg_desc_index: u8, arg_langid: u16, arg_data: []u8) c_int {
        var wIndex = arg_langid;
        var data = arg_data.ptr;
        var wValue = @as(u16, @enumToInt(enums.Descriptor.Type.STRING) <<  8) |  @as(u16, arg_desc_index);
        var wLength = @bitCast(u16, @truncate(c_short, arg_data.len));
        return libusb_control_transfer(arg_dev_handle, Endpoint.Direction.IN, @enumToInt(StandardRequest.GET_DESCRIPTOR), wValue, wIndex, data, wLength,  1000);
    }
};

pub const BOS = extern struct {
    pub const Type = enum(c_uint) {
        WIRELESS_USB_DEVICE_CAPABILITY = 1,
        USB_2_0_EXTENSION = 2,
        SS_USB_DEVICE_CAPABILITY = 3,
        CONTAINER_ID = 4,
    };

    pub const DeviceCapability = extern struct {
        const Descriptor = extern struct {
            bLength: u8 align(1),
            bDescriptorType: enums.Descriptor.Type,
            bDevCapabilityType: u8,
            dev_capability_data: [*c]u8,
        };
    };

    pub const Descriptor = extern struct {
        bLength: u8 align(8),
        bDescriptorType: enums.Descriptor.Type,
        wTotalLength: u16,
        bNumDeviceCaps: u8,
        dev_capabilitty: [0]BOS.DeviceCapability.Descriptor,
    };
};

extern fn libusb_get_configuration(dev_handle: *DeviceHandle, config: [*]c_int) c_int;
extern fn libusb_get_bos_descriptor(dev_handle: *DeviceHandle, bos: *?*BOS.Descriptor) c_int;
extern fn libusb_close(dev_handle: *DeviceHandle) void;
extern fn libusb_get_device(dev_handle: *DeviceHandle) ?*Device;
extern fn libusb_set_configuration(dev_handle: *DeviceHandle, configuration: c_int) c_int;
extern fn libusb_claim_interface(dev_handle: *DeviceHandle, interface_number: Interface.Number) c_int;
extern fn libusb_release_interface(dev_handle: *DeviceHandle, interface_number: Interface.Number) c_int;
extern fn libusb_set_interface_alt_setting(dev_handle: *DeviceHandle, interface_number: Interface.Number, alternate_setting: c_int) c_int;
extern fn libusb_clear_halt(dev_handle: *DeviceHandle, endpoint: Endpoint.Address) c_int;
extern fn libusb_reset_device(dev_handle: *DeviceHandle) c_int;
extern fn libusb_alloc_streams(dev_handle: *DeviceHandle, num_streams: u32, endpoints: [*]Endpoint.Address, num_endpoints: c_int) c_int;
extern fn libusb_free_streams(dev_handle: *DeviceHandle, endpoints: [*]Endpoint.Address, num_endpoints: c_int) c_int;
extern fn libusb_dev_mem_alloc(dev_handle: *DeviceHandle, length: usize) ?[*]u8;
extern fn libusb_dev_mem_free(dev_handle: *DeviceHandle, buffer: [*]u8, length: usize) c_int;
extern fn libusb_kernel_driver_active(dev_handle: *DeviceHandle, interface_number: Interface.Number) c_int;
extern fn libusb_detach_kernel_driver(dev_handle: *DeviceHandle, interface_number: Interface.Number) c_int;
extern fn libusb_attach_kernel_driver(dev_handle: *DeviceHandle, interface_number: Interface.Number) c_int;
extern fn libusb_set_auto_detach_kernel_driver(dev_handle: *DeviceHandle, enable: c_int) c_int;
extern fn libusb_control_transfer(dev_handle: *DeviceHandle, request_type: RequestType, bRequest: u8, wValue: u16, wIndex: u16, data: [*]u8, wLength: u16, timeout: c_uint) c_int;
extern fn libusb_bulk_transfer(dev_handle: *DeviceHandle, endpoint: Endpoint.Address, data: [*c]u8, length: c_int, actual_length: [*]c_int, timeout: c_uint) c_int;
extern fn libusb_interrupt_transfer(dev_handle: *DeviceHandle, endpoint: u8, data: [*c]u8, length: c_int, actual_length: *c_int, timeout: c_uint) c_int;
extern fn libusb_get_string_descriptor_ascii(dev_handle: ?DeviceHandle, desc_index: u8, data: [*c]u8, length: c_int) c_int;
