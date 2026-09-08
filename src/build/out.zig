const std = @import("std");
const Config = @import("config.zig").Config;

const vertices = @import("vertices.zig");
const instance = @import("instance.zig");
const mesh = @import("mesh.zig");

const Entry = struct {
    /// 模块名, 同时对应 Modules 结构体的字段名
    name: []const u8,
    build: fn (Config) *std.Build.Module,
};

/// 自定义结构体构建函数清单: 新增结构体时在此追加一项即可,
/// build.zig 无需任何改动
pub const list = [_]Entry{
    .{ .name = vertices.name, .build = vertices.build },
    .{ .name = instance.name, .build = instance.build },
    .{ .name = mesh.name, .build = mesh.build },
};

/// 构建完成后暴露给引擎侧引用的模块集合
pub const Modules = struct {
    vertices: *std.Build.Module,
    instance: *std.Build.Module,
    mesh: *std.Build.Module,
};

/// 依次调用 list 中的构建函数, 完成创建 + 上游/下游接线
pub fn build(cfg: Config) Modules {
    var result: Modules = undefined;
    inline for (list) |entry| {
        @field(result, entry.name) = entry.build(cfg);
    }
    return result;
}
