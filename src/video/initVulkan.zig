const vk = @cImport(@cInclude("vulkan/vulkan.h"));
const std = @import("std");
const heap = @import("std").heap;
const Allocator = @import("std").mem.Allocator;
const VkSystemAllocationScope = vk.VkSystemAllocationScope;
const VkError = @import("vulkanType.zig").VkError;
const VkResult = @import("vulkanType.zig").VkResult;
const VkResultToError = @import("resultToError.zig");

fn comptime_print(comptime format: []const u8, comptime args: anytype) void {
    @compileLog(std.fmt.comptimePrint(format, args));
}

// pub const VkError = error{
//     VulkanError,
// };

pub fn checkVkResult(result: vk.VkResult) VkError!void {
    return VkResultToError.VkResultToError(@enumFromInt(result));
}

fn vkAlloc(pUserData: *anyopaque, size: c_ulonglong, alignment: c_ulonglong, allocationScope: VkSystemAllocationScope) callconv(.C) *anyopaque {
    _ = allocationScope;
    const gpa = @as(Allocator, @alignCast(@ptrCast(pUserData)));
    const mem = gpa.alignedAlloc(u8, @as(u29, alignment), @as(usize, size)) catch |err| {
        std.debug.print("Vulkan allocation failed: {s}\n", .{@errorName(err)});
        return null;
    };
    return mem.ptr;
}

fn vkRealloc(pUserData: *anyopaque, pOriginal: *anyopaque, size: c_ulonglong, alignment: c_ulonglong, allocationScope: VkSystemAllocationScope) *anyopaque {
    _ = allocationScope;
    _ = alignment;

    const gpa = @as(Allocator, @alignCast(@ptrCast(pUserData)));
    const mem = gpa.realloc(pOriginal, size) catch |err| {
        std.debug.print("Vulkan allocation failed: {s}\n", .{@errorName(err)});
        return null;
    };

    return mem.ptr;
}

fn vkFree(pUserData: *anyopaque, pMemory: *anyopaque) void {
    const gpa = @as(Allocator, @alignCast(@ptrCast(pUserData)));
    gpa.free(pMemory);
}

// fn getVulkanVersion() !u32 {
//     const apiVersion: c_uint = 0;
//     const result = vk.vkEnumerateInstanceVersion(apiVersion);
// }

// pub fn initVulkan() !void {}
