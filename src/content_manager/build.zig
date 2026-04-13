const std = @import("std");
const builtin = @import("builtin");
const c_flags = [_][]const u8{"-std=c11"};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{ .default_target = .{ .abi = .gnu } });
    const optimize = b.standardOptimizeOption(.{ .preferred_optimize_mode = .Debug });

    const force_update = b.option(bool, "force_update", "force contentManager update all resources") orelse false;

    const options = b.addOptions();
    options.addOption(bool, "force_update", force_update);

    const cglm_dep = b.dependency("cglm", .{});
    const cglm_install_step = cglm_dep.builder.getInstallStep();

    const meshopt_dep = b.dependency("meshoptimizer", .{});
    const meshopt_install_step = meshopt_dep.builder.getInstallStep();

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
    sqliteModule.addCSourceFile(.{
        .file = b.path("../sqlite3/sqlite3.c"),
        .language = .c,
        .flags = &c_flags,
    });
    const tables_mod = b.createModule(.{
        .root_source_file = b.path("../tables.zig"),
        .target = target,
        .optimize = optimize,
    });
    const cgltf_mod = b.createModule(.{
        .root_source_file = b.path("../cgltf/cgltf.zig"),
        .target = target,
        .optimize = optimize,
    });
    cgltf_mod.addCSourceFile(.{
        .file = b.path("../../include/cgltf/cgltf_namespace.h"),
        .language = .c,
    });
    const vertexStruct_mod = b.createModule(.{
        .root_source_file = b.path("../vertexStruct.zig"),
        .target = target,
        .optimize = optimize,
    });
    const UUID_mod = b.createModule(.{
        .root_source_file = b.path("../UUID/UUID.zig"),
        .target = target,
        .optimize = optimize,
    });
    UUID_mod.addCSourceFile(.{
        .file = b.path("../UUID/UUID.c"),
        .language = .c,
        .flags = &c_flags,
    });
    const cglm_mod = b.createModule(.{
        .root_source_file = b.path("../cglm/cglm.zig"),
        .target = target,
        .optimize = optimize,
    });
    const meshopt_mod = b.createModule(.{
        .root_source_file = b.path("../meshoptimizer/meshopt.zig"),
        .target = target,
        .optimize = optimize,
    });

    const blake3_dep = b.dependency("blake3", .{});
    const blake3_lib = blake3_dep.artifact("blake3");

    meshopt_mod.addIncludePath(b.path("../../include/"));

    cglm_mod.addIncludePath(b.path("../../include"));
    // cglm_mod.addCSourceFile(.{ .file = b.path("../cglm/cglm.c"), .language = .c });

    cgltf_mod.addImport("vertexStruct", vertexStruct_mod);
    cgltf_mod.addImport("enumFromC", enum_c_mod);
    cgltf_mod.addImport("UUID", UUID_mod);
    cgltf_mod.addIncludePath(b.path("../../include"));

    vertexStruct_mod.addImport("cglm", cglm_mod);

    UUID_mod.addIncludePath(b.path("../../include"));

    contentManagerModule.addImport("options", options.createModule());
    contentManagerModule.addImport("cgltf", cgltf_mod);
    contentManagerModule.addImport("vertexStruct", vertexStruct_mod);
    contentManagerModule.addImport("reflect", spReflectModule);
    contentManagerModule.addImport("sqlDb", sqliteModule);
    contentManagerModule.addImport("tables", tables_mod);
    contentManagerModule.addImport("tracy", tracy.module("tracy"));
    contentManagerModule.addImport("UUID", UUID_mod);
    contentManagerModule.addImport("meshopt", meshopt_mod);
    contentManagerModule.addIncludePath(b.path("../../include"));
    contentManagerModule.addIncludePath(b.path("../../../../../../msys64/mingw64/include/"));
    contentManagerModule.addLibraryPath(b.path("../../lib"));
    contentManagerModule.addLibraryPath(cglm_dep.path("install/lib"));
    contentManagerModule.addLibraryPath(meshopt_dep.path("install/lib"));
    contentManagerModule.linkLibrary(blake3_lib);
    // contentManagerModule.linkSystemLibrary("blake3", .{ .preferred_link_mode = .static });
    contentManagerModule.linkSystemLibrary("meshoptimizer", .{ .preferred_link_mode = .static });
    contentManagerModule.linkSystemLibrary("cglm", .{ .preferred_link_mode = .static });
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

    contenManager.step.dependOn(cglm_install_step);
    contenManager.step.dependOn(meshopt_install_step);

    // b.install_path =
}
