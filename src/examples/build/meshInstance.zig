const std = @import("std");
const Config = @import("config.zig").Config;

pub const name = "meshInstance";

pub fn build(cfg: Config) *std.Build.Module {
    const m = cfg.b.createModule(.{
        .root_source_file = cfg.b.path("src/customStruct/meshInstance.zig"),
        .target = cfg.target,
        .optimize = cfg.optimize,
    });

    m.addImport("global", cfg.global);
    m.addImport("handle", cfg.handle);
    m.addImport("processRender", cfg.processRender);
    m.addImport("vertexStruct", cfg.vertexStruct);
    m.addImport("video", cfg.video);

    cfg.exe.addImport("meshInstance", m);
    cfg.resource.addImport("meshInstance", m);
    cfg.resourceProcess.addImport("meshInstance", m);

    return m;
}
