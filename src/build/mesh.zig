const std = @import("std");
const Config = @import("config.zig").Config;

/// 自定义结构体模块名, 也是引擎侧 @import 时使用的名字
pub const name = "mesh";

/// 构建 src/customStruct/mesh.zig 模块并完成依赖接线
pub fn build(cfg: Config) *std.Build.Module {
    const m = cfg.b.createModule(.{
        .root_source_file = cfg.b.path("src/customStruct/mesh.zig"),
        .target = cfg.target,
        .optimize = cfg.optimize,
    });

    // 上游: 源码自身 @import 的模块
    m.addImport("global", cfg.global);
    m.addImport("handle", cfg.handle);
    m.addImport("vertexStruct", cfg.vertexStruct);
    m.addImport("video", cfg.video);
    m.addImport("processRender", cfg.processRender);

    // 下游: 引擎中需要 @import("mesh") 的消费者模块
    cfg.exe.addImport("mesh", m);
    cfg.resource.addImport("mesh", m);
    cfg.resourceProcess.addImport("mesh", m);

    return m;
}
