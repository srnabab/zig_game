const std = @import("std");
const lazyP = @import("std").Build.LazyPath;
const builtin = @import("builtin");

const cpp_compileFlag = [_][]const u8{ "-std=c++17", "-g" };
const c_flags = [_][]const u8{"-std=c11"};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{ .default_target = .{ .abi = .gnu } });
    const optimize = b.standardOptimizeOption(.{ .preferred_optimize_mode = .Debug });

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

    const root_path = b.pathFromRoot("..\\..\\..\\");
    const contentDbPath = b.pathResolve(&[_][]const u8{ root_path, "zig-out\\bin\\Content.db" });
    const contentPath = b.pathResolve(&[_][]const u8{ root_path, "zig-out\\bin\\Content" });
    const cookerPath = b.pathResolve(&[_][]const u8{ root_path, "tools\\cooker.exe" });
    const cookerRootPath = b.pathResolve(&[_][]const u8{ root_path, "tools\\srcs\\cooker\\" });
    const run_cmd = b.addRunArtifact(exe);
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    run_cmd.addArgs(&[_][]const u8{
        "--f",
        root_path,
        "--d",
        contentDbPath,
        contentPath,
        "--c",
        cookerPath,
        cookerRootPath,
        "-force",
    });

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

    b.getInstallStep().dependOn(&install.step);

    b.getInstallStep().dependOn(&preKillGameProcessCmd.step);

    b.getInstallStep().dependOn(&install_cooker.step);
    b.getInstallStep().dependOn(&install_loadmapConverter.step);

    run_cmd.step.dependOn(b.getInstallStep());
    run_step.dependOn(&run_cmd.step);
}
