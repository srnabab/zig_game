const VkStruct = @import("video");
const std = @import("std");
const Allocator = std.mem.Allocator;
const OneTimeCommand = @import("processRender").oneTimeCommand;
const TextureSet = @import("textureSet");
const Handles = @import("handle");

pub const databaseName = "Content.db";

pub const StackMemorySize = 512 * 1024;
pub const vertexCount = 4;
pub const indexCount = 6;

pub var down = false;
pub var vulkan: *VkStruct = undefined;

pub var graphic: *OneTimeCommand = undefined;
pub var textureSet: *TextureSet = undefined;

pub const HandlesType = Handles.Handles(10240, .Once);
