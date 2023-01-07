
pub inline fn toError(err: c_int) anyerror{
    return @intToError(@bitCast(u16, @truncate(i16, -err)));
}

pub const no_str = "No error description.";
extern fn libusb_strerror(code: c_int) [*c]const u8;

pub inline fn toString(err: anyerror) [*:0]const u8 {
    var opt_str: ?[*:0]const u8 = libusb_strerror(@errorToInt(err));
    return if (opt_str) |str| str else no_str;
}
