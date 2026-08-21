const std = @import("std");
const builtin = @import("builtin");

const vk = @import("vulkan");

var debug_allocator: std.heap.DebugAllocator(.{ .stack_trace_frames = 10 }) = .init;

pub fn praseSampler(io: std.Io, content: []const u8, outputPath: []const u8, gpa: std.mem.Allocator) !void {
    var buffer2 = [_]u8{0} ** 1024;

    var output = try std.Io.Dir.createFileAbsolute(io, outputPath, .{});
    defer output.close(io);

    var json: std.json.Parsed(std.json.Value) = try std.json.parseFromSlice(std.json.Value, gpa, content, .{});
    defer json.deinit();

    var jsonValue = json.value;

    const info = vk.VkSamplerCreateInfo{
        .sType = vk.VK_STRUCTURE_TYPE_SAMPLER_CREATE_INFO,
        .pNext = null,
        .flags = @intCast(jsonValue.object.get("flags").?.integer),
        .magFilter = @intCast(jsonValue.object.get("magFilter").?.integer),
        .minFilter = @intCast(jsonValue.object.get("minFilter").?.integer),
        .mipmapMode = @intCast(jsonValue.object.get("mipmapMode").?.integer),
        .addressModeU = @intCast(jsonValue.object.get("addressModeU").?.integer),
        .addressModeV = @intCast(jsonValue.object.get("addressModeV").?.integer),
        .addressModeW = @intCast(jsonValue.object.get("addressModeW").?.integer),
        .mipLodBias = @floatCast(jsonValue.object.get("mipLodBias").?.float),
        .anisotropyEnable = @intFromBool(jsonValue.object.get("anisotropyEnable").?.bool),
        .maxAnisotropy = @floatCast(jsonValue.object.get("maxAnisotropy").?.float),
        .compareEnable = @intFromBool(jsonValue.object.get("compareEnable").?.bool),
        .compareOp = @intCast(jsonValue.object.get("compareOp").?.integer),
        .minLod = @floatCast(jsonValue.object.get("minLod").?.float),
        .maxLod = @floatCast(jsonValue.object.get("maxLod").?.float),
        .borderColor = @intCast(jsonValue.object.get("borderColor").?.integer),
        .unnormalizedCoordinates = @intFromBool(jsonValue.object.get("unnormalizedCoordinates").?.bool),
    };

    var bytes = std.mem.toBytes(info);

    var writer = output.writer(io, &buffer2);
    try writer.interface.writeAll(&bytes);
    try writer.interface.flush();

    std.log.debug("parse sampler {s}", .{outputPath});
}
