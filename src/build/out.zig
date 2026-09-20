const std = @import("std");
const Config = @import("config.zig").Config;

const vertices = @import("vertices.zig");
const meshInstance = @import("meshInstance.zig");
const mesh = @import("mesh.zig");
const passGroupMapping = @import("passGroupMapping.zig");
const renderData = @import("renderData.zig");

const Entry = struct {
    /// 模块名, 同时对应 Modules 结构体的字段名
    name: []const u8,
    build: fn (Config) *std.Build.Module,
};

/// 自定义结构体构建函数清单: 新增结构体时在此追加一项即可,
/// build.zig 无需任何改动
pub const list = [_]Entry{
    .{ .name = vertices.name, .build = vertices.build },
    .{ .name = meshInstance.name, .build = meshInstance.build },
    .{ .name = mesh.name, .build = mesh.build },
    .{ .name = passGroupMapping.name, .build = passGroupMapping.build },
    .{ .name = renderData.name, .build = renderData.build },
};

/// 构建完成后暴露给引擎侧引用的模块集合
pub const Modules = struct {
    vertices: *std.Build.Module,
    meshInstance: *std.Build.Module,
    mesh: *std.Build.Module,
    passGroupMapping: *std.Build.Module,
    renderData: *std.Build.Module,
};

/// 依次调用 list 中的构建函数, 完成创建 + 上游/下游接线
pub fn build(cfg: Config) void {
    _ = vertices.build(cfg);
    _ = meshInstance.build(cfg);
    _ = mesh.build(cfg);
    _ = passGroupMapping.build(cfg);
    _ = renderData.build(cfg);
}
