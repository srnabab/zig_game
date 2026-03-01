pub const VkStruct = @import("video");
const std = @import("std");
const Allocator = std.mem.Allocator;
const OneTimeCommand = @import("processRender").oneTimeCommand;
const TextureSet = @import("textureSet");
const Handles = @import("handle");

pub const databaseName = "Content.db";

pub const StackMemorySize = 512 * 1024;
pub const vertexCount = 4;
pub const indexCount = 6;
pub const LOGICAL_HEIGHT = 600;
pub const LOGICAL_WEIGHT = 800;

pub const HandlesType = Handles.Handles(10240, .Once);

pub const Name = "Game";
pub const AppVersionMajor = 0;
pub const AppVersionMinor = 1;
pub const AppVersionPatch = 125;

pub const EngineName = "Engine";
pub const EngineVersionMajor = 0;
pub const EngineVersionMinor = 1;
pub const EngineVersionPatch = 125;
