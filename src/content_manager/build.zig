const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{ .default_target = .{} });
    const optimize = b.standardOptimizeOption(.{ .preferred_optimize_mode = .Debug });

    const tracy_enable = b.option(bool, "tracy_enable", "Enable profiling") orelse false;
    const tracy = b.dependency("tracy", .{
        .target = target,
        .optimize = optimize,
        .tracy_enable = tracy_enable,
        .tracy_delayed_init = true,
        .tracy_manual_lifetime = true,
    });
    const contentManagerModule = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    contentManagerModule.addCSourceFile(.{ .file = b.path("src/UUID.c"), .language = .c });
    const spReflectModule = b.createModule(.{
        .root_source_file = b.path("../sprivReflect/reflect.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    spReflectModule.addCSourceFile(.{ .file = b.path("../sprivReflect/spirv_reflect.c"), .language = .c });
    const enum_c_mod = b.createModule(.{
        .root_source_file = b.path("../enumFromC.zig"),
        .target = target,
        .optimize = optimize,
    });
    const sqliteModule = b.createModule(.{
        .root_source_file = b.path("../sqlite3/sqliteDB.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    sqliteModule.addCSourceFile(.{ .file = b.path("../sqlite3/sqlite3.c"), .language = .c });
    const tables_mod = b.createModule(.{
        .root_source_file = b.path("../tables.zig"),
        .target = target,
        .optimize = optimize,
    });

    contentManagerModule.addImport("reflect", spReflectModule);
    contentManagerModule.addImport("sqlDb", sqliteModule);
    contentManagerModule.addImport("tables", tables_mod);
    contentManagerModule.addImport("tracy", tracy.module("tracy"));
    contentManagerModule.addIncludePath(b.path("../../include"));
    contentManagerModule.addIncludePath(b.path("../../../../../../msys64/mingw64/include/"));
    contentManagerModule.addLibraryPath(b.path("../../lib"));
    contentManagerModule.linkSystemLibrary("blake3", .{ .preferred_link_mode = .static });
    contentManagerModule.linkSystemLibrary("sdl3", .{ .preferred_link_mode = .static });
    contentManagerModule.linkSystemLibrary("setupapi", .{ .preferred_link_mode = .static });
    contentManagerModule.linkSystemLibrary("imm32", .{ .preferred_link_mode = .static });
    contentManagerModule.linkSystemLibrary("version", .{ .preferred_link_mode = .static });
    contentManagerModule.linkSystemLibrary("winmm", .{ .preferred_link_mode = .static });
    contentManagerModule.linkSystemLibrary("ole32", .{ .preferred_link_mode = .static });
    contentManagerModule.linkSystemLibrary("gdi32", .{ .preferred_link_mode = .static });
    contentManagerModule.linkSystemLibrary("OleAut32", .{ .preferred_link_mode = .static });
    contentManagerModule.linkSystemLibrary("Rpcrt4", .{ .preferred_link_mode = .static });
    contentManagerModule.linkSystemLibrary("vulkan-1", .{});
    contentManagerModule.linkLibrary(tracy.artifact("tracy"));

    spReflectModule.addImport("EnumC", enum_c_mod);
    spReflectModule.addIncludePath(b.path("../../include"));

    sqliteModule.addImport("tracy", tracy.module("tracy"));
    sqliteModule.addIncludePath(b.path("../../include"));

    tables_mod.addImport("sqlDb", sqliteModule);

    const contenManager = b.addExecutable(.{
        .name = "ContentManager",
        .root_module = contentManagerModule,
    });
    b.installArtifact(contenManager);

    // b.install_path =
}
