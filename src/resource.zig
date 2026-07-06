const std = @import("std");
const vk = @import("vk");
const vma = @import("vma");
const VkStruct = @import("video");
const Handles = @import("handle");
const Texture_t = @import("textureSet").Texture_t;
const vertexStruct = @import("vertexStruct");
const Mesh_t = @import("mesh").Mesh_t;
const Instance_t = @import("instance").Instance_t;

const vec3 = vertexStruct.vec3;

pub const ResourceType = enum {
    texture,
    position2D,
    mesh,
    instance,
    meshInstance,
    others,
};

pub const Resource = union(ResourceType) {
    texture: Texture,
    position2D: Position2D,
    mesh: Mesh,
    instance: Instance,
    meshInstance: MeshInstance,
    others: Others,
};

pub const MeshInstance = struct {
    passName: []const u8,
    mesh: Mesh_t,
    instance: Instance_t,
};

pub const Instance = struct {
    texture: ?Texture_t,
    handle: Handles.Handle,
    sampler: ?u32,
    pos: vec3,
    scale: vec3,
    rotation: vec3,
};

pub const Mesh = struct {
    fileID: u32,
    vertexStride: u32,
    handle: Handles.Handle,
    meshletStagingBuffer: VkStruct.Buffer_t,
    verticesStagingBuffer: VkStruct.Buffer_t,
    meshletVerticesStagingBuffer: VkStruct.Buffer_t,
    meshletTrianglesStagingBuffer: VkStruct.Buffer_t,
    meshletSize: u32,
    verticesSize: u32,
    meshletVerticesSize: u32,
    meshletTrianglesSize: u32,
};

pub const Texture = struct {
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

pub const Others = struct {
    fileID: u32,
    mem: []u8,
    handle: Handles.Handle,
};

pub const Position2D = struct {
    x: f32,
    y: f32,
    width: f32,
    height: f32,
    depth: f32,
    texture: Texture_t,
};
