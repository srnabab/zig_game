const std = @import("std");
const Config = @import("config.zig").Config;

pub const name = "renderData";

pub fn build(cfg: Config) *std.Build.Module {
    const m = cfg.b.createModule(.{
        .root_source_file = cfg.b.path("src/customStruct/renderData.zig"),
        .target = cfg.target,
        .optimize = cfg.optimize,
    });

    m.addImport("handle", cfg.handle);
    m.addImport("pass", cfg.pass);
    m.addImport("u8pack", cfg.u8pack);

    cfg.exe.addImport("renderData", m);
    cfg.resourceProcess.addImport("renderData", m);

    return m;
}
