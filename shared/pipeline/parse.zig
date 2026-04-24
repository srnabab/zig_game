const std = @import("std");
const builtin = @import("builtin");
const parse = @import("pipeline.zig");
const trans = @import("translate2.zig");

pub fn pipelineJsonParse(io: std.Io, pipelineContent: []const u8, shaderFolder: []const u8, outputPath: []const u8, gpa: std.mem.Allocator) ![][:0]u8 {
    var jsonP = try parse.parse(pipelineContent, gpa);
    defer jsonP.deinit();

    const res = try trans.toVulkan2(io, &jsonP, shaderFolder, gpa);
    defer {
        gpa.destroy(res.info);
        for (res.shaderCodes) |value| {
            gpa.free(value);
        }
        gpa.free(res.shaderCodes);
        if (res.pushConstantInfo) |_| {
            for (res.pushConstantInfo.?) |value| {
                gpa.free(value.pushConstantMembers);
            }
            gpa.free(res.pushConstantInfo.?);
        }
    }

    var outputFile = try std.Io.Dir.createFileAbsolute(
        io,
        outputPath,
        .{},
    );
    defer outputFile.close(io);

    const slice = std.mem.asBytes(res.info);
    var totalLen: u64 = 0;
    totalLen += @sizeOf(trans.VulkanPipelineInfo);
    // std.log.debug("total len {d}", .{totalLen});
    for (0..res.shaderCodes.len) |i| {
        totalLen += res.shaderCodes[i].len + @sizeOf(u32);
        // std.log.debug("total len {d}", .{totalLen});
    }

    // std.log.debug("total len {d}", .{totalLen});

    var buffer = [_]u8{0} ** 20480;
    var writer = outputFile.writer(io, buffer[0..]);
    _ = try writer.interface.write(slice);

    for (0..res.shaderCodes.len) |i| {
        const val_u32: u32 = @intCast(res.shaderCodes[i].len);
        var val = std.mem.toBytes(val_u32);
        // std.log.debug("len {d}", .{res.shaderCodes[i].len});
        _ = try writer.interface.write(&val);
        _ = try writer.interface.write(res.shaderCodes[i]);
    }
    try writer.flush();

    var shaderNames = try gpa.alloc([:0]u8, res.shaderCodes.len);
    for (0..res.shaderCodes.len) |i| {
        const len = std.mem.len(@as([*c]u8, @ptrCast(&res.info.shaderName[i])));
        shaderNames[i] = try gpa.allocSentinel(u8, len, 0);
        @memcpy(shaderNames[i], res.info.shaderName[i][0..len]);
    }

    std.log.debug("parse {s}", .{outputPath});

    return shaderNames;
}
