const std = @import("std");

/// customStruct build import
pub const Config = struct {
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,

    // ---- required from engine ----
    video: *std.Build.Module,
    processRender: *std.Build.Module,
    vertexStruct: *std.Build.Module,
    global: *std.Build.Module,
    handle: *std.Build.Module,
    u8pack: *std.Build.Module,
    pass: *std.Build.Module,

    // ---- used in engine ----
    exe: *std.Build.Module,
    resource: *std.Build.Module,
    resourceProcess: *std.Build.Module,
};
