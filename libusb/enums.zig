pub const ClassCode = enum(u8) {
    PER_INTERFACE = 0,
    AUDIO = 1,
    COMM = 2,
    HID = 3,
    PHYSICAL = 5,
    PRINTER = 7,
    IMAGE = 6,
    MASS_STORAGE = 8,
    HUB = 9,
    DATA = 10,
    SMART_CARD = 11,
    CONTENT_SECURITY = 13,
    VIDEO = 14,
    PERSONAL_HEALTHCARE = 15,
    DIAGNOSTIC_DEVICE = 220,
    WIRELESS = 224,
    APPLICATION = 254,
    VENDOR_SPEC = 255,
};

pub const TransferType = enum(u2) {
    CONTROL = 0,
    ISOCHRONOUS = 1,
    BULK = 2,
    INTERRUPT = 3,
};

pub const StandardRequest = enum(c_int) {
    GET_STATUS = 0,
    CLEAR_FEATURE = 1,
    SET_FEATURE = 3,
    SET_ADDRESS = 5,
    GET_DESCRIPTOR = 6,
    SET_DESCRIPTOR = 7,
    GET_CONFIGURATION = 8,
    SET_CONFIGURATION = 9,
    GET_INTERFACE = 10,
    SET_INTERFACE = 11,
    SYNCH_FRAME = 12,
    SET_SEL = 48,
    SET_ISOCH_DELAY = 49,
};

pub const RequestType = enum(u8) {
    STANDARD = 0,
    CLASS = 32,
    VENDOR = 64,
    RESERVED = 96,
};

pub const RequestRecipient = enum(c_int) {
    DEVICE = 0,
    INTERFACE = 1,
    ENDPOINT = 2,
    OTHER = 3,
};

pub const IsoSyncType = enum(u2) {
    NONE = 0,
    ASYNC = 1,
    ADAPTIVE = 2,
    SYNC = 3,
};

pub const IsoUsageType = enum(u2) {
    DATA = 0,
    FEEDBACK = 1,
    IMPLICIT = 2,
};


pub const Descriptor = extern struct {
    pub const Type = enum(u8) {
        DEVICE = 1,
        CONFIG = 2,
        STRING = 3,
        INTERFACE = 4,
        ENDPOINT = 5,
        BOS = 15,
        DEVICE_CAPABILITY = 16,
        HID = 33,
        REPORT = 34,
        PHYSICAL = 35,
        HUB = 41,
        SUPERSPEED_HUB = 42,
        SS_ENDPOINT_COMPANION = 48,
    };
};

pub const Capability = enum(u32) {
    CAPABILITY = 0x0000,
    HOTPLUG = 0x0001,
    HID_ACCESS = 0x0100,
    SUPPORTS_DETACH_KERNEL_DRIVER = 0x0101,
};
