const std = @import("std");
const Allocator = std.mem.Allocator;

pub const databaseName = "Content.db";

pub var gpa: Allocator = undefined;
pub var down = false;
pub var cwd: std.fs.Dir = undefined;
