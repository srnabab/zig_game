const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    // const optimize = b.standardOptimizeOption(.{});

    const zig_triple = target.result.linuxTriple(b.allocator) catch |err| {
        std.log.err("Failed to get Zig triple: {s}", .{@errorName(err)});
        return;
    };

    const cglm_dep = b.dependency("cglm", .{});

    const cmake = b.findProgramLazy(.{ .names = &.{"cmake"} });

    // var haveLib = true;
    // std.Io.Dir.accessAbsolute(b.graph.io, b.fmt("{s}/lib/libcglm.a", .{cglm_install_path_full}), .{}) catch |err| {
    //     if (err == error.FileNotFound) {
    //         haveLib = false;
    //         std.log.info("libcglm.a not found, will build...", .{});
    //     } else {
    //         std.log.err("Failed to access libcglm.a: {s}", .{@errorName(err)});
    //         return;
    //     }
    // };

    // const mkdir_cmake_build = b.addSystemCommand(&.{
    //     "cmd", "/c", "mkdir", cglm_build_path_full, "2>nul", "||", "exit", "/b", "0",
    // });
    // const mkdir_cmake_build2 = b.addSystemCommand(&.{
    //     "cmd", "/c", "mkdir", cglm_install_path_full, "2>nul", "||", "exit", "/b", "0",
    // });

    // const clear_cmake_build = b.addSystemCommand(&.{
    //     "powershell", "rm", "-r", "-fo", cglm_build_path_full,
    // });
    // const clear_cmake_build_step = b.step("clear_cmake_build", "Clear cmake build");
    // if (!std.mem.eql(u8, cglm_dep.builder.pkg_hash, "N-V-__8AAGApJACv6OGRSLZEdwbH9P68sV3B96LAZsZ21_4C") or !haveLib) {
    //     haveLib = false;
    //     std.log.info("pkg hash updated, will build...", .{});
    //     clear_cmake_build_step.dependOn(&clear_cmake_build.step);
    // }

    // if (haveLib) {
    //     std.log.info("have libcglm.a, skipped\n", .{});
    //     return;
    // }

    const cmake_configure_cmd = b.addRunFile(cmake);
    cmake_configure_cmd.addArg("-S");
    cmake_configure_cmd.addDirectoryArg2(cglm_dep.path("./"), .{});
    const cmake_build_path = cmake_configure_cmd.addOutputDirectoryArg2("build", .{ .prefix = "-B" });
    const cmake_install_path = cmake_configure_cmd.addOutputDirectoryArg2("install", .{ .prefix = "-DCMAKE_INSTALL_PREFIX=" });
    cmake_configure_cmd.addArgs(&.{
        "-DCMAKE_BUILD_TYPE=Release",
        "-DCGLM_STATIC=ON",
        "-G",
        "Ninja",
    });

    cmake_configure_cmd.setEnvironmentVariable(
        "CC",
        b.fmt("zig cc --target={s}", .{zig_triple}),
    );
    cmake_configure_cmd.setEnvironmentVariable(
        "CXX",
        b.fmt("zig c++ --target={s}", .{zig_triple}),
    );

    const cmake_build_cmd = b.addRunFile(cmake);
    cmake_build_cmd.addArg("--build");
    cmake_build_cmd.addDirectoryArg2(cmake_build_path, .{ .prefix = "" });
    _ = cmake_build_cmd.captureStdOut(.{});

    const cmake_install_cmd = b.addRunFile(cmake);
    cmake_install_cmd.addArg("--install");
    cmake_install_cmd.addDirectoryArg2(cmake_build_path, .{});
    cmake_install_cmd.addArg("--prefix");
    cmake_install_cmd.addDirectoryArg2(cmake_install_path, .{});
    _ = cmake_install_cmd.captureStdOut(.{});

    const cglm_build_step = b.step("build_cglm", "Build cglm static library using Zig as compiler");

    const install_step = b.getInstallStep();

    cglm_build_step.dependOn(install_step);

    cmake_install_cmd.step.dependOn(&cmake_build_cmd.step);
    cmake_build_cmd.step.dependOn(&cmake_configure_cmd.step);
    install_step.dependOn(&cmake_install_cmd.step);
}
