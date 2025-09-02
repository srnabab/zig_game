const sqlDB = @import("sqlDb");
const sqlite = sqlDB.sqlite;
const std = @import("std");
const global = @import("global");
const assert = std.debug.assert;
const tables = @import("tables");
const base = @import("fileSystemBase.zig");

pub fn init() void {
    base.init(global.databaseName);
}

pub fn getFile(fileName: []const u8) !std.fs.File {
    return base.getFile(fileName, global.cwd);
}

const FileType = base.FileType;

pub fn getFileType(name: []const u8) sqlDB.sqliteError!FileType {
    return base.getFileType(name);
}

const vk = @cImport(@cInclude("vulkan/vulkan.h"));

pub const PipelineShaderInfo = base.PipelineShaderInfo;

pub fn getShaderLoadParameter(name: []const u8) !PipelineShaderInfo {
    return base.getShaderLoadParameter(name, global.gpa, global.cwd);
}

pub fn deinit() void {
    base.deinit();
}
