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

buffer_countMap: std.AutoHashMap(VkStruct.Buffer_t, TotalAndCount),
meshs: std.array_list.Managed(Mesh),
meshMap: std.AutoHashMap(u32, Mesh_t),
vulkan: *VkStruct,
handles: *global.HandlesType,

updated: bool = false,

updateStart: usize = 0,
updateEnd: usize = 0,

pub fn init(allocator: std.mem.Allocator, vulkan: *VkStruct, handles: *global.HandlesType) Self {
    return Self{
        .buffer_countMap = .init(allocator),
        .meshMap = .init(allocator),
        .meshs = .init(allocator),
        .vulkan = vulkan,
        .handles = handles,
    };
}

pub fn deinit(self: *Self) void {
    self.buffer_countMap.deinit();
    self.meshMap.deinit();
    self.meshs.deinit();
}

pub fn addMesh(
    self: *Self,
    fileID: u32,
    meshletBuffer: VkStruct.Buffer_t,
    meshletSize: u64,
    verticesBuffer: VkStruct.Buffer_t,
    verticesSize: u64,
    meshletVerticesBuffer: VkStruct.Buffer_t,
    meshletVerticesSize: u64,
    meshletTrianglesBuffer: VkStruct.Buffer_t,
    meshletTrianglesSize: u64,
    verticeStride: u32,
    handle: ?Handle,
) !Mesh_t {
    if (self.meshMap.get(fileID)) |mesh| {
        return mesh;
    }

    const meshletCount = meshletSize / @sizeOf(vertexStruct.Meshlet);
    const verticesCount = verticesSize / verticeStride;
    const meshletVerticesCount = meshletVerticesSize / @sizeOf(u32);
    const meshletTrianglesCount = meshletTrianglesSize / @sizeOf(u8);

    const counts = [_]u64{
        meshletCount,
        verticesCount,
        meshletVerticesCount,
        meshletTrianglesCount,
    };

    const buffers = [_]VkStruct.Buffer_t{
        meshletBuffer,
        verticesBuffer,
        meshletVerticesBuffer,
        meshletTrianglesBuffer,
    };

    const strides = [_]u64{
        @sizeOf(vertexStruct.Meshlet),
        verticeStride,
        @sizeOf(u32),
        @sizeOf(u8),
    };

    var offsets = [_]u64{ 0, 0, 0, 0 };

    for (0..4) |i| {
        var getOrPut = try self.buffer_countMap.getOrPut(buffers[i]);
        if (!getOrPut.found_existing) {
            const bufferContent = self.vulkan.buffers.getBufferContent(buffers[i]);
            if (bufferContent.allocation == .virtual) {
                const bufferContent2 = self.vulkan.buffers.getBufferContent(bufferContent.queue.ref);

                getOrPut.value_ptr.* = .{
                    .total = @intCast(bufferContent2.size / strides[i]),
                    .count = 0,
                };
            } else {
                getOrPut.value_ptr.* = .{
                    .total = @intCast(bufferContent.size / strides[i]),
                    .count = 0,
                };
            }
        }

        offsets[i] = getOrPut.value_ptr.count;
        getOrPut.value_ptr.count += @intCast(counts[i]);
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

    const finalHandle = bl: {
        if (handle) |h| {
            self.handles.setIndex(h, @intCast(index));

            break :bl h;
        } else {
            break :bl self.handles.createHandle(@intCast(index), .mesh);
        }
    };

    try self.meshMap.put(fileID, @ptrCast(finalHandle));

    self.updated = true;

    if (self.updateStart == 0) {
        self.updateStart = index;
        self.updateEnd = index;
    } else {
        self.updateEnd = @max(self.updateEnd, index);
        self.updateStart = @min(self.updateStart, index);
    }

    return @ptrCast(finalHandle);
}

pub fn getMesh(self: *Self, fileID: u32) !Mesh_t {
    return self.meshMap.get(fileID) orelse return error.notFound;
}

pub fn upload(self: *Self, commands: *Commands, buffer: VkStruct.Buffer_t) !void {
    if (!self.updated) {
        return;
    }

    self.updated = false;

    const meshs = self.meshs.items[self.updateStart .. self.updateEnd + 1];

    const stagingBuffer = try self.vulkan.createBufferByUsage(
        meshs.len * @sizeOf(Mesh),
        0,
        .staging,
        false,
    );

    var copyRegion = [1]vk.VkBufferCopy2{.{
        .sType = vk.VK_STRUCTURE_TYPE_BUFFER_COPY_2,
        .pNext = null,
        .srcOffset = 0,
        .dstOffset = self.updateStart * @sizeOf(Mesh),
        .size = meshs.len * @sizeOf(Mesh),
    }};

    try commands.cacheCommand(.{ .copyBuffer = .{
        .srcBuffer = stagingBuffer,
        .dstBuffer = buffer,
        .regions = &copyRegion,
    } });
}
