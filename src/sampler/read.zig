const std = @import("std");

const vk = @import("vulkan");
const fileSystem = @import("fileSystem");

const tracy = @import("tracy");

pub fn readSampler(io: std.Io, id: u32, allocator: std.mem.Allocator) !vk.VkSamplerCreateInfo {
    const zone = tracy.initZone(@src(), .{ .name = "read sampler" });
    defer zone.deinit();

    var buffer = [_]u8{0} ** 256;

    var file = try fileSystem.getFile(io, @intCast(id));
    defer file.close(io);

    var reader = file.reader(io, &buffer);
    const content = try reader.interface.readAlloc(allocator, @sizeOf(vk.VkSamplerCreateInfo));
    defer allocator.free(content);

    // for (content) |value| {
    //     std.log.debug("{s}", .{std.fmt.hex(value)});
    // }

    if (content.len != @sizeOf(vk.VkSamplerCreateInfo)) return error.FileSizeMismatch;

    const info: vk.VkSamplerCreateInfo = std.mem.bytesToValue(vk.VkSamplerCreateInfo, content.ptr);

    return info;
}
