const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const libgit2_dep = b.dependency("libgit2", .{});
    const libgit2_step = libgit2_dep.builder.getInstallStep();

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    exe_mod.addIncludePath(b.path("../../include"));
    exe_mod.addLibraryPath(libgit2_dep.path("install/lib"));
    exe_mod.linkSystemLibrary("libgit2", .{});

    const exe = b.addExecutable(.{
        .name = "selectModifiedFileToTxt",
        .root_module = exe_mod,
    });

    const install = b.addInstallArtifact(exe, .{});

    install.step.dependOn(libgit2_step);
}
