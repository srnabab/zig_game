const std = @import("std");
const Config = @import("config.zig").Config;

pub const name = "passGroupMapping";

pub fn build(cfg: Config) *std.Build.Module {
    const m = cfg.b.createModule(.{
        .root_source_file = cfg.b.path("src/customStruct/passGroupMapping.zig"),
        .target = cfg.target,
        .optimize = cfg.optimize,
    });

    m.addImport("vertexStruct", cfg.vertexStruct);
    m.addImport("video", cfg.video);
    m.addImport("processRender", cfg.processRender);
    m.addImport("u8pack", cfg.u8pack);

    cfg.exe.addImport("passGroupMapping", m);
    cfg.resource.addImport("passGroupMapping", m);
    cfg.resourceProcess.addImport("passGroupMapping", m);

    return m;
}
