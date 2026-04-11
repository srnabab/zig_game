const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    // const optimize = b.standardOptimizeOption(.{});

    const zig_triple = target.result.linuxTriple(b.allocator) catch |err| {
        std.log.err("Failed to get Zig triple: {s}", .{@errorName(err)});
        return;
    };

    const mesh_dep = b.dependency("meshoptimizer", .{});

    const mesh_build_path = "build";
    const mesh_build_path_full = b.path(mesh_build_path).getPath(b);
    const mesh_install_path = "install";
    const mesh_install_path_full = b.path(mesh_install_path).getPath(b);

    var haveLib = true;
    std.fs.accessAbsolute(b.fmt("{s}/lib/libmeshoptimizer.a", .{mesh_install_path_full}), .{}) catch |err| {
        if (err == error.FileNotFound) {
            haveLib = false;
            std.log.info("libmesh.a not found, will build...", .{});
        } else {
            std.log.err("Failed to access libmesh.a: {s}", .{@errorName(err)});
            return;
        }
    };

    const mkdir_cmake_build = b.addSystemCommand(&.{
        "cmd", "/c", "mkdir", mesh_build_path_full, "2>nul", "||", "exit", "/b", "0",
    });
    const mkdir_cmake_build2 = b.addSystemCommand(&.{
        "cmd", "/c", "mkdir", mesh_install_path_full, "2>nul", "||", "exit", "/b", "0",
    });

    const clear_cmake_build = b.addSystemCommand(&.{
        "powershell", "rm", "-r", "-fo", mesh_build_path_full,
    });
    const clear_cmake_build_step = b.step("clear_cmake_build", "Clear cmake build");
    if (!std.mem.eql(u8, mesh_dep.builder.pkg_hash, "N-V-__8AAKnSIQCkk0aPuh72cQgc0y29X8ViYL7t_gjPuz_D") or !haveLib) {
        haveLib = false;
        std.log.info("pkg hash updated, will build...", .{});
        clear_cmake_build_step.dependOn(&clear_cmake_build.step);
    }

    if (haveLib) {
        std.log.info("have libmeshoptimizer.a, skipped", .{});
        return;
    }

    const cmake_configure_cmd = b.addSystemCommand(&.{
        "cmake",
        "-S",
        mesh_dep.path(".\\").getPath(mesh_dep.builder),
        b.fmt("-B{s}", .{mesh_build_path_full}),
        b.fmt("-DCMAKE_INSTALL_PREFIX={s}", .{mesh_install_path_full}),
        "-DCMAKE_BUILD_TYPE=Release",
        // "-DMESHOPT_INSTALL=OFF",
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
        mesh_build_path_full,
    });

    const cmake_install_cmd = b.addSystemCommand(&.{
        "cmake",
        "--install",
        mesh_build_path_full,
        "--prefix",
        mesh_install_path_full,
    });

    const mesh_build_step = b.step("build_mesh", "Build mesh static library using Zig as compiler");

    const install_step = b.getInstallStep();

    const copy_header = b.addSystemCommand(
        if (target.result.os.tag == .windows) &.{ "cmd", "/c", "xcopy", b.path("install/include").getPath(b), b.path("../../include").getPath(b), "/s", "/y", "/q" } else unreachable,
    );

    mesh_build_step.dependOn(install_step);

    install_step.dependOn(&copy_header.step);
    copy_header.step.dependOn(&cmake_install_cmd.step);

    cmake_install_cmd.step.dependOn(&cmake_build_cmd.step);
    cmake_build_cmd.step.dependOn(&cmake_configure_cmd.step);
    cmake_configure_cmd.step.dependOn(clear_cmake_build_step);
    clear_cmake_build_step.dependOn(&mkdir_cmake_build.step);
    clear_cmake_build_step.dependOn(&mkdir_cmake_build2.step);
}
