const std = @import("std");
const process = std.process;
const json = std.json;

const builtin = @import("builtin");

// const git2 = @cImport(@cInclude("git2.h"));

const folderPath_Hash_Pair = struct {
    path: []const u8,
    hash: []const u8,
};

const default_output_file = "a.txt";
const cachePath = "cache.json";

var cacheMap: std.StringHashMap([]u8) = undefined;

var debug_allocator: std.heap.DebugAllocator(.{ .stack_trace_frames = 10 }) = .init;
pub fn main() !void {
    var buffer1 = [_]u8{0} ** 1024;
    var buffer2 = [_]u8{0} ** 1024;
    var buffer3 = [_]u8{0} ** 1024;
    var buffer4 = [_]u8{0} ** 1024;

    const gpa, const is_debug = gpa: {
        break :gpa switch (builtin.mode) {
            .Debug, .ReleaseSafe => .{ debug_allocator.allocator(), true },
            .ReleaseFast, .ReleaseSmall => .{ std.heap.smp_allocator, false },
        };
    };
    defer if (is_debug) {
        _ = debug_allocator.deinit();
    };

    cacheMap = .init(gpa);
    defer cacheMap.deinit();

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const args = try process.argsAlloc(gpa);
    defer process.argsFree(gpa, args);

    if (args.len < 3) {
        std.log.info(".exe [root dir] [relative to root folder] (output file path)", .{});
        return;
    }

    const root_dir = args[1];
    const dest_folder_path = args[2];

    var ouput_file: [:0]u8 = undefined;
    if (args.len > 3) {
        ouput_file = args[3];
    } else {
        ouput_file = @constCast(&default_output_file.*);
    }

    for (args) |arg| {
        std.log.info("arg: {s}", .{arg});
    }

    var cwd = try std.fs.cwd().openDir(root_dir, .{});
    defer cwd.close();

    try cwd.setAsCwd();

    var dest_dir = try cwd.openDir(dest_folder_path, .{ .iterate = true });
    defer dest_dir.close();

    var cacheFile = std.fs.cwd().openFile(cachePath, .{
        .mode = .read_write,
    }) catch |err| switch (err) {
        error.FileNotFound => try std.fs.cwd().createFile(cachePath, .{
            .read = true,
            .truncate = false,
        }),
        else => return err,
    };
    defer cacheFile.close();

    var initCacheCount: u32 = 0;
    var cacheFileReader = cacheFile.reader(&buffer1);
    const cacheFileStat = try cacheFile.stat();
    if (cacheFileStat.size != 0) {
        const cacheContent = try cacheFileReader.interface.readAlloc(gpa, cacheFileStat.size);
        defer gpa.free(cacheContent);

        var cacheJson: json.Parsed([]folderPath_Hash_Pair) = try json.parseFromSlice([]folderPath_Hash_Pair, gpa, cacheContent, .{});
        defer cacheJson.deinit();

        for (cacheJson.value) |value| {
            const tempStr = try arenaAllocator.dupe(u8, value.path);
            const tempHash = try arenaAllocator.dupe(u8, value.hash);
            try cacheMap.put(tempStr, tempHash);
            initCacheCount += 1;
        }
    }

    var outputFile = try std.fs.cwd().createFile(ouput_file, .{ .truncate = true });
    defer outputFile.close();

    var outputFileWriter = outputFile.writer(&buffer2);

    var hasher = std.hash.Wyhash.init(987461);

    var folderIt = dest_dir.iterate();
    while (try folderIt.next()) |entry| {
        switch (entry.kind) {
            .file => {
                const path = try std.fs.path.join(arenaAllocator, &.{ dest_folder_path, entry.name });

                const file = try cwd.openFile(path, .{});
                defer file.close();

                var fileReader = file.reader(&buffer4);
                defer @memset(&buffer4, 0);

                const fileStat = try file.stat();
                const content = try fileReader.interface.readAlloc(gpa, fileStat.size);
                defer gpa.free(content);

                hasher.update(content);
                const hash = hasher.final();
                hasher = std.hash.Wyhash.init(987461);

                const hashHex = std.fmt.hex(hash);

                const tempHashBytes = try arenaAllocator.dupe(u8, &hashHex);

                // const tempHashBytes = try arenaAllocator.alloc(u8, hashBytes.len + 1);
                // @memcpy(tempHashBytes[0..hashBytes.len], &hashBytes);
                // tempHashBytes[hashBytes.len] = 0;

                const hashMapRes = try cacheMap.getOrPut(path);
                if (hashMapRes.found_existing) {
                    if (std.mem.eql(u8, hashMapRes.value_ptr.*, tempHashBytes)) {
                        continue;
                    } else {
                        hashMapRes.value_ptr.* = tempHashBytes;
                        _ = try outputFileWriter.interface.write(entry.name);
                        _ = try outputFileWriter.interface.write("\n");
                    }
                } else {
                    hashMapRes.value_ptr.* = tempHashBytes;
                    _ = try outputFileWriter.interface.write(entry.name);
                    _ = try outputFileWriter.interface.write("\n");
                    initCacheCount += 1;
                }
            },
            else => {},
        }
    }
    try outputFileWriter.interface.flush();

    var cacheMapIt = cacheMap.iterator();
    var jsonValue = try gpa.alloc(folderPath_Hash_Pair, initCacheCount);
    defer gpa.free(jsonValue);

    while (cacheMapIt.next()) |kv| {
        jsonValue[initCacheCount - 1] = folderPath_Hash_Pair{
            .path = kv.key_ptr.*,
            .hash = kv.value_ptr.*,
        };
        initCacheCount -= 1;
    }

    var cacheFileWriter = cacheFile.writer(&buffer3);
    var stringify = std.json.Stringify{ .writer = &cacheFileWriter.interface, .options = .{ .whitespace = .indent_tab } };
    try stringify.write(jsonValue);
    try cacheFileWriter.interface.flush();
}
