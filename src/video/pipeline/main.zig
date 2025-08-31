const std = @import("std");
const builtin = @import("builtin");
const parse = @import("pipeline.zig");
const trans = @import("translate2.zig");

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

    var argsIt = try std.process.argsWithAllocator(gpa);
    defer argsIt.deinit();
    var argCount: u32 = 0;
    var args: [10][:0]const u8 = undefined;
    args[2] = "a.pipeb";
    while (argsIt.next()) |arg| {
        std.log.info("{s}", .{arg});
        args[argCount] = arg;

        argCount += 1;
        if (argCount > 3) break;
    }
    if (argCount < 2 or argCount > 3) {
        std.log.err("pipe.exe [jsonFile] [output]", .{});
        std.process.exit(1);
    }

    var jsonP = try parse.parse(args[1], gpa);
    defer jsonP.deinit();
    const res = try trans.toVulkan2(&jsonP, gpa);
    defer gpa.destroy(res);

    var outputFile = std.fs.cwd().openFile(args[2], .{ .mode = .write_only }) catch |err| switch (err) {
        error.FileNotFound => try std.fs.cwd().createFile(args[2], .{}),
        else => {
            return err;
        },
    };
    defer outputFile.close();

    const slice = std.mem.asBytes(res);

    try outputFile.writeAll(slice);
}
