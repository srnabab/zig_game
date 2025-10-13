const std = @import("std");
const inn = @cImport(@cInclude("UUID/UUID.h"));
const tracy = @import("tracy");

const UUIDerr = error{
    ErrorUUID,
};

pub const len = 38;

pub fn createNewUUID(uuidStr: [*]u8) !void {
    const zone = tracy.initZone(@src(), .{ .name = "create new uuid" });
    defer zone.deinit();

    if (!inn.createNewUUID(@ptrCast(uuidStr))) return UUIDerr.ErrorUUID;
}
