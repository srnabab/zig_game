const std = @import("std");
pub const BufferUsage = @import("processRender").drawC.BufferUsage;
pub const PushConstantPack = @import("processRender").drawC.PushConstantPack;
const Commands = @import("processRender").commands;
const ExternalCommands = @import("processRender").externalCommands;
const VkStruct = @import("video");
const vk = @import("vulkan");
const PassImp = @import("passImp");
const TextureSet = @import("textureSet");

const Str = @import("u8pack").Str;

const emptyVTable = VTable{
    .init = initEmpty,
    .addCommand = addCommandEmpty,
};
fn initEmpty(
    userdata: *?*anyopaque,
    pass: *PassImp.Pass,
    vulkan: *VkStruct,
    commands: *ExternalCommands,
    gpa: std.mem.Allocator,
) !void {
    _ = userdata;
    _ = pass;
    _ = vulkan;
    _ = gpa;
    _ = commands;
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
    name: Str,
    parentName: ?Str,
    initSize: u64,
    usage: BufferUsage,
    stride: u64,
    residuentCapacity: u64,
    offset: u64 = 0,
};

pub const uboSlot = enum(u8) {
    ui,
    @"2d",
    @"3d",
};

pub const UBO = struct {
    name: Str,
    slot: uboSlot,
    size: u64,
};

pub const Pipeline = struct {
    name: Str,
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
        userdata: *?*anyopaque,
        pass: *PassImp.Pass,
        vulkan: *VkStruct,
        commands: *ExternalCommands,
        gpa: std.mem.Allocator,
    ) anyerror!void,

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
    name: Str,
    buffers: []Buffer,
    pipeline: ?[]Pipeline = null,
    pushConstant: []PushConstantPack = &.{},

    vtable: *const VTable = &emptyVTable,
};
