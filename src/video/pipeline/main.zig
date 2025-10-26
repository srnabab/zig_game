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
        if (res.pushConstantInfo) |_| {
            for (res.pushConstantInfo.?) |value| {
                gpa.free(value.pushConstantMembers);
            }
            gpa.free(res.pushConstantInfo.?);
        }
    }
    // errdefer

    if (res.pushConstantInfo) |_| {
        var configFile = std.fs.cwd().openFile("config/pipelinePushConstants.json", .{
            .mode = .read_write,
        }) catch |err| rs: switch (err) {
            error.FileNotFound => break :rs try std.fs.cwd().createFile("config/pipelinePushConstants.json", .{ .truncate = false, .read = true }),
            else => return err,
        };
        defer configFile.close();

        var smallBuffer = [_]u8{0} ** (1);
        var smallBuffer2 = [_]u8{0} ** (1);
        const fileState = try configFile.stat();
        var json: std.json.Parsed(trans.PipelinePushConstatsJson) = undefined;
        var jsonValue: trans.PipelinePushConstatsJson = undefined;
        if (fileState.size != 0) {
            // std.log.debug("1", .{});
            const fileBuffer = try gpa.alloc(u8, fileState.size);
            defer gpa.free(fileBuffer);

            // std.log.debug("2", .{});
            var reader = configFile.reader(&smallBuffer);
            const content = try reader.interface.readAlloc(gpa, fileState.size);
            defer gpa.free(content);

            // std.log.debug("3", .{});
            json = try std.json.parseFromSlice(trans.PipelinePushConstatsJson, gpa, content, .{});
            defer json.deinit();

            jsonValue = json.value;
            // std.log.debug("name: {s}", .{jsonValue.@"0".?[0].name});

            // std.log.debug("4", .{});
            var arenaAllocator = json.arena.allocator();
            const index = json.value.@"0".?.len;
            json.value.@"0".? = try arenaAllocator.realloc(json.value.@"0".?, json.value.@"0".?.len + 1);
            // .log.debug("a: {d}, b: {d}", .{ index, json.value.@"0".?.len });

            // std.log.debug("5", .{});
            json.value.@"0".?[index] = trans.PipelineNameAndPushConstantsByStage{
                .name = jsonP.name,
                .stagePushConstants = try arenaAllocator.alloc(trans.PushConstantAndStage, res.pushConstantInfo.?.len),
            };

            // std.log.debug("6", .{});
            for (res.pushConstantInfo.?, 0..) |value, i| {
                json.value.@"0".?[index].stagePushConstants[i] = trans.PushConstantAndStage{
                    .stage = value.stage,
                    .members = try arenaAllocator.alloc(trans.PushConstantMember, value.pushConstantMembers.len),
                };
                for (value.pushConstantMembers, 0..) |member, j| {
                    json.value.@"0".?[index].stagePushConstants[i].members[j] = trans.PushConstantMember{
                        .name = undefined,
                        .memberType = member.varType,
                    };
                    // std.log.debug("enum value {}", .{member.varType});
                    const strPtr: [*c]const u8 = @ptrCast(&member.name);
                    const len = std.mem.len(strPtr);
                    json.value.@"0".?[index].stagePushConstants[i].members[j].name = try arenaAllocator.dupe(u8, member.name[0..len]);
                }
            }

            var fileWriter = configFile.writer(&smallBuffer2);
            var stringify = std.json.Stringify{ .writer = &fileWriter.interface, .options = .{ .whitespace = .indent_tab } };
            try stringify.write(json.value);
            try fileWriter.interface.flush();
        } else {
            var arena = std.heap.ArenaAllocator.init(gpa);
            var arenaAllocator = arena.allocator();
            defer arena.deinit();

            jsonValue.@"0" = try arenaAllocator.alloc(trans.PipelineNameAndPushConstantsByStage, 1);
            jsonValue.@"0".?[0] = trans.PipelineNameAndPushConstantsByStage{
                .name = jsonP.name,
                .stagePushConstants = try arenaAllocator.alloc(trans.PushConstantAndStage, res.pushConstantInfo.?.len),
            };
            for (res.pushConstantInfo.?, 0..) |value, i| {
                jsonValue.@"0".?[0].stagePushConstants[i] = trans.PushConstantAndStage{
                    .stage = value.stage,
                    .members = try arenaAllocator.alloc(trans.PushConstantMember, value.pushConstantMembers.len),
                };
                for (value.pushConstantMembers, 0..) |member, j| {
                    jsonValue.@"0".?[0].stagePushConstants[i].members[j] = trans.PushConstantMember{
                        .name = undefined,
                        .memberType = member.varType,
                    };
                    // std.log.debug("enum value {}", .{member.varType});
                    const strPtr: [*c]const u8 = @ptrCast(&member.name);
                    const len = std.mem.len(strPtr);
                    jsonValue.@"0".?[0].stagePushConstants[i].members[j].name = try arenaAllocator.dupe(u8, member.name[0..len]);
                }
            }

            var fileWriter = configFile.writer(&smallBuffer2);
            var stringify = std.json.Stringify{ .writer = &fileWriter.interface, .options = .{ .whitespace = .indent_tab } };
            try stringify.write(jsonValue);
            try fileWriter.interface.flush();
        }
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
