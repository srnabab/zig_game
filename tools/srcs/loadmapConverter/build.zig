const std = @import("std");
const lazyP = @import("std").Build.LazyPath;
const builtin = @import("builtin");

const cpp_compileFlag = [_][]const u8{ "-std=c++17", "-g" };
const c_flags = [_][]const u8{"-std=c11"};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{ .default_target = .{ .abi = .gnu } });
    const optimize = b.standardOptimizeOption(.{ .preferred_optimize_mode = .Debug });

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    const exe = b.addExecutable(.{
        .name = "loadmapConverter",
        .root_module = exe_mod,
    });

    const install = b.addInstallArtifact(exe, .{ .dest_dir = .{
        .override = .{
            .custom = "../../../",
        },
    } });

    b.getInstallStep().dependOn(&install.step);
}
