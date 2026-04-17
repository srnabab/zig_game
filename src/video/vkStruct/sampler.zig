const std = @import("std");

const vk = @import("vulkan");

const samplerRead = @import("sampler");
const resultToError = @import("resultToError");
const file = @import("fileSystem");

const checkVkResult = resultToError.checkVkResult;

pub const SamplerType = enum {
    pixel2d,
};

const Self = @This();

pixel2dSampler: vk.VkSampler = null,

pub fn _createSampler(io: std.Io, device: vk.VkDevice, pAllocCallBacks: [*c]vk.VkAllocationCallbacks, allocator: std.mem.Allocator, ID: u32, anisotropy: f32) !vk.VkSampler {
    var info = try samplerRead.readSampler(io, ID, allocator);
    info.maxAnisotropy = anisotropy;

    var sampler: vk.VkSampler = null;

    try checkVkResult(vk.vkCreateSampler(device, @ptrCast(&info), pAllocCallBacks, @ptrCast(&sampler)));

    return sampler;
}

pub fn initSamplers(self: *Self, io: std.Io, device: vk.VkDevice, pAllocCallBacks: [*c]vk.VkAllocationCallbacks, allocator: std.mem.Allocator) !void {
    self.pixel2dSampler = try _createSampler(io, device, pAllocCallBacks, allocator, comptime file.comptimeGetID("pixel2dSampler.sampler"), 1.0);
}

pub fn destroySamplers(self: *Self, device: vk.VkDevice, pAllocCallBacks: [*c]vk.VkAllocationCallbacks) void {
    vk.vkDestroySampler(device, self.pixel2dSampler, pAllocCallBacks);
}

pub fn getDefaultSampler(self: *Self, samplerType: SamplerType) vk.VkSampler {
    return switch (samplerType) {
        .pixel2d => self.pixel2dSampler,
    };
}
