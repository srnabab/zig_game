const std = @import("std");

const global = @import("global");
const Handles = @import("handle");
const Handle = Handles.Handle;

const vertexStruct = @import("vertexStruct");

const VkStruct = @import("video");
const processRender = @import("processRender");
// const OneTimeCommand = processRender.oneTimeCommand;
const Commands = processRender.commands;
const vk = VkStruct.vk;

const Mesh = vertexStruct.Mesh;
pub const Mesh_t = *opaque {};

const Self = @This();

const TotalAndCount = struct {
    total: u32,
    count: u32,
};

meshletBuffer: VkStruct.Buffer_t,
meshlet: TotalAndCount,
verticesBuffer: VkStruct.Buffer_t,
vertices: TotalAndCount,
meshletVerticesBuffer: VkStruct.Buffer_t,
meshletVertices: TotalAndCount,
meshletTrianglesBuffer: VkStruct.Buffer_t,
meshletTriangles: TotalAndCount,
meshesBuffer: VkStruct.Buffer_t,

meshs: std.array_list.Managed(Mesh),
meshMap: std.AutoHashMap(u32, Mesh_t),
vulkan: *VkStruct,
handles: *global.HandlesType,

updated: bool = false,

updateStart: usize = 0,
updateEnd: usize = 0,

pub fn init(
    allocator: std.mem.Allocator,
    vulkan: *VkStruct,
    handles: *global.HandlesType,
    buffers: [5]VkStruct.Buffer_t,
) Self {
    const meshletContent = vulkan.buffers.getBufferContent(buffers[0]);
    const verticesContent = vulkan.buffers.getBufferContent(buffers[1]);
    const meshletVerticesContent = vulkan.buffers.getBufferContent(buffers[2]);
    const meshletTrianglesContent = vulkan.buffers.getBufferContent(buffers[3]);

    return Self{
        .meshletBuffer = buffers[0],
        .meshlet = .{ .total = @intCast(meshletContent.size / meshletContent.stride), .count = 0 },
        .verticesBuffer = buffers[1],
        .vertices = .{ .total = @intCast(verticesContent.size / verticesContent.stride), .count = 0 },
        .meshletVerticesBuffer = buffers[2],
        .meshletVertices = .{ .total = @intCast(meshletVerticesContent.size / meshletVerticesContent.stride), .count = 0 },
        .meshletTrianglesBuffer = buffers[3],
        .meshletTriangles = .{ .total = @intCast(meshletTrianglesContent.size / meshletTrianglesContent.stride), .count = 0 },
        .meshesBuffer = buffers[4],
        .meshMap = .init(allocator),
        .meshs = .init(allocator),
        .vulkan = vulkan,
        .handles = handles,
    };
}

pub fn deinit(self: *Self) void {
    self.meshMap.deinit();
    self.meshs.deinit();
}

pub fn addMesh(
    self: *Self,
    meshletSize: u64,
    verticesSize: u64,
    meshletVerticesSize: u64,
    meshletTrianglesSize: u64,
    verticeStride: u32,
) !u32 {
    // @breakpoint();
    const counts = [_]u64{
        meshletSize / @sizeOf(vertexStruct.Meshlet),
        verticesSize / verticeStride,
        meshletVerticesSize / @sizeOf(u32),
        meshletTrianglesSize / @sizeOf(u8),
    };

    var offsets = [_]u64{ 0, 0, 0, 0 };

    const totalAndCounts = [_]*TotalAndCount{
        &self.meshlet,
        &self.vertices,
        &self.meshletVertices,
        &self.meshletTriangles,
    };

    for (0..4) |i| {
        offsets[i] = totalAndCounts[i].count;
        totalAndCounts[i].count += @intCast(counts[i]);
    }

    try self.meshs.append(.{
        .meshletCount = @intCast(counts[0]),
        .meshletOffset = @intCast(offsets[0]),
        .verticesOffset = @intCast(offsets[1]),
        .meshletVerticesOffset = @intCast(offsets[2]),
        .meshletTrianglesOffset = @intCast(offsets[3]),
        .verticeStride = verticeStride,
    });
    const index = self.meshs.items.len - 1;

    self.updated = true;

    if (self.updateStart == 0) {
        self.updateStart = index;
        self.updateEnd = index;
    } else {
        self.updateEnd = @max(self.updateEnd, index);
        self.updateStart = @min(self.updateStart, index);
    }

    return @intCast(index);
}

pub fn upload(self: *Self, commands: *Commands) !void {
    if (!self.updated) {
        return;
    }

    self.updated = false;

    const meshs = self.meshs.items[self.updateStart .. self.updateEnd + 1];
    std.log.debug("mesh count {d}", .{meshs[0].meshletCount});

    const stagingBuffer = try self.vulkan.createBufferByUsage(
        meshs.len * @sizeOf(Mesh),
        0,
        .staging,
        false,
        null,
    );
    self.vulkan.buffers.copyDataToMapped(stagingBuffer, 0, vertexStruct.Mesh, meshs);

    var copyRegion = [1]vk.VkBufferCopy2{.{
        .sType = vk.VK_STRUCTURE_TYPE_BUFFER_COPY_2,
        .pNext = null,
        .srcOffset = 0,
        .dstOffset = self.updateStart * @sizeOf(Mesh),
        .size = meshs.len * @sizeOf(Mesh),
    }};

    try commands.cacheCommand(.{ .copyBuffer = .{
        .srcBuffer = stagingBuffer,
        .dstBuffer = self.meshesBuffer,
        .regions = &copyRegion,
    } });
}
