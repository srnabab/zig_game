const std = @import("std");
pub const BufferUsage = @import("processRender").drawC.BufferUsage;
const PushConstantPack = @import("processRender").drawC.PushConstantPack;
const Commands = @import("processRender").commands;
const VkStruct = @import("video");
const vk = @import("vulkan");
const PassImp = @import("passImp");
const TextureSet = @import("textureSet");

const emptyVTable = VTable{
    .init = initEmpty,
    .setPushConstants = setPushConstantsEmpty,
    .addCommand = addCommandEmpty,
};
fn initEmpty(
    userdata: ?*anyopaque,
    pass: *PassImp.Pass,
    vulkan: *VkStruct,
    gpa: std.mem.Allocator,
) !void {
    _ = userdata;
    _ = pass;
    _ = vulkan;
    _ = gpa;
}
fn setPushConstantsEmpty(userdata: ?*anyopaque, pValues: *anyopaque) void {
    _ = userdata;
    _ = pValues;
}
fn addCommandEmpty(
    userdata: ?*anyopaque,
    pass: *PassImp.Pass,
    vulkan: *VkStruct,
    textureSet: *TextureSet,
    commands: *Commands,
    gpa: std.mem.Allocator,
) !void {
    _ = userdata;
    _ = pass;
    _ = vulkan;
    _ = textureSet;
    _ = commands;
    _ = gpa;
}

pub const Buffer = struct {
    name: []const u8,
    initSize: u64,
    usage: BufferUsage,
    stride: u64,
};

pub const Pipeline = struct {
    name: []const u8,
    isMesh: bool,
};

pub const Stage = enum(u8) {
    vert,
    frag,
    comp,
    mesh,
    task,
};

pub const VTable = struct {
    init: *const fn (
        userdata: ?*anyopaque,
        pass: *PassImp.Pass,
        vulkan: *VkStruct,
        gpa: std.mem.Allocator,
    ) anyerror!void,

    setPushConstants: *const fn (
        userdata: ?*anyopaque,
        pushConstantMem: *anyopaque,
    ) void,

    addCommand: *const fn (
        userdata: ?*anyopaque,
        pass: *PassImp.Pass,
        vulkan: *VkStruct,
        textureSet: *TextureSet,
        commands: *Commands,
        gpa: std.mem.Allocator,
    ) anyerror!void,
};

pub const Pass = struct {
    name: []const u8,
    buffers: []Buffer,
    pipeline: ?Pipeline = null,
    pushConstant: PushConstantPack,

    vtable: *const VTable = &emptyVTable,
};
