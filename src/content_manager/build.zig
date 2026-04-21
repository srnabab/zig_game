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
    const vk_c = b.addTranslateC(.{
        .root_source_file = b.path("../../include/vulkan/vulkan.h"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    const vk_c_mod = vk_c.createModule();
    const spriv_reflect_c = b.addTranslateC(.{
        .root_source_file = b.path("../../include/spirv_reflect/spirv_reflect.h"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    const srpiv_reflect_c_mod = spriv_reflect_c.createModule();
    srpiv_reflect_c_mod.addCSourceFile(.{ .file = b.path("../sprivReflect/spirv_reflect.c"), .language = .c });
    const spReflectModule = b.createModule(.{
        .root_source_file = b.path("../sprivReflect/reflect.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    const enum_c_mod = b.createModule(.{
        .root_source_file = b.path("../enumFromC.zig"),
        .target = target,
        .optimize = optimize,
    });
    const sqlite_c = b.addTranslateC(.{
        .root_source_file = b.path("../../include/sqlite3/sqlite3.h"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    const sqlite_c_mod = sqlite_c.createModule();
    sqlite_c_mod.addCSourceFile(.{
        .file = b.path("../../shared/sqlite3/sqlite3.c"),
        .language = .c,
        .flags = &c_flags,
    });
    const sqliteModule = b.createModule(.{
        .root_source_file = b.path("../../shared/sqlite3/sqliteDB.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    const tables_mod = b.createModule(.{
        .root_source_file = b.path("../../shared/tables.zig"),
        .target = target,
        .optimize = optimize,
    });
    const cgltf_c = b.addTranslateC(.{
        .root_source_file = b.path("../../include/cgltf/cgltf.h"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    const cgltf_c_mod = cgltf_c.createModule();
    cgltf_c_mod.addCSourceFile(.{
        .file = b.path("../../include/cgltf/cgltf_namespace.h"),
        .language = .c,
    });

    const cgltf_mod = b.createModule(.{
        .root_source_file = b.path("../cgltf/cgltf.zig"),
        .target = target,
        .optimize = optimize,
    });
    const vertexStruct_mod = b.createModule(.{
        .root_source_file = b.path("../vertexStruct.zig"),
        .target = target,
        .optimize = optimize,
    });
    const UUID_c = b.addTranslateC(.{
        .root_source_file = b.path("../../include/UUID/UUID.h"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    const UUID_c_mod = UUID_c.createModule();
    UUID_c_mod.addCSourceFile(.{
        .file = b.path("../UUID/UUID.c"),
        .language = .c,
        .flags = &c_flags,
    });

    const UUID_mod = b.createModule(.{
        .root_source_file = b.path("../UUID/UUID.zig"),
        .target = target,
        .optimize = optimize,
    });
    const cglm_c = b.addTranslateC(.{
        .root_source_file = b.path("../../include/cglm/call.h"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    const cglm_mod = cglm_c.createModule();
    const meshopt_c = b.addTranslateC(.{
        .root_source_file = b.path("../../include/meshoptimizer.h"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    const meshopt_c_mod = meshopt_c.createModule();
    const meshopt_mod = b.createModule(.{
        .root_source_file = b.path("../meshoptimizer/meshopt.zig"),
        .target = target,
        .optimize = optimize,
    });
    const blake3_c = b.addTranslateC(.{
        .root_source_file = b.path("../../include/blake3.h"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    const blake3_c_mod = blake3_c.createModule();
    const blake3_hash_mod = b.createModule(.{
        .root_source_file = b.path("../../shared/blake3/blake_hash.zig"),
        .target = target,
        .optimize = optimize,
    });

    const blake3_dep = b.dependency("blake3", .{});
    const blake3_lib = blake3_dep.artifact("blake3");

    blake3_hash_mod.addImport("blake3", blake3_c_mod);

    blake3_c.addIncludePath(b.path("../../include"));
    meshopt_mod.addImport("meshopt", meshopt_c_mod);
    meshopt_c.addIncludePath(b.path("../../include"));

    cglm_c.addIncludePath(b.path("../../include"));
    // cglm_mod.addCSourceFile(.{ .file = b.path("../cglm/cglm.c"), .language = .c });

    cgltf_mod.addImport("cgltf", cgltf_c_mod);
    cgltf_mod.addImport("vertexStruct", vertexStruct_mod);
    cgltf_mod.addImport("enumFromC", enum_c_mod);
    cgltf_mod.addImport("UUID", UUID_mod);
    cgltf_mod.addIncludePath(b.path("../../include"));

    vertexStruct_mod.addImport("cglm", cglm_mod);

    UUID_c.addIncludePath(b.path("../../include"));
    UUID_c_mod.addIncludePath(b.path("../../include"));
    UUID_mod.addImport("UUID_C", UUID_c_mod);

    contentManagerModule.addImport("options", options.createModule());
    contentManagerModule.addImport("cgltf", cgltf_mod);
    contentManagerModule.addImport("vertexStruct", vertexStruct_mod);
    contentManagerModule.addImport("reflect", spReflectModule);
    contentManagerModule.addImport("sqlDb", sqliteModule);
    contentManagerModule.addImport("tables", tables_mod);
    contentManagerModule.addImport("tracy", tracy.module("tracy"));
    contentManagerModule.addImport("UUID", UUID_mod);
    contentManagerModule.addImport("meshopt", meshopt_mod);
    contentManagerModule.addImport("blake_hash", blake3_hash_mod);
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

    vk_c.addIncludePath(b.path("../../include"));

    spReflectModule.addImport("EnumC", enum_c_mod);
    spReflectModule.addImport("vulkan", vk_c_mod);
    spReflectModule.addImport("spriv_reflect", srpiv_reflect_c_mod);
    spriv_reflect_c.addIncludePath(b.path("../../include"));
    srpiv_reflect_c_mod.addIncludePath(b.path("../../include"));

    sqliteModule.addImport("sqlite3", sqlite_c_mod);
    sqlite_c.addIncludePath(b.path("../../include"));

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
