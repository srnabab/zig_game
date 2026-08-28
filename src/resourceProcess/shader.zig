const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;

const pipelineParse = @import("pipelinrParse");
const tables = @import("tables");

const resourceProcess = @import("../resourceProcess.zig");
const PreProcessParm = resourceProcess.PreProcessParm;
const db = @import("db");
const ProcessType = resourceProcess.ProcessType;

pub const Shader_Cooker = struct {
    pub const TableName = "ContentPathT";
    pub const Enable = true;
    const TableType = tables.ContentPath;

    pub fn preProcess(
        io: Io,
        gpa: Allocator,
        dir: Io.Dir,
        parmas: *PreProcessParm,
        Table: *TableType,
    ) !void {
        _ = io;
        _ = gpa;
        _ = dir;
        _ = Table;
        _ = parmas;
    }

    pub fn preProcess2(
        io: Io,
        gpa: Allocator,
        contentFolderPath: []const u8,
        fileName: [:0]u8,
        content: []const u8,
        fullPath: [:0]u8,
        database: *db,
    ) !void {
        _ = content;
        var readBuffer = [_]u8{0} ** 64;

        const spvName = try std.fmt.allocPrintSentinel(
            gpa,
            "{s}.spv",
            .{fileName},
            0,
        );
        defer gpa.free(spvName);

        const spvFullPath = try std.fs.path.joinZ(
            gpa,
            &[_][]const u8{
                contentFolderPath,
                "Shaders",
                spvName,
            },
        );
        defer gpa.free(spvFullPath);

        const runRes = try std.process.run(gpa, io, .{
            .argv = &[_][]const u8{ "glslc", "--target-env=vulkan1.4", "-g", "-o", spvFullPath, fullPath },
        });
        defer {
            gpa.free(runRes.stderr);
            gpa.free(runRes.stdout);
        }

        std.log.err("{s}", .{runRes.stderr});
        std.log.debug("{s}", .{runRes.stdout});

        switch (runRes.term) {
            .exited => |code| {
                if (code != 0) {
                    std.debug.print("Command failed with code: {d}\n", .{code});
                }
            },
            .signal => |sig| {
                _ = sig;
                std.debug.print("Process killed by signal: \n", .{});
            },
            .stopped => |sig| {
                _ = sig;
                std.debug.print("Process stopped: \n", .{});
            },
            .unknown => |val| {
                std.debug.print("Process exited with unknown code: {d}\n", .{val});
            },
        }

        const nodeType_u32: u32 = @intFromEnum(db.NodeType.Shader);
        database.ShaderPipelineGraphNodeT.insert(.{
            .Name = fileName.ptr,
            .Path = fullPath.ptr,
            .Type = nodeType_u32,
        }) catch {
            std.log.err("insert shader failed", .{});
        };

        var fromNodeID: i32 = -1;
        var gets = [_]*anyopaque{@ptrCast(&fromNodeID)};
        var types = [_]db.innerType{.INTEGER32};
        database.ShaderPipelineGraphNodeT.get(
            "ID",
            null,
            "Name = ?",
            .{fileName},
            &gets,
            &types,
        ) catch {
            std.log.err("get shader id failed", .{});
            return;
        };

        var pipelineCount: u32 = 0;

        database.ShaderPipelineGraphEdgeT.gets(
            "ToNodeID",
            null,
            "FromNodeID = ?",
            .{fromNodeID},
            null,
            null,
            &pipelineCount,
        ) catch {
            std.log.err("get pipeline count failed", .{});
            return;
        };

        if (pipelineCount > 0) {
            const getValues = gpa.alloc([]*anyopaque, pipelineCount) catch return;
            defer gpa.free(getValues);
            const ToNodeIDs = gpa.alloc(u32, pipelineCount) catch return;
            defer gpa.free(ToNodeIDs);
            for (getValues, 0..) |*value, i| {
                value.* = gpa.alloc(*anyopaque, 1) catch return;
                value.*[0] = @ptrCast(&ToNodeIDs[i]);
            }
            defer for (getValues) |value| gpa.free(value);

            database.ShaderPipelineGraphEdgeT.gets(
                "ToNodeID",
                null,
                "FromNodeID = ?",
                .{fromNodeID},
                getValues,
                &types,
                &pipelineCount,
            ) catch {
                std.log.err("get pipeline count failed", .{});
                return;
            };

            for (ToNodeIDs) |value| {
                var pipelinePath = [_]u8{0} ** 256;
                var pipelineGets = [_]*anyopaque{&pipelinePath};
                var pipelineTypes = [_]db.innerType{.TEXT};
                database.ShaderPipelineGraphNodeT.get(
                    "Path",
                    null,
                    "ID = ?",
                    .{value},
                    &pipelineGets,
                    &pipelineTypes,
                ) catch {
                    std.log.err("get pipeline path failed", .{});
                    return;
                };

                const pipelinePathLen = std.mem.len(@as([*c]u8, @ptrCast(&pipelinePath)));

                var pipelineNameStart = std.mem.findLast(
                    u8,
                    pipelinePath[0..pipelinePathLen],
                    "\\",
                );
                if (pipelineNameStart == null) {
                    pipelineNameStart = 0;
                } else {
                    pipelineNameStart.? += 1;
                }

                const pipebName = try std.fmt.allocPrintSentinel(
                    gpa,
                    "{s}b",
                    .{pipelinePath[pipelineNameStart.?..pipelinePathLen]},
                    0,
                );
                defer gpa.free(pipebName);

                const pipebFullPath = try std.fs.path.joinZ(
                    gpa,
                    &[_][]const u8{
                        contentFolderPath,
                        "Pipeline",
                        pipebName,
                    },
                );
                defer gpa.free(pipebFullPath);

                const shaderFolderFullPath = try std.fs.path.joinZ(
                    gpa,
                    &[_][]const u8{
                        contentFolderPath,
                        "Shaders",
                    },
                );
                defer gpa.free(shaderFolderFullPath);

                const pipelineFile = std.Io.Dir.openFileAbsolute(
                    io,
                    pipelinePath[0..pipelinePathLen],
                    .{},
                ) catch |err| {
                    std.log.err(
                        "failed to open pipeline file {s} {s}",
                        .{ pipelinePath[0..pipelinePathLen], @errorName(err) },
                    );
                    return;
                };

                const pipelineFileStat = pipelineFile.stat(io) catch |err| {
                    std.log.err(
                        "failed to stat pipeline file {s} {s}",
                        .{ pipelinePath[0..pipelinePathLen], @errorName(err) },
                    );
                    return;
                };

                var pipelineReader = pipelineFile.reader(io, &readBuffer);
                const pipelineContent = try pipelineReader.interface.readAlloc(gpa, pipelineFileStat.size);
                defer gpa.free(pipelineContent);

                const shaderNames = pipelineParse.pipelineJsonParse(
                    io,
                    pipelineContent,
                    shaderFolderFullPath,
                    pipebFullPath,
                    gpa,
                ) catch |err| {
                    std.log.err("pipeline json parse failed {s}", .{@errorName(err)});
                    return;
                };
                defer {
                    for (shaderNames) |shaderName| {
                        gpa.free(shaderName);
                    }
                    gpa.free(shaderNames);
                }
                // std.log.debug("ID {d}", .{value});
            }
        }
    }

    pub fn judgeFileType2(content: []u8, fType: ProcessType) ProcessType {
        _ = content;
        return fType;
    }
};
