const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;

const assert = std.debug.assert;

const configFile = ".watching";
const databaseFile = "Content.db";

const EXIT_COMPLETION_KEY = 0xDEADBEEF;
const SAVE_COMPLETION_KEY = 0xCAFEBABE;

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

const CTRL_C_EVENT: windows.DWORD = 0;
const CTRL_BREAK_EVENT: windows.DWORD = 1;

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
    fullPath: [:0]const u8,
};

const TimeAction = struct {
    time: [5]i64,
    action: [5]bool,
};

var global_iocp: ?windows.HANDLE = null;

var contentWatch: *DirectoryWatch = undefined;

// var database: *db = undefined;
var cooker: std.process.Child = undefined;
var cookerWriterBuffer = [_]u8{0} ** 1024;
var cookerWriter: std.Io.File.Writer = undefined;

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const gpa = init.gpa;
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    const allocator = arena.allocator();

    var argsIt = try init.minimal.args.iterateAllocator(allocator);
    defer argsIt.deinit();

    var folder: ?[:0]u16 = null;
    var path: ?[:0]const u8 = null;
    var contentDatabaseRelativePathStart: ?[:0]const u8 = null;
    var cookerPath: ?[:0]const u8 = null;
    var cookerRootPath: ?[:0]const u8 = null;

    var watchingFilePath: []const u8 = configFile;
    var databaseFilePath: []const u8 = databaseFile;

    {
        errdefer {
            std.log.debug(
                ".exe --f [root folder]\n --d [database path]\n [database relative path start]\n--c [cooker.exe path]\n (optional) --w [config file path]",
                .{},
            );
        }
        _ = argsIt.next();
        while (argsIt.next()) |arg| {
            // std.log.debug("{s}", .{arg});
            if (arg.len >= 6) {
                if (std.mem.eql(u8, arg[0..6], "-force")) {
                    // db.iterateFolder.forceUpdata = true;

                    continue;
                }
            } else if (arg.len >= 3) {
                if (std.mem.eql(u8, arg[0..3], "--f")) {
                    path = argsIt.next() orelse return error.NoFolder;

                    folder = try std.unicode.wtf8ToWtf16LeAllocZ(allocator, path.?);
                    errdefer allocator.free(folder.?);
                    continue;
                } else if (std.mem.eql(u8, arg[0..3], "--w")) {
                    watchingFilePath = argsIt.next() orelse configFile;
                    continue;
                } else if (std.mem.eql(u8, arg[0..3], "--d")) {
                    databaseFilePath = argsIt.next() orelse databaseFile;
                    contentDatabaseRelativePathStart = argsIt.next() orelse return error.NoDatabaseRelativePathStart;

                    continue;
                } else if (std.mem.eql(u8, arg[0..3], "--c")) {
                    cookerPath = argsIt.next() orelse return error.NoCookerPath;
                    cookerRootPath = argsIt.next() orelse return error.NoCookerPath;

                    continue;
                }
            }

            std.log.err("unknow command {s}", .{arg});
        }
    }
    defer allocator.free(folder.?);

    if (folder == null) return error.NoFolder;
    if (cookerPath == null) return error.NoCookerPath;
    if (contentDatabaseRelativePathStart == null) return error.NoDatabaseRelativePathStart;

    const dbPath = try std.fmt.allocPrint(allocator, "{s}?", .{databaseFilePath});
    defer allocator.free(dbPath);

    const dbPathStart = try std.fmt.allocPrint(allocator, "{s}?", .{contentDatabaseRelativePathStart.?});
    defer allocator.free(dbPathStart);

    var cookerArgv = [_][]const u8{cookerPath.?};

    try cookerInit(io, &cookerArgv, dbPath, dbPathStart);

    // database = try db.init(allocator, databaseFilePath);
    // errdefer database.rollback();
    // defer database.deinit(allocator);

    var watchMap: std.StringHashMap(i64) = .init(allocator);
    defer watchMap.deinit();

    var watcherPathMap: std.StringHashMap(*DirectoryWatch) = .init(allocator);
    defer watcherPathMap.deinit();

    var watchingFileFullPath: []const u8 = undefined;

    if (std.fs.path.isAbsolute(watchingFilePath)) {
        watchingFileFullPath = try allocator.dupe(u8, watchingFilePath);
    } else {
        watchingFileFullPath = try std.fs.path.join(allocator, &[_][]const u8{ path.?, watchingFilePath });
    }
    defer allocator.free(watchingFileFullPath);

    const watchingFile: ?std.Io.File = std.Io.Dir.openFileAbsolute(
        io,
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
        watchingFileReader = file.reader(io, &fileBuffer);
        const fileSize = (try file.stat(io)).size;
        const content = try watchingFileReader.interface.readAlloc(allocator, fileSize);
        defer allocator.free(content);

        const tempTime = std.Io.Timestamp.now(io, .real).toMilliseconds();

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
                std.log.debug("{s}, {s}", .{ w.?.path, contentDatabaseRelativePathStart.? });
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

    var removeArray: std.array_list.Managed([]const u8) = .init(allocator);
    defer removeArray.deinit();

    // try database.processFolder(contentFolder, io, allocator);
    // defer db.iterateFolder.cleanSceneJson();

    std.log.info("watching {s}...", .{path.?});

    var arrayFirstIndex: usize = 0;
    var notifyArray = std.array_list.Managed(NotifyInformation).init(allocator);
    defer notifyArray.deinit();

    var debonuceArray = std.array_list.Managed(NotifyInformation).init(allocator);
    defer debonuceArray.deinit();

    var debonuceMutex: Io.Mutex = .init;

    var debonuceFuture = Io.async(io, debonuce, .{ io, allocator, iocp.?, &debonuceMutex, &debonuceArray, &notifyArray });
    defer debonuceFuture.cancel(io) catch {};

    while (true) {
        if (cooker.id == null) {
            try cookerInit(io, &cookerArgv, dbPath, dbPathStart);
        }

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
            cookerWriter.interface.writeAll("404??\n") catch {};
            // cookerWriter.flush() catch {};

            const wRes = try cooker.wait(io);

            switchOnTerm(wRes);

            std.log.debug("Exit", .{});
            break;
        }

        if (completion_key == SAVE_COMPLETION_KEY) {
            try cookerWriter.interface.writeAll("1234??\n");
            cookerWriter.flush() catch {
                try cookerInit(io, &cookerArgv, dbPath, dbPathStart);
            };

            continue;
        }

        // if (completion_key == 0) {
        //     std.log.debug("aaa", .{});
        // }

        if ((res != windows.BOOL.FALSE and lp_overlapped != null) or completion_key == 0) {
            if (completion_key != 0) {
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

                        if (info.Action == 100) continue;

                        const name_slice_u16 = @as([*]const u16, &info.FileName)[0 .. info.FileNameLength / 2];

                        const name_utf8 = try std.unicode.wtf16LeToWtf8Alloc(allocator, name_slice_u16);
                        errdefer allocator.free(name_utf8);

                        const fullPath = try std.fs.path.joinZ(
                            allocator,
                            &[_][]const u8{ watch.path, name_utf8 },
                        );
                        errdefer allocator.free(fullPath);

                        if (watch == rootW.?) {
                            const fullPath_u16 = try std.unicode.wtf8ToWtf16LeAllocZ(allocator, fullPath);
                            defer allocator.free(fullPath_u16);

                            const attrs = win32.GetFileAttributesW(fullPath_u16.ptr);

                            if (attrs == windows.INVALID_FILE_ATTRIBUTES or (attrs & FILE_ATTRIBUTE_DIRECTORY) != 0) {
                                defer allocator.free(name_utf8);
                                defer allocator.free(fullPath);
                                continue;
                            }
                        }

                        const time = std.Io.Timestamp.now(io, .real).toMilliseconds();

                        try debonuceMutex.lock(io);
                        defer debonuceMutex.unlock(io);
                        try debonuceArray.append(.{
                            .Action = info.Action,
                            .name = name_utf8,
                            .fullPath = fullPath,
                            .time = time,
                        });
                    }
                }
                try watch.startWatch();
            }

            while (true) {
                try debonuceMutex.lock(io);
                defer debonuceMutex.unlock(io);

                if (arrayFirstIndex >= notifyArray.items.len) {
                    if (notifyArray.items.len > 1000) {
                        for (notifyArray.items) |value| {
                            allocator.free(value.name);
                            allocator.free(value.fullPath);
                        }
                        notifyArray.clearRetainingCapacity();
                        arrayFirstIndex = 0;
                    }
                    break;
                }

                const info = notifyArray.items[arrayFirstIndex];
                arrayFirstIndex += 1;

                if (info.Action == 100) continue;

                var action = info.Action;

                const name_utf8 = info.name;
                const fullPath = info.fullPath;

                if (std.mem.startsWith(u8, fullPath, cookerRootPath.?)) {
                    if (std.mem.containsAtLeast(u8, fullPath, 1, ".zig-cache")) {
                        continue;
                    }

                    try cookerWriter.interface.writeAll("404??\n");
                    cookerWriter.flush() catch {
                        // try cookerInit(io, &cookerArgv, dbPath, dbPathStart);
                    };

                    Io.sleep(io, .fromSeconds(1), .real) catch {};
                    cooker.kill(io);
                    // switchOnTerm(wRes);

                    const cookerBuildZig =
                        try std.fmt.allocPrint(allocator, "{s}{s}build.zig", .{ cookerRootPath.?, "/" });
                    defer allocator.free(cookerBuildZig);

                    const runRes = try std.process.run(allocator, io, .{ .argv = &[_][]const u8{
                        "zig",
                        "build",
                        "--build-file",
                        cookerBuildZig,
                    } });
                    defer {
                        allocator.free(runRes.stderr);
                        allocator.free(runRes.stdout);
                    }

                    std.log.err("{s}", .{runRes.stderr});
                    switchOnTerm(runRes.term);

                    try cookerInit(io, &cookerArgv, dbPath, dbPathStart);
                }

                if (std.mem.eql(u8, name_utf8, watchingFilePath)) {
                    if (watchingFile == null) {
                        continue;
                    }

                    const curTime = std.Io.Timestamp.now(io, .real).toMilliseconds();

                    try std.Io.sleep(io, .fromMilliseconds(10), .real);

                    const fileSize = (try watchingFile.?.stat(io)).size;

                    _ = try watchingFileReader.seekTo(0);

                    const content = try watchingFileReader.interface.readAlloc(allocator, fileSize);
                    defer allocator.free(content);

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

                    continue;
                }

                if (std.mem.startsWith(u8, fullPath, contentDatabaseRelativePathStart.?)) {
                    action += 1000;
                }

                const cookerOut = try std.fmt.allocPrint(allocator, "{d}?{s}?{s}\n", .{ action, name_utf8, fullPath });
                defer allocator.free(cookerOut);

                try cookerWriter.interface.writeAll(cookerOut);
                cookerWriter.flush() catch {
                    try cookerInit(io, &cookerArgv, dbPath, dbPathStart);
                };
            }
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
    if (global_iocp) |iocp| {
        switch (ctrl_type) {
            CTRL_BREAK_EVENT => {
                std.log.debug("\nSaving...\n", .{});
                _ = win32.PostQueuedCompletionStatus(iocp, 0, SAVE_COMPLETION_KEY, null);
                return windows.BOOL.fromBool(true);
            },
            CTRL_C_EVENT => {
                std.log.debug("\nShutting down...\n", .{});
                _ = win32.PostQueuedCompletionStatus(iocp, 0, EXIT_COMPLETION_KEY, null);
                return windows.BOOL.fromBool(true);
            },
            else => return windows.BOOL.fromBool(true),
        }
    }
    return windows.BOOL.fromBool(true);
}

