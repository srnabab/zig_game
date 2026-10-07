const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{ .default_target = .{ .abi = .msvc } });
    const optimize = b.standardOptimizeOption(.{ .preferred_optimize_mode = .ReleaseFast });

    // Microsoft Detours static library (built by ../../../dependencies/Detours).
    const detours_dep = b.dependency("Detours", .{});
    const detours_lib = detours_dep.artifact("detours");

    // autoDir.exe - launcher that injects the hook DLL into the child process.
    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/autodir_main.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe_mod.linkLibrary(detours_lib);
    // exe_mod.linkSystemLibrary("stdc++", .{ .preferred_link_mode = .static });

    const exe = b.addExecutable(.{
        .name = "autoDir",
        .root_module = exe_mod,
    });

    // autoDirHook.dll - injected hook (CreateFileW / CreateProcessW).
    const dll_mod = b.createModule(.{
        .root_source_file = b.path("src/dlmain.zig"),
        .target = target,
        .optimize = optimize,
    });
    dll_mod.linkLibrary(detours_lib);
    // SHCreateDirectoryExW lives in shell32.
    dll_mod.linkSystemLibrary("shell32", .{ .preferred_link_mode = .static });
    // dll_mod.linkSystemLibrary("stdc++", .{ .preferred_link_mode = .static });

    const dll = b.addLibrary(.{
        .name = "autoDirHook",
        .root_module = dll_mod,
        .linkage = .dynamic,
    });

    // Install both next to the other tools in game/tools/ so that autoDir.exe
    // finds autoDirHook.dll in its own directory.
    const install_exe = b.addInstallArtifact(exe, .{ .dest_dir = .{
        .override = .{
            .custom = "../../../",
        },
    } });
    const install_dll = b.addInstallArtifact(dll, .{ .dest_dir = .{
        .override = .{
            .custom = "../../../",
        },
    } });

    b.getInstallStep().dependOn(&install_exe.step);
    b.getInstallStep().dependOn(&install_dll.step);
}
