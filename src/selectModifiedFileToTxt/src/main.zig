const std = @import("std");
const process = std.process;
const json = std.json;

const builtin = @import("builtin");

const git2 = @cImport(@cInclude("git2.h"));

const folderPath_GitHash_Pair = struct {
    path: []u8,
    hash: [40]u8,
};

const default_output_file = "a.txt";
const cachePath = "cache.json";

var cacheMap: std.StringHashMap([40]u8) = undefined;

var debug_allocator: std.heap.DebugAllocator(.{ .stack_trace_frames = 10 }) = .init;
pub fn main() !void {
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
        std.log.info(".exe [repo dir] [dest folder] (output file path)", .{});
    }

    const repo_dir = args[1];
    const dest_folder = args[2];

    var ouput_file: [:0]u8 = undefined;
    if (args.len > 3) {
        ouput_file = args[3];
    } else {
        ouput_file = default_output_file.*;
    }

    for (args) |arg| {
        std.log.info("arg: {s}", .{arg});
    }

    var cwd = try std.fs.cwd().openDir(repo_dir, .{});
    defer cwd.close();

    try cwd.setAsCwd();

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

    var cacheFileReader = cacheFile.reader();
    const cacheFileStat = try cacheFile.stat();
    // if (cacheFileStat.size == 0) {} else
    {
        const cacheContent = try cacheFileReader.interface.readAlloc(gpa, cacheFileStat.size);
        defer gpa.free(cacheContent);

        var cacheJson: json.Parsed([]folderPath_GitHash_Pair) = json.parseFromSlice([]folderPath_GitHash_Pair, gpa, cacheContent, .{});
        defer cacheJson.deinit();

        for (cacheJson.value) |value| {
            const tempStr = try arenaAllocator.dupe(u8, value.path);
            try cacheMap.put(tempStr, value.hash);
        }
    }

    const initTimes = git2.git_libgit2_init();
    defer for (0..@intCast(initTimes)) |_| {
        _ = git2.git_libgit2_shutdown();
    };

    const dest_folder_path = try std.fmt.allocPrint(gpa, "HEAD:{s}", .{dest_folder});
    var repo: ?*git2.git_repository = null;
    var obj: ?*git2.git_object = null;

    check_lg2(git2.git_repository_open_ext(@ptrCast(&repo), args[1], 0, null), "unable open repository", args[1]);
    defer git2.git_repository_free(repo);

    check_lg2(
        git2.git_revparse_single(@ptrCast(&obj), repo, @ptrCast(dest_folder_path.ptr)),
        "Error resolving path",
        @ptrCast(dest_folder_path.ptr),
    );
    defer git2.git_object_free(obj);

    if (git2.git_object_type(obj) != git2.GIT_OBJECT_BLOB) {
        std.log.err("object is not a blob", .{});
        return;
    }
    const tree: *git2.git_tree = @ptrCast(obj);
}

fn check_lg2(git2_error: c_int, message: [*c]const u8, extra: [*c]const u8) void {
    var lg2err: [*c]git2.git_error = null;
    var lg2msg: [*c]const u8 = "";
    var lg2spacer: [*c]const u8 = "";

    if (git2_error == 0)
        return;

    lg2err = git2.git_error_last();
    if (lg2err != null and lg2err.message != null) {
        lg2msg = lg2err.message;
        lg2spacer = " - ";
    }

    if (extra != null) {
        std.log.err("{s} '{s}' [{d}]{s}{s}", .{
            message,
            extra,
            git2_error,
            lg2spacer,
            lg2msg,
        });
    } else {
        std.log.err("{s} [{d}]{s}{s}", .{
            message,
            git2_error,
            lg2spacer,
            lg2msg,
        });
    }

    process.exit(git2.EXIT_FAILURE);
}
