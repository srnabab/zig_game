const std = @import("std");
const Config = @import("config.zig").Config;

pub const name = "vertices";

pub fn build(cfg: Config) *std.Build.Module {
    const m = cfg.b.createModule(.{
        .root_source_file = cfg.b.path("src/customStruct/vertices.zig"),
        .target = cfg.target,
        .optimize = cfg.optimize,
    });

    m.addImport("video", cfg.video);
    m.addImport("vertexStruct", cfg.vertexStruct);
    m.addImport("processRender", cfg.processRender);

    cfg.exe.addImport("vertices", m);
    cfg.resourceProcess.addImport("vertices", m);

    return m;
}
