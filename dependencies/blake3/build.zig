const std = @import("std");

// pub fn build 是 Zig 构建脚本的入口点
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{ .default_target = .{} });
    const optimize = b.standardOptimizeOption(.{ .preferred_optimize_mode = .ReleaseFast });

    const blake_dep = b.dependency("blake3", .{});
    const blake_src = blake_dep.path("c");

    const blake3_module = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    // blake3_module.addIncludePath(blake_dep.path("c"));
    const common_c_files = [_][]const u8{
        "c/blake3.c",
        "c/blake3_dispatch.c",
        "c/blake3_portable.c",
    };
    blake3_module.addCSourceFiles(.{
        .files = &common_c_files,
        .language = .c,
    });

    const no_simd = b.option(bool, "no-simd", "Disable all SIMD and build portable-only code") orelse false;

    if (no_simd) {
        // disable SIMD
        blake3_module.addCMacro("BLAKE3_NO_SSE2", "");
        blake3_module.addCMacro("BLAKE3_NO_SSE41", "");
        blake3_module.addCMacro("BLAKE3_NO_AVX2", "");
        blake3_module.addCMacro("BLAKE3_NO_AVX512", "");
    } else {
        const use_asm = b.option(bool, "asm", "Use assembly implementations (x86_64 only)") orelse true;

        if (use_asm and target.result.cpu.arch == .x86_64) {
            const os_tag = target.result.os.tag;

            const flavor = if (os_tag == .windows) "windows_gnu" else "unix";

            const asm_files = [_][]const u8{
                std.fmt.allocPrint(b.allocator, "c/blake3_sse2_x86-64_{s}.S", .{flavor}) catch unreachable,
                std.fmt.allocPrint(b.allocator, "c/blake3_sse41_x86-64_{s}.S", .{flavor}) catch unreachable,
                std.fmt.allocPrint(b.allocator, "c/blake3_avx2_x86-64_{s}.S", .{flavor}) catch unreachable,
                std.fmt.allocPrint(b.allocator, "c/blake3_avx512_x86-64_{s}.S", .{flavor}) catch unreachable,
            };
            blake3_module.addCSourceFiles(.{
                .files = &asm_files,
                .language = .assembly,
            });
        } else {
            blake3_module.addCSourceFile(.{
                .file = b.path("c/blake3_sse2.c"),
                .flags = &.{"-msse2"},
                .language = .c,
            });
            blake3_module.addCSourceFile(.{
                .file = b.path("c/blake3_sse41.c"),
                .flags = &.{"-msse4.1"},
                .language = .c,
            });
            blake3_module.addCSourceFile(.{
                .file = b.path("c/blake3_avx2.c"),
                .flags = &.{"-mavx2"},
                .language = .c,
            });
            blake3_module.addCSourceFile(.{
                .file = b.path("c/blake3_avx512.c"),
                .flags = &.{ "-mavx512f", "-mavx512vl" },
                .language = .c,
            });
        }
    }

    const copy_src = b.addSystemCommand(if (target.result.os.tag == .windows) &.{
        "cmd",
        "/c",
        "xcopy",
        blake_src.getPath(b),
        b.path("c").getPath(b),
        "/s",
        "/y",
        "/i",
        "/q",
    } else unreachable);

    const lib = b.addLibrary(.{
        .root_module = blake3_module,
        .linkage = .static,
        .name = "blake3",
    });

    const copy_header = b.addSystemCommand(if (target.result.os.tag == .windows) &.{
        "cmd", "/c", "copy", b.path("dependencies/blake3/c/blake3.h").getPath(b), b.path("../../include/blake3.h").getPath(b),
    } else unreachable);

    b.installArtifact(lib);
    const install_step = b.getInstallStep();

    install_step.dependOn(&copy_header.step);
    copy_header.step.dependOn(&lib.step);
    lib.step.dependOn(&copy_src.step);
}
