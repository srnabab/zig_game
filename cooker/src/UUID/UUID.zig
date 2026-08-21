const std = @import("std");
const inn = @import("UUID_C");

const UUIDerr = error{
    ErrorUUID,
};

pub const len = 38;

pub fn createNewUUID2(allocator: std.mem.Allocator) ![]u8 {
    const uuidStr = try allocator.alloc(u8, len);

    if (!inn.createNewUUID(@ptrCast(uuidStr.ptr))) return UUIDerr.ErrorUUID;
    return uuidStr;
}

pub fn createNewUUID(uuidStr: [*]u8) !void {
    if (!inn.createNewUUID(@ptrCast(uuidStr))) return UUIDerr.ErrorUUID;
}
