const std = @import("std");
const Io = std.Io;

const shaderc = @import("shaderc");
const sampler = @import("sampler");

const db = @import("db");

const configFile = ".watching";
const databaseFile = "Content.db";

const EXIT_COMPLETION_KEY = 0xDEADBEEF;

pub const watches_recursively = true; // ReadDirectoryChangesW with bWatchSubtree=1
pub const detects_file_modifications = true;
pub const emits_close_events = false;
pub const emits_rename_for_files = true;
pub const emits_rename_for_dirs = true;
pub const emits_subtree_created_on_movein = true;

const windows = std.os.windows;

// Types removed from std.os.windows in zig-0.16.
const OVERLAPPED = extern struct {
    Internal: windows.ULONG_PTR = 0,
    InternalHigh: windows.ULONG_PTR = 0,
    Offset: windows.DWORD = 0,
    OffsetHigh: windows.DWORD = 0,
    hEvent: ?windows.HANDLE = null,
};

const FILE_NOTIFY_INFORMATION = extern struct {
    NextEntryOffset: windows.DWORD = 0,
    Action: windows.DWORD = 0,
    FileNameLength: windows.DWORD = 0,
    FileName: [1]windows.WCHAR,
};
const PFILE_NOTIFY_INFORMATION = *FILE_NOTIFY_INFORMATION;

// Constants removed from std.os.windows in zig-0.16.
const FILE_FLAG_BACKUP_SEMANTICS: windows.DWORD = 0x02000000;
const FILE_FLAG_OVERLAPPED: windows.DWORD = 0x40000000;
const FILE_LIST_DIRECTORY: windows.DWORD = 0x0001;
const FILE_NOTIFY_CHANGE_FILE_NAME: windows.DWORD = 0x00000001;
const FILE_NOTIFY_CHANGE_DIR_NAME: windows.DWORD = 0x00000002;
const FILE_NOTIFY_CHANGE_LAST_WRITE: windows.DWORD = 0x00000010;
const FILE_ATTRIBUTE_DIRECTORY: windows.DWORD = 0x00000010;

const GENERIC_READ: windows.DWORD = 0x80000000;
const FILE_SHARE_READ: windows.DWORD = 0x00000001;
const FILE_SHARE_WRITE: windows.DWORD = 0x00000002;
const FILE_SHARE_DELETE: windows.DWORD = 0x00000004;
const OPEN_EXISTING: windows.DWORD = 3;
const INFINITE: windows.DWORD = 0xFFFFFFFF;

const PHANDLER_ROUTINE = *const fn (windows.DWORD) callconv(.winapi) windows.BOOL;

const win32 = struct {
    pub extern "kernel32" fn CloseHandle(hObject: windows.HANDLE) callconv(.winapi) windows.BOOL;

    pub extern "kernel32" fn ReadDirectoryChangesW(
        hDirectory: windows.HANDLE,
        lpBuffer: *anyopaque,
        nBufferLength: windows.DWORD,
        bWatchSubtree: windows.BOOL,
        dwNotifyFilter: windows.DWORD,
        lpBytesReturned: ?*windows.DWORD,
        lpOverlapped: ?*OVERLAPPED,
        lpCompletionRoutine: ?*anyopaque,
    ) callconv(.winapi) windows.BOOL;

    pub extern "kernel32" fn GetQueuedCompletionStatus(
        CompletionPort: windows.HANDLE,
        lpNumberOfBytesTransferred: *windows.DWORD,
        lpCompletionKey: *windows.ULONG_PTR,
        lpOverlapped: *?*OVERLAPPED,
        dwMilliseconds: windows.DWORD,
    ) callconv(.winapi) windows.BOOL;

    pub extern "kernel32" fn CreateFileW(
        lpFileName: [*:0]const windows.WCHAR,
        dwDesiredAccess: windows.DWORD,
        dwShareMode: windows.DWORD,
        lpSecurityAttributes: ?*anyopaque,
        dwCreationDisposition: windows.DWORD,
        dwFlagsAndAttributes: windows.DWORD,
        hTemplateFile: ?windows.HANDLE,
    ) callconv(.winapi) windows.HANDLE;

    pub extern "kernel32" fn PostQueuedCompletionStatus(
        CompletionPort: windows.HANDLE,
        dwNumberOfBytesTransferred: windows.DWORD,
        dwCompletionKey: windows.ULONG_PTR,
        lpOverlapped: ?*OVERLAPPED,
    ) callconv(.winapi) windows.BOOL;

    pub extern "kernel32" fn GetFileAttributesW(lpFileName: [*:0]const windows.WCHAR) callconv(.winapi) windows.DWORD;

    pub extern "kernel32" fn CreateIoCompletionPort(
        FileHandle: windows.HANDLE,
        ExistingCompletionPort: ?windows.HANDLE,
        CompletionKey: windows.ULONG_PTR,
        NumberOfConcurrentThreads: windows.DWORD,
    ) callconv(.winapi) ?windows.HANDLE;

    pub extern "kernel32" fn SetConsoleCtrlHandler(
        HandlerRoutine: PHANDLER_ROUTINE,
        Add: windows.BOOL,
    ) callconv(.winapi) windows.BOOL;
};

