const std = @import("std");
const json = std.json;
const fs = std.fs;
const file = @import("fileSystem");
const global = @import("global");

pub fn parse(pipelineFileName: []const u8) !void {
    const pipelineFile = try file.getFile(pipelineFileName);
    defer pipelineFile.close();

    const metadata = try pipelineFile.metadata();
    var content = try global.gpa.alloc(u8, metadata.size());
    defer global.gpa.free(content);

    _ = try pipelineFile.readAll(content[0..metadata.size()]);

    var parser = try json.parseFromSlice(json.Value, global.gpa, content, .{});
    defer parser.deinit();

    const jsonValue = parser.value;

    std.log.debug("name {s}", .{jsonValue.string});
}
