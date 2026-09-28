const std = @import("std");
const Config = @import("config.zig").Config;

pub const name = "mesh";

pub fn build(cfg: Config) *std.Build.Module {
    const m = cfg.b.createModule(.{
        .root_source_file = cfg.b.path("src/customStruct/mesh.zig"),
        .target = cfg.target,
        .optimize = cfg.optimize,
    });

    m.addImport("global", cfg.global);
    m.addImport("handle", cfg.handle);
    m.addImport("vertexStruct", cfg.vertexStruct);
    m.addImport("video", cfg.video);
    m.addImport("processRender", cfg.processRender);

    cfg.exe.addImport("mesh", m);
    cfg.resource.addImport("mesh", m);
    cfg.resourceProcess.addImport("mesh", m);

    return m;
}