const DirectoryWatch = struct {
    handle: windows.HANDLE,
    overlapped: OVERLAPPED = .{},
    buffer: [2048]u8 align(@alignOf(FILE_NOTIFY_INFORMATION)) = undefined,
    path: []const u8,
    dwNotifyFilter: windows.DWORD,
    recursive: bool,
    stopWatch: bool = false,

    pub fn startWatch(self: *DirectoryWatch) !void {
        if (self.stopWatch) return;

        const success = win32.ReadDirectoryChangesW(
            self.handle,
            &self.buffer,
            self.buffer.len,
            windows.BOOL.fromBool(self.recursive),
            self.dwNotifyFilter,
            null,
            &self.overlapped,
            null,
        );
        if (success == windows.BOOL.FALSE) {
            std.log.debug("{s} {d}", .{ self.path, @as(u32, @intFromEnum(windows.GetLastError())) });
        }
        // std.log.debug("watch {s}", .{self.path});
    }
};

const NotifyInformation = struct {
    Action: windows.DWORD,
    time: i64,
    name: []const u8,
};

var global_iocp: ?windows.HANDLE = null;

pub fn main(init: std.process.Init) !void {
    const gpa = init.gpa;
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    const allocator = arena.allocator();

    var argsIt = try init.minimal.args.iterateAllocator(gpa);
    defer argsIt.deinit();

    var folder: ?[:0]u16 = null;
    var path: ?[:0]const u8 = null;
    var contentDatabaseRelativePathStart: ?[:0]const u8 = null;

    var watchingFilePath: []const u8 = configFile;
    var databaseFilePath: []const u8 = databaseFile;

    {
        errdefer {
            std.log.debug(
                ".exe --f [root folder]\n --d [database path]\n [database relative path start]\n (optional) --w [config file path]",
                .{},
            );
        }
        _ = argsIt.next();
        while (argsIt.next()) |arg| {
            // std.log.debug("{s}", .{arg});
            if (std.mem.eql(u8, arg[0..3], "--f")) {
                path = argsIt.next() orelse return error.NoFolder;

                folder = try std.unicode.wtf8ToWtf16LeAllocZ(gpa, path.?);
                errdefer gpa.free(folder.?);
                continue;
            } else if (std.mem.eql(u8, arg[0..3], "--w")) {
                watchingFilePath = argsIt.next() orelse configFile;
                continue;
            } else if (std.mem.eql(u8, arg[0..3], "--d")) {
                databaseFilePath = argsIt.next() orelse databaseFile;
                contentDatabaseRelativePathStart = argsIt.next() orelse return error.NoDatabaseRelativePathStart;

                continue;
            }

            std.log.err("unknow command {s}", .{arg});
        }
    }
    defer gpa.free(folder.?);
    if (folder == null) return error.NoFolder;

    var contentFolder = try std.Io.Dir.openDirAbsolute(
        init.io,
        contentDatabaseRelativePathStart.?,
        .{ .iterate = true },
    );
    defer contentFolder.close(init.io);

    var database = try db.init(allocator, databaseFilePath);
    errdefer database.rollback();
    defer database.deinit(allocator);

    var watchMap: std.StringHashMap(i64) = .init(gpa);
    defer watchMap.deinit();

    var watcherPathMap: std.StringHashMap(*DirectoryWatch) = .init(gpa);
    defer watcherPathMap.deinit();

    var watchingFileFullPath: []const u8 = undefined;

    if (std.fs.path.isAbsolute(watchingFilePath)) {
        watchingFileFullPath = try gpa.dupe(u8, watchingFilePath);
    } else {
        watchingFileFullPath = try std.fs.path.join(gpa, &[_][]const u8{ path.?, watchingFilePath });
    }
    defer gpa.free(watchingFileFullPath);

    const watchingFile: ?std.Io.File = std.Io.Dir.openFileAbsolute(
        init.io,
        watchingFileFullPath,
        .{ .mode = .read_only },
    ) catch |err| bl: switch (err) {
        error.FileNotFound => {
            std.log.debug("no watching file", .{});
            break :bl null;
        },
        else => return err,
    };

    var watchingFilePos: u64 = 0;
    var fileBuffer = [_]u8{0} ** 1024;
    var watchingFileReader: std.Io.File.Reader = undefined;
    if (watchingFile) |file| {
        watchingFileReader = file.reader(init.io, &fileBuffer);
        const fileSize = (try file.stat(init.io)).size;
        const content = try watchingFileReader.interface.readAlloc(gpa, fileSize);
        defer gpa.free(content);

        const tempTime = std.Io.Timestamp.now(init.io, .real).toMilliseconds();

        while (watchingFilePos < fileSize) {
            const index = std.mem.indexOf(u8, content[watchingFilePos..], "\n") orelse break;

            const line = content[watchingFilePos .. watchingFilePos + index];
            const clean_path = std.mem.trim(u8, line, "\r\t");

            const path_ = try allocator.dupe(u8, clean_path);

            try watchMap.put(path_, tempTime);
            watchingFilePos += index + 1;
        }
        try watchMap.put(watchingFilePath, tempTime);
    }

    const iocp = win32.CreateIoCompletionPort(
        windows.INVALID_HANDLE_VALUE,
        null,
        0,
        1,
    );
    if (iocp == null) return error.CreateIoCompletionPortFailed;

    global_iocp = iocp;
    _ = win32.SetConsoleCtrlHandler(consoleCtrlHandler, windows.BOOL.TRUE);

    var contentWatch: *DirectoryWatch = undefined;

    defer windows.CloseHandle(iocp.?);
    {
        var it = watchMap.iterator();
        while (it.next()) |kv| {
            const w = try addWatchFolder(
                path.?,
                kv.key_ptr.*,
                allocator,
                iocp,
                FILE_NOTIFY_CHANGE_FILE_NAME | FILE_NOTIFY_CHANGE_LAST_WRITE | FILE_NOTIFY_CHANGE_DIR_NAME,
                true,
            );

            if (w != null) {
                if (std.mem.eql(u8, w.?.path, contentDatabaseRelativePathStart.?)) {
                    contentWatch = w.?;
                }
                try watcherPathMap.put(kv.key_ptr.*, w.?);
            }
        }
    }

    const rootW = try addWatchFolder(
        path.?,
        "",
        allocator,
        iocp,
        FILE_NOTIFY_CHANGE_FILE_NAME | FILE_NOTIFY_CHANGE_LAST_WRITE,
        false,
    );

    var file_time_hashMap: std.StringHashMap(i64) = .init(gpa);
    defer file_time_hashMap.deinit();
    var removeArray: std.array_list.Managed([]const u8) = .init(allocator);
    defer removeArray.deinit();

    try database.processFolder(contentFolder, init.io, gpa);

    std.log.info("watching {s}...", .{path.?});

    var pending_old_name: ?[]u8 = null;
    var committer: db.AutoCommitter = .init(database, init.io, 2000);
    var future: ?Io.Future(@typeInfo(@TypeOf(db.AutoCommitter.runMonitor)).@"fn".return_type.?) = null;
    errdefer {
        if (future) |_| {
            _ = future.?.cancel(init.io) catch |err| std.log.err("AutoCommitter.runMonitor failed: {}", .{err});
        }
    }
    defer {
        if (future) |_| {
            _ = future.?.await(init.io) catch |err| std.log.err("AutoCommitter.runMonitor failed: {}", .{err});
        }
    }

    var arrayFirstIndex: usize = 0;
    var notifyArray = std.array_list.Managed(NotifyInformation).init(allocator);
    defer notifyArray.deinit();
    var notifyTimeMap: std.StringHashMap(i64) = .init(gpa);
    defer notifyTimeMap.deinit();

    const shaderCompiler = shaderc.Compiler.init(null, null, 2);

    var fileWriterBuffer = [_]u8{0} ** 1024;

    while (true) {
        var completion_key: usize = 0;
        var lp_overlapped: ?*OVERLAPPED = null;
        var bytes_transferred: windows.DWORD = 0;

        const res = win32.GetQueuedCompletionStatus(
            iocp.?,
            &bytes_transferred,
            &completion_key,
            &lp_overlapped,
            INFINITE,
        );

        if (completion_key == EXIT_COMPLETION_KEY) {
            break;
        }

        if (res != windows.BOOL.FALSE and lp_overlapped != null) {
            const watch: *DirectoryWatch = @ptrFromInt(completion_key);

            var breakFlag = false;
            var offset: usize = 0;
            while (true) {
                if (breakFlag) break;
                {
                    const info: *const FILE_NOTIFY_INFORMATION = @ptrCast(@alignCast(&watch.buffer[offset]));
                    defer {
                        if (info.NextEntryOffset == 0) breakFlag = true;
                        // std.log.debug("offset {d}", .{info.NextEntryOffset});
                        offset += info.NextEntryOffset;
                    }
                    const name_slice_u16 = @as([*]const u16, &info.FileName)[0 .. info.FileNameLength / 2];

                    const name_utf8 = try std.unicode.wtf16LeToWtf8Alloc(allocator, name_slice_u16);
                    errdefer allocator.free(name_utf8);

                    if (watch == rootW.?) {
                        const fullPath = try std.fs.path.joinZ(gpa, &[_][]const u8{ path.?, name_utf8 });
                        defer gpa.free(fullPath);
                        const fullPath_u16 = try std.unicode.wtf8ToWtf16LeAllocZ(gpa, fullPath);
                        defer gpa.free(fullPath_u16);

                        const attrs = win32.GetFileAttributesW(fullPath_u16.ptr);

                        if (attrs == windows.INVALID_FILE_ATTRIBUTES or (attrs & FILE_ATTRIBUTE_DIRECTORY) != 0) {
                            continue;
                        }
                    }

                    const time = std.Io.Timestamp.now(init.io, .real).toMilliseconds();

                    const last = notifyArray.getLastOrNull();
                    if (last) |l| {
                        // std.log.debug("{}, {}, {d}ms", .{ l.Action == info.Action, std.mem.eql(u8, l.name, name_utf8), time - l.time });
                        if (l.Action == info.Action and std.mem.eql(u8, l.name, name_utf8) and time - l.time < 500) {
                            // std.log.debug("name {s} 2", .{name_utf8});
                            allocator.free(name_utf8);
                            continue;
                        } else {
                            if (notifyTimeMap.get(name_utf8)) |t| {
                                // std.log.debug("{d}ms", .{time - t});
                                if (time - t < 500) {
                                    // std.log.debug("name {s} 1", .{name_utf8});
                                    allocator.free(name_utf8);
                                    continue;
                                }
                            }
                        }
                    }
                    try notifyArray.append(.{
                        .Action = info.Action,
                        .name = name_utf8,
                        .time = std.Io.Timestamp.now(init.io, .real).toMilliseconds(),
                    });
                    try notifyTimeMap.put(name_utf8, time);
                }
            }

            while (true) {
                if (arrayFirstIndex >= notifyArray.items.len) {
                    if (notifyArray.items.len > 1000) {
                        for (notifyArray.items) |value| {
                            allocator.free(value.name);
                        }
                        notifyArray.clearRetainingCapacity();
                        arrayFirstIndex = 0;
                    }
                    break;
                }

                const info = notifyArray.items[arrayFirstIndex];
                arrayFirstIndex += 1;

                if (info.Action == 100) continue;

                const name_utf8 = info.name;

                const action_str = switch (info.Action) {
                    1 => "create",
                    2 => "delete",
                    3 => "modify",
                    4 => "rename (old)",
                    5 => "rename (new)",
                    else => "unknown",
                };

                std.log.info("[{s}] {s}", .{ action_str, name_utf8 });

                switch (info.Action) {
                    1, 3 => {
                        if (std.mem.eql(u8, name_utf8, watchingFilePath)) {
                            if (watchingFile == null) {
                                continue;
                            }

                            const curTime = std.Io.Timestamp.now(init.io, .real).toMilliseconds();

                            try std.Io.sleep(init.io, .fromMilliseconds(10), .real);

                            const fileSize = (try watchingFile.?.stat(init.io)).size;

                            _ = try watchingFileReader.seekTo(0);

                            const content = try watchingFileReader.interface.readAlloc(gpa, fileSize);
                            defer gpa.free(content);

                            watchingFilePos = 0;
                            while (watchingFilePos < fileSize) {
                                const index = std.mem.indexOf(
                                    u8,
                                    content[watchingFilePos..],
                                    "\n",
                                ) orelse break;

                                const line = content[watchingFilePos .. watchingFilePos + index];
                                const clean_path = std.mem.trim(u8, line, "\r\t");
                                const path_ = try allocator.dupe(u8, clean_path);

                                const getRes = watchMap.getPtr(path_);
                                if (getRes != null) {
                                    allocator.free(path_);
                                    getRes.?.* = curTime;
                                } else {
                                    const wRes = watcherPathMap.get(path_);

                                    if (wRes != null) {
                                        // std.log.debug("found", .{});

                                        if (wRes.?.*.stopWatch) {
                                            // std.log.debug("resume {s}", .{path_});
                                            wRes.?.*.stopWatch = false;
                                            try wRes.?.*.startWatch();
                                        }
                                    } else {
                                        std.log.debug("new", .{});
                                        const w = try addWatchFolder(
                                            path.?,
                                            path_,
                                            allocator,
                                            iocp,
                                            FILE_NOTIFY_CHANGE_FILE_NAME | FILE_NOTIFY_CHANGE_LAST_WRITE | FILE_NOTIFY_CHANGE_DIR_NAME,
                                            true,
                                        );
                                        if (w != null) {
                                            try watcherPathMap.put(path_, w.?);
                                            try w.?.startWatch();
                                        }
                                    }
                                    try watchMap.put(path_, curTime);
                                }

                                watchingFilePos += index + 1;
                            }

                            var it = watchMap.iterator();

                            while (it.next()) |kv| {
                                if (kv.value_ptr.* != curTime) {
                                    try removeArray.append(kv.key_ptr.*);
                                    continue;
                                }
                            }

                            for (removeArray.items) |key| {
                                _ = watchMap.remove(key);
                                const w = watcherPathMap.get(key);
                                if (w != null) {
                                    w.?.stopWatch = true;
                                }
                            }
                            removeArray.clearRetainingCapacity();
                        } else {
                            const fullPath = try std.fs.path.joinZ(
                                gpa,
                                &[_][]const u8{ watch.path, name_utf8 },
                            );
                            defer gpa.free(fullPath);

                            try std.Io.sleep(init.io, .fromMilliseconds(1), .real);

                            const file: ?std.Io.File = std.Io.Dir.openFileAbsolute(
                                init.io,
                                fullPath,
                                .{},
                            ) catch |err| s: switch (err) {
                                else => {
                                    std.log.err("failed to open file {s} {s}", .{ fullPath, @errorName(err) });
                                    break :s null;
                                },
                            };

                            if (file) |f| {
                                defer f.close(init.io);
                                const stat = try f.stat(init.io);

                                if (stat.kind == .file) {
                                    var startIndex = std.mem.findLast(u8, fullPath, "\\") orelse 0;
                                    if (startIndex != 0) startIndex += 1;
                                    const fileName = fullPath[startIndex..];

                                    var fType = db.FileType.UNKNOWN;

                                    if (watch == contentWatch) {
                                        // std.log.debug("in", .{});
                                        const dir = try std.Io.Dir.openDirAbsolute(
                                            init.io,
                                            fullPath[0 .. startIndex - 1],
                                            .{},
                                        );
                                        defer dir.close(init.io);

                                        const idx = std.mem.findLast(u8, fullPath, "Content");

                                        if (idx) |i| {
                                            // std.log.debug("in in", .{});
                                            var parentUUID = [_]u8{0} ** db.UUID.len;
                                            var getValues: [1]*anyopaque = undefined;
                                            getValues[0] = @ptrCast(&parentUUID);
                                            var types = [_]db.innerType{.TEXT};

                                            const parentPathZ = try std.fs.path.joinZ(
                                                gpa,
                                                &[_][]const u8{fullPath[i .. startIndex - 1]},
                                            );
                                            defer gpa.free(parentPathZ);

                                            try database.ContentPathT.get(
                                                "UUID",
                                                null,
                                                "RelativePath = ?",
                                                .{parentPathZ},
                                                &getValues,
                                                &types,
                                            );
                                            std.log.debug("{s}", .{parentPathZ});
                                            fType = try db.iterateFolder.processFile(
                                                init.io,
                                                dir,
                                                fileName,
                                                fullPath[i..],
                                                &parentUUID,
                                            );
                                        }

                                        if (committer.is_active) {
                                            committer.poke();
                                        } else {
                                            if (future) |_| {
                                                _ = try future.?.await(init.io);
                                                future = null;
                                            }
                                            committer.activate();
                                            future = init.io.async(db.AutoCommitter.runMonitor, .{&committer});
                                        }
                                    } else {
                                        const dotIndex = std.mem.findLast(u8, fileName, ".") orelse fileName.len;

                                        var readBuffer = [_]u8{0} ** 64;
                                        var reader = f.reader(init.io, &readBuffer);
                                        const content = try reader.interface.readAlloc(gpa, stat.size);
                                        defer gpa.free(content);

                                        fType = db.judgeFileType(fileName[dotIndex..], content);

                                        switch (fType) {
                                            .Shader => {
                                                const spv = shaderCompiler.compileShader(
                                                    content,
                                                    fileName,
                                                    "main",
                                                    gpa,
                                                ) catch continue;
                                                defer gpa.free(spv);

                                                const spvName = try std.fmt.allocPrint(gpa, "{s}.spv", .{fileName});
                                                defer gpa.free(spvName);

                                                const spvFullPath = try std.fs.path.joinZ(
                                                    gpa,
                                                    &[_][]const u8{
                                                        contentDatabaseRelativePathStart.?,
                                                        "Shaders",
                                                        spvName,
                                                    },
                                                );
                                                defer gpa.free(spvFullPath);

                                                const spvFile = std.Io.Dir.createFileAbsolute(
                                                    init.io,
                                                    spvFullPath,
                                                    .{},
                                                ) catch {
                                                    std.log.err("create file {s} failed", .{spvFullPath});
                                                    continue;
                                                };
                                                defer spvFile.close(init.io);

                                                var writer = spvFile.writer(init.io, &fileWriterBuffer);
                                                writer.interface.writeAll(spv) catch {
                                                    std.log.err("write file {s} failed", .{spvFullPath});
                                                    continue;
                                                };

                                                const nodeType_u32: u32 = @intFromEnum(db.NodeType.Shader);
                                                try database.ShaderPipelineGraphNodeT.insert(.{
                                                    .Name = @constCast(spvName.ptr),
                                                    .Type = nodeType_u32,
                                                });
                                            },
                                            .Sampler => {
                                                const samplerName = try std.fmt.allocPrint(gpa, "{s}ler", .{fileName});
                                                defer gpa.free(samplerName);

                                                const samplerFullPath = try std.fs.path.joinZ(
                                                    gpa,
                                                    &[_][]const u8{
                                                        contentDatabaseRelativePathStart.?,
                                                        "Sampler",
                                                        samplerName,
                                                    },
                                                );
                                                defer gpa.free(samplerFullPath);

                                                sampler.praseSampler(init.io, content, samplerFullPath, gpa) catch |err| {
                                                    std.log.err("write file {s} failed {s}", .{ samplerFullPath, @errorName(err) });
                                                    continue;
                                                };
                                            },
                                            .Pipeline => {},
                                            else => {},
                                        }
                                    }

                                    std.log.debug("name {s} {s}", .{ fileName, @tagName(fType) });
                                } else if (stat.kind == .directory) {
                                    const dir: ?std.Io.Dir = std.Io.Dir.openDirAbsolute(
                                        init.io,
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
                                        defer d.close(init.io);

                                        std.log.debug("in", .{});

                                        if (watch == contentWatch) {
                                            const parentDir = try std.Io.Dir.openDirAbsolute(
                                                init.io,
                                                fullPath[0 .. startIndex - 1],
                                                .{},
                                            );
                                            defer parentDir.close(init.io);

                                            const idx = std.mem.findLast(u8, fullPath, "Content");

                                            if (idx) |i| {
                                                std.log.debug("in in", .{});
                                                var parentUUID = [_]u8{0} ** db.UUID.len;
                                                var getValues: [1]*anyopaque = undefined;
                                                getValues[0] = @ptrCast(&parentUUID);
                                                var types = [_]db.innerType{.TEXT};

                                                const parentPathZ = try std.fs.path.joinZ(
                                                    gpa,
                                                    &[_][]const u8{fullPath[i .. startIndex - 1]},
                                                );
                                                defer gpa.free(parentPathZ);

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
                                                    init.io,
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
                                                    _ = try future.?.await(init.io);
                                                    future = null;
                                                }
                                                committer.activate();
                                                future = init.io.async(db.AutoCommitter.runMonitor, .{&committer});
                                            }
                                        }

                                        std.log.debug("dir {s}", .{dirname});
                                    }
                                }
                            }
                        }
                    },
                    2 => {
                        const fullPath = try std.fs.path.joinZ(
                            gpa,
                            &[_][]const u8{ watch.path, name_utf8 },
                        );
                        defer gpa.free(fullPath);

                        var startIndex = std.mem.findLast(u8, fullPath, "\\") orelse 0;
                        if (startIndex != 0) startIndex += 1;
                        const fileName = fullPath[startIndex..];

                        if (watch == contentWatch) {
                            try database.ContentPathT.delete(
                                "FileName = ?",
                                .{fileName},
                            );

                            if (committer.is_active) {
                                committer.poke();
                            } else {
                                if (future) |_| {
                                    _ = try future.?.await(init.io);
                                    future = null;
                                }
                                committer.activate();
                                future = init.io.async(db.AutoCommitter.runMonitor, .{&committer});
                            }
                        }
                    },
                    4 => {
                        if (pending_old_name) |old| allocator.free(old);
                        pending_old_name = try allocator.dupe(u8, name_utf8);
                    },
                    5 => {
                        if (pending_old_name) |old| {
                            const fullPath = try std.fs.path.joinZ(
                                gpa,
                                &[_][]const u8{ watch.path, name_utf8 },
                            );
                            defer gpa.free(fullPath);

                            if (watch == contentWatch) {
                                var startIndex = std.mem.findLast(u8, fullPath, "\\") orelse 0;
                                if (startIndex != 0) startIndex += 1;
                                const fileName = fullPath[startIndex..];

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
                                        gpa,
                                        &[_][]const u8{fullPath[i .. startIndex - 1]},
                                    );
                                    defer gpa.free(parentPathZ);

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
                            }

                            std.log.info("rename {s} -> {s}", .{ old, name_utf8 });
                            allocator.free(old);
                            pending_old_name = null;
                        }
                    },
                    else => {},
                }
            }
            try watch.startWatch();
        }
    }

    std.log.debug("end", .{});
}
fn addWatchFolder(rootPath: []const u8, path: []const u8, allocator: std.mem.Allocator, iocp: ?windows.HANDLE, dwNotifyFilter: windows.DWORD, recursive: bool) !?*DirectoryWatch {
    const fullPath = try std.fs.path.joinZ(allocator, &[_][]const u8{ rootPath, path });

    std.log.debug("{s}", .{fullPath});

    const path_w = try std.unicode.wtf8ToWtf16LeAllocZ(allocator, fullPath);
    const h_dir = win32.CreateFileW(
        path_w,
        FILE_LIST_DIRECTORY,
        FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE,
        null,
        OPEN_EXISTING,
        FILE_FLAG_BACKUP_SEMANTICS | FILE_FLAG_OVERLAPPED,
        null,
    );

    if (h_dir == windows.INVALID_HANDLE_VALUE) {
        std.log.debug("{s} not found error {d}", .{ fullPath, windows.GetLastError() });
        return null;
    }

    const watch = try allocator.create(DirectoryWatch);
    watch.* = .{
        .dwNotifyFilter = dwNotifyFilter,
        .handle = h_dir,
        .path = fullPath,
        .recursive = recursive,
    };

    _ = win32.CreateIoCompletionPort(h_dir, iocp, @intFromPtr(watch), 0);

    try watch.startWatch();

    return watch;
}

fn consoleCtrlHandler(ctrl_type: windows.DWORD) callconv(.winapi) windows.BOOL {
    _ = ctrl_type;
    if (global_iocp) |iocp| {
        std.debug.print("\nShutting down...\n", .{});
        _ = win32.PostQueuedCompletionStatus(iocp, 0, EXIT_COMPLETION_KEY, null);
    }
    return windows.BOOL.fromBool(true);
}
