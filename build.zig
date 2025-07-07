const std = @import("std");

const targets: []const std.Target.Query = &.{
    .{ .cpu_arch = .aarch64, .os_tag = .macos },
    .{ .cpu_arch = .aarch64, .os_tag = .linux },
    .{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .gnu },
    .{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .musl },
    .{ .cpu_arch = .x86_64, .os_tag = .windows },
};

const package = struct {
    dep: *std.Build.Dependency,
    lib: *std.Build.Step.Compile,
    test_lib: *std.Build.Step.Compile,
};

fn sdl_library(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) package {
    const sdl_dep = b.dependency("sdl", .{
        .target = target,
        .optimize = optimize,
        //.preferred_linkage = .static,
        //.strip = null,
        //.sanitize_c = null,
        //.pic = null,
        //.lto = null,
        //.emscripten_pthreads = false,
        //.install_build_config_h = false,
    });
    const sdl_lib = sdl_dep.artifact("SDL3");
    const sdl_test_lib = sdl_dep.artifact("SDL3_test");

    return package{ .dep = sdl_dep, .lib = sdl_lib, .test_lib = sdl_test_lib };
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const sdl = sdl_library(b, target, .ReleaseFast);

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src\\main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "game",
        .root_module = exe_mod,
    });

    exe.linkLibrary(sdl.lib);
    exe.addIncludePath(sdl.dep.path("include"));

    // 在 Windows 上链接必要的系统库
    if (target.query.os_tag == .windows) {
        exe.linkSystemLibrary("gdi32");
        exe.linkSystemLibrary("shell32");
        exe.linkSystemLibrary("ole32");
        exe.linkSystemLibrary("imm32");
        exe.linkSystemLibrary("version");
    }

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_unit_tests = b.addTest(.{
        .root_module = exe_mod,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}
