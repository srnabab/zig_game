const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    // const optimize = b.standardOptimizeOption(.{});

    const zig_triple = target.result.linuxTriple(b.allocator) catch |err| {
        std.log.err("Failed to get Zig triple: {s}", .{@errorName(err)});
        return;
    };

    const cglm_dep = b.dependency("cglm", .{});

    const cglm_build_path = "build";
    const cglm_build_path_full = b.path(cglm_build_path).getPath(b);
    const cglm_install_path = "install";
    const cglm_install_path_full = b.path(cglm_install_path).getPath(b);

    var haveLib = true;
    std.fs.accessAbsolute(b.fmt("{s}/lib/libcglm.a", .{cglm_install_path_full}), .{}) catch |err| {
        if (err == error.FileNotFound) {
            haveLib = false;
            std.log.info("libcglm.a not found, will build...", .{});
        } else {
            std.log.err("Failed to access libcglm.a: {s}", .{@errorName(err)});
            return;
        }
    };

    const mkdir_cmake_build = b.addSystemCommand(&.{
        "cmd", "/c", "mkdir", cglm_build_path_full, "2>nul", "||", "exit", "/b", "0",
    });
    const mkdir_cmake_build2 = b.addSystemCommand(&.{
        "cmd", "/c", "mkdir", cglm_install_path_full, "2>nul", "||", "exit", "/b", "0",
    });

    const clear_cmake_build = b.addSystemCommand(&.{
        "powershell", "rm", "-r", "-fo", cglm_build_path_full,
    });
    const clear_cmake_build_step = b.step("clear_cmake_build", "Clear cmake build");
    if (!std.mem.eql(u8, cglm_dep.builder.pkg_hash, "N-V-__8AAGApJACv6OGRSLZEdwbH9P68sV3B96LAZsZ21_4C") or !haveLib) {
        haveLib = false;
        std.log.info("pkg hash updated, will build...", .{});
        clear_cmake_build_step.dependOn(&clear_cmake_build.step);
    }

    if (haveLib) {
        std.log.info("have libcglmoptimizer.a, skipped", .{});
        return;
    }

    const cmake_configure_cmd = b.addSystemCommand(&.{
        "cmake",
        "-S",
        cglm_dep.path(".\\").getPath(cglm_dep.builder),
        b.fmt("-B{s}", .{cglm_build_path_full}),
        b.fmt("-DCMAKE_INSTALL_PREFIX={s}", .{cglm_install_path_full}),
        "-DCMAKE_BUILD_TYPE=Release",
        "-DCGLM_STATIC=ON",
        "-G",
        "MinGW Makefiles",
    });
    cmake_configure_cmd.setEnvironmentVariable(
        "CC",
        b.fmt("zig cc --target={s}", .{zig_triple}),
    );
    cmake_configure_cmd.setEnvironmentVariable(
        "CXX",
        b.fmt("zig c++ --target={s}", .{zig_triple}),
    );

    const cmake_build_cmd = b.addSystemCommand(&.{
        "cmake",
        "--build",
        cglm_build_path_full,
    });

    const cmake_install_cmd = b.addSystemCommand(&.{
        "cmake",
        "--install",
        cglm_build_path_full,
        "--prefix",
        cglm_install_path_full,
    });

    const cglm_build_step = b.step("build_cglm", "Build cglm static library using Zig as compiler");

    const install_step = b.getInstallStep();

    const copy_header = b.addSystemCommand(
        if (target.result.os.tag == .windows) &.{ "cmd", "/c", "xcopy", b.path("install/include").getPath(b), b.path("../../include").getPath(b), "/s", "/y", "/q" } else unreachable,
    );

    cglm_build_step.dependOn(install_step);

    install_step.dependOn(&copy_header.step);
    copy_header.step.dependOn(&cmake_install_cmd.step);

    cmake_install_cmd.step.dependOn(&cmake_build_cmd.step);
    cmake_build_cmd.step.dependOn(&cmake_configure_cmd.step);
    cmake_configure_cmd.step.dependOn(clear_cmake_build_step);
    clear_cmake_build_step.dependOn(&mkdir_cmake_build.step);
    clear_cmake_build_step.dependOn(&mkdir_cmake_build2.step);
}
