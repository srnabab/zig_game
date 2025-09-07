const std = @import("std");
const lazyP = @import("std").Build.LazyPath;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{ .default_target = .{} });
    const optimize = b.standardOptimizeOption(.{ .preferred_optimize_mode = .Debug });

    const shader_compile = b.step("shader compile", "compile shader");
    const script_cmd = b.addSystemCommand(&[_][]const u8{ "build_script/shaderCompile.bat", "Shaders", "zig-out/bin/Content/Shaders" });
    shader_compile.dependOn(&script_cmd.step);

    const pipeline_compile = b.step("pipeline parse", "parse pipeline json");
    const pipeline_script_cmd = b.addSystemCommand(&[_][]const u8{
        "build_script/pipelineParse.bat",
        "Pipeline",
        "zig-out/bin/Content/Shaders",
        "zig-out/bin/Content/Pipeline",
    });
    pipeline_compile.dependOn(&pipeline_script_cmd.step);

    const vk_mod = b.createModule(.{
        .root_source_file = b.path("src/vulkan.zig"),
        .target = target,
        .optimize = optimize,
    });
    vk_mod.addIncludePath(b.path("include"));

    const enum_c_mod = b.createModule(.{
        .root_source_file = b.path("src/enumFromC.zig"),
        .target = target,
        .optimize = optimize,
    });

    const spReflectModule = b.createModule(.{
        .root_source_file = b.path("src/sprivReflect/reflect.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    spReflectModule.addImport("EnumC", enum_c_mod);
    spReflectModule.addCSourceFile(.{ .file = b.path("src/sprivReflect/spirv_reflect.c"), .language = .c });
    spReflectModule.addIncludePath(b.path("include"));

    const pipelineJsonParse_mod = b.createModule(.{
        .root_source_file = b.path("src/video/pipeline/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    pipelineJsonParse_mod.addIncludePath(b.path("include"));
    pipelineJsonParse_mod.addImport("vulkan", vk_mod);
    pipelineJsonParse_mod.addImport("reflect", spReflectModule);
    pipelineJsonParse_mod.addImport("enumFromC", enum_c_mod);

    const pipelineJsonParse_exe = b.addExecutable(.{
        .name = "pipelineJsonParse",
        .root_module = pipelineJsonParse_mod,
    });
    b.installArtifact(pipelineJsonParse_exe);
    // pipeline_compile.dependOn(&pipelineJsonParse_exe.step);

    const sqliteModule = b.createModule(.{
        .root_source_file = b.path("src/sqlite3/sqliteDB.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    sqliteModule.addCSourceFile(.{ .file = b.path("src/sqlite3/sqlite3.c"), .language = .c });
    sqliteModule.addIncludePath(b.path("include"));

    const tables_mod = b.createModule(.{
        .root_source_file = b.path("src/tables.zig"),
        .target = target,
        .optimize = optimize,
    });
    tables_mod.addImport("sqlDb", sqliteModule);

    const contentManagerModule = b.createModule(.{
        .root_source_file = b.path("src/content_manager/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    contentManagerModule.addImport("reflect", spReflectModule);
    contentManagerModule.addImport("sqlDb", sqliteModule);
    contentManagerModule.addImport("tables", tables_mod);
    contentManagerModule.addIncludePath(b.path("include"));
    contentManagerModule.addIncludePath(b.path("../../../../msys64/mingw64/include/"));
    contentManagerModule.addLibraryPath(b.path("lib/"));
    contentManagerModule.addCSourceFile(.{ .file = b.path("src/content_manager/UUID.c"), .language = .c });

    const contenManager = b.addExecutable(.{
        .name = "ContentManager",
        .root_module = contentManagerModule,
    });

    contenManager.step.dependOn(shader_compile);
    contenManager.step.dependOn(pipeline_compile);

    contenManager.linkSystemLibrary2("blake3", .{ .preferred_link_mode = .static });
    contenManager.linkSystemLibrary2("sdl3", .{ .preferred_link_mode = .static });
    contenManager.linkSystemLibrary2("setupapi", .{ .preferred_link_mode = .static });
    contenManager.linkSystemLibrary2("imm32", .{ .preferred_link_mode = .static });
    contenManager.linkSystemLibrary2("version", .{ .preferred_link_mode = .static });
    contenManager.linkSystemLibrary2("winmm", .{ .preferred_link_mode = .static });
    contenManager.linkSystemLibrary2("ole32", .{ .preferred_link_mode = .static });
    contenManager.linkSystemLibrary2("gdi32", .{ .preferred_link_mode = .static });
    contenManager.linkSystemLibrary2("OleAut32", .{ .preferred_link_mode = .static });
    contenManager.linkSystemLibrary2("Rpcrt4", .{ .preferred_link_mode = .static });

    contenManager.linkSystemLibrary2("vulkan-1", .{});

    b.installArtifact(contenManager);

    const runContenManager = b.step("run content manager", "collect resources");
    const runContenManager_cmd = b.addRunArtifact(contenManager);
    runContenManager.dependOn(&runContenManager_cmd.step);
    runContenManager_cmd.addArg(b.getInstallPath(.bin, "ContentManager"));

    const gen_fileName_ID_mod = b.createModule(.{
        .root_source_file = b.path("src/fileSystem/fileName_ID/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    gen_fileName_ID_mod.addImport("sqlDb", sqliteModule);
    gen_fileName_ID_mod.addImport("tables", tables_mod);

    const genFileNameIDexe = b.addExecutable(.{
        .root_module = gen_fileName_ID_mod,
        .name = "genFileNameIdHashMap",
    });
    b.installArtifact(genFileNameIDexe);

    const runGenFileNameIdExe = b.step("create hash map", "create filename id static string hash map");
    const runGenFileNameIdExe_cmd = b.addRunArtifact(genFileNameIDexe);
    runGenFileNameIdExe.dependOn(&runGenFileNameIdExe_cmd.step);
    runGenFileNameIdExe_cmd.step.dependOn(runContenManager);
    runGenFileNameIdExe_cmd.addArg(b.getInstallPath(.bin, "genFileNameIdHashMap"));

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
    vulkanType_mod.addImport("enumFromC", enum_c_mod);
    vulkanType_mod.addImport("vulkan", vk_mod);

    const gen_mod = b.createModule(.{
        .root_source_file = b.path("src/video/gen.zig"),
        .target = target,
        .optimize = .ReleaseFast,
    });
    gen_mod.addImport("enumFromC", enum_c_mod);
    gen_mod.addImport("vulkanType", vulkanType_mod);

    const gen_exe = b.addExecutable(.{ .name = "gen", .root_module = gen_mod });
    gen_exe.addIncludePath(b.path("include"));
    gen_exe.addLibraryPath(b.path("lib"));
    gen_exe.linkLibC();

    gen_exe.linkSystemLibrary2("vulkan-1", .{});
    const run_gen_exe = b.addRunArtifact(gen_exe);

    run_gen_exe.step.dependOn(&gen_exe.step);

    // const gen_file = run_gen_exe.addOutputFileArg("resultToError.zig");
    const root_path = b.build_root.path orelse "";
    const gen_file_path = b.fmt("{s}/{s}", .{ root_path, "src/video/resultToError.zig" });
    run_gen_exe.addArg(b.fmt("{s}", .{gen_file_path}));

    const sdl_mod = b.createModule(.{
        .root_source_file = b.path("src/sdl.zig"),
        .target = target,
        .optimize = optimize,
    });
    sdl_mod.addIncludePath(b.path("include"));

    const sdlError_mod = b.createModule(.{
        .root_source_file = b.path("src/sdlError.zig"),
        .target = target,
        .optimize = optimize,
    });
    sdlError_mod.addImport("sdl", sdl_mod);

    // const pipeline_mod = b.createModule(.{
    //     .root_source_file = b.path("src/video/pipeline/pipeline.zig"),
    //     .target = target,
    //     .optimize = optimize,
    // });

    const translate_mod = b.createModule(.{
        .root_source_file = b.path("src/video/pipeline/translate.zig"),
        .target = target,
        .optimize = optimize,
    });
    // translate_mod.addImport("pipeline", pipeline_mod);
    translate_mod.addImport("vulkan", vk_mod);

    const video_mod = b.createModule(.{
        .root_source_file = b.path("src/video/initVulkan.zig"),
        .target = target,
        .optimize = optimize,
    });

    video_mod.addImport("sdl", sdl_mod);
    video_mod.addImport("sdlError", sdlError_mod);
    video_mod.addImport("vulkan", vk_mod);
    video_mod.addImport("translate", translate_mod);

    const global_mod = b.createModule(.{
        .root_source_file = b.path("src/global.zig"),
        .target = target,
        .optimize = optimize,
    });
    global_mod.addImport("video", video_mod);

    const fileSystem_mod = b.createModule(.{
        .root_source_file = b.path("src/fileSystem/fileSystem.zig"),
        .target = target,
        .optimize = optimize,
    });
    fileSystem_mod.addImport("sqlDb", sqliteModule);
    fileSystem_mod.addImport("global", global_mod);
    fileSystem_mod.addImport("tables", tables_mod);
    // pipeline_mod.addImport("fileSystem", fileSystem_mod);
    // pipeline_mod.addImport("global", global_mod);
    translate_mod.addImport("fileSystem", fileSystem_mod);
    translate_mod.addImport("global", global_mod);
    translate_mod.addImport("enumFromC", enum_c_mod);

    fileSystem_mod.addIncludePath(b.path("include"));

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "game",
        .root_module = exe_mod,
    });
    exe.step.dependOn(&run_gen_exe.step);
    exe.step.dependOn(runContenManager);
    exe.step.dependOn(runGenFileNameIdExe);

    const cpp_compileFlag = [_][]const u8{ "-std=c++17", "-g" };

    exe.addCSourceFile(.{ .file = b.path("src/steam_C/steamC.cpp"), .language = .cpp, .flags = &cpp_compileFlag });
    exe.addCSourceFile(.{ .file = b.path("src/steam_C/ISteamUserStats.cpp"), .language = .cpp, .flags = &cpp_compileFlag });

    video_mod.addImport("enumFromC", enum_c_mod);
    exe_mod.addImport("ECS", ecs_mod);
    exe_mod.addImport("video", video_mod);
    exe_mod.addImport("enumFromC", enum_c_mod);
    exe_mod.addImport("output", output_mod);
    exe_mod.addImport("fileSystem", fileSystem_mod);
    exe_mod.addImport("global", global_mod);
    exe_mod.addImport("sdlError", sdlError_mod);
    exe_mod.addImport("translate", translate_mod);
    // exe_mod.addImport("pipeline", pipeline_mod);

    exe.addIncludePath(b.path("include/"));
    exe.addLibraryPath(b.path("lib/"));
    exe.linkLibC();
    exe.linkSystemLibrary2("sdl3", .{ .preferred_link_mode = .static });
    exe.linkSystemLibrary2("steam_api64", .{});

    exe.linkSystemLibrary2("setupapi", .{ .preferred_link_mode = .static });
    exe.linkSystemLibrary2("imm32", .{ .preferred_link_mode = .static });
    exe.linkSystemLibrary2("version", .{ .preferred_link_mode = .static });
    exe.linkSystemLibrary2("winmm", .{ .preferred_link_mode = .static });
    exe.linkSystemLibrary2("ole32", .{ .preferred_link_mode = .static });
    exe.linkSystemLibrary2("gdi32", .{ .preferred_link_mode = .static });
    exe.linkSystemLibrary2("OleAut32", .{ .preferred_link_mode = .static });

    exe.linkSystemLibrary2("vulkan-1", .{});

    const waf = b.addWriteFiles();
    _ = waf.addCopyFile(exe.getEmittedAsm(), "main.asm");
    waf.step.dependOn(&exe.step);
    b.getInstallStep().dependOn(&waf.step);

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
