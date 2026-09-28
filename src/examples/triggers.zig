const std = @import("std");
const Io = std.Io;

const resourceProcess = @import("resourceProcess.zig");
const ProcessType = resourceProcess.ProcessType;

const tableNames = [_][]const u8{ "ImageLoadParameter", "ModelLoadParameter" };
pub const CreateTriggerContentPathOnInsertInsertIntoSubTable = tt: {
    var buffer = [_]u8{0} ** 10240;
    var writer = std.Io.Writer.fixed(&buffer);

    var count: usize = 0;

    for (@typeInfo(ProcessType).@"enum".fields) |field| {
        switch (@as(ProcessType, @enumFromInt(field.value))) {
            // .SPV => {
            //     count += writer.write(std.fmt.comptimePrint(
            //         "CREATE TRIGGER IF NOT EXISTS insertInto{s} AFTER INSERT ON ContentPath " ++
            //             " FOR EACH ROW WHEN NEW.FileType={d} BEGIN INSERT INTO ShaderLoadParameter (FileName,ContentHash,RelativePath,FileSize,FileID) VALUES " ++
            //             "(NEW.FileName,NEW.ContentHash,NEW.RelativePath,NEW.FileSize,NEW.ID) ON CONFLICT(FileName,ContentHash) DO UPDATE SET " ++
            //             "FileID = NEW.ID, FileName = NEW.FileName, ContentHash = NEW.ContentHash, RelativePath = NEW.RelativePath, FileSize = NEW.FileSize; END;",
            //         .{ tableNames[1], field.value },
            //     )) catch |err| {
            //         @compileError(std.fmt.comptimePrint("{s}", .{@errorName(err)}));
            //     };
            // },
            .PNG => {
                count += writer.write(std.fmt.comptimePrint(
                    "CREATE TRIGGER IF NOT EXISTS insertInto{s} AFTER INSERT ON ContentPath " ++
                        "FOR EACH ROW WHEN NEW.FileType={d} BEGIN INSERT INTO ImageLoadParameter (ID,FileName,ContentHash,RelativePath,FileUUID) VALUES " ++
                        "(NEW.ID,NEW.FileName,NEW.ContentHash,NEW.RelativePath,NEW.UUID) ON CONFLICT(FileName,ContentHash) DO UPDATE SET " ++
                        "ID = NEW.ID, FileUUID = NEW.UUID, FileName = NEW.FileName, ContentHash = NEW.ContentHash, RelativePath = NEW.RelativePath; END;",
                    .{ tableNames[0], field.value },
                )) catch |err| {
                    @compileError(std.fmt.comptimePrint("{s}", .{@errorName(err)}));
                };
            },
            .VTX => {
                count += writer.write(std.fmt.comptimePrint(
                    "CREATE TRIGGER IF NOT EXISTS insertInto{s} AFTER INSERT ON ContentPath " ++
                        "FOR EACH ROW WHEN NEW.FileType={d} BEGIN INSERT INTO ModelLoadParameter (ID,FileName,ContentHash,RelativePath,FileUUID) VALUES " ++
                        "(NEW.ID,NEW.FileName,NEW.ContentHash,NEW.RelativePath,NEW.UUID) ON CONFLICT(FileName,ContentHash) DO UPDATE SET " ++
                        "ID = NEW.ID, FileUUID = NEW.UUID, FileName = NEW.FileName, ContentHash = NEW.ContentHash, RelativePath = NEW.RelativePath; END;",
                    .{ tableNames[1], field.value },
                )) catch |err| {
                    @compileError(std.fmt.comptimePrint("{s}", .{@errorName(err)}));
                };
            },
            else => {
                continue;
            },
        }
    }

    break :tt std.fmt.comptimePrint("{s}", .{buffer});
};

pub const createUniqueIndexFileNameAndContentHash = cu: {
    var buffer = [_]u8{0} ** 10240;
    var writer = std.Io.Writer.fixed(&buffer);
    var count: usize = 0;

    for (tableNames) |name| {
        count += writer.write(
            std.fmt.comptimePrint("CREATE UNIQUE INDEX IF NOT EXISTS index{s}FileNameHashTable ON {s}(FileName,ContentHash);", .{ name, name }),
        ) catch |err| {
            @compileError(std.fmt.comptimePrint("{s}", .{@errorName(err)}));
        };
    }

    break :cu std.fmt.comptimePrint("{s}", .{buffer});
};

