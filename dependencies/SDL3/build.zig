const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    // const optimize = b.standardOptimizeOption(.{});

    const zig_triple = target.result.linuxTriple(b.allocator) catch |err| {
        std.log.err("Failed to get Zig triple: {s}", .{@errorName(err)});
        return;
    };

    const sdl_dep = b.dependency("sdl3", .{});

    const sdl3_build_path = "build";
    const sdl3_build_path_full = b.path(sdl3_build_path).getPath(b);
    const sdl3_install_path = "install";
    const sdl3_install_path_full = b.path(sdl3_install_path).getPath(b);

    var haveLib = true;
    std.fs.accessAbsolute(b.fmt("{s}/lib/libSDL3.a", .{sdl3_install_path_full}), .{}) catch |err| {
        if (err == error.FileNotFound) {
            haveLib = false;
            std.log.info("libSDL3.a not found, will build...", .{});
        } else {
            std.log.err("Failed to access libSDL3.a: {s}", .{@errorName(err)});
            return;
        }
    };

    const clear_cmake_build = b.addSystemCommand(&.{
        "powershell", "rm", "-r", "-fo", sdl3_build_path_full,
    });
    const clear_cmake_build_step = b.step("clear_cmake_build", "Clear cmake build");
    if (!std.mem.eql(u8, sdl_dep.builder.pkg_hash, "N-V-__8AAIBfjAMynWwoadl2SIwSsfVfJKbqzrpN21cmhmpR")) {
        haveLib = false;
        std.log.info("pkg hash updated, will build...", .{});
        clear_cmake_build_step.dependOn(&clear_cmake_build.step);
    }

    if (haveLib) {
        std.log.info("have libSDL3.a, skipped", .{});
        return;
    }

    const cmake_configure_cmd = b.addSystemCommand(&.{
        "cmake",
        "-S",
        sdl_dep.path(".\\").getPath(sdl_dep.builder),
        b.fmt("-B{s}", .{sdl3_build_path_full}),
        b.fmt("-DCMAKE_INSTALL_PREFIX={s}", .{sdl3_install_path_full}),
        "-DCMAKE_BUILD_TYPE=Release",
        "-DSDL_SHARED=OFF",
        "-DSDL_STATIC=ON",
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
        sdl3_build_path_full,
        "--target",
        "install",
    });

    const sdl3_build_step = b.step("build_sdl3", "Build SDL3 static library using Zig as compiler");

    const install_step = b.getInstallStep();

    sdl3_build_step.dependOn(install_step);

    install_step.dependOn(&cmake_build_cmd.step);
    cmake_build_cmd.step.dependOn(&cmake_configure_cmd.step);
    cmake_configure_cmd.step.dependOn(clear_cmake_build_step);
}
