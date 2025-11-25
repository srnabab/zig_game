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
    var stream_writer = std.Io.Writer.fixed(&func_content);

    for (@typeInfo(VkResult).@"enum".fields) |field| {
        if (field.value < 0)
            stream_writer.print(".{s} => VkError.{s},\n", .{ field.name, field.name }) catch |err| {
                comptime_print("error: {s}\n", .{@errorName(err)});
            };
        // try writer.print(".{s} => VkError.{s},\n", .{ field.name, field.name });
    }

    break :str .{ .ctx = func_content, .len = @intCast(stream_writer.end) };
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

    const func_start = " const vk = @import(\"vulkan\").vulkan; const VkError = @import(\"vulkanType.zig\").VkError;\npub const vulkanType= @import(\"vulkanType.zig\");\n const VkResult = vulkanType.VkResult;\n pub fn VkResultToError(result: VkResult) VkError!void {\nreturn switch(result) {\n";
    const func_end = "};\n}\n pub fn checkVkResult(result: vk.VkResult) VkError!void { VkResultToError(@enumFromInt(result)) catch |err| { return err; };  \n}\n";

    var func = std.array_list.Managed(u8).init(gpa);
    defer func.deinit();

    const writer = func.writer();
    try writer.print("{s}", .{func_start});

    try writer.print("{s}", .{funcs.ctx[0..funcs.len]});
    try writer.print("else => {{}},\n{s}", .{func_end});

    _ = try file.write(func.items);
}
