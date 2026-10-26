const std = @import("std");
const lazyP = @import("std").Build.LazyPath;
const builtin = @import("builtin");

const cpp_compileFlag = [_][]const u8{ "-std=c++17", "-g" };
const c_flags = [_][]const u8{"-std=c11"};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{ .default_target = .{ .abi = .gnu } });
    const optimize = b.standardOptimizeOption(.{ .preferred_optimize_mode = .debug });

    const autoDir_dep = b.dependency("autoDirHook", .{});
    const autoDir = autoDir_dep.artifact("autoDir");

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "watcher",
        .root_module = exe_mod,
    });

    const preKillGameProcessCmd = b.addSystemCommand(if (builtin.target.os.tag == .windows) &.{
        "cmd",
        "/c",
        "taskkill",
        "/F",
        "/IM",
        "watcher.exe",
        "2>nul",
        "||",
        "exit",
        "/b",
        "0",
        "cmd",
        "/c",
        "taskkill",
        "/F",
        "/IM",
        "cooker.exe",
        "2>nul",
        "||",
        "exit",
        "/b",
        "0",
    } else unreachable);

    const root_path = b.path("../../..");
    const contentDbPath = b.path("../../../zig-out/bin/Content.db");
    const contentPath = b.path("../../../zig-out/bin/Content");
    const cookerPath = b.path("../../../tools/cooker.exe");
    const cookerRootPath = b.path("../../../tools/srcs/cooker");
    const run_cmd = b.addRunArtifact(autoDir);
    run_cmd.addArtifactArg2(exe, .{ .make_absolute = true });
    run_cmd.addArg("--f");
    run_cmd.addDirectoryArg2(root_path, .{ .make_absolute = true });
    run_cmd.addArg("--d");
    run_cmd.addDirectoryArg2(contentDbPath, .{ .make_absolute = true });
    run_cmd.addDirectoryArg2(contentPath, .{ .make_absolute = true });
    run_cmd.addArg("--c");
    run_cmd.addDirectoryArg2(cookerPath, .{ .make_absolute = true });
    run_cmd.addDirectoryArg2(cookerRootPath, .{ .make_absolute = true });
    run_cmd.addArg("-force");

    const run_step = b.step("run", "Run the app");

    const install = b.addInstallArtifact(exe, .{ .dest_dir = .{
        .override = .{
            .custom = "../../../",
        },
    } });

    // cooker / loadmapConverter are sibling packages (`../cooker`, `../loadmapConverter`).
    // Build their executables and install them next to `watcher.exe` in `tools/`
    // so that `run_cmd` always sees an up-to-date cooker.exe.
    const cooker_dep = b.dependency("cooker", .{});
    const loadmapConverter_dep = b.dependency("loadmapConverter", .{});
    const install_cooker = b.addInstallArtifact(cooker_dep.artifact("cooker"), .{ .dest_dir = .{
        .override = .{
            .custom = "../../../",
        },
    } });
    const install_loadmapConverter = b.addInstallArtifact(loadmapConverter_dep.artifact("loadmapConverter"), .{ .dest_dir = .{
        .override = .{
            .custom = "../../../",
        },
    } });
    const install_autoDir = b.addInstallArtifact(autoDir_dep.artifact("autoDir"), .{ .dest_dir = .{
        .override = .{
            .custom = "../../../",
        },
    } });
    const install_autoDirHook = b.addInstallArtifact(autoDir_dep.artifact("autoDirHook"), .{ .dest_dir = .{
        .override = .{
            .custom = "../../../",
        },
    } });

    b.getInstallStep().dependOn(&install.step);

    b.getInstallStep().dependOn(&preKillGameProcessCmd.step);

    b.getInstallStep().dependOn(&install_cooker.step);
    b.getInstallStep().dependOn(&install_loadmapConverter.step);
    b.getInstallStep().dependOn(&install_autoDir.step);
    b.getInstallStep().dependOn(&install_autoDirHook.step);

    run_cmd.step.dependOn(b.getInstallStep());
    run_step.dependOn(&run_cmd.step);
}
