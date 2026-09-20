const std = @import("std");
const Config = @import("config.zig").Config;

/// 自定义结构体模块名, 也是引擎侧 @import 时使用的名字
pub const name = "renderData";

/// 构建 src/customStruct/renderData.zig 模块并完成依赖接线
pub fn build(cfg: Config) *std.Build.Module {
    const m = cfg.b.createModule(.{
        .root_source_file = cfg.b.path("src/customStruct/renderData.zig"),
        .target = cfg.target,
        .optimize = cfg.optimize,
    });

    // 上游: 源码自身 @import 的模块
    m.addImport("handle", cfg.handle);
    m.addImport("pass", cfg.pass);
    m.addImport("u8pack", cfg.u8pack);

    // 下游: 引擎中需要 @import("renderData") 的消费者模块
    cfg.exe.addImport("renderData", m);
    cfg.resourceProcess.addImport("renderData", m);

    return m;
}
