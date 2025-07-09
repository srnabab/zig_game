const vk = @cImport(@cInclude("vulkan/vulkan.h"));
const std = @import("std");
const heap = @import("std").heap;
const Allocator = @import("std").mem.Allocator;
const cEnum = @import("enumFromC");

fn comptime_print(comptime format: []const u8, comptime args: anytype) void {
    // @compileLog 会在编译时无条件地打印信息到 stderr
    @compileLog(std.fmt.comptimePrint(format, args));
}

pub const VkResult = cEnum.generateEnumFromC(vk, vk.VkResult, "VK_SUCCESS", "VK_RESULT_MAX_ENUM");

pub fn checkVkResult(result: vk.VkResult) VkResult {
    return @enumFromInt(result);
}

const VkSystemAllocationScope = vk.VkSystemAllocationScope;

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
