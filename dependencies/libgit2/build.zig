const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    // const optimize = b.standardOptimizeOption(.{});

    const zig_triple = target.result.linuxTriple(b.allocator) catch |err| {
        std.log.err("Failed to get Zig triple: {s}", .{@errorName(err)});
        return;
    };

    const git2_dep = b.dependency("libgit2", .{});

    const git2_build_path = "build";
    const git2_build_path_full = b.path(git2_build_path).getPath(b);
    const git2_install_path = "install";
    const git2_install_path_full = b.path(git2_install_path).getPath(b);

    var haveLib = true;
    std.fs.accessAbsolute(b.fmt("{s}/lib/libgit2.a", .{git2_install_path_full}), .{}) catch |err| {
        if (err == error.FileNotFound) {
            haveLib = false;
            std.log.info("libgit2.a not found, will build...", .{});
        } else {
            std.log.err("Failed to access libgit2.a: {s}", .{@errorName(err)});
            return;
        }
    };

    const clear_cmake_build = b.addSystemCommand(&.{
        "powershell", "rm", "-r", "-fo", git2_build_path_full,
    });
    const clear_cmake_build_step = b.step("clear_cmake_build", "Clear cmake build");
    if (!std.mem.eql(u8, git2_dep.builder.pkg_hash, "N-V-__8AAPAkMAHF73yNJSpdsQlf-mNs4jTb0NHpLoiNRzOw")) {
        haveLib = false;
        std.log.info("pkg hash updated, will build...", .{});
        clear_cmake_build_step.dependOn(&clear_cmake_build.step);
    }

    if (haveLib) {
        std.log.info("have libgit2.a, skipped", .{});
        return;
    }

    const cmake_configure_cmd = b.addSystemCommand(&.{
        "cmake",
        "-S",
        git2_dep.path(".\\").getPath(git2_dep.builder),
        b.fmt("-B{s}", .{git2_build_path_full}),
        "-Wno-deprecated",
        b.fmt("-DCMAKE_INSTALL_PREFIX={s}", .{git2_install_path_full}),
        "-DBUILD_SHARED_LIBS=OFF",
        "-DUSE_BUNDLED_ZLIB=ON",
        "-DBUILD_TESTS=OFF",
        "-DBUILD_CLI=OFF",
        "-DBUILD_EXAMPLES=OFF",
        "-DDEPRECATE_HARD=ON",
        "-DCMAKE_BUILD_TYPE=Release",
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
        git2_build_path_full,
        "--target",
        "install",
    });

    const git2_build_step = b.step("build_git2", "Build git2 static library using Zig as compiler");

    const install_step = b.getInstallStep();

    const copy_header = b.addSystemCommand(
        if (target.result.os.tag == .windows) &.{ "cmd", "/c", "xcopy", b.path("install/include").getPath(b), b.path("../../include").getPath(b), "/s", "/y", "/q" } else unreachable,
    );

    git2_build_step.dependOn(install_step);
    install_step.dependOn(&copy_header.step);
    copy_header.step.dependOn(&cmake_build_cmd.step);
    cmake_build_cmd.step.dependOn(&cmake_configure_cmd.step);
    cmake_configure_cmd.step.dependOn(clear_cmake_build_step);
}
