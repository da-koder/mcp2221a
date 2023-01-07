
const libusb = @import("libusb.zig");
const std = @import("std");
const print = std.debug.print;
const assert = std.debug.assert;

test "Initialization" {
    if (libusb.Context.init()) |ctx| {
        defer ctx.deinit();
        std.debug.print("Inside init...\n", .{});
    } else |err| {
        std.debug.print("Error occured: {s}", .{@errorName(err)});
    }
}

fn log(ctx: ?*libusb.Context, lvl: libusb.Log.Level, msg: [*:0]const u8) callconv(.C) void {
    _ = ctx;
    switch(lvl) {
        .ERROR => std.log.err("{s}", .{msg}),
        .WARNING => std.log.warn("{s}", .{msg}),
        .INFO => std.log.info("{s}", .{msg}),
        else => std.log.debug("{s}", .{msg}),
    }
}

test "Info level debug" {
    if (libusb.Context.init()) |ctx| {
        defer ctx.deinit();
        print("Inside Info level.\n", .{});
        ctx.setLogCb(log, libusb.Log.CallBack.Mode.CONTEXT);
        ctx.setOption(libusb.Option.LOG_LEVEL, .{libusb.Log.Level.INFO}) catch |err| print("setOption failed: {s}.\n", .{@errorName(err)});
    } else |err| {
        print("Error occured: {s}", .{@errorName(err)});
    }
}

test "Device Array" {
    if (libusb.Context.init()) |ctx| {
        defer ctx.deinit();
        print("Inside Info level.\n", .{});
        ctx.setLogCb(log, libusb.Log.CallBack.Mode.CONTEXT);
        ctx.setOption(libusb.Option.LOG_LEVEL, .{libusb.Log.Level.INFO}) catch |err| print("setOption failed: {s}.\n", .{@errorName(err)});

        var dev_list = ctx.getDeviceArray() catch |err| print("getDeviceArray failed: {s}", .{@errorName(err)});
        defer libusb.Context.freeDeviceArray(dev_list);
        assert(dev_list.len > 0);
    } else |err| {
        print("Error occured: {s}", .{@errorName(err)});
    }
}

