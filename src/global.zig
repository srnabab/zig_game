const VkStruct = @import("video");
const std = @import("std");
const Allocator = std.mem.Allocator;
const OneTimeCommand = @import("processRender").oneTimeCommand;

pub const databaseName = "Content.db";

pub var gpa: Allocator = undefined;
pub var down = false;
pub var cwd: std.fs.Dir = undefined;
pub var vulkan: VkStruct = undefined;

pub var graphic: OneTimeCommand = undefined;
