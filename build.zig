const std = @import("std");
const lazyP = @import("std").Build.LazyPath;
const cpp_compileFlag = [_][]const u8{ "-std=c++17", "-g" };
const builtin = @import("builtin");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{ .default_target = .{} });
    const optimize = b.standardOptimizeOption(.{ .preferred_optimize_mode = .Debug });

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

    const force_update = b.option(bool, "force_update", "force contentManager update all resources") orelse false;
    const contentManagerModule = b.dependency("contentManager", .{});
    const contenManager = contentManagerModule.artifact("ContentManager");
    const contenManager_install = b.addInstallArtifact(contenManager, .{ .dest_dir = .default });

    const sdl3Module = b.dependency("sdl3", .{});
    const sdl3_lib_install_step = sdl3Module.builder.getInstallStep();

    const selectModifiedFileToTxtModule = b.dependency("selectModifiedFileToTxt", .{});
    const selectModifiedFileToTxt = selectModifiedFileToTxtModule.artifact("selectModifiedFileToTxt");

    const vk_mod = b.createModule(.{
        .root_source_file = b.path("src/vulkan/vulkan.zig"),
        .target = target,
        .optimize = optimize,
    });
    const vma_mod = b.createModule(.{
        .root_source_file = b.path("src/vma/vma.zig"),
        .target = target,
        .optimize = optimize,
        .link_libcpp = true,
    });
    vma_mod.addCSourceFile(.{ .file = b.path("src/vma/vma_impl.cpp"), .language = .cpp });
    const enum_c_mod = b.createModule(.{
        .root_source_file = b.path("src/enumFromC.zig"),
        .target = target,
        .optimize = optimize,
    });
    const queue_mod = b.createModule(.{
        .root_source_file = b.path("src/queue/queue.zig"),
        .target = target,
        .optimize = optimize,
    });
    const spReflectModule = b.createModule(.{
        .root_source_file = b.path("src/sprivReflect/reflect.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    spReflectModule.addCSourceFile(.{ .file = b.path("src/sprivReflect/spirv_reflect.c"), .language = .c });
    const pipelineJsonParse_mod = b.createModule(.{
        .root_source_file = b.path("src/video/pipeline/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    const sqliteModule = b.createModule(.{
        .root_source_file = b.path("src/sqlite3/sqliteDB.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    sqliteModule.addCSourceFile(.{ .file = b.path("src/sqlite3/sqlite3.c"), .language = .c });
    const tables_mod = b.createModule(.{
        .root_source_file = b.path("src/tables.zig"),
        .target = target,
        .optimize = optimize,
    });
    const gen_fileName_ID_mod = b.createModule(.{
        .root_source_file = b.path("src/fileSystem/fileName_ID/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    const ecs_mod = b.createModule(.{
        .root_source_file = b.path("src/ecs/ecs.zig"),
        .target = target,
        .optimize = optimize,
    });
    const output_mod = b.createModule(.{
        .root_source_file = b.path("src/stdOutPut.zig"),
        .target = target,
        .optimize = .ReleaseFast,
    });
    const vulkanType_mod = b.createModule(.{
        .root_source_file = b.path("src/video/vulkanType.zig"),
        .target = target,
        .optimize = optimize,
    });
    const gen_mod = b.createModule(.{
        .root_source_file = b.path("src/video/gen.zig"),
        .target = target,
        .optimize = .ReleaseFast,
        .link_libc = true,
    });
    const sdl_mod = b.createModule(.{
        .root_source_file = b.path("src/sdl.zig"),
        .target = target,
        .optimize = optimize,
    });
    const translate_mod = b.createModule(.{
        .root_source_file = b.path("src/video/pipeline/translate.zig"),
        .target = target,
        .optimize = optimize,
    });
    const stb_image_mod = b.createModule(.{
        .root_source_file = b.path("src/stb_image.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    stb_image_mod.addCSourceFile(.{ .file = b.path("include/stb/stb_image_impl.h"), .language = .c });
    const textureSet_mod = b.createModule(.{
        .root_source_file = b.path("src/video/textureSet.zig"),
        .target = target,
        .optimize = optimize,
    });
    const video_mod = b.createModule(.{
        .root_source_file = b.path("src/video/VkStruct.zig"),
        .target = target,
        .optimize = optimize,
    });
    const global_mod = b.createModule(.{
        .root_source_file = b.path("src/global.zig"),
        .target = target,
        .optimize = optimize,
    });
    const fileSystem_mod = b.createModule(.{
        .root_source_file = b.path("src/fileSystem/fileSystem.zig"),
        .target = target,
        .optimize = optimize,
    });
    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libcpp = true,
    });
    const steam_mod = b.createModule(.{
        .root_source_file = b.path("src/steam_C/SteamC.zig"),
        .target = target,
        .optimize = optimize,
        .link_libcpp = true,
    });
    steam_mod.addCSourceFile(.{ .file = b.path("src/steam_C/steamC.cpp"), .language = .cpp, .flags = &cpp_compileFlag });
    steam_mod.addCSourceFile(.{ .file = b.path("src/steam_C/ISteamUserStats.cpp"), .language = .cpp, .flags = &cpp_compileFlag });
    const processRender_mod = b.createModule(.{
        .root_source_file = b.path("src/video/processRender.zig"),
        .target = target,
        .optimize = optimize,
    });
    const memoryPool_mod = b.createModule(.{
        .root_source_file = b.path("src/memoryPool/memoryPool.zig"),
        .target = target,
        .optimize = optimize,
    });
    const math_mod = b.createModule(.{
        .root_source_file = b.path("src/math.zig"),
        .target = target,
        .optimize = optimize,
    });
    const uniqueArrayList_mod = b.createModule(.{
        .root_source_file = b.path("src/uniqueArrayList.zig"),
        .target = target,
        .optimize = optimize,
    });
    const sampler_mod = b.createModule(.{
        .root_source_file = b.path("src/sampler/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    const sampler_read_mod = b.createModule(.{
        .root_source_file = b.path("src/sampler/read.zig"),
        .target = target,
        .optimize = optimize,
    });
    const stableArray_mod = b.createModule(.{
        .root_source_file = b.path("src/stableArray/array.zig"),
        .target = target,
        .optimize = optimize,
    });
    const objectPool_mod = b.createModule(.{
        .root_source_file = b.path("src/objectPool/pool.zig"),
        .target = target,
        .optimize = optimize,
    });
    const vertices_mod = b.createModule(.{
        .root_source_file = b.path("src/video/vertices.zig"),
        .target = target,
        .optimize = optimize,
    });
    const cglm_mod = b.createModule(.{
        .root_source_file = b.path("src/cglm/cglm.zig"),
        .target = target,
        .optimize = optimize,
    });
    const handle_mod = b.createModule(.{
        .root_source_file = b.path("src/handle/handle.zig"),
        .target = target,
        .optimize = optimize,
    });
    const resultToError_mod = b.createModule(.{
        .root_source_file = b.path("src/video/resultToError.zig"),
        .target = target,
        .optimize = optimize,
    });
    const fixedIndexArray_mod = b.createModule(.{
        .root_source_file = b.path("src/fixedIndexArray/array.zig"),
        .target = target,
        .optimize = optimize,
    });
    const error_mod = b.createModule(.{
        .root_source_file = b.path("src/error/messageBox.zig"),
        .target = target,
        .optimize = optimize,
    });
    const vk_types_mod = b.createModule(.{
        .root_source_file = b.path("src/video/vkStruct/types.zig"),
        .target = target,
        .optimize = optimize,
    });
    const debug_mod = b.createModule(.{
        .root_source_file = b.path("src/debug/debug.zig"),
        .target = target,
        .optimize = optimize,
    });
    const rendering_mod = b.createModule(.{
        .root_source_file = b.path("src/video/vkStruct/rendering.zig"),
        .target = target,
        .optimize = optimize,
    });

    // dependency
    rendering_mod.addImport("vulkan", vk_mod);
    rendering_mod.addImport("global", global_mod);
    rendering_mod.addImport("handle", handle_mod);
    rendering_mod.addImport("textureSet", textureSet_mod);
    rendering_mod.addImport("tracy", tracy.module("tracy"));

    error_mod.addImport("sdl", sdl_mod);

    resultToError_mod.addImport("enumFromC", enum_c_mod);
    resultToError_mod.addImport("vulkan", vk_mod);

    cglm_mod.addIncludePath(b.path("include"));

    vertices_mod.addImport("tracy", tracy.module("tracy"));
    vertices_mod.addImport("vulkan", vk_mod);
    vertices_mod.addImport("global", global_mod);
    vertices_mod.addImport("video", video_mod);
    vertices_mod.addImport("cglm", cglm_mod);
    vertices_mod.addImport("processRender", processRender_mod);

    objectPool_mod.addImport("tracy", tracy.module("tracy"));

    sampler_read_mod.addImport("vulkan", vk_mod);
    sampler_read_mod.addImport("fileSystem", fileSystem_mod);
    sampler_read_mod.addImport("tracy", tracy.module("tracy"));

    sampler_mod.addImport("vulkan", vk_mod);

    vk_mod.addIncludePath(b.path("include"));

    math_mod.addImport("tracy", tracy.module("tracy"));

    steam_mod.addImport("tracy", tracy.module("tracy"));
    steam_mod.addIncludePath(b.path("include"));

    spReflectModule.addImport("EnumC", enum_c_mod);
    spReflectModule.addIncludePath(b.path("include"));

    pipelineJsonParse_mod.addIncludePath(b.path("include"));
    pipelineJsonParse_mod.addImport("vulkan", vk_mod);
    pipelineJsonParse_mod.addImport("reflect", spReflectModule);
    pipelineJsonParse_mod.addImport("enumFromC", enum_c_mod);

    sqliteModule.addImport("tracy", tracy.module("tracy"));
    sqliteModule.addIncludePath(b.path("include"));

    tables_mod.addImport("sqlDb", sqliteModule);

    gen_fileName_ID_mod.addImport("sqlDb", sqliteModule);
    gen_fileName_ID_mod.addImport("tables", tables_mod);

    vulkanType_mod.addImport("enumFromC", enum_c_mod);
    vulkanType_mod.addImport("vulkan", vk_mod);

    gen_mod.addIncludePath(b.path("include"));
    gen_mod.addLibraryPath(b.path("lib"));
    gen_mod.addImport("enumFromC", enum_c_mod);
    gen_mod.addImport("vulkanType", vulkanType_mod);
    gen_mod.linkSystemLibrary("vulkan-1", .{});

    sdl_mod.addIncludePath(b.path("include"));

    translate_mod.addImport("vulkan", vk_mod);
    translate_mod.addImport("fileSystem", fileSystem_mod);
    translate_mod.addImport("global", global_mod);
    translate_mod.addImport("enumFromC", enum_c_mod);
    translate_mod.addImport("tracy", tracy.module("tracy"));

    textureSet_mod.addImport("stb_image", stb_image_mod);
    textureSet_mod.addImport("vulkan", vk_mod);
    textureSet_mod.addImport("memoryPool", memoryPool_mod);
    textureSet_mod.addImport("video", video_mod);
    textureSet_mod.addImport("global", global_mod);
    textureSet_mod.addImport("fileSystem", fileSystem_mod);
    textureSet_mod.addImport("tracy", tracy.module("tracy"));
    textureSet_mod.addImport("objectPool", objectPool_mod);
    textureSet_mod.addImport("handle", handle_mod);
    textureSet_mod.addImport("processRender", processRender_mod);
    textureSet_mod.addIncludePath(b.path("include"));

    debug_mod.addImport("vulkan", vk_mod);
    debug_mod.addImport("resultToError", resultToError_mod);

    stableArray_mod.addImport("tracy", tracy.module("tracy"));

    stb_image_mod.addIncludePath(b.path("include"));

    vma_mod.addIncludePath(b.path("include"));

    vk_types_mod.addImport("vulkan", vk_mod);

    video_mod.addImport("sdl", sdl_mod);
    video_mod.addImport("vma", vma_mod);
    video_mod.addImport("vulkan", vk_mod);
    video_mod.addImport("translate", translate_mod);
    video_mod.addImport("enumFromC", enum_c_mod);
    video_mod.addImport("textureSet", textureSet_mod);
    video_mod.addImport("tracy", tracy.module("tracy"));
    video_mod.addImport("fileSystem", fileSystem_mod);
    video_mod.addImport("sampler", sampler_read_mod);
    video_mod.addImport("math", math_mod);
    video_mod.addImport("resultToError", resultToError_mod);
    video_mod.addImport("fixedIndexArray", fixedIndexArray_mod);
    video_mod.addImport("handle", handle_mod);
    video_mod.addImport("processRender", processRender_mod);
    video_mod.addImport("global", global_mod);
    video_mod.addImport("error", error_mod);
    video_mod.addImport("types", vk_types_mod);
    video_mod.addImport("debug", debug_mod);

    queue_mod.addImport("tracy", tracy.module("tracy"));

    memoryPool_mod.addImport("tracy", tracy.module("tracy"));

    processRender_mod.addImport("video", video_mod);
    processRender_mod.addImport("vulkan", vk_mod);
    processRender_mod.addImport("textureSet", textureSet_mod);
    processRender_mod.addImport("queue", queue_mod);
    processRender_mod.addImport("global", global_mod);
    processRender_mod.addImport("tracy", tracy.module("tracy"));
    processRender_mod.addImport("math", math_mod);
    processRender_mod.addImport("uniqueArrayList", uniqueArrayList_mod);
    processRender_mod.addImport("rendering", rendering_mod);
    processRender_mod.addImport("handle", handle_mod);

    uniqueArrayList_mod.addImport("tracy", tracy.module("tracy"));

    global_mod.addImport("video", video_mod);
    global_mod.addImport("processRender", processRender_mod);
    global_mod.addImport("textureSet", textureSet_mod);
    global_mod.addImport("handle", handle_mod);

    fileSystem_mod.addImport("sqlDb", sqliteModule);
    fileSystem_mod.addImport("global", global_mod);
    fileSystem_mod.addImport("tables", tables_mod);
    fileSystem_mod.addImport("tracy", tracy.module("tracy"));
    fileSystem_mod.addIncludePath(b.path("include"));

    exe_mod.addImport("ECS", ecs_mod);
    exe_mod.addImport("cglm", cglm_mod);
    exe_mod.addImport("video", video_mod);
    exe_mod.addImport("enumFromC", enum_c_mod);
    exe_mod.addImport("output", output_mod);
    exe_mod.addImport("fileSystem", fileSystem_mod);
    exe_mod.addImport("global", global_mod);
    exe_mod.addImport("translate", translate_mod);
    exe_mod.addImport("textureSet", textureSet_mod);
    exe_mod.addImport("queue", queue_mod);
    exe_mod.addImport("steam", steam_mod);
    exe_mod.addImport("processRender", processRender_mod);
    exe_mod.addImport("tracy", tracy.module("tracy"));
    exe_mod.addImport("vertices", vertices_mod);
    exe_mod.addImport("handle", handle_mod);
    exe_mod.addImport("sdl", sdl_mod);
    exe_mod.addImport("rendering", rendering_mod);
    exe_mod.addImport("vulkan", vk_mod);
    exe_mod.addIncludePath(b.path("include/"));

    exe_mod.addLibraryPath(b.path("lib/"));
    exe_mod.addLibraryPath(sdl3Module.path("install/lib"));
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
    const samplerJsonPrase_exe = b.addExecutable(.{
        .name = "samplerJsonPrase",
        .root_module = sampler_mod,
    });
    b.installArtifact(samplerJsonPrase_exe);

    const pipelineJsonParse_exe = b.addExecutable(.{
        .name = "pipelineJsonParse",
        .root_module = pipelineJsonParse_mod,
    });
    b.installArtifact(pipelineJsonParse_exe);

    const genFileNameIDexe = b.addExecutable(.{
        .root_module = gen_fileName_ID_mod,
        .name = "genFileNameIdHashMap",
    });
    b.installArtifact(genFileNameIDexe);

    const gen_exe = b.addExecutable(.{ .name = "gen", .root_module = gen_mod });

    const exe = b.addExecutable(.{
        .name = "game",
        .root_module = exe_mod,
    });
    b.installArtifact(exe);

    // run task
    const preKillContentManagerProcessCmd = b.addSystemCommand(if (builtin.target.os.tag == .windows) &.{
        "cmd",
        "/c",
        "taskkill",
        "/F",
        "/IM",
        "ContentManager.exe",
        "2>nul",
        "||",
        "exit",
        "/b",
        "0",
    } else unreachable);
    const preKillPipelineParseProcessCmd = b.addSystemCommand(if (builtin.target.os.tag == .windows) &.{
        "cmd",
        "/c",
        "taskkill",
        "/F",
        "/IM",
        "pipelineJsonParse.exe",
        "2>nul",
        "||",
        "exit",
        "/b",
        "0",
    } else unreachable);
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

    const root_path = b.build_root.path orelse "";

    // const compile_txt_generate = b.step("generate compile txt", "produce txt");

    const shader_need_compile_txt = "shaders.txt";
    const compile_txt_shaders_cmd = b.addRunArtifact(selectModifiedFileToTxt);
    compile_txt_shaders_cmd.addArg(b.build_root.path.?);
    compile_txt_shaders_cmd.addArg("Shaders");
    compile_txt_shaders_cmd.addArg(b.fmt("build_script/{s}", .{shader_need_compile_txt}));

    const pipeline_need_compile_txt = "pipeline.txt";
    const compile_txt_pipeline_cmd = b.addRunArtifact(selectModifiedFileToTxt);
    compile_txt_pipeline_cmd.addArg(b.build_root.path.?);
    compile_txt_pipeline_cmd.addArg("Pipeline");
    compile_txt_pipeline_cmd.addArg(b.fmt("build_script/{s}", .{pipeline_need_compile_txt}));

    const sampler_need_compile_txt = "sampler.txt";
    const compile_txt_sampler_cmd = b.addRunArtifact(selectModifiedFileToTxt);
    compile_txt_sampler_cmd.addArg(b.build_root.path.?);
    compile_txt_sampler_cmd.addArg("Pipeline");
    compile_txt_sampler_cmd.addArg(b.fmt("build_script/{s}", .{sampler_need_compile_txt}));

    const shader_compile = b.step("shader compile", "compile shader");
    const script_cmd = b.addSystemCommand(&[_][]const u8{
        "build_script/shaderCompile.bat",
        "Shaders",
        "zig-out/bin/Content/Shaders",
        b.fmt("build_script/{s}", .{shader_need_compile_txt}),
    });

    const pipeline_compile = b.step("pipeline parse", "parse pipeline json");
    const pipeline_script_cmd = b.addSystemCommand(&[_][]const u8{
        "build_script/pipelineParse.bat",
        "Pipeline",
        "zig-out/bin/Content/Shaders",
        "zig-out/bin/Content/Pipeline",
        b.fmt("build_script/{s}", .{pipeline_need_compile_txt}),
    });

    const sampler_compile = b.step("sampler compile", "compile sampler");
    const sampler_script_cmd = b.addSystemCommand(&[_][]const u8{
        "build_script/samplerParse.bat",
        "Sampler",
        "zig-out/bin/Content/Sampler",
        b.fmt("build_script/{s}", .{sampler_need_compile_txt}),
    });

    const runContenManager = b.step("run content manager", "collect resources");
    const runContenManager_cmd = b.addRunArtifact(contenManager);
    if (force_update)
        runContenManager_cmd.addArg("-f");
    // runContenManager_cmd.addArg(b.getInstallPath(.bin, "ContentManager"));

    const runGenFileNameIdExe = b.step("create hash map", "create filename id static string hash map");
    const runGenFileNameIdExe_cmd = b.addRunArtifact(genFileNameIDexe);
    runGenFileNameIdExe_cmd.addArg(b.fmt("{s}/{s}", .{ root_path, "src/fileSystem/fileNameID.zig" }));

    const run_gen_exe = b.addRunArtifact(gen_exe);
    run_gen_exe.addArg(b.fmt("{s}/{s}", .{ root_path, "src/video/resultToError.zig" }));

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
    preKillContentManagerProcessCmd.step.dependOn(&preKillGameProcessCmd.step);

    shader_compile.dependOn(&preKillContentManagerProcessCmd.step);
    shader_compile.dependOn(&preKillPipelineParseProcessCmd.step);
    shader_compile.dependOn(&script_cmd.step);
    shader_compile.dependOn(&compile_txt_pipeline_cmd.step);
    shader_compile.dependOn(&compile_txt_sampler_cmd.step);
    script_cmd.step.dependOn(&compile_txt_shaders_cmd.step);

    pipeline_script_cmd.step.dependOn(shader_compile);
    pipeline_script_cmd.step.dependOn(&pipelineJsonParse_exe.step);
    pipeline_script_cmd.step.dependOn(&compile_txt_pipeline_cmd.step);
    pipeline_compile.dependOn(&pipeline_script_cmd.step);

    sampler_script_cmd.step.dependOn(&compile_txt_sampler_cmd.step);
    sampler_script_cmd.step.dependOn(&samplerJsonPrase_exe.step);
    sampler_compile.dependOn(&sampler_script_cmd.step);

    // contenManager.step.dependOn(&copy_blake3_header.step);
    runContenManager.dependOn(&runContenManager_cmd.step);
    runContenManager_cmd.step.dependOn(pipeline_compile);
    runContenManager_cmd.step.dependOn(sampler_compile);
    runContenManager_cmd.step.dependOn(&contenManager_install.step);

    runGenFileNameIdExe.dependOn(&runGenFileNameIdExe_cmd.step);
    runGenFileNameIdExe_cmd.step.dependOn(runContenManager);

    run_gen_exe.step.dependOn(&gen_exe.step);

    // copy_sdl3_header.step.dependOn(sdl3_lib_install_step);

    // exe.step.dependOn(&copy_sdl3_header.step);
    exe.step.dependOn(sdl3_lib_install_step);
    exe.step.dependOn(&run_gen_exe.step);
    exe.step.dependOn(runGenFileNameIdExe);
    exe.step.dependOn(runContenManager);

    waf.step.dependOn(&exe.step);
    b.getInstallStep().dependOn(&waf.step);

    run_cmd.step.dependOn(b.getInstallStep());
    run_cmd.step.dependOn(&pre_run_message_cmd.step);
    run_step.dependOn(&run_cmd.step);

    test_step.dependOn(&run_exe_unit_tests.step);
}
