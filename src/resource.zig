const std = @import("std");
const vk = @import("vk");
const vma = @import("vma");
const VkStruct = @import("video");
const Handles = @import("handle");
const Texture_t = @import("textureSet").Texture_t;

pub const ResourceType = enum {
    texture,
    others,
};

pub const Resource = union(ResourceType) {
    texture: ResourceTexture,
    others: ResourceOthers,
};

pub const ResourceTexture = struct {
    width: u32,
    height: u32,
    fileID: u32,
    format: vk.VkFormat, // 16
    vkImage: vk.VkImage,
    vkImageView: vk.VkImageView,
    allocation: vma.VmaAllocation,
    staginfBuffer: VkStruct.Buffer_t,
    handle: Handles.Handle,
};

pub const ResourceOthers = struct {
    fileID: u32,
    mem: []u8,
    handle: Handles.Handle,
};

pub const ResourcePosition2D = struct {
    x: u32,
    y: u32,
    width: u32,
    height: u32,
    texture: Texture_t,
};
