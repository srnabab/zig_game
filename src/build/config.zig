const std = @import("std");

/// 自定义结构体(customStruct)构建上下文
///
/// 引擎侧 build.zig 把自定义结构体所需的引擎模块(上游)、
/// 以及需要回填注册的引擎消费者模块(下游)统一填入此结构体,
/// 再交给 src/build/out.zig 的 build()。
pub const Config = struct {
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,

    // ---- 上游: 自定义结构体源码自身 @import 的引擎模块 ----
    video: *std.Build.Module,
    processRender: *std.Build.Module,
    vertexStruct: *std.Build.Module,
    global: *std.Build.Module,
    handle: *std.Build.Module,
    u8pack: *std.Build.Module,
    pass: *std.Build.Module,

    // ---- 下游: 引擎中需要 @import 自定义结构体的消费者模块 ----
    exe: *std.Build.Module,
    resource: *std.Build.Module,
    resourceProcess: *std.Build.Module,
};
