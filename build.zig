const std = @import("std");
const lazyP = @import("std").Build.LazyPath;
const cpp_compileFlag = [_][]const u8{ "-std=c++17", "-g" };
const builtin = @import("builtin");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{ .default_target = .{ .abi = .gnu } });
    const optimize = b.standardOptimizeOption(.{ .preferred_optimize_mode = .Debug });

    const root_path = b.build_root.path orelse "";

    // modules
    const tracy_enable = b.option(bool, "tracy_enable", "Enable profiling") orelse false;
    const tracy_callstack = b.option(u8, "tracy_callstack", "Callstack depth") orelse 10;
    const tracy = b.dependency("tracy", .{
        .target = target,
        .optimize = optimize,
        .tracy_enable = tracy_enable,
        .tracy_callstack = tracy_callstack,
        .tracy_delayed_init = true,
        .tracy_manual_lifetime = true,
    });

    const sdl3Module = b.dependency("sdl3", .{});
    const sdl3_lib_install_step = sdl3Module.builder.getInstallStep();

    // const meshoptimizerModule = b.dependency("meshoptimizer", .{});
    // const meshopt_lib_install_step = meshoptimizerModule.builder.getInstallStep();

    const cglm_dep = b.dependency("cglm", .{});
    const cglm_install_step = cglm_dep.builder.getInstallStep();

    const mvzr = b.dependency("mvzr", .{});
    const mvzr_mod = mvzr.module("mvzr");

    const vma_c = b.addTranslateC(.{
        .root_source_file = b.path("include/vma/vk_mem_alloc_namespace.h"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    const vma_mod = vma_c.createModule();
    vma_mod.addCSourceFile(.{ .file = b.path("monsoon/vma/vma_impl.cpp"), .language = .cpp });
    const enum_c_mod = b.createModule(.{
        .root_source_file = b.path("shared/enumFromC.zig"),
        .target = target,
        .optimize = optimize,
    });
    const spriv_reflect_c = b.addTranslateC(.{
        .root_source_file = b.path("include/spirv_reflect/spirv_reflect.h"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    const srpiv_reflect_c_mod = spriv_reflect_c.createModule();
    const vk_c = b.addTranslateC(.{
        .root_source_file = b.path("include/vulkan/vulkan.h"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    const vk_c_mod = vk_c.createModule();
    const spReflectModule = b.createModule(.{
        .root_source_file = b.path("shared/sprivReflect/reflect.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    spReflectModule.addCSourceFile(.{ .file = b.path("shared/sprivReflect/spirv_reflect.c"), .language = .c });
    const sqlite_c = b.addTranslateC(.{
        .root_source_file = b.path("include/sqlite3/sqlite3.h"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    const sqlite_c_mod = sqlite_c.createModule();
    const sqlite_c_flags = [_][]const u8{"-DSQLITE_THREADSAFE=2"};
    sqlite_c_mod.addCSourceFile(.{
        .file = b.path("shared/sqlite3/sqlite3.c"),
        .language = .c,
        .flags = &sqlite_c_flags,
    });
    const sqliteModule = b.createModule(.{
        .root_source_file = b.path("shared/sqlite3/sqliteDB.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    const tables_mod = b.createModule(.{
        .root_source_file = b.path("shared/tables.zig"),
        .target = target,
        .optimize = optimize,
    });
    const gen_fileName_ID_mod = b.createModule(.{
        .root_source_file = b.path("monsoon/fileSystem/fileName_ID/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    const vulkanType_mod = b.createModule(.{
        .root_source_file = b.path("monsoon/video/vulkanType.zig"),
        .target = target,
        .optimize = optimize,
    });
    // const gen_mod = b.createModule(.{
    //     .root_source_file = b.path("monsoon/video/gen.zig"),
    //     .target = target,
    //     .optimize = .ReleaseFast,
    //     .link_libc = true,
    // });
    const sdl_c = b.addTranslateC(.{
        .root_source_file = b.path("include/SDL3/SDL_namespace.h"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    const sdl_c_mod = sdl_c.createModule();
    const sdl_mod = b.createModule(.{
        .root_source_file = b.path("monsoon/sdl.zig"),
        .target = target,
        .optimize = optimize,
    });
    const translate_mod = b.createModule(.{
        .root_source_file = b.path("shared/pipeline/translate.zig"),
        .target = target,
        .optimize = optimize,
    });
    const stb_image_c = b.addTranslateC(.{
        .root_source_file = b.path("include/stb/stb_image.h"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    const stb_image_mod = stb_image_c.createModule();
    stb_image_mod.addCSourceFile(.{ .file = b.path("include/stb/stb_image_impl.h"), .language = .c });

    const textureSet_mod = b.createModule(.{
        .root_source_file = b.path("monsoon/video/textureSet.zig"),
        .target = target,
        .optimize = optimize,
    });
    const video_mod = b.createModule(.{
        .root_source_file = b.path("monsoon/video/VkStruct.zig"),
        .target = target,
        .optimize = optimize,
    });
    const global_mod = b.createModule(.{
        .root_source_file = b.path("monsoon/global.zig"),
        .target = target,
        .optimize = optimize,
    });
    const fileSystem_mod = b.createModule(.{
        .root_source_file = b.path("monsoon/fileSystem/fileSystem.zig"),
        .target = target,
        .optimize = optimize,
    });
    const exe_mod = b.createModule(.{
        .root_source_file = b.path("monsoon/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libcpp = true,
    });
    const steam_c = b.addTranslateC(.{
        .root_source_file = b.path("include/steam_C/SteamC.h"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    const steam_c_mod = steam_c.createModule();
    steam_c_mod.addCSourceFile(.{ .file = b.path("monsoon/steam_C/steamC.cpp"), .language = .cpp, .flags = &cpp_compileFlag });
    steam_c_mod.addCSourceFile(.{ .file = b.path("monsoon/steam_C/ISteamUserStats.cpp"), .language = .cpp, .flags = &cpp_compileFlag });
    const steam_mod = b.createModule(.{
        .root_source_file = b.path("monsoon/steam_C/SteamC.zig"),
        .target = target,
        .optimize = optimize,
        .link_libcpp = true,
    });
    const processRender_mod = b.createModule(.{
        .root_source_file = b.path("monsoon/video/processRender.zig"),
        .target = target,
        .optimize = optimize,
    });
    const sampler_read_mod = b.createModule(.{
        .root_source_file = b.path("monsoon/sampler/read.zig"),
        .target = target,
        .optimize = optimize,
    });

    const vertices_mod = b.createModule(.{
        .root_source_file = b.path("monsoon/video/vertices.zig"),
        .target = target,
        .optimize = optimize,
    });
    const cglm_c = b.addTranslateC(.{
        .root_source_file = b.path("include/cglm/call.h"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    const cglm_mod = cglm_c.createModule();
    const handle_mod = b.createModule(.{
        .root_source_file = b.path("monsoon/handle/handle.zig"),
        .target = target,
        .optimize = optimize,
    });
    const resultToError_mod = b.createModule(.{
        .root_source_file = b.path("monsoon/video/resultToError.zig"),
        .target = target,
        .optimize = optimize,
    });
    const error_mod = b.createModule(.{
        .root_source_file = b.path("monsoon/error/messageBox.zig"),
        .target = target,
        .optimize = optimize,
    });
    const vk_types_mod = b.createModule(.{
        .root_source_file = b.path("monsoon/video/vkStruct/types.zig"),
        .target = target,
        .optimize = optimize,
    });
    const debug_mod = b.createModule(.{
        .root_source_file = b.path("monsoon/debug/debug.zig"),
        .target = target,
        .optimize = optimize,
    });
    const input_mod = b.createModule(.{
        .root_source_file = b.path("monsoon/input/input.zig"),
        .target = target,
        .optimize = optimize,
    });
    // const meshopt_mod = b.createModule(.{
    //     .root_source_file = b.path("monsoon/meshopt/meshopt.zig"),
    //     .target = target,
    //     .optimize = optimize,
    // });
    const vertexStruct_mod = b.createModule(.{
        .root_source_file = b.path("shared/vertexStruct.zig"),
        .target = target,
        .optimize = optimize,
    });
    const fileTypes_mod = b.createModule(.{
        .root_source_file = b.path("shared/types.zig"),
        .target = target,
        .optimize = optimize,
    });
    const resource_mod = b.createModule(.{
        .root_source_file = b.path("monsoon/resource.zig"),
        .target = target,
        .optimize = optimize,
    });
    const pass_mod = b.createModule(.{
        .root_source_file = b.path("monsoon/pass/PassImp.zig"),
        .target = target,
        .optimize = optimize,
    });
    const renderFlow_mod = b.createModule(.{
        .root_source_file = b.path("monsoon/pass/renderFlow.zig"),
        .target = target,
        .optimize = optimize,
    });
    const renderDebug_mod = b.createModule(.{
        .root_source_file = b.path("monsoon/video/debug/print.zig"),
        .target = target,
        .optimize = optimize,
    });
    const mesh_mod = b.createModule(.{
        .root_source_file = b.path("monsoon/video/mesh/mesh.zig"),
        .target = target,
        .optimize = optimize,
    });
    const instance_mod = b.createModule(.{
        .root_source_file = b.path("monsoon/video/instance/instance.zig"),
        .target = target,
        .optimize = optimize,
    });
    const passGroupMapping_mod = b.createModule(.{
        .root_source_file = b.path("monsoon/video/pass/pass.zig"),
        .target = target,
        .optimize = optimize,
    });
    const vulkanCapability_mod = b.createModule(.{
        .root_source_file = b.path("monsoon/video/capability.zig"),
        .target = target,
        .optimize = optimize,
    });
    const ktx2_c = b.addTranslateC(.{
        .root_source_file = b.path("include/KTX/ktx.h"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    const ktx_mod = ktx2_c.createModule();

    const loadmap_mod = b.createModule(.{
        .root_source_file = b.path("monsoon/loadmap/loadmap.zig"),
        .target = target,
        .optimize = optimize,
    });
    const ms_mod = b.createModule(.{
        .root_source_file = b.path("monsoon/ms_std/std.zig"),
        .target = target,
        .optimize = optimize,
    });
    const setPass_mod = b.createModule(.{
        .root_source_file = b.path("src/setPass.zig"),
        .target = target,
        .optimize = optimize,
    });
    const resourceProcess_mod = b.createModule(.{
        .root_source_file = b.path("src/resourceProcess.zig"),
        .target = target,
        .optimize = optimize,
    });

    // aaa
    resourceProcess_mod.addImport("handle", handle_mod);
    resourceProcess_mod.addImport("vulkan", vk_c_mod);
    resourceProcess_mod.addImport("tables", tables_mod);

    setPass_mod.addImport("vertexStruct", vertexStruct_mod);
    setPass_mod.addImport("cglm", cglm_mod);
    setPass_mod.addImport("vulkan", vk_c_mod);
    setPass_mod.addImport("renderFlow", renderFlow_mod);
    setPass_mod.addImport("video", video_mod);
    setPass_mod.addImport("processRender", processRender_mod);
    setPass_mod.addImport("textureSet", textureSet_mod);
    setPass_mod.addImport("pass", pass_mod);
    setPass_mod.addImport("renderDebug", renderDebug_mod);
    setPass_mod.addImport("ms_std", ms_mod);

    ms_mod.addImport("tracy", tracy.module("tracy"));
    ms_mod.addImport("cglm", cglm_mod);

    loadmap_mod.addImport("cglm", cglm_mod);

    ktx2_c.addIncludePath(b.path("include"));
    ktx2_c.addIncludePath(b.path("include/KTX"));

    passGroupMapping_mod.addImport("vertexStruct", vertexStruct_mod);
    passGroupMapping_mod.addImport("video", video_mod);
    passGroupMapping_mod.addImport("processRender", processRender_mod);

    instance_mod.addImport("processRender", processRender_mod);
    instance_mod.addImport("vertexStruct", vertexStruct_mod);
    instance_mod.addImport("video", video_mod);
    instance_mod.addImport("fileSystem", fileSystem_mod);
    instance_mod.addImport("vulkan", vk_c_mod);
    instance_mod.addImport("global", global_mod);
    instance_mod.addImport("handle", handle_mod);

    renderDebug_mod.addImport("processRender", processRender_mod);
    renderDebug_mod.addImport("global", global_mod);
    renderDebug_mod.addImport("mvzr", mvzr_mod);
    renderDebug_mod.addImport("video", video_mod);
    renderDebug_mod.addImport("pass", pass_mod);

    renderFlow_mod.addImport("processRender", processRender_mod);
    renderFlow_mod.addImport("video", video_mod);
    renderFlow_mod.addImport("vulkan", vk_c_mod);
    renderFlow_mod.addImport("passImp", pass_mod);
    renderFlow_mod.addImport("textureSet", textureSet_mod);

    pass_mod.addImport("renderFlow", renderFlow_mod);
    pass_mod.addImport("textureSet", textureSet_mod);
    pass_mod.addImport("video", video_mod);
    pass_mod.addImport("processRender", processRender_mod);
    pass_mod.addImport("fileSystem", fileSystem_mod);
    pass_mod.addImport("vulkan", vk_c_mod);

    resource_mod.addImport("video", video_mod);
    resource_mod.addImport("vk", vk_c_mod);
    resource_mod.addImport("vma", vma_mod);
    resource_mod.addImport("handle", handle_mod);
    resource_mod.addImport("textureSet", textureSet_mod);
    resource_mod.addImport("mesh", mesh_mod);
    resource_mod.addImport("instance", instance_mod);
    resource_mod.addImport("vertexStruct", vertexStruct_mod);
    resource_mod.addImport("global", global_mod);
    resource_mod.addImport("stb_image", stb_image_mod);
    resource_mod.addImport("fileSystem", fileSystem_mod);
    resource_mod.addImport("ktx", ktx_mod);
    resource_mod.addImport("ms_std", ms_mod);
    resource_mod.addImport("resourceProcess", resourceProcess_mod);
    // resource_mod.addImport("ktx_vulkan", ktx_vulkan_mod);

    mesh_mod.addImport("processRender", processRender_mod);
    mesh_mod.addImport("vertexStruct", vertexStruct_mod);
    mesh_mod.addImport("video", video_mod);
    mesh_mod.addImport("fileSystem", fileSystem_mod);
    mesh_mod.addImport("vulkan", vk_c_mod);
    mesh_mod.addImport("global", global_mod);
    mesh_mod.addImport("handle", handle_mod);

    vertexStruct_mod.addImport("cglm", cglm_mod);

    // meshopt_mod.addIncludePath(b.path("include"));

    input_mod.addImport("sdl", sdl_mod);

    error_mod.addImport("sdl", sdl_mod);

    resultToError_mod.addImport("enumFromC", enum_c_mod);
    resultToError_mod.addImport("vulkan", vk_c_mod);
    resultToError_mod.addImport("renderDebug", renderDebug_mod);

    cglm_c.addIncludePath(b.path("include"));

    vertices_mod.addImport("tracy", tracy.module("tracy"));
    vertices_mod.addImport("vertexStruct", vertexStruct_mod);
    vertices_mod.addImport("vulkan", vk_c_mod);
    vertices_mod.addImport("global", global_mod);
    vertices_mod.addImport("video", video_mod);
    vertices_mod.addImport("cglm", cglm_mod);
    vertices_mod.addImport("textureSet", textureSet_mod);
    vertices_mod.addImport("processRender", processRender_mod);

    sampler_read_mod.addImport("vulkan", vk_c_mod);
    sampler_read_mod.addImport("fileSystem", fileSystem_mod);
    sampler_read_mod.addImport("tracy", tracy.module("tracy"));

    vk_c.addIncludePath(b.path("include"));

    steam_mod.addImport("tracy", tracy.module("tracy"));
    steam_mod.addImport("steamC", steam_c_mod);
    steam_c.addIncludePath(b.path("include"));
    steam_c_mod.addIncludePath(b.path("include"));

    spriv_reflect_c.addIncludePath(b.path("include"));

    spReflectModule.addImport("EnumC", enum_c_mod);
    spReflectModule.addImport("spriv_reflect", srpiv_reflect_c_mod);
    spReflectModule.addImport("vulkan", vk_c_mod);
    spReflectModule.addIncludePath(b.path("include"));

    sqliteModule.addImport("sqlite3", sqlite_c_mod);
    sqlite_c.addIncludePath(b.path("include"));

    tables_mod.addImport("sqlDb", sqliteModule);

    gen_fileName_ID_mod.addImport("sqlDb", sqliteModule);
    gen_fileName_ID_mod.addImport("tables", tables_mod);

    vulkanType_mod.addImport("enumFromC", enum_c_mod);
    vulkanType_mod.addImport("vulkan", vk_c_mod);

    // gen_mod.addIncludePath(b.path("include"));
    // gen_mod.addLibraryPath(b.path("lib"));
    // gen_mod.addImport("enumFromC", enum_c_mod);
    // gen_mod.addImport("vulkanType", vulkanType_mod);
    // gen_mod.linkSystemLibrary("vulkan-1", .{});

    sdl_c.addIncludePath(b.path("include"));

    sdl_mod.addIncludePath(b.path("include"));
    sdl_mod.addImport("enumFromC", enum_c_mod);
    sdl_mod.addImport("sdl", sdl_c_mod);

    translate_mod.addImport("vulkan", vk_c_mod);
    translate_mod.addImport("fileSystem", fileSystem_mod);
    translate_mod.addImport("global", global_mod);
    translate_mod.addImport("enumFromC", enum_c_mod);
    translate_mod.addImport("tracy", tracy.module("tracy"));

    textureSet_mod.addImport("stb_image", stb_image_mod);
    textureSet_mod.addImport("ms_std", ms_mod);
    textureSet_mod.addImport("vulkan", vk_c_mod);
    textureSet_mod.addImport("video", video_mod);
    textureSet_mod.addImport("global", global_mod);
    textureSet_mod.addImport("fileSystem", fileSystem_mod);
    textureSet_mod.addImport("tracy", tracy.module("tracy"));
    textureSet_mod.addImport("handle", handle_mod);
    textureSet_mod.addImport("processRender", processRender_mod);
    textureSet_mod.addImport("resource", resource_mod);
    textureSet_mod.addIncludePath(b.path("include"));

    debug_mod.addImport("vulkan", vk_c_mod);
    debug_mod.addImport("resultToError", resultToError_mod);

    stb_image_mod.addIncludePath(b.path("include"));

    vma_c.addIncludePath(b.path("include"));
    vma_mod.addIncludePath(b.path("include"));

    vk_types_mod.addImport("vulkan", vk_c_mod);

    video_mod.addImport("ms_std", ms_mod);
    video_mod.addImport("sdl", sdl_mod);
    video_mod.addImport("vma", vma_mod);
    video_mod.addImport("vulkan", vk_c_mod);
    video_mod.addImport("translate", translate_mod);
    video_mod.addImport("enumFromC", enum_c_mod);
    video_mod.addImport("textureSet", textureSet_mod);
    video_mod.addImport("tracy", tracy.module("tracy"));
    video_mod.addImport("fileSystem", fileSystem_mod);
    video_mod.addImport("sampler", sampler_read_mod);
    video_mod.addImport("resultToError", resultToError_mod);
    video_mod.addImport("handle", handle_mod);
    video_mod.addImport("processRender", processRender_mod);
    video_mod.addImport("global", global_mod);
    video_mod.addImport("error", error_mod);
    video_mod.addImport("types", vk_types_mod);
    video_mod.addImport("debug", debug_mod);
    video_mod.addImport("renderDebug", renderDebug_mod);
    video_mod.addImport("capability", vulkanCapability_mod);

    processRender_mod.addImport("video", video_mod);
    processRender_mod.addImport("mesh", mesh_mod);
    processRender_mod.addImport("vulkan", vk_c_mod);
    processRender_mod.addImport("textureSet", textureSet_mod);
    processRender_mod.addImport("global", global_mod);
    processRender_mod.addImport("tracy", tracy.module("tracy"));
    processRender_mod.addImport("ms_std", ms_mod);
    processRender_mod.addImport("handle", handle_mod);
    processRender_mod.addImport("renderDebug", renderDebug_mod);
    processRender_mod.addImport("capability", vulkanCapability_mod);

    global_mod.addImport("video", video_mod);
    global_mod.addImport("resource", resource_mod);
    global_mod.addImport("processRender", processRender_mod);
    global_mod.addImport("textureSet", textureSet_mod);
    global_mod.addImport("handle", handle_mod);
    global_mod.addImport("vertexStruct", vertexStruct_mod);
    global_mod.addImport("ms_std", ms_mod);

    fileSystem_mod.addImport("resourceProcess", resourceProcess_mod);
    fileSystem_mod.addImport("sqlDb", sqliteModule);
    fileSystem_mod.addImport("global", global_mod);
    fileSystem_mod.addImport("tables", tables_mod);
    fileSystem_mod.addImport("types", fileTypes_mod);
    fileSystem_mod.addImport("vulkan", vk_c_mod);
    fileSystem_mod.addImport("tracy", tracy.module("tracy"));
    fileSystem_mod.addImport("vertexStruct", vertexStruct_mod);
    fileSystem_mod.addIncludePath(b.path("include"));

    exe_mod.addImport("setPass", setPass_mod);
    exe_mod.addImport("ms_std", ms_mod);
    exe_mod.addImport("loadmap", loadmap_mod);
    exe_mod.addImport("passGroupMapping", passGroupMapping_mod);
    exe_mod.addImport("instance", instance_mod);
    exe_mod.addImport("renderDebug", renderDebug_mod);
    exe_mod.addImport("textureSet", textureSet_mod);
    exe_mod.addImport("renderFlow", renderFlow_mod);
    exe_mod.addImport("pass", pass_mod);
    exe_mod.addImport("video", video_mod);
    exe_mod.addImport("stb_image", stb_image_mod);
    exe_mod.addImport("vertexStruct", vertexStruct_mod);
    exe_mod.addImport("input", input_mod);
    exe_mod.addImport("cglm", cglm_mod);
    exe_mod.addImport("video", video_mod);
    exe_mod.addImport("enumFromC", enum_c_mod);
    exe_mod.addImport("fileSystem", fileSystem_mod);
    exe_mod.addImport("global", global_mod);
    exe_mod.addImport("translate", translate_mod);
    exe_mod.addImport("textureSet", textureSet_mod);
    exe_mod.addImport("steam", steam_mod);
    exe_mod.addImport("processRender", processRender_mod);
    exe_mod.addImport("tracy", tracy.module("tracy"));
    exe_mod.addImport("vertices", vertices_mod);
    exe_mod.addImport("handle", handle_mod);
    exe_mod.addImport("sdl", sdl_mod);
    exe_mod.addImport("vulkan", vk_c_mod);
    exe_mod.addImport("resource", resource_mod);
    exe_mod.addImport("mesh", mesh_mod);
    exe_mod.addIncludePath(b.path("include/"));

    exe_mod.addLibraryPath(b.path("lib/"));
    // exe_mod.addLibraryPath(meshoptimizerModule.path("install/lib"));
    // exe_mod.linkSystemLibrary("meshoptimizer", .{ .preferred_link_mode = .static });
    exe_mod.addLibraryPath(sdl3Module.path("install/lib"));
    exe_mod.addLibraryPath(cglm_dep.path("install/lib"));
    exe_mod.linkSystemLibrary("cglm", .{ .preferred_link_mode = .static });
    exe_mod.linkSystemLibrary("ktx", .{ .preferred_link_mode = .dynamic });
    exe_mod.linkSystemLibrary("sdl3", .{ .preferred_link_mode = .static });
    exe_mod.linkSystemLibrary("steam_api64", .{});
    exe_mod.linkSystemLibrary("setupapi", .{ .preferred_link_mode = .static });
    exe_mod.linkSystemLibrary("imm32", .{ .preferred_link_mode = .static });
    exe_mod.linkSystemLibrary("version", .{ .preferred_link_mode = .static });
    exe_mod.linkSystemLibrary("winmm", .{ .preferred_link_mode = .static });
    exe_mod.linkSystemLibrary("ole32", .{ .preferred_link_mode = .static });
    exe_mod.linkSystemLibrary("gdi32", .{ .preferred_link_mode = .static });
    exe_mod.linkSystemLibrary("OleAut32", .{ .preferred_link_mode = .static });
    exe_mod.linkSystemLibrary("vulkan-1", .{});
    exe_mod.linkLibrary(tracy.artifact("tracy"));

    // exe

    const genFileNameIDexe = b.addExecutable(.{
        .root_module = gen_fileName_ID_mod,
        .name = "genFileNameIdHashMap",
    });
    const genFileNameIDexeInstallStep = b.addInstallArtifact(genFileNameIDexe, .{});

    // const gen_exe = b.addExecutable(.{ .name = "gen", .root_module = gen_mod });

    const exe = b.addExecutable(.{
        .name = "game",
        .root_module = exe_mod,
    });
    b.installArtifact(exe);

    // run task
    const preKillGameProcessCmd = b.addSystemCommand(if (builtin.target.os.tag == .windows) &.{
        "cmd",
        "/c",
        "taskkill",
        "/F",
        "/IM",
        "game.exe",
        "2>nul",
        "||",
        "exit",
        "/b",
        "0",
    } else unreachable);

    const runGenFileNameIdExe = b.step("create hash map", "create filename id static string hash map");
    const runGenFileNameIdExe_cmd = b.addRunArtifact(genFileNameIDexe);
    runGenFileNameIdExe_cmd.addArg(b.fmt("{s}/{s}", .{ root_path, "monsoon/fileSystem/fileNameID.zig" }));

    const waf = b.addWriteFiles();
    _ = waf.addCopyFile(exe.getEmittedAsm(), "main.asm");

    const pre_run_message_cmd = b.addSystemCommand(if (builtin.target.os.tag == .windows) &.{ "cmd", "/c", "echo" } else unreachable);
    pre_run_message_cmd.addArg(b.fmt("tracy-enable: {}", .{tracy_enable}));
    pre_run_message_cmd.addArg(b.fmt("tracy-callstack: {d}", .{tracy_callstack}));

    const run_cmd = b.addRunArtifact(exe);
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");

    const test_step = b.step("test", "Run unit tests");

    const exe_unit_tests = b.addTest(.{
        .root_module = exe_mod,
    });
    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    // run task dependency

    runGenFileNameIdExe.dependOn(&runGenFileNameIdExe_cmd.step);
    runGenFileNameIdExe_cmd.step.dependOn(&genFileNameIDexeInstallStep.step);

    exe.step.dependOn(sdl3_lib_install_step);
    exe.step.dependOn(cglm_install_step);
    exe.step.dependOn(runGenFileNameIdExe);

    waf.step.dependOn(&exe.step);
    b.getInstallStep().dependOn(&waf.step);
    b.getInstallStep().dependOn(&preKillGameProcessCmd.step);

    run_cmd.step.dependOn(b.getInstallStep());
    run_cmd.step.dependOn(&pre_run_message_cmd.step);
    run_step.dependOn(&run_cmd.step);

    test_step.dependOn(&run_exe_unit_tests.step);
}