fn switchOnTerm(term: std.process.Child.Term) void {
    switch (term) {
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
}

fn debonuce(
    io: Io,
    allocator: Allocator,
    iocp: windows.HANDLE,
    mutex: *Io.Mutex,
    array: *std.array_list.Managed(NotifyInformation),
    resArray: *std.array_list.Managed(NotifyInformation),
) !void {
    const sortS = struct {
        fn lessThan(_: void, a: NotifyInformation, b: NotifyInformation) bool {
            if (a.time == 0) return false;
            if (b.time == 0) return true;

            if (a.time < b.time) return true;

            return false;
        }
    };
    while (true) {
        try Io.sleep(io, .fromMilliseconds(500), .real);

        const time = std.Io.Timestamp.now(io, .real).toMilliseconds();
        {
            try mutex.lock(io);
            defer mutex.unlock(io);
            if (array.items.len > 0) {
                // std.log.debug("len {d}", .{array.items.len});
                for (array.items[0 .. array.items.len - 1], 0..) |*value, i| {
                    for (array.items[i + 1 ..]) |*value2| {
                        if (value.time != 0 and value.Action == value.Action and std.mem.eql(u8, value.name, value2.name)) {
                            // std.log.debug("{s}: {d}\n{s}: {d}", .{ value.name, value.time, value2.name, value2.time });
                            assert(value.time <= value2.time);

                            if (value.time + 500 > value2.time) {
                                allocator.free(value.name);
                                allocator.free(value.fullPath);
                                value.time = 0;
                            }
                        }
                    }
                }

                for (array.items) |*value| {
                    if (value.time != 0 and time - value.time > 500) {
                        // std.log.debug("{s}", .{value.name});
                        try resArray.append(value.*);
                        value.time = 0;
                    }
                }

                std.sort.insertion(NotifyInformation, array.items, void{}, sortS.lessThan);

                var end = array.items.len;
                for (array.items, 0..) |value, i| {
                    if (value.time == 0) {
                        end = i;
                        break;
                    }
                }
                array.items.len = end;

                _ = win32.PostQueuedCompletionStatus(iocp, 0, 0, null);
            }
        }
    }
}

fn cookerInit(
    io: Io,
    argv: []const []const u8,
    databaseFilePath: []const u8,
    contentDatabaseRelativePathStart: []const u8,
) !void {
    cooker = try std.process.spawn(io, .{
        .argv = argv,
        .stdin = .pipe,
        .stdout = .inherit,
        .stderr = .inherit,
    });
    cookerWriter = cooker.stdin.?.writer(io, &cookerWriterBuffer);

    try cookerWriter.interface.writeAll(databaseFilePath);
    try cookerWriter.interface.writeAll(contentDatabaseRelativePathStart);
    try cookerWriter.interface.writeAll("404?");
    try cookerWriter.flush();
}
