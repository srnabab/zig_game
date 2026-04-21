const std = @import("std");
const lazyP = @import("std").Build.LazyPath;
const cpp_compileFlag = [_][]const u8{ "-std=c++17", "-g" };
const builtin = @import("builtin");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{ .default_target = .{ .abi = .gnu } });
    const optimize = b.standardOptimizeOption(.{ .preferred_optimize_mode = .Debug });

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    // const blake3_c = b.addTranslateC(.{
    //     .root_source_file = b.path("../../include/blake3.h"),
    //     .target = target,
    //     .optimize = optimize,
    //     .link_libc = true,
    // });
    // const blake3_c_mod = blake3_c.createModule();

    // const blake3_dep = b.dependency("blake3", .{});
    // const blake3_lib = blake3_dep.artifact("blake3");

    const exe = b.addExecutable(.{
        .name = "watcher",
        .root_module = exe_mod,
    });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    run_cmd.addArg("--f");
    run_cmd.addArg("C:\\D\\code\\zig\\game");

    const run_step = b.step("run", "Run the app");

    run_cmd.step.dependOn(b.getInstallStep());
    run_step.dependOn(&run_cmd.step);
}
