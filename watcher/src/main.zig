const std = @import("std");
const Io = std.Io;

const configFile = ".watching";

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

const GENERIC_READ: windows.DWORD = 0x80000000;
const FILE_SHARE_READ: windows.DWORD = 0x00000001;
const FILE_SHARE_WRITE: windows.DWORD = 0x00000002;
const FILE_SHARE_DELETE: windows.DWORD = 0x00000004;
const OPEN_EXISTING: windows.DWORD = 3;
const INFINITE: windows.DWORD = 0xFFFFFFFF;

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
};

const DirectoryWatch = struct {
    handle: windows.HANDLE,
    overlapped: OVERLAPPED = .{},
    buffer: [2048]u8 align(@alignOf(FILE_NOTIFY_INFORMATION)) = undefined,
    path: []const u8,
    recursive: bool,
    stopWatch: bool = false,

    pub fn startWatch(self: *DirectoryWatch) !void {
        if (self.stopWatch) return;

        const success = win32.ReadDirectoryChangesW(
            self.handle,
            &self.buffer,
            self.buffer.len,
            windows.BOOL.fromBool(self.recursive),
            FILE_NOTIFY_CHANGE_FILE_NAME | FILE_NOTIFY_CHANGE_LAST_WRITE | FILE_NOTIFY_CHANGE_DIR_NAME,
            null,
            &self.overlapped,
            null,
        );
        if (success == windows.BOOL.FALSE) {
            std.log.debug("{s} {d}", .{ self.path, @as(u32, @intFromEnum(windows.GetLastError())) });
        }
        std.log.debug("watch {s}", .{self.path});
    }
};

pub fn main(init: std.process.Init) !void {
    const gpa = init.gpa;
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    const allocator = arena.allocator();

    var argsIt = try init.minimal.args.iterateAllocator(gpa);
    defer argsIt.deinit();

    var folder: ?[:0]u16 = null;
    var path: ?[:0]const u8 = null;

    var watchingFilePath: []const u8 = configFile;

    _ = argsIt.next();

    while (argsIt.next()) |arg| {
        std.log.debug("{s}", .{arg});
        if (std.mem.eql(u8, arg[0..3], "--f")) {
            path = argsIt.next() orelse return error.NoFolder;

            folder = try std.unicode.wtf8ToWtf16LeAllocZ(gpa, path.?);
            errdefer gpa.free(folder.?);
            continue;
        } else if (std.mem.eql(u8, arg[0..3], "--w")) {
            watchingFilePath = argsIt.next() orelse configFile;
            continue;
        }

        std.log.err("unknow command {s}", .{arg});
    }
    defer gpa.free(folder.?);

    if (folder == null) return error.NoFolder;

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

    const watchingFile: ?std.Io.File = std.Io.Dir.openFileAbsolute(init.io, watchingFileFullPath, .{ .mode = .read_only }) catch |err| bl: switch (err) {
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
    defer windows.CloseHandle(iocp.?);
    {
        var it = watchMap.iterator();
        while (it.next()) |kv| {
            const w = try addWatchFolder(
                path.?,
                kv.key_ptr.*,
                allocator,
                iocp,
                true,
            );

            if (w != null)
                try watcherPathMap.put(kv.key_ptr.*, w.?);
        }
    }

    _ = try addWatchFolder(
        path.?,
        "",
        allocator,
        iocp,
        false,
    );

    var file_time_hashMap: std.StringHashMap(i64) = .init(gpa);
    defer file_time_hashMap.deinit();
    var removeArray: std.array_list.Managed([]const u8) = .init(allocator);
    defer removeArray.deinit();

    std.log.info("watching {s}...", .{path.?});

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

        if (res != windows.BOOL.FALSE and lp_overlapped != null) {
            const watch: *DirectoryWatch = @ptrFromInt(completion_key);

            var offset: usize = 0;
            while (true) {
                const info: *const FILE_NOTIFY_INFORMATION = @ptrCast(@alignCast(&watch.buffer[offset]));

                const name_slice_u16 = @as([*]const u16, &info.FileName)[0 .. info.FileNameLength / 2];

                const name_utf8 = try std.unicode.wtf16LeToWtf8Alloc(allocator, name_slice_u16);

                const timeRes = file_time_hashMap.getPtr(name_utf8);
                // std.log.debug("{}", .{timeRes.found_existing});
                if (timeRes != null) {
                    const curTime = std.Io.Timestamp.now(init.io, .real).toMilliseconds();

                    if (curTime - timeRes.?.* < 100) {
                        if (info.NextEntryOffset == 0) break;
                        offset += info.NextEntryOffset;
                        continue;
                    }
                } else {
                    try file_time_hashMap.put(name_utf8, std.Io.Timestamp.now(init.io, .real).toMilliseconds());
                }

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
                    3 => {
                        if (std.mem.eql(u8, name_utf8, watchingFilePath)) {
                            if (watchingFile == null) {
                                continue;
                            }

                            const curTime = std.Io.Timestamp.now(init.io, .real).toMilliseconds();

                            try std.Io.sleep(init.io, .fromMilliseconds(10), .real);

                            const fileSize = (try watchingFile.?.stat(init.io)).size;
                            // std.log.debug("size {d}", .{fileSize});

                            _ = try watchingFileReader.seekTo(0);

                            const content = try watchingFileReader.interface.readAlloc(gpa, fileSize);
                            defer gpa.free(content);

                            watchingFilePos = 0;
                            while (watchingFilePos < fileSize) {
                                // std.log.debug("in", .{});
                                const index = std.mem.indexOf(u8, content[watchingFilePos..], "\n") orelse break;

                                const line = content[watchingFilePos .. watchingFilePos + index];
                                const clean_path = std.mem.trim(u8, line, "\r\t");

                                const path_ = try allocator.dupe(u8, clean_path);

                                // std.log.debug("path {s}", .{path_});

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
                                        // std.log.debug("new", .{});
                                        const w = try addWatchFolder(path.?, path_, allocator, iocp, true);
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
                                // std.log.debug("path {s} {d} {d}", .{ kv.key_ptr.*, kv.value_ptr.*, curTime });
                                if (kv.value_ptr.* != curTime) {
                                    try removeArray.append(kv.key_ptr.*);
                                    continue;
                                }
                                // std.log.debug("path {s}", .{kv.key_ptr.*});
                            }

                            for (removeArray.items) |key| {
                                _ = watchMap.remove(key);
                                const w = watcherPathMap.get(key);
                                if (w != null) {
                                    w.?.stopWatch = true;
                                }
                            }
                            removeArray.clearRetainingCapacity();
                        } else {}
                    },
                    else => {},
                    // }
                }

                if (timeRes != null) {
                    allocator.free(name_utf8);
                }

                if (info.NextEntryOffset == 0) break;
                offset += info.NextEntryOffset;
            }
            try watch.startWatch();
        }
    }
}
fn addWatchFolder(rootPath: []const u8, path: []const u8, allocator: std.mem.Allocator, iocp: ?windows.HANDLE, recursive: bool) !?*DirectoryWatch {
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
        .handle = h_dir,
        .path = fullPath,
        .recursive = recursive,
    };

    _ = win32.CreateIoCompletionPort(h_dir, iocp, @intFromPtr(watch), 0);

    try watch.startWatch();

    return watch;
}
