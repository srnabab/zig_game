const std = @import("std");

const vk = @import("vulkan");
const fileSystem = @import("fileSystem");

const tracy = @import("tracy");

pub fn readSampler(id: u32, allocator: std.mem.Allocator) !vk.vulkan.VkSamplerCreateInfo {
    const zone = tracy.initZone(@src(), .{ .name = "read sampler" });
    defer zone.deinit();

    var buffer = [_]u8{0} ** 256;

    var file = try fileSystem.getFile(@intCast(id));
    defer file.close();

    var reader = file.reader(&buffer);
    const content = try reader.interface.readAlloc(allocator, @sizeOf(vk.vulkan.VkSamplerCreateInfo));
    defer allocator.free(content);

    // for (content) |value| {
    //     std.log.debug("{s}", .{std.fmt.hex(value)});
    // }

    if (content.len != @sizeOf(vk.vulkan.VkSamplerCreateInfo)) return error.FileSizeMismatch;

    const info: vk.vulkan.VkSamplerCreateInfo = std.mem.bytesToValue(vk.vulkan.VkSamplerCreateInfo, content.ptr);

    return info;
}
