const std = @import("std");

pub fn build(b: *std.Build) void {
    std.log.info("build libblake3.a", .{});

    const target = b.standardTargetOptions(.{ .default_target = .{} });
    const optimize = b.standardOptimizeOption(.{ .preferred_optimize_mode = .ReleaseFast });

    const blake_dep = b.dependency("blake3", .{});
    const blake_src = blake_dep.path("c");

    const blake3_module = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    // blake3_module.addIncludePath(blake_src);
    const common_c_files = [_][]const u8{
        "blake3.c",
        "blake3_dispatch.c",
        "blake3_portable.c",
    };
    blake3_module.addCSourceFiles(.{
        // files are resolved against the upstream BLAKE3 sources directly
        .root = blake_src,
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
                b.fmt("blake3_sse2_x86-64_{s}.S", .{flavor}),
                b.fmt("blake3_sse41_x86-64_{s}.S", .{flavor}),
                b.fmt("blake3_avx2_x86-64_{s}.S", .{flavor}),
                b.fmt("blake3_avx512_x86-64_{s}.S", .{flavor}),
            };
            blake3_module.addCSourceFiles(.{
                .root = blake_src,
                .files = &asm_files,
                .language = .assembly,
            });
        } else {
            blake3_module.addCSourceFile(.{
                .file = blake_src.path(b, "blake3_sse2.c"),
                .flags = &.{"-msse2"},
                .language = .c,
            });
            blake3_module.addCSourceFile(.{
                .file = blake_src.path(b, "blake3_sse41.c"),
                .flags = &.{"-msse4.1"},
                .language = .c,
            });
            blake3_module.addCSourceFile(.{
                .file = blake_src.path(b, "blake3_avx2.c"),
                .flags = &.{"-mavx2"},
                .language = .c,
            });
            blake3_module.addCSourceFile(.{
                .file = blake_src.path(b, "blake3_avx512.c"),
                .flags = &.{ "-mavx512f", "-mavx512vl" },
                .language = .c,
            });
        }
    }

    const lib = b.addLibrary(.{
        .root_module = blake3_module,
        .linkage = .static,
        .name = "blake3",
    });
    const blake3_c = b.addTranslateC(.{
        .root_source_file = blake_src.path(b, "blake3.h"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    _ = blake3_c.addModule("blake3_c");

    b.installArtifact(lib);
}
