const std = @import("std");

// Mirrors the OBJS list of src/Makefile.
// NOTE: uimports.cpp is intentionally absent because creatwth.cpp `#include`s it.
// NOTE: disol*.cpp are 2-line files that define a DETOURS_*_OFFLINE_LIBRARY macro
//       and then `#include "disasm.cpp"`, so they compile disasm.cpp for each ISA.
const detours_sources = [_][]const u8{
    "src/detours.cpp",
    "src/modules.cpp",
    "src/disasm.cpp",
    "src/image.cpp",
    "src/creatwth.cpp",
    "src/disolx86.cpp",
    "src/disolx64.cpp",
    "src/disolia64.cpp",
    "src/disolarm.cpp",
    "src/disolarm64.cpp",
};

pub fn build(b: *std.Build) void {
    std.log.info("build libdetours.a", .{});

    const target = b.standardTargetOptions(.{ .default_target = .{ .abi = .msvc } });
    const optimize = b.standardOptimizeOption(.{ .preferred_optimize_mode = .ReleaseFast });

    // The Microsoft Detours source is fetched through build.zig.zon; only its
    // source tree is used here (it ships no build.zig of its own).
    const detours_dep = b.dependency("Detours", .{});

    // Mirrors the CFLAGS of src/Makefile from Microsoft Detours 4.0.1.
    //  - `compat_msvc.h` works around detours.h's `_MSC_VER < 1299` MSVC-only branch
    //    (see the header for details).
    //  - the ISA macro is required by detours.h but clang/mingw does not predefine it.
    // Allocated from the build arena because the slice must outlive build().
    const flags = [_][]const u8{
        "-std=c++17",                     "-fno-exceptions",         "-fno-rtti", "-DWIN32_LEAN_AND_MEAN",
        "-fno-sanitize=pointer-overflow", "-fno-sanitize=undefined",
        switch (target.result.cpu.arch) {
            .x86_64 => "-D_AMD64_=1",
            .x86 => "-D_X86_=1",
            .aarch64 => "-D_ARM64_=1",
            .arm => "-D_ARM_=1",
            else => @panic("unsupported architecture for Detours"),
        },
    };

    const detours_module = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    detours_module.addIncludePath(detours_dep.path("src"));

    for (detours_sources) |src| {
        detours_module.addCSourceFile(.{
            .file = detours_dep.path(src),
            .flags = &flags,
            .language = .cpp,
        });
    }

    const lib = b.addLibrary(.{
        .root_module = detours_module,
        .linkage = .static,
        .name = "detours",
    });

    b.installArtifact(lib);
}
