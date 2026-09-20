const std = @import("std");
const Config = @import("config.zig").Config;

/// 自定义结构体模块名, 也是引擎侧 @import 时使用的名字
pub const name = "vertices";

/// 构建 src/customStruct/vertices.zig 模块并完成依赖接线
pub fn build(cfg: Config) *std.Build.Module {
    const m = cfg.b.createModule(.{
        .root_source_file = cfg.b.path("src/customStruct/vertices.zig"),
        .target = cfg.target,
        .optimize = cfg.optimize,
    });

    // 上游: 源码自身 @import 的模块
    m.addImport("video", cfg.video);
    m.addImport("vertexStruct", cfg.vertexStruct);
    m.addImport("processRender", cfg.processRender);

    // 下游: 引擎中需要 @import("vertices") 的消费者模块
    cfg.exe.addImport("vertices", m);
    cfg.resourceProcess.addImport("vertices", m);

    return m;
}
