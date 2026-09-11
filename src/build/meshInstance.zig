const std = @import("std");
const Config = @import("config.zig").Config;

/// 自定义结构体模块名, 也是引擎侧 @import 时使用的名字
pub const name = "meshInstance";

/// 构建 src/customStruct/meshInstance.zig 模块并完成依赖接线
pub fn build(cfg: Config) *std.Build.Module {
    const m = cfg.b.createModule(.{
        .root_source_file = cfg.b.path("src/customStruct/meshInstance.zig"),
        .target = cfg.target,
        .optimize = cfg.optimize,
    });

    // 上游: 源码自身 @import 的模块
    m.addImport("global", cfg.global);
    m.addImport("handle", cfg.handle);
    m.addImport("processRender", cfg.processRender);
    m.addImport("vertexStruct", cfg.vertexStruct);
    m.addImport("video", cfg.video);

    // 下游: 引擎中需要 @import("meshInstance") 的消费者模块
    cfg.exe.addImport("meshInstance", m);
    cfg.resource.addImport("meshInstance", m);
    cfg.resourceProcess.addImport("meshInstance", m);
    cfg.instances2.addImport("meshInstance", m);

    return m;
}
