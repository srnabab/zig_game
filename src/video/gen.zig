const std = @import("std");
const builtin = @import("builtin");
const process = @import("std").process;
const VkError = @import("vulkanType").VkError;
const VkResult = @import("vulkanType").VkResult;

fn comptime_print(comptime format: []const u8, comptime args: anytype) void {
    @compileLog(std.fmt.comptimePrint(format, args));
}

const funcs: struct { ctx: [20000]u8, len: u64 } = str: {
    var func_content: [20000]u8 = undefined;
    var stream = std.io.fixedBufferStream(&func_content);
    const stream_writer = stream.writer();

    for (@typeInfo(VkResult).@"enum".fields) |field| {
        if (field.value < 0)
            stream_writer.print(".{s} => VkError.{s},\n", .{ field.name, field.name }) catch |err| {
                comptime_print("error: {s}\n", .{@errorName(err)});
            };
        // try writer.print(".{s} => VkError.{s},\n", .{ field.name, field.name });
    }
    const pos = stream.getPos() catch |err| {
        comptime_print("error: {s}\n", .{@errorName(err)});
    };

    break :str .{ .ctx = func_content, .len = pos };
};

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

    const args = try process.argsAlloc(gpa);
    defer process.argsFree(gpa, args);

    const file = try std.fs.createFileAbsolute(args[1], .{});
    defer file.close();

    const func_start = "const VkError = @import(\"vulkanType.zig\").VkError;\nconst VkResult = @import(\"vulkanType.zig\").VkResult;\npub fn VkResultToError(result: VkResult) VkError!void {\nreturn switch(result) {\n";
    const func_end = "};\n}";

    var func = std.array_list.Managed(u8).init(gpa);
    defer func.deinit();

    const writer = func.writer();
    try writer.print("{s}", .{func_start});

    try writer.print("{s}", .{funcs.ctx[0..funcs.len]});
    try writer.print("else => {{}},\n{s}", .{func_end});

    _ = try file.write(func.items);
}
