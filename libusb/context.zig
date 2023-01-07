//! I've decided to use *varieble as pointers instead of ?*varieble.
//! Optional will be used when creating a struct/opaque from c code.
//! The rest of the time it will be *Struct.
//! The original(the one i'm wrapping) c api will be private.
//
//! The error will have to be handled via switch(enum),
//!  using @intToError didn't work since c functions return c_int whereas @intToError expects u16.
//!  This causes unreadable code @intToError( @bitCast(u16, @truncate(i16, -err)));

//const Device = @import("device.zig").Device;

//const DeviceHandle = @import("devicehandle.zig").DeviceHandle;

const struct_timeval = @cImport(@cInclude("sys/time.h")).struct_timeval;
const std = @import("std");

const Device = @import("device.zig").Device;
const DeviceHandle = @import("devicehandle.zig").DeviceHandle;
const Capability = @import("enums.zig").Capability;
const toError = @import("errors.zig").toError;

const DeviceArray = [*]*Device;

pub const Context = opaque {

    // extern fn libusb_init(*?*Context) c_int;
    pub fn init() !*Context {
        var optional_ctx: ?*Context = undefined;
        var res = libusb_init (&optional_ctx);
        if (optional_ctx) |ctx|
            return if (res < 0) toError(res) else ctx
        else 
            return error.NULL_CONTEXT;
   }

// extern fn libusb_set_debug(*Context, Log.Level) anyopaque;
    pub fn setDebug(ctx: *Context, level: Log.Level) void {
        libusb_set_debug( ctx, @enumToInt(level) );
    }

    pub const setLogCb = libusb_set_log_cb;
// extern fn libusb_set_log_cb(*Context, Log.CallBack.Fn, Log.CallBack.Mode);
    // pub fn setLogCb(ctx: *Context, cb: Log.CallBack.Fn, mode: Log.CallBack.Mode) void {
    //     libusb_set_log_cb(ctx, cb, @enumToInt(mode));
    // }

// extern fn libusb_get_device_list(ctx: *Context, list: *?[*]?*Device) isize
    pub fn getDeviceArray(ctx: *Context) ![]*Device {
        var arr: DeviceArray = undefined;
        var res = libusb_get_device_list(ctx, &arr);
        var slice: []*Device = arr[0..@bitCast(usize,res)];
        return if (res >= 0) slice else toError(-@truncate(c_int,res));
    }

    pub fn freeDeviceArray(list: []*Device) void {
        libusb_free_device_list(list.ptr, 1);
    }
//     extern fn libusb_get_port_path(ctx: *Context, dev: ?Device, path: [*c]u8, path_length: u8) c_int
    //const getPortPath(ctx: *Context, dev: ?Device, path: [*c]u8, path_length: u8)  = libusb_get_port_path;
    // pub fn wrapSysDevice(ctx: *Context, sys_dev: isize) !void {
    //     var hdl: [*c]?DeviceHandle = undefined;
    //     var res = libusb_wrap_sys_device(ctx, sys_dev, hdl);
    //     return if (res < 0) toError(res) else res;
    // }
    
    pub fn openDeviceWithVidPid(ctx: *Context, vendor_id: u16, product_id: u16) !*DeviceHandle {
        var optional_dev_handle = libusb_open_device_with_vid_pid(ctx, vendor_id, product_id);
        return if (optional_dev_handle) |dev_handle| dev_handle else error.OpenError;
    }
    
    // pub extern fn libusb_free_pollfds(pollfds: [*c][*c]const PollFd) void;
    pub fn freePollFds(ctx: *Context, pollfds: [*:null]?*PollFd) void {
        libusb_free_pollfds(ctx, pollfds.ptr);
    }

// extern fn libuusb_exit(*Context) void;
    pub const deinit = libusb_exit;
//     extern fn libusb_try_lock_events(ctx: *Context) c_int
    pub fn tryLockEvents(ctx: *Context) bool {
        var res = libusb_try_lock_events(ctx);
        return if ( res == 0 ) true else false;
    }

//     extern fn libusb_lock_events(ctx: *Context) void
    pub const lockEvents = libusb_lock_events;
//     extern fn libusb_unlock_events(ctx: *Context) void
    pub const unlockEvents = libusb_unlock_events;
//     extern fn libusb_event_handling_ok(ctx: *Context) c_int
    pub fn eventHandlingOk(ctx: *Context) bool { //Should the thread continue?
        var res = libusb_event_handling_ok(ctx);
        return if ( res == 0 ) false else true;
    }

//     extern fn libusb_event_handler_active(ctx: *Context) c_int
    pub fn eventHandlerActive(ctx: *Context) bool { //Is there a thread handling events?
        var res = libusb_event_handler_active(ctx);
        return if ( res == 0 ) false else true;
    }

//     extern fn libusb_interrupt_event_handler(ctx: *Context) void
    pub const interruptEventHandler = libusb_interrupt_event_handler;
//     extern fn libusb_lock_event_waiters(ctx: *Context) void
    pub const lockEventWaiters = libusb_lock_event_waiters;
//     extern fn libusb_unlock_event_waiters(ctx: *Context) void
    pub const unlockEventWaiters = libusb_unlock_event_waiters;
//     extern fn libusb_wait_for_event(ctx: *Context, tv: [*c]struct_timeval) c_int
    pub fn waitForEvent(ctx: *Context, tv: ?*struct_timeval) !bool { // Is it a timeout.
        var res = libusb_wait_for_event(ctx, tv);
        return if (res < 0) toError(res)
            else if (res == 0) false else true;
    }

//     extern fn libusb_handle_events_timeout(ctx: *Context, tv: [*c]struct_timeval) c_int
    pub fn handleEventsTimeout(ctx: *Context, tv: ?*struct_timeval) !void {
        var res = libusb_handle_events_timeout(ctx, tv);
        return if ( res < 0 ) toError(res);
    }

//     extern fn libusb_handle_events_timeout_completed(ctx: *Context, tv: [*c]struct_timeval, completed: [*c]c_int) c_int
    pub fn handleEventsTimeoutCompleted(ctx: *Context, tv: ?*struct_timeval, completed: [*c]c_int) !void {
        var res = libusb_handle_events_timeout_completed(ctx, tv, completed);
        return if ( res < 0 ) toError(res);
    }

//     extern fn libusb_handle_events(ctx: *Context) c_int
    pub fn handleEvents(ctx: *Context) !void {
        var res = libusb_handle_events(ctx);
        return if ( res < 0 ) toError(res);
    }

//     extern fn libusb_handle_events_completed(ctx: *Context, completed: [*c]c_int) c_int
    pub fn handleEventsCompleted(ctx: *Context, completed: [*c]c_int) !void {
        var res = libusb_handle_events_completed(ctx, completed);
        return if ( res < 0 ) toError(res);
    }

//     extern fn libusb_handle_events_locked(ctx: *Context, tv: [*c]struct_timeval) c_int
    pub fn handleEventsLocked(ctx: *Context, tv: ?*struct_timeval) !void {
        var res = libusb_handle_events_locked(ctx, tv);
        return if ( res < 0 ) toError(res);
    }

//     extern fn libusb_pollfds_handle_timeouts(ctx: *Context) c_int
    pub fn pollfdsHandleTimeouts(ctx: *Context) bool { //Don't call into libusb at times determined by getNextTimeout.
        var res = libusb_pollfds_handle_timeouts(ctx);
        return if (res == 0) false else true;
    }

//     extern fn libusb_get_next_timeout(ctx: *Context, tv: [*c]struct_timeval) c_int
    pub fn getNextTimeout(ctx: *Context, tv: ?*struct_timeval) !bool { //Is there a timeout pending.
        var res = libusb_get_next_timeout(ctx, tv);
        return if (res < 0) toError(res)
            else if (res == 0) false else true;
    }

//     extern fn libusb_get_pollfds(ctx: *Context) [*c][*c]const PollFd
    pub fn  getPollfds(ctx: *Context) ![*:null]const PollFd {
        return libusb_get_pollfds(ctx);
    }

//     extern fn libusb_set_pollfd_notifiers(ctx: *Context, added_cb: PollFd.CallBack.added
//    , removed_cb: PollFd.CallBack.removed, user_data: ?*anyopaque) void
    pub const setPollfdNotifiers = libusb_set_pollfd_notifiers;
//     extern fn libusb_hotplug_register_callback(ctx: *Context, events: Hotplug.Event, flags: Hotplug.Flag, vendor_id: c_int, product_id: c_int, dev_class: c_int, cb_fn: libusb_hotplug_callback_fn, user_data: ?*anyopaque, callback_handle: [*c]Hotplug.CallBack.Handle) c_int
    pub fn hotplugRegisterCallback(ctx: *Context, events: Hotplug.Event, flags: Hotplug.Flag, vendor_id: c_int, product_id: c_int, dev_class: c_int, cb_fn: Hotplug.CallBack.Fn, user_data: ?*anyopaque, callback_handle: [*c]Hotplug.CallBack.Handle) !void {
        var res = libusb_hotplug_register_callback(ctx, events, flags, vendor_id, product_id, dev_class, cb_fn, user_data, callback_handle);
        return if ( res < 0 ) toError(res);
    }

//     extern fn libusb_hotplug_deregister_callback(ctx: *Context, callback_handle: Hotplug.CallBack.Handle) void
    pub const hotplugDeregisterCallback = libusb_hotplug_deregister_callback;
//     extern fn libusb_set_option(ctx: *Context, option: enum_Option, ...) c_int
    pub fn setOption(ctx: *Context, option: Option, option_arg: anytype) !void {
        var res = switch(option) {
            .LOG_LEVEL => libusb_set_option(ctx, option, @enumToInt(option_arg[0])),
            .USE_USBDK => libusb_set_option(ctx, option),
            .NO_DEVICE_DISCOVERY => libusb_set_option(ctx, option),
            else => -1,
        };
        return if ( res < 0 ) toError(res); }

};

