const std = @import("std");
pub const blake3 = @import("blake3");
const tracy = @import("tracy");

pub fn blake3HashContent(content: []const u8) [blake3.BLAKE3_OUT_LEN]u8 {
    const zone = tracy.initZone(@src(), .{ .name = "blake3 hash" });
    defer zone.deinit();

    var output = [_]u8{0} ** blake3.BLAKE3_OUT_LEN;
    var hasher: blake3.blake3_hasher = undefined;
    blake3.blake3_hasher_init(@ptrCast(&hasher));

    blake3.blake3_hasher_update(@ptrCast(&hasher), @ptrCast(content.ptr), content.len);
    blake3.blake3_hasher_finalize(@ptrCast(&hasher), @ptrCast(&output), blake3.BLAKE3_OUT_LEN);

    return output;
}
