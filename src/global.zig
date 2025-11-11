const VkStruct = @import("video");
const std = @import("std");
const Allocator = std.mem.Allocator;
const OneTimeCommand = @import("processRender").oneTimeCommand;
const TextureSet = @import("textureSet");
const Handle = @import("handle");

pub const databaseName = "Content.db";

pub const StackMemorySize = 512 * 1024;
pub const vertexCount = 4;
pub const indexCount = 6;

pub var gpa: *Allocator = undefined;
pub var down = false;
pub var cwd: std.fs.Dir = undefined;
pub var vulkan: *VkStruct = undefined;

pub var graphic: *OneTimeCommand = undefined;
pub var textureSet: *TextureSet = undefined;

pub var handles: Handle.Handles(10240, .Once) = undefined;
