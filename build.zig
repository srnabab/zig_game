const std = @import("std");
const lazyP = @import("std").Build.LazyPath;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const enum_c_mod = b.createModule(.{ .root_source_file = b.path("src/enumFromC.zig"), .target = target, .optimize = optimize });
    const video_mod = b.createModule(.{ .root_source_file = b.path("src/video/initVulkan.zig"), .target = target, .optimize = optimize });

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "game",
        .root_module = exe_mod,
    });
    video_mod.addImport("enumFromC", enum_c_mod);
    exe_mod.addImport("video", video_mod);
    exe_mod.addImport("enumFromC", enum_c_mod);

    exe.addIncludePath(b.path("include/"));
    exe.addLibraryPath(b.path("lib/"));
    exe.linkLibC();
    exe.linkSystemLibrary2("sdl3", .{ .preferred_link_mode = .static });

    exe.linkSystemLibrary2("setupapi", .{ .preferred_link_mode = .static });
    exe.linkSystemLibrary2("imm32", .{ .preferred_link_mode = .static });
    exe.linkSystemLibrary2("version", .{ .preferred_link_mode = .static });
    exe.linkSystemLibrary2("winmm", .{ .preferred_link_mode = .static });
    exe.linkSystemLibrary2("ole32", .{ .preferred_link_mode = .static });
    exe.linkSystemLibrary2("gdi32", .{ .preferred_link_mode = .static });
    exe.linkSystemLibrary2("OleAut32", .{ .preferred_link_mode = .static });

    exe.linkSystemLibrary2("vulkan-1", .{});

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