pub const createTriggerOnDeleteContentPathUpdateTablesRelativePathWhereSameContentHash = cto: {
    var buffer = [_]u8{0} ** 10240;
    var writer = std.Io.Writer.fixed(&buffer);
    var count: usize = 0;

    for (tableNames) |name| {
        count += writer.write(std.fmt.comptimePrint(
            "CREATE TRIGGER IF NOT EXISTS onDeleteUpdataRelativePath{s} AFTER DELETE ON ContentPath FOR EACH ROW " ++
                "WHEN OLD.ContentHash IS NOT NULL BEGIN UPDATE {s} SET RelativePath = NULL,FileUUID = NULL WHERE ContentHash = OLD.ContentHash; END;",
            .{ name, name },
        )) catch |err| {
            @compileError(std.fmt.comptimePrint("{s}", .{@errorName(err)}));
        };
    }

    break :cto std.fmt.comptimePrint("{s}", .{buffer});
};

pub const createTriggerOnInsertContentPathCheckContentHash =
    "CREATE TRIGGER IF NOT EXISTS onInsertUpdateContentPath BEFORE INSERT ON ContentPath FOR EACH ROW BEGIN " ++
    "DELETE FROM ContentPath WHERE ContentHash = NEW.ContentHash; END;";

fn getTableIndexForFileType(ft: ProcessType) ?u32 {
    return switch (ft) {
        .PNG => 0,
        .VTX => 1,
        else => null,
    };
}

pub const createTriggerOnUpdateContentPathUpdateOrInsertTables = ct: {
    var buffer = [_]u8{0} ** 20480;
    var writer = std.Io.Writer.fixed(&buffer);
    var count: usize = 0;

    for (tableNames, 0..) |tableName, idx| {
        var id_list_buffer = [_]u8{0} ** 20480;
        var id_list_writer = std.Io.Writer.fixed(&id_list_buffer);
        var first = true;

        for (@typeInfo(ProcessType).@"enum".fields) |field| {
            const val = @as(ProcessType, @enumFromInt(field.value));
            if (getTableIndexForFileType(val)) |i| {
                if (i == idx) {
                    if (!first) _ = id_list_writer.write(", ") catch unreachable;
                    _ = id_list_writer.write(std.fmt.comptimePrint("{d}", .{field.value})) catch unreachable;
                    first = false;
                }
            }
        }

        const id_list = id_list_writer.buffered();
        if (id_list.len == 0) continue;

        count += writer.write(std.fmt.comptimePrint(
            "CREATE TRIGGER IF NOT EXISTS onUpdateContentPathUpdateOrInsertTables{s} AFTER UPDATE OF " ++
                "ID, FileName, ContentHash, RelativePath, FileType ON ContentPath FOR EACH ROW " ++
                "WHEN NEW.FileType IN ({s}) BEGIN INSERT INTO {s} (ID,FileName,ContentHash,RelativePath) VALUES " ++
                "(NEW.ID,NEW.FileName,NEW.ContentHash,NEW.RelativePath) ON CONFLICT(FileName,ContentHash) DO UPDATE SET " ++
                "ID = NEW.ID, RelativePath = NEW.RelativePath " ++
                "WHERE FileUUID = NEW.UUID; END;",
            .{ tableName, id_list, tableName },
        )) catch unreachable;

        count += writer.write(std.fmt.comptimePrint(
            "CREATE TRIGGER IF NOT EXISTS insertInto{s} AFTER INSERT ON ContentPath " ++
                "FOR EACH ROW WHEN NEW.FileType IN ({s}) BEGIN INSERT INTO {s} (ID,FileName,ContentHash,RelativePath,FileUUID) VALUES " ++
                "(NEW.ID,NEW.FileName,NEW.ContentHash,NEW.RelativePath,NEW.UUID) ON CONFLICT(FileName,ContentHash) DO UPDATE SET " ++
                "ID = NEW.ID, FileUUID = NEW.UUID, FileName = NEW.FileName, ContentHash = NEW.ContentHash, RelativePath = NEW.RelativePath; END;",
            .{ tableName, id_list, tableName },
        )) catch unreachable;
    }

    break :ct std.fmt.comptimePrint("{s}", .{buffer});
};
