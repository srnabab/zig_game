const std = @import("std");
const process = @import("std").process;
const sdl = @cImport(@cInclude("SDL3/SDL.h"));
const vk = @cImport(@cInclude("vulkan/vulkan.h"));
const video = @import("video/initVulkan.zig");
const Thread = @import("std").Thread;
const builtin = @import("builtin");

pub const gpaType = @TypeOf(std.heap.GeneralPurposeAllocator(.{}).init);
const Allocator = @import("std").mem.Allocator;

const osPack = struct {
    const Self = @This();

    stdin: std.fs.File.Reader,
    stdout: std.fs.File.Writer,
    gpa: gpaType,
    allocator: Allocator,

    fn init() osPack {
        return osPack{
            .stdout = std.io.getStdOut().writer(),
            .stdin = std.io.getStdIn().reader(),
            .gpa = std.heap.GeneralPurposeAllocator(.{}).init,
            .allocator = undefined,
        };
    }

    fn initAllocator(self: *Self) void {
        self.*.allocator = self.*.gpa.allocator();
    }

    fn deinit(self: *Self) std.heap.Check {
        return self.*.gpa.deinit();
    }
};

var bignum: u64 = 0;

fn add(num: *anyopaque) void {
    const num1 = @as(*u64, @alignCast(@ptrCast(num)));

    for (0..1000000) |_| {
        num1.* += 1;
    }
}

var debug_allocator: std.heap.DebugAllocator(.{}) = .init;
pub fn main() !void {
    const gpa, const is_debug = gpa: {
        break :gpa switch (builtin.mode) {
            .Debug, .ReleaseSafe => .{ debug_allocator.allocator(), true },
            .ReleaseFast, .ReleaseSmall => .{ std.heap.smp_allocator, false },
        };
    };
    defer if (is_debug) {
        _ = debug_allocator.deinit();
    };

    const stdout = std.io.getStdOut().writer();

    const args = try process.argsAlloc(gpa);
    defer process.argsFree(gpa, args);

    for (args) |arg| {
        try stdout.print("arg: {s}\n", .{arg});
    }
    const name = video.checkVkResult(vk.VK_ERROR_DEVICE_LOST);
    std.debug.print("name {d}\n", .{@intFromEnum(name)});
}
