const std = @import("std");

const vk = @import("vulkan");

const samplerRead = @import("sampler");
const resultToError = @import("resultToError");
const file = @import("fileSystem");
const global = @import("global");

const checkVkResult = resultToError.checkVkResult;

pub const SamplerType = enum {
    pixel2d,
};

const Self = @This();

samplers: [global.TotalSamplerCount]vk.VkSampler = undefined,

pub fn _createSampler(
    io: std.Io,
    device: vk.VkDevice,
    db: file.sqlite3,
    pAllocCallBacks: [*c]vk.VkAllocationCallbacks,
    allocator: std.mem.Allocator,
    ID: i32,
    anisotropy: f32,
) !vk.VkSampler {
    var info = try samplerRead.readSampler(io, ID, db, allocator);
    info.maxAnisotropy = anisotropy;

    var sampler: vk.VkSampler = null;

    try checkVkResult(vk.vkCreateSampler(device, @ptrCast(&info), pAllocCallBacks, @ptrCast(&sampler)));

    return sampler;
}

pub fn initSamplers(
    self: *Self,
    io: std.Io,
    device: vk.VkDevice,
    fileNames: [][]const u8,
    db: file.sqlite3,
    pAllocCallBacks: [*c]vk.VkAllocationCallbacks,
    allocator: std.mem.Allocator,
) !void {
    std.debug.assert(fileNames.len == global.TotalSamplerCount);

    for (fileNames, 0..) |name, i| {
        self.samplers[i] = try _createSampler(
            io,
            device,
            db,
            pAllocCallBacks,
            allocator,
            file.getID(name),
            1.0,
        );
    }
}

pub fn destroySamplers(self: *Self, device: vk.VkDevice, pAllocCallBacks: [*c]vk.VkAllocationCallbacks) void {
    for (self.samplers) |sampler| {
        vk.vkDestroySampler(device, sampler, pAllocCallBacks);
    }
}
