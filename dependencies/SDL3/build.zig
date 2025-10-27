const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    // const optimize = b.standardOptimizeOption(.{});

    //  .zigTriple(b.allocator)
    const zig_triple = target.result.linuxTriple(b.allocator) catch |err| {
        std.log.err("Failed to get Zig triple: {s}", .{@errorName(err)});
        return;
    };

    const sdl_dep = b.dependency("sdl3", .{});

    const sdl3_build_path = "build";
    const sdl3_build_path_full = b.path(sdl3_build_path).getPath(b);
    const sdl3_install_path = "install";
    const sdl3_install_path_full = b.path(sdl3_install_path).getPath(b);

    // std.log.debug("build root {s}", .{b.build_root.path.?});
    // std.log.debug("{s}", .{sdl_dep.path("").getPath(sdl_dep.builder)});
    // std.log.debug("{s}", .{sdl3_install_path});

    // const env_set_cmd1 = b.addSystemCommand(&.{
    //     "cmd",
    //     "/c",
    //     b.fmt("set CC=\"zig cc --target={s}\"", .{zig_triple}),
    // });
    // const env_set_cmd2 = b.addSystemCommand(&.{
    //     "cmd",
    //     "/c",
    //     b.fmt("set CXX='zig c++ --target={s}'", .{zig_triple}),
    // });

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
    // for (cmake_configure_cmd.argv.items) |value| {
    //     std.log.info("{s}", .{value.bytes});
    // }
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
}
