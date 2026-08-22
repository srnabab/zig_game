const std = @import("std");
const Io = std.Io;

const db = @import("db");

var database: *db = undefined;

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    var arena = std.heap.ArenaAllocator.init(init.gpa);
    defer arena.deinit();

    const allocator = arena.allocator();

    var stdinReadBuffer = [_]u8{0} ** 1024;

    var databaseFilePath: [:0]const u8 = undefined;
    var contentDatabaseRelativePathStart: [:0]const u8 = undefined;

    var stdinFile = std.Io.File.stdin();

    var stdin = stdinFile.reader(io, &stdinReadBuffer);

    try Io.sleep(io, .fromSeconds(1), .real);

    var count: u32 = 0;
    while (true) {
        const buffer = try stdin.interface.takeDelimiter('?');

        if (buffer) |b| {
            switch (count) {
                0 => {
                    databaseFilePath = try std.fmt.allocPrintSentinel(allocator, "{s}", .{b}, 0);
                    std.log.debug("child: {s}", .{b});
                },
                1 => {
                    contentDatabaseRelativePathStart = try std.fmt.allocPrintSentinel(allocator, "{s}", .{b}, 0);
                    std.log.debug("child: {s}", .{b});
                },
                else => {
                    if (std.mem.eql(u8, "404", b)) {
                        break;
                    }
                },
            }
            count += 1;
        }
    }

    var contentFolder = try std.Io.Dir.openDirAbsolute(
        io,
        contentDatabaseRelativePathStart,
        .{ .iterate = true },
    );
    defer contentFolder.close(io);

    database = try db.init(io, allocator, contentFolder, databaseFilePath);
    errdefer database.rollback();
    defer database.deinit(allocator);

    var pending_old_name: ?[]u8 = null;
    var committer: db.AutoCommitter = .init(database, io, 60000);
    var future: ?Io.Future(@typeInfo(@TypeOf(db.AutoCommitter.runMonitor)).@"fn".return_type.?) = null;
    errdefer {
        if (future) |_| {
            _ = future.?.cancel(io) catch |err| std.log.err("AutoCommitter.runMonitor failed: {}", .{err});
        }
    }
    defer {
        if (future) |_| {
            _ = future.?.await(io) catch |err| std.log.err("AutoCommitter.runMonitor failed: {}", .{err});
        }
    }

    while (true) {
        const buffer = try stdin.interface.takeDelimiter('\n');
        // const now = Io.Timestamp.now(io, .real).toMicroseconds();

        if (buffer == null) continue;
        const b = buffer.?;
        var inContent = false;

        const numEnd = std.mem.find(u8, b, "?") orelse std.debug.panic("missing \"?\"", .{});
        const num = try std.fmt.parseInt(u32, b[0..numEnd], 10);

        var action_num = num;
        // std.log.debug("from child: {d}", .{action_num});
        if (num > 1000) {
            action_num -= 1000;
            inContent = true;
        }

        // std.log.debug("time used: {d}", .{Io.Timestamp.now(io, .real).toMicroseconds() - now});

        const action_str = switch (action_num) {
            1 => "create",
            2 => "delete",
            3 => "modify",
            4 => "rename (old)",
            5 => "rename (new)",
            404 => return,
            else => "unknown",
        };

        var nameEnd = std.mem.find(u8, b[numEnd + 1 ..], "?") orelse {
            std.debug.panic("missing \"?\"", .{});
        };
        nameEnd += 1 + numEnd;
        const name_utf8 = try std.fmt.allocPrintSentinel(allocator, "{s}", .{b[numEnd + 1 .. nameEnd]}, 0);
        defer allocator.free(name_utf8);

        // std.log.debug("a: {d}, b: {d}", .{ numEnd, nameEnd });

        const fullPath = try std.fmt.allocPrintSentinel(allocator, "{s}", .{b[nameEnd + 1 ..]}, 0);
        defer allocator.free(fullPath);

        std.log.debug("from child: [{s}] {s} {s}", .{ action_str, name_utf8, fullPath });

        switch (action_num) {
            1, 3 => {
                // config file process else

                // other file process

                // try std.Io.sleep(io, .fromMilliseconds(1), .real);

                const file: ?std.Io.File = std.Io.Dir.openFileAbsolute(
                    io,
                    fullPath,
                    .{},
                ) catch |err| s: switch (err) {
                    else => {
                        std.log.err("failed to open file {s} {s}", .{ fullPath, @errorName(err) });
                        break :s null;
                    },
                };

                if (file) |f| {
                    defer f.close(io);
                    const stat = try f.stat(io);

                    if (stat.kind == .file) {
                        var startIndex = std.mem.findLast(u8, fullPath, "\\") orelse 0;
                        if (startIndex != 0) startIndex += 1;
                        const fileName = fullPath[startIndex.. :0];

                        var fType = db.FileType.UNKNOWN;

                        // std.log.debug("{s}; {s}", .{watch.path, contentWatch.path});

                        if (inContent) {
                            // std.log.debug("in content", .{});
                            const dir = try std.Io.Dir.openDirAbsolute(
                                io,
                                fullPath[0 .. startIndex - 1],
                                .{},
                            );
                            defer dir.close(io);

                            const idx = std.mem.findLast(u8, fullPath, "Content");

                            if (idx) |i| {
                                // std.log.debug("in in", .{});
                                var parentUUID = [_]u8{0} ** db.UUID.len;
                                var getValues: [1]*anyopaque = undefined;
                                getValues[0] = @ptrCast(&parentUUID);
                                var types = [_]db.innerType{.TEXT};

                                const parentPathZ = try std.fs.path.joinZ(
                                    allocator,
                                    &[_][]const u8{fullPath[i .. startIndex - 1]},
                                );
                                defer allocator.free(parentPathZ);

                                try database.ContentPathT.get(
                                    "UUID",
                                    null,
                                    "RelativePath = ?",
                                    .{parentPathZ},
                                    &getValues,
                                    &types,
                                );
                                // std.log.debug("{s}", .{parentPathZ});
                                fType = db.iterateFolder.processFile(
                                    io,
                                    dir,
                                    fileName,
                                    fullPath[i..],
                                    &parentUUID,
                                ) catch |err| {
                                    std.log.err("err: {s}", .{@errorName(err)});
                                    continue;
                                };
                            }

                            if (committer.is_active) {
                                committer.poke();
                            } else {
                                if (future) |_| {
                                    _ = try future.?.await(io);
                                    future = null;
                                }
                                committer.activate();
                                future = io.async(db.AutoCommitter.runMonitor, .{&committer});
                            }
                        } else {
                            // std.log.debug("not in content", .{});
                            const dotIndex = std.mem.findLast(u8, fileName, ".") orelse fileName.len;

                            var readBuffer = [_]u8{0} ** 64;
                            var reader = f.reader(io, &readBuffer);
                            const content = try reader.interface.readAlloc(allocator, stat.size);
                            defer allocator.free(content);

                            reader.seekTo(0) catch continue;

                            fType = db.judgeFileType(fileName[dotIndex..], content);
                            // std.log.debug("fileType: {s}", .{@tagName(fType)});

                            switch (fType) {
                                inline else => |t| {
                                    const cookerName = std.fmt.comptimePrint("{s}{s}", .{ @tagName(t), "_Cooker" });

                                    if (@hasDecl(db.resourceProcess, cookerName)) {
                                        const field = @field(db.resourceProcess, cookerName);

                                        if (field.Enable)
                                            try field.preProcess2(io, allocator, contentDatabaseRelativePathStart, fileName, content, fullPath, database);
                                    } else {
                                        try db.resourceProcess.Example_Cooker.preProcess2(
                                            io,
                                            allocator,
                                            contentDatabaseRelativePathStart,
                                            fileName,
                                            content,
                                            fullPath,
                                            database,
                                        );
                                    }
                                },
                            }
                        }

                        std.log.debug("{s} {s} {s}", .{ fileName, @tagName(fType), if (inContent) "in content" else " " });
                    } else if (stat.kind == .directory) {
                        const dir: ?std.Io.Dir = std.Io.Dir.openDirAbsolute(
                            io,
                            fullPath,
                            .{},
                        ) catch |err| s: switch (err) {
                            else => {
                                std.log.err("failed to open dir {s} {s}", .{ fullPath, @errorName(err) });
                                break :s null;
                            },
                        };

                        var startIndex = std.mem.findLast(u8, fullPath, "\\") orelse 0;
                        if (startIndex != 0) startIndex += 1;
                        const dirname = fullPath[startIndex..];

                        if (dir) |d| {
                            defer d.close(io);

                            std.log.debug("in", .{});

                            if (inContent) {
                                const parentDir = try std.Io.Dir.openDirAbsolute(
                                    io,
                                    fullPath[0 .. startIndex - 1],
                                    .{},
                                );
                                defer parentDir.close(io);

                                const idx = std.mem.findLast(u8, fullPath, "Content");

                                if (idx) |i| {
                                    std.log.debug("in in", .{});
                                    var parentUUID = [_]u8{0} ** db.UUID.len;
                                    var getValues: [1]*anyopaque = undefined;
                                    getValues[0] = @ptrCast(&parentUUID);
                                    var types = [_]db.innerType{.TEXT};

                                    const parentPathZ = try std.fs.path.joinZ(
                                        allocator,
                                        &[_][]const u8{fullPath[i .. startIndex - 1]},
                                    );
                                    defer allocator.free(parentPathZ);

                                    try database.ContentPathT.get(
                                        "UUID",
                                        null,
                                        "RelativePath = ?",
                                        .{parentPathZ},
                                        &getValues,
                                        &types,
                                    );
                                    // std.log.debug("{s}", .{parentPathZ});

                                    try db.iterateFolder.processDirectory(
                                        io,
                                        parentDir,
                                        dirname,
                                        fullPath[i..],
                                        &parentUUID,
                                        true,
                                    );
                                }

                                if (committer.is_active) {
                                    committer.poke();
                                } else {
                                    if (future) |_| {
                                        _ = try future.?.await(io);
                                        future = null;
                                    }
                                    committer.activate();
                                    future = io.async(db.AutoCommitter.runMonitor, .{&committer});
                                }
                            }

                            std.log.debug("dir {s}", .{dirname});
                        }
                    }
                }
            },
            2 => {
                var startIndex = std.mem.findLast(u8, fullPath, "\\") orelse 0;
                if (startIndex != 0) startIndex += 1;
                const fileName = fullPath[startIndex..];

                if (inContent) {
                    std.log.debug("delete", .{});
                    try database.ContentPathT.delete(
                        "FileName = ?",
                        .{fileName},
                    );

                    if (committer.is_active) {
                        committer.poke();
                    } else {
                        if (future) |_| {
                            _ = try future.?.await(io);
                            future = null;
                        }
                        committer.activate();
                        future = io.async(db.AutoCommitter.runMonitor, .{&committer});
                    }
                }
            },
            4 => {
                if (pending_old_name) |old| allocator.free(old);
                pending_old_name = try allocator.dupe(u8, name_utf8);
            },
            5 => {
                renameNew(
                    io,
                    allocator,
                    allocator,
                    name_utf8,
                    fullPath,
                    pending_old_name,
                    inContent,
                ) catch continue;
                pending_old_name = null;
            },
            1234 => {
                if (future) |_| {
                    _ = future.?.await(io) catch |err| std.log.err("AutoCommitter.runMonitor failed: {}", .{err});
                    future = null;
                }
                database.saveToDrive();

                std.log.debug("Saved", .{});
            },
            else => {},
        }
    }

    // try stdout.interface.writeAll("tteesstt");
}

