const std = @import("std");
const inn = @cImport(@cInclude("UUID/UUID.h"));

const UUIDerr = error{
    ErrorUUID,
};

pub const len = 38;

pub fn createNewUUID(uuidStr: [*]u8) !void {
    if (!inn.createNewUUID(@ptrCast(uuidStr))) return UUIDerr.ErrorUUID;
}
