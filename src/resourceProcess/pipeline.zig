const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;

const pipelineParse = @import("pipelinrParse");
const tables = @import("tables");

const resourceProcess = @import("../resourceProcess.zig");
const PreProcessParm = resourceProcess.PreProcessParm;
const db = @import("db");
const ProcessType = resourceProcess.ProcessType;

pub const Pipeline_Cooker = struct {
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
        const pipebName = try std.fmt.allocPrintSentinel(
            gpa,
            "{s}b",
            .{fileName},
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

        const shaderNames = pipelineParse.pipelineJsonParse(
            io,
            content,
            shaderFolderFullPath,
            pipebFullPath,
            gpa,
        ) catch {
            std.log.err("pipeline json parse failed", .{});
            return;
        };
        defer {
            for (shaderNames) |value| {
                gpa.free(value);
            }
            gpa.free(shaderNames);
        }

        database.ShaderPipelineGraphNodeT.insert(.{
            .Name = fileName.ptr,
            .Path = fullPath.ptr,
            .Type = @as(u32, @intFromEnum(db.NodeType.Pipeline)),
        }) catch {};

        var nodeID: i32 = -1;
        var gets = [_]*anyopaque{@ptrCast(&nodeID)};
        var types = [_]db.innerType{.INTEGER32};
        database.ShaderPipelineGraphNodeT.get(
            "ID",
            null,
            "Name = ?",
            .{fileName},
            &gets,
            &types,
        ) catch {
            std.log.err("get pipeline id failed", .{});
            return;
        };

        database.ShaderPipelineGraphEdgeT.delete("ToNodeID = ?", .{nodeID}) catch {};

        for (shaderNames) |shaderName| {
            const shaderNameNoSpv = gpa.allocSentinel(
                u8,
                shaderName.len - 4,
                0,
            ) catch return;
            defer gpa.free(shaderNameNoSpv);
            @memcpy(shaderNameNoSpv, shaderName[0 .. shaderName.len - 4]);

            var shaderID: i32 = -1;
            var gets2 = [_]*anyopaque{@ptrCast(&shaderID)};
            var types2 = [_]db.innerType{.INTEGER32};
            database.ShaderPipelineGraphNodeT.get(
                "ID",
                null,
                "Name = ?",
                .{shaderNameNoSpv},
                &gets2,
                &types2,
            ) catch {
                // @breakpoint();
                std.log.err("get shader id failed (shader name: {s})", .{
                    shaderNameNoSpv,
                });
                return;
            };

            database.ShaderPipelineGraphEdgeT.insert(.{
                .FromNodeID = shaderID,
                .ToNodeID = nodeID,
            }) catch {
                database.ShaderPipelineGraphEdgeT.update(
                    "FromNodeID",
                    "ToNodeID = ?",
                    .{ shaderID, nodeID },
                ) catch {
                    std.log.err("insert pipeline edge failed", .{});
                    return;
                };
            };
            std.log.debug("{s}", .{shaderName});
        }
    }

    pub fn judgeFileType2(content: []u8, fType: ProcessType) ProcessType {
        _ = content;
        return fType;
    }
};
