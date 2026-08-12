const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{ .default_target = .{ .abi = .gnu } });
    // const optimize = b.standardOptimizeOption(.{});

    const zig_triple = target.result.linuxTriple(b.allocator) catch |err| {
        std.log.err("Failed to get Zig triple: {s}", .{@errorName(err)});
        return;
    };

    const shaderc_dep = b.dependency("shaderc", .{});

    const shaderc_build_path = "build";
    const shaderc_build_path_full = b.path(shaderc_build_path).getPath(b);
    const shaderc_install_path = "install";
    const shaderc_install_path_full = b.path(shaderc_install_path).getPath(b);

    var haveLib = true;
    std.Io.Dir.accessAbsolute(
        b.graph.io,
        b.fmt("{s}/lib/libshaderc_combined.a", .{shaderc_install_path_full}),
        .{},
    ) catch |err| {
        if (err == error.FileNotFound) {
            haveLib = false;
            std.log.info("libshaderc_combined.a not found, will build...", .{});
        } else {
            std.log.err("Failed to access libshaderc_combined.a: {s}", .{@errorName(err)});
            return;
        }
    };

    const mkdir_cmake_build = b.addSystemCommand(&.{
        "cmd", "/c", "mkdir", shaderc_build_path_full, "2>nul", "||", "exit", "/b", "0",
    });
    const mkdir_cmake_build2 = b.addSystemCommand(&.{
        "cmd", "/c", "mkdir", shaderc_install_path_full, "2>nul", "||", "exit", "/b", "0",
    });

    const clear_cmake_build = b.addSystemCommand(&.{
        "powershell", "rm", "-r", "-fo", shaderc_build_path_full,
    });
    const clear_cmake_build_step = b.step("clear_cmake_build", "Clear cmake build");
    if (!std.mem.eql(u8, shaderc_dep.builder.pkg_hash, "N-V-__8AAAh4EgD_1vyfeRQed3y6urhGewfbgX0yP6g04hGv") or !haveLib) {
        haveLib = false;
        std.log.info("pkg hash updated, will build...", .{});
        clear_cmake_build_step.dependOn(&clear_cmake_build.step);
    }

    if (haveLib) {
        std.log.info("have libshaderc_combined.a, skipped", .{});
        return;
    }

    const git_sync_deps = b.addSystemCommand(&.{
        "python",
        shaderc_dep.path("./utils/git-sync-deps").getPath(shaderc_dep.builder),
    });

    const cmake_configure_cmd = b.addSystemCommand(&.{
        "cmake",
        "-S",
        shaderc_dep.path(".\\").getPath(shaderc_dep.builder),
        b.fmt("-B{s}", .{shaderc_build_path_full}),
        b.fmt("-DCMAKE_INSTALL_PREFIX={s}", .{shaderc_install_path_full}),
        "-DCMAKE_BUILD_TYPE=Release",
        "-DSHADERC_SKIP_TESTS=ON",
        "-DSHADERC_SKIP_EXAMPLES=ON",
        "-DCMAKE_CXX_FLAGS=\"-D_CRT_SECURE_NO_WARNINGS\"",
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
        shaderc_build_path_full,
        "--parallel",
    });

    const cmake_install_cmd = b.addSystemCommand(&.{
        "cmake",
        "--install",
        shaderc_build_path_full,
        "--prefix",
        shaderc_install_path_full,
    });

    const shaderc_build_step = b.step("build_shaderc", "Build shaderc static library using Zig as compiler");

    const install_step = b.getInstallStep();

    const copy_header = b.addSystemCommand(
        if (target.result.os.tag == .windows) &.{ "cmd", "/c", "xcopy", b.path("install/include").getPath(b), b.path("../../include").getPath(b), "/s", "/y", "/q" } else unreachable,
    );

    shaderc_build_step.dependOn(install_step);

    install_step.dependOn(&copy_header.step);
    copy_header.step.dependOn(&cmake_install_cmd.step);

    cmake_install_cmd.step.dependOn(&cmake_build_cmd.step);
    cmake_build_cmd.step.dependOn(&cmake_configure_cmd.step);
    cmake_configure_cmd.step.dependOn(&git_sync_deps.step);
    git_sync_deps.step.dependOn(clear_cmake_build_step);
    clear_cmake_build_step.dependOn(&mkdir_cmake_build.step);
    clear_cmake_build_step.dependOn(&mkdir_cmake_build2.step);
}
