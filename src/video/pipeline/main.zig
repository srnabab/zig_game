const std = @import("std");
const builtin = @import("builtin");
const parse = @import("pipeline.zig");
const trans = @import("translate2.zig");

var debug_allocator: std.heap.DebugAllocator(.{}) = .init;
pub fn main() !void {
    const start = std.time.nanoTimestamp();

    const gpa, const is_debug = gpa: {
        break :gpa switch (builtin.mode) {
            .Debug, .ReleaseSafe => .{ debug_allocator.allocator(), true },
            .ReleaseFast, .ReleaseSmall => .{ std.heap.smp_allocator, false },
        };
    };
    defer if (is_debug) {
        _ = debug_allocator.deinit();
    };

    // @breakpoint();
    var argsIt = try std.process.argsWithAllocator(gpa);
    defer argsIt.deinit();
    var argCount: u32 = 0;
    var args: [10][:0]const u8 = undefined;
    args[2] = "a.pipeb";
    while (argsIt.next()) |arg| {
        // std.log.info("{s}", .{arg});
        args[argCount] = arg;

        argCount += 1;
        if (argCount > 3) break;
    }
    if (argCount < 2 or argCount > 4) {
        std.log.err("pipe.exe [jsonFile] [shaderFolder] [output] {d}", .{argCount});
        std.process.exit(1);
    }

    var jsonP = try parse.parse(args[1], gpa);
    defer jsonP.deinit();
    const res = try trans.toVulkan2(&jsonP, args[2], gpa);
    defer {
        gpa.destroy(res.info);
        for (res.shaderCodes) |value| {
            gpa.free(value);
        }
        gpa.free(res.shaderCodes);
    }

    var outputFile = ps: {
        if (std.fs.path.isAbsolute(args[3])) {
            break :ps std.fs.openFileAbsolute(args[3], .{ .mode = .write_only }) catch |err| switch (err) {
                error.FileNotFound => try std.fs.createFileAbsolute(args[3], .{}),
                else => {
                    return err;
                },
            };
        } else {
            break :ps std.fs.cwd().openFile(args[3], .{ .mode = .write_only }) catch |err| switch (err) {
                error.FileNotFound => try std.fs.cwd().createFile(args[3], .{}),
                else => {
                    return err;
                },
            };
        }
    };
    defer outputFile.close();

    const slice = std.mem.asBytes(res.info);
    var totalLen: u64 = 0;
    totalLen += @sizeOf(trans.VulkanPipelineInfo);
    // std.log.debug("total len {d}", .{totalLen});
    for (0..res.shaderCodes.len) |i| {
        totalLen += res.shaderCodes[i].len + @sizeOf(usize);
        // std.log.debug("total len {d}", .{totalLen});
    }

    var buffer = [_]u8{0} ** 102400;
    var writer = outputFile.writer(buffer[0..totalLen]);
    _ = try writer.interface.write(slice);
    for (0..res.shaderCodes.len) |i| {
        var val = std.mem.toBytes(res.shaderCodes[i].len);
        _ = try writer.interface.write(&val);
        _ = try writer.interface.write(res.shaderCodes[i]);
    }
    try writer.end();

    const endTime = std.time.nanoTimestamp();

    std.log.info("create pipeline file {s} time: {d}ms", .{ args[3], @as(f128, @floatFromInt(endTime - start)) / @as(f128, @floatFromInt(std.time.ns_per_ms)) });
}
