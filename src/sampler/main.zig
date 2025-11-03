const std = @import("std");
const builtin = @import("builtin");

const vk = @import("vulkan").vulkan;

var debug_allocator: std.heap.DebugAllocator(.{ .stack_trace_frames = 10 }) = .init;

const SamplerCreateInfo = extern struct {
    flags: vk.VkSamplerCreateFlags = @import("std").mem.zeroes(vk.VkSamplerCreateFlags),
    magFilter: vk.VkFilter = @import("std").mem.zeroes(vk.VkFilter),
    minFilter: vk.VkFilter = @import("std").mem.zeroes(vk.VkFilter),
    mipmapMode: vk.VkSamplerMipmapMode = @import("std").mem.zeroes(vk.VkSamplerMipmapMode),
    addressModeU: vk.VkSamplerAddressMode = @import("std").mem.zeroes(vk.VkSamplerAddressMode),
    addressModeV: vk.VkSamplerAddressMode = @import("std").mem.zeroes(vk.VkSamplerAddressMode),
    addressModeW: vk.VkSamplerAddressMode = @import("std").mem.zeroes(vk.VkSamplerAddressMode),
    mipLodBias: f32 = @import("std").mem.zeroes(f32),
    anisotropyEnable: vk.VkBool32 = @import("std").mem.zeroes(vk.VkBool32),
    maxAnisotropy: f32 = @import("std").mem.zeroes(f32),
    compareEnable: vk.VkBool32 = @import("std").mem.zeroes(vk.VkBool32),
    compareOp: vk.VkCompareOp = @import("std").mem.zeroes(vk.VkCompareOp),
    minLod: f32 = @import("std").mem.zeroes(f32),
    maxLod: f32 = @import("std").mem.zeroes(f32),
    borderColor: vk.VkBorderColor = @import("std").mem.zeroes(vk.VkBorderColor),
    unnormalizedCoordinates: vk.VkBool32 = @import("std").mem.zeroes(vk.VkBool32),
};

pub fn main() !void {
    const start = std.time.nanoTimestamp();

    var buffer1 = [_]u8{0} ** 1024;
    var buffer2 = [_]u8{0} ** 1024;

    const gpa, const is_debug = gpa: {
        break :gpa switch (builtin.mode) {
            .Debug, .ReleaseSafe => .{ debug_allocator.allocator(), true },
            .ReleaseFast, .ReleaseSmall => .{ std.heap.smp_allocator, false },
        };
    };
    defer if (is_debug) {
        _ = debug_allocator.deinit();
    };

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const args = try std.process.argsAlloc(gpa);
    defer std.process.argsFree(gpa, args);

    if (args.len < 2) {
        std.log.info(".exe [sampler json] (output file path)", .{});
        return;
    }

    const filePath = args[1];
    const outputPath = if (args.len > 2) args[2] else "a.sampler";

    var file = try std.fs.cwd().openFile(filePath, .{});
    defer file.close();

    var output = try std.fs.cwd().createFile(outputPath, .{});
    defer output.close();

    const stat = try file.stat();

    var reader = file.reader(&buffer1);
    const content = try reader.interface.readAlloc(arenaAllocator, stat.size);

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

    var writer = output.writer(&buffer2);
    try writer.interface.writeAll(&bytes);
    try writer.interface.flush();

    const endTime = std.time.nanoTimestamp();
    std.log.info("create sampler file {s} time: {d}ms", .{ args[3], @as(f128, @floatFromInt(endTime - start)) / @as(f128, @floatFromInt(std.time.ns_per_ms)) });
}