pub const Log = struct {
    pub const Level = enum(c_int) {
        NONE = 0,
        ERROR = 1,
        WARNING = 2,
        INFO = 3,
        DEBUG = 4,
    };

    pub const CallBack = struct {
        pub const Mode = enum(c_int) {
            GLOBAL = 1,
            CONTEXT = 2,
        };

        pub const Fn = ?fn (*Context, Log.Level, [*:0]const u8) callconv(.C) void;
    };
};

pub const Hotplug = struct {
    pub const Flag = enum(c_int) {
        NO_FLAGS = 0,
        ENUMERATE = 1,
    };

    //Used in paremeter(vendor_id, product_id, dev_class) to register hotplug callback.
    pub const MATCH_ANY = -1;

    pub const CallBack = extern struct {
        pub const Handle = c_int;
        pub const Fn = ?fn (?Context, *Device, Hotplug.Event, *anyopaque) callconv(.C) c_int;
    };
    pub const Event = enum(c_uint) {
        DEVICE_ARRIVED = 1,
        DEVICE_LEFT = 2,
    };
};

pub const Option = enum(c_uint) {
    LOG_LEVEL,
    USE_USBDK,
    NO_DEVICE_DISCOVERY,
    MAX,
};

pub const PollFd = extern struct {
    fd: c_int,
    events: c_short,

    pub const CallBack = struct {
        pub const added = ?fn (c_int, c_short, ?*anyopaque) callconv(.C) void;
        pub const removed = ?fn (c_int, ?*anyopaque) callconv(.C) void;
    };

};

