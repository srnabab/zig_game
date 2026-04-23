const std = @import("std");
const lazyP = @import("std").Build.LazyPath;
const builtin = @import("builtin");

const cpp_compileFlag = [_][]const u8{ "-std=c++17", "-g" };
const c_flags = [_][]const u8{"-std=c11"};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{ .default_target = .{ .abi = .gnu } });
    const optimize = b.standardOptimizeOption(.{ .preferred_optimize_mode = .Debug });

    const blake3_dep = b.dependency("blake3", .{});
    const blake3_lib = blake3_dep.artifact("blake3");

    const meshopt_dep = b.dependency("meshoptimizer", .{});
    const meshopt_lib_install_step = meshopt_dep.builder.getInstallStep();

    const shaderc_dep = b.dependency("shaderc", .{});
    const shaderc_lib_install_step = shaderc_dep.builder.getInstallStep();

    const cglm_dep = b.dependency("cglm", .{});
    const cglm_install_step = cglm_dep.builder.getInstallStep();

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    const blake3_c = b.addTranslateC(.{
        .root_source_file = b.path("../include/blake3.h"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    const blake3_c_mod = blake3_c.createModule();
    const db_mod = b.createModule(.{
        .root_source_file = b.path("src/db.zig"),
        .target = target,
        .optimize = optimize,
    });
    const sqliteModule = b.createModule(.{
        .root_source_file = b.path("../shared/sqlite3/sqliteDB.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    const sqlite_c = b.addTranslateC(.{
        .root_source_file = b.path("../include/sqlite3/sqlite3.h"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    const sqlite_c_mod = sqlite_c.createModule();
    sqlite_c_mod.addCSourceFile(.{
        .file = b.path("../shared/sqlite3/sqlite3.c"),
        .language = .c,
        .flags = &c_flags,
    });
    const tables_mod = b.createModule(.{
        .root_source_file = b.path("../shared/tables.zig"),
        .target = target,
        .optimize = optimize,
    });
    const blake3_hash_mod = b.createModule(.{
        .root_source_file = b.path("../shared/blake3/blake_hash.zig"),
        .target = target,
        .optimize = optimize,
    });
    const types_mod = b.createModule(.{
        .root_source_file = b.path("../shared/types.zig"),
        .target = target,
        .optimize = optimize,
    });
    const UUID_c = b.addTranslateC(.{
        .root_source_file = b.path("../include/UUID/UUID.h"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    const UUID_c_mod = UUID_c.createModule();
    UUID_c_mod.addCSourceFile(.{
        .file = b.path("src/UUID/UUID.c"),
        .language = .c,
        .flags = &c_flags,
    });
    const UUID_mod = b.createModule(.{
        .root_source_file = b.path("src/UUID/UUID.zig"),
        .target = target,
        .optimize = optimize,
    });
    const vk_c = b.addTranslateC(.{
        .root_source_file = b.path("../include/vulkan/vulkan.h"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    const vk_c_mod = vk_c.createModule();
    const spriv_reflect_c = b.addTranslateC(.{
        .root_source_file = b.path("../include/spirv_reflect/spirv_reflect.h"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    const srpiv_reflect_c_mod = spriv_reflect_c.createModule();
    srpiv_reflect_c_mod.addCSourceFile(.{ .file = b.path("../shared/sprivReflect/spirv_reflect.c"), .language = .c });
    const spReflectModule = b.createModule(.{
        .root_source_file = b.path("../shared/sprivReflect/reflect.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    const enum_c_mod = b.createModule(.{
        .root_source_file = b.path("../shared/enumFromC.zig"),
        .target = target,
        .optimize = optimize,
    });
    const vertexStruct_mod = b.createModule(.{
        .root_source_file = b.path("../shared/vertexStruct.zig"),
        .target = target,
        .optimize = optimize,
    });
    const meshopt_c = b.addTranslateC(.{
        .root_source_file = b.path("../include/meshoptimizer.h"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    const meshopt_c_mod = meshopt_c.createModule();
    const meshopt_mod = b.createModule(.{
        .root_source_file = b.path("src/meshoptimizer/meshopt.zig"),
        .target = target,
        .optimize = optimize,
        .link_libcpp = true,
    });
    const cgltf_c = b.addTranslateC(.{
        .root_source_file = b.path("../include/cgltf/cgltf.h"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    const cgltf_c_mod = cgltf_c.createModule();
    cgltf_c_mod.addCSourceFile(.{
        .file = b.path("../include/cgltf/cgltf_namespace.h"),
        .language = .c,
    });

    const cgltf_mod = b.createModule(.{
        .root_source_file = b.path("src/cgltf/cgltf.zig"),
        .target = target,
        .optimize = optimize,
    });
    const cglm_c = b.addTranslateC(.{
        .root_source_file = b.path("../include/cglm/call.h"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    const cglm_mod = cglm_c.createModule();
    const shaderc_c = b.addTranslateC(.{
        .root_source_file = b.path("../include/shaderc/shaderc.h"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    const shaderc_c_mod = shaderc_c.createModule();
    const shaderC_mod = b.createModule(.{
        .root_source_file = b.path("src/shaderc/shaderc.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .link_libcpp = true,
    });
    // const sampler_mod = b.createModule(.{
    //     .root_source_file = b.path("src/sampler/sampler.zig"),
    //     .target = target,
    //     .optimize = optimize,
    // });

    shaderC_mod.addImport("shaderc", shaderc_c_mod);
    shaderc_c.addIncludePath(b.path("../include"));

    cglm_c.addIncludePath(b.path("../include"));

    vertexStruct_mod.addImport("cglm", cglm_mod);

    meshopt_mod.addIncludePath(b.path("../include"));
    meshopt_mod.addImport("meshopt", meshopt_c_mod);
    meshopt_c.addIncludePath(b.path("../include"));

    vk_c.addIncludePath(b.path("../include"));

    cgltf_mod.addImport("cgltf", cgltf_c_mod);
    cgltf_mod.addImport("vertexStruct", vertexStruct_mod);
    cgltf_mod.addImport("enumFromC", enum_c_mod);
    cgltf_mod.addImport("UUID", UUID_mod);
    cgltf_mod.addIncludePath(b.path("../include"));

    spReflectModule.addImport("EnumC", enum_c_mod);
    spReflectModule.addImport("vulkan", vk_c_mod);
    spReflectModule.addImport("spriv_reflect", srpiv_reflect_c_mod);
    spriv_reflect_c.addIncludePath(b.path("../include"));
    srpiv_reflect_c_mod.addIncludePath(b.path("../include"));

    UUID_c.addIncludePath(b.path("../include"));
    UUID_c_mod.addIncludePath(b.path("../include"));
    UUID_mod.addImport("UUID_C", UUID_c_mod);

    sqliteModule.addImport("sqlite3", sqlite_c_mod);
    sqlite_c.addIncludePath(b.path("../include"));

    tables_mod.addImport("sqlDb", sqliteModule);

    blake3_hash_mod.addImport("blake3", blake3_c_mod);

    db_mod.addImport("sqlDb", sqliteModule);
    db_mod.addImport("tables", tables_mod);
    db_mod.addImport("types", types_mod);
    db_mod.addImport("UUID", UUID_mod);
    db_mod.addImport("reflect", spReflectModule);
    db_mod.addImport("blake_hash", blake3_hash_mod);
    db_mod.addImport("vertexStruct", vertexStruct_mod);
    db_mod.addImport("meshopt", meshopt_mod);
    db_mod.addImport("cgltf", cgltf_mod);

    exe_mod.addImport("db", db_mod);
    exe_mod.addImport("shaderc", shaderC_mod);
    exe_mod.addLibraryPath(meshopt_dep.path("install/lib"));
    exe_mod.linkSystemLibrary("meshoptimizer", .{ .preferred_link_mode = .static });

    exe_mod.addLibraryPath(cglm_dep.path("install/lib"));
    exe_mod.addLibraryPath(shaderc_dep.path("install/lib"));
    exe_mod.linkSystemLibrary("setupapi", .{ .preferred_link_mode = .static });
    exe_mod.linkSystemLibrary("cglm", .{ .preferred_link_mode = .static });
    exe_mod.linkSystemLibrary("Rpcrt4", .{ .preferred_link_mode = .static });
    exe_mod.linkSystemLibrary("shaderc_combined", .{ .preferred_link_mode = .static });

    const exe = b.addExecutable(.{
        .name = "watcher",
        .root_module = exe_mod,
    });
    exe_mod.linkLibrary(blake3_lib);

    exe.step.dependOn(meshopt_lib_install_step);
    exe.step.dependOn(cglm_install_step);
    exe.step.dependOn(shaderc_lib_install_step);

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    run_cmd.addArgs(&[_][]const u8{
        "--f",
        "C:\\D\\code\\zig\\game",
        "--d",
        "C:\\D\\code\\zig\\game\\zig-out\\bin\\Content.db",
        "C:\\D\\code\\zig\\game\\zig-out\\bin\\Content",
    });

    const run_step = b.step("run", "Run the app");

    run_cmd.step.dependOn(b.getInstallStep());
    run_step.dependOn(&run_cmd.step);
}
