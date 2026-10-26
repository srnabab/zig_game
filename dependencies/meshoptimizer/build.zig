const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    // const optimize = b.standardOptimizeOption(.{});

    const zig_triple = target.result.linuxTriple(b.allocator) catch |err| {
        std.log.err("Failed to get Zig triple: {s}", .{@errorName(err)});
        return;
    };

    const mesh_dep = b.dependency("meshoptimizer", .{});

    const cmake = b.findProgramLazy(.{ .names = &.{"cmake"} });

    const cmake_configure_cmd = b.addRunFile(cmake);
    cmake_configure_cmd.addArg("-S");
    cmake_configure_cmd.addDirectoryArg2(mesh_dep.path("./"), .{});

    const cmake_build_path = cmake_configure_cmd.addOutputDirectoryArg2("build", .{ .prefix = "-B" });
    cmake_configure_cmd.addDirectoryArg2(b.path("install"), .{ .prefix = "-DCMAKE_INSTALL_PREFIX=" });
    cmake_configure_cmd.addArgs(&.{
        "-DCMAKE_BUILD_TYPE=Release",
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
    cmake_build_cmd.addDirectoryArg2(cmake_build_path, .{});
    _ = cmake_build_cmd.captureStdOut(.{});
    // cmake_build_cmd.addPrefixedFileContentArg(prefix: []const u8, lp: LazyPath)

    const cmake_install_cmd = b.addRunFile(cmake);
    cmake_install_cmd.addArg("--install");
    cmake_install_cmd.addDirectoryArg2(cmake_build_path, .{});
    cmake_install_cmd.addArg("--prefix");
    cmake_install_cmd.addDirectoryArg2(b.path("install"), .{});
    _ = cmake_install_cmd.captureStdOut(.{});

    const mesh_build_step = b.step("build_mesh", "Build mesh static library using Zig as compiler");

    const install_step = b.getInstallStep();

    // 头文件不再 xcopy 到 ../../include：消费方直接用 mesh_dep.path("src/meshoptimizer.h")
    mesh_build_step.dependOn(install_step);

    install_step.dependOn(&cmake_install_cmd.step);
    cmake_install_cmd.step.dependOn(&cmake_build_cmd.step);
    cmake_build_cmd.step.dependOn(&cmake_configure_cmd.step);
}