pub fn hasCapability(cap: Capability) bool {
    return if ( libusb_has_capability(cap) == 0 ) false else true;
}

extern fn libusb_init(*?*Context) c_int;

extern fn libusb_has_capability( Capability ) c_int;

extern fn libusb_exit(*Context) void;

extern fn libusb_get_device_list(ctx: *Context, list: *DeviceArray) isize;

extern fn libusb_free_device_list(list: DeviceArray, unref: c_int) void;

// extern fn libusb_get_port_path(ctx: *Context, dev: ?Device, path: [*c]u8, path_length: u8) c_int;

// extern fn libusb_wrap_sys_device(*Context, isize, **DeviceHandle) c_int;

// extern fn libusb_open(*Device, **DeviceHandle) c_int;

extern fn libusb_open_device_with_vid_pid(*Context, u16, u16) ?*DeviceHandle;

extern fn libusb_set_debug(*Context, Log.Level) anyopaque;

extern fn libusb_set_log_cb(*Context, Log.CallBack.Fn, Log.CallBack.Mode) void;

extern fn libusb_try_lock_events(ctx: *Context) c_int;

extern fn libusb_lock_events(ctx: *Context) void;

extern fn libusb_unlock_events(ctx: *Context) void;

extern fn libusb_event_handling_ok(ctx: *Context) c_int;

extern fn libusb_event_handler_active(ctx: *Context) c_int;

extern fn libusb_interrupt_event_handler(ctx: *Context) void;

extern fn libusb_lock_event_waiters(ctx: *Context) void;

extern fn libusb_unlock_event_waiters(ctx: *Context) void;

extern fn libusb_wait_for_event(ctx: *Context, tv: ?*struct_timeval) c_int;

extern fn libusb_handle_events_timeout(ctx: *Context, tv: ?*struct_timeval) c_int;

extern fn libusb_handle_events_timeout_completed(ctx: *Context, tv: ?*struct_timeval, completed: [*c]c_int) c_int;

extern fn libusb_handle_events(ctx: *Context) c_int;

extern fn libusb_handle_events_completed(ctx: *Context, completed: [*c]c_int) c_int;

extern fn libusb_handle_events_locked(ctx: *Context, tv: ?*struct_timeval) c_int;

extern fn libusb_pollfds_handle_timeouts(ctx: *Context) c_int;

extern fn libusb_get_next_timeout(ctx: *Context, tv: ?*struct_timeval) c_int;

extern fn libusb_get_pollfds(ctx: *Context) [*c][*c]const PollFd;

extern fn libusb_set_pollfd_notifiers(ctx: *Context, added_cb: PollFd.CallBack.added, removed_cb: PollFd.CallBack.removed, user_data: ?*anyopaque) void;

extern fn libusb_hotplug_register_callback(ctx: *Context, events: Hotplug.Event, flags: Hotplug.Flag, vendor_id: c_int, product_id: c_int, dev_class: c_int, cb_fn: Hotplug.CallBack.Fn, user_data: ?*anyopaque, callback_handle: [*c]Hotplug.CallBack.Handle) c_int;

extern fn libusb_hotplug_deregister_callback(ctx: *Context, callback_handle: Hotplug.CallBack.Handle) void;

extern fn libusb_set_option(ctx: *Context, option: Option, ...) c_int;

extern fn libusb_free_pollfds(pollfds: [*c][*c]const PollFd) void;

