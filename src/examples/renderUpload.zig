const std = @import("std");
const Io = std.Io;

const VkStruct = @import("video");
const pass = @import("pass");
const textureSet = @import("textureSet");
const resourceProcess = @import("resourceProcess");

const processRender = @import("processRender");
const Commands = processRender.commands;

pub fn upload(io: Io, vulkan: *VkStruct, passes: *pass, pTextureSet: *textureSet, uctx: *resourceProcess.UserContext, commands: *Commands) !void {
    _ = passes;
    _ = pTextureSet;
    try uctx.vertices.uploadInstance(io, vulkan, commands);
    try uctx.instances1.upload(io, vulkan, commands);
    try uctx.passGroupMapping.upload(io, vulkan, commands);
    try uctx.meshes.upload(commands);
}