fn renameNew(
    io: Io,
    allocator: std.mem.Allocator,
    arena: std.mem.Allocator,
    name_utf8: []const u8,
    fullPath: []const u8,
    pending_old_name: ?[]u8,
    inContent: bool,
) !void {
    if (pending_old_name) |old| {
        defer allocator.free(fullPath);
        var startIndex = std.mem.findLast(u8, fullPath, "\\") orelse 0;
        if (startIndex != 0) startIndex += 1;
        const fileName = fullPath[startIndex..];

        var fType = db.FileType.UNKNOWN;

        if (inContent) {
            var oldStartIndex = std.mem.findLast(u8, old, "\\") orelse 0;
            if (oldStartIndex != 0) oldStartIndex += 1;

            const idx = std.mem.findLast(u8, fullPath, "Content");

            if (idx) |i| {
                var parentUUID = [_]u8{0} ** db.UUID.len;
                parentUUID[db.UUID.len - 2] = 0;
                parentUUID[db.UUID.len - 1] = 0;

                var getValues: [1]*anyopaque = undefined;
                getValues[0] = @ptrCast(&parentUUID);
                var types = [_]db.innerType{.TEXT};

                const parentPathZ = try std.fs.path.joinZ(
                    allocator,
                    &[_][]const u8{fullPath[i .. startIndex - 1]},
                );
                defer allocator.free(parentPathZ);

                std.log.debug("{s}", .{parentPathZ});

                try database.ContentPathT.get(
                    "UUID",
                    null,
                    "RelativePath = ?",
                    .{parentPathZ},
                    &getValues,
                    &types,
                );
                try database.ContentPathT.update(
                    "FileName, RelativePath, ParentUUID",
                    "FileName = ?",
                    .{ fileName, fullPath[i..], parentUUID, old[oldStartIndex..] },
                );
            }
        } else {
            const dotIndex = std.mem.findLast(u8, fileName, ".") orelse fileName.len;

            const file: std.Io.File = std.Io.Dir.openFileAbsolute(
                io,
                fullPath,
                .{},
            ) catch |err| switch (err) {
                else => {
                    std.log.err("failed to open file {s} {s}", .{ fullPath, @errorName(err) });
                    return err;
                },
            };
            defer file.close(io);
            const stat = try file.stat(io);

            var readBuffer = [_]u8{0} ** 64;
            var reader = file.reader(io, &readBuffer);
            const content = try reader.interface.readAlloc(allocator, stat.size);
            defer allocator.free(content);

            reader.seekTo(0) catch return;

            fType = db.judgeFileType(fileName[dotIndex..], content);

            switch (fType) {
                .Shader => {
                    try database.ShaderPipelineGraphNodeT.update(
                        "Path, Name",
                        "Name = ?",
                        .{ fullPath, name_utf8, old },
                    );
                },
                else => {},
            }
        }

        std.log.info("rename {s} -> {s}", .{ old, name_utf8 });
        arena.free(old);
    }
}
