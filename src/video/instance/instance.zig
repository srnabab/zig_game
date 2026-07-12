const std = @import("std");

const global = @import("global");
const Handles = @import("handle");
const Handle = Handles.Handle;

const processRender = @import("processRender");
const Commands = processRender.commands;

const vertexStruct = @import("vertexStruct");
const cglm = vertexStruct.cglm;

const vec3 = vertexStruct.vec3;
const mat4 = vertexStruct.mat4;

const VkStruct = @import("video");
const vk = VkStruct.vk;

const Self = @This();

const Instance = vertexStruct.Instance3D;
pub const Instance_t = *opaque {};

instances: std.array_list.Managed(Instance),
handles: *global.HandlesType,

updated: bool = false,
updateStart: u32 = 0,
updateEnd: u32 = 0,

pub fn init(allocator: std.mem.Allocator, handles: *global.HandlesType) Self {
    return Self{
        .instances = .init(allocator),
        .handles = handles,
    };
}

pub fn deinit(self: *Self) void {
    self.instances.deinit();
}

pub fn add(
    self: *Self,
    textureIndex: ?u32,
    samplerIndex: ?u32,
    pos: vec3,
    scale: vec3,
    rotation: vec3,
    handle: ?Handle,
) !Instance_t {
    const instance = try self.instances.addOne();
    const index: u32 = @intCast(self.instances.items.len - 1);

    instance.* = Instance{
        .matrix = undefined,
        .texIndex = textureIndex orelse 0,
        .samplerIndex = samplerIndex orelse 0,
    };

    var matrix: mat4 align(16) = undefined;

    var x = vec3{ 1.0, 0, 0 };
    // var y = vec3{ 0, 1.0, 0 };
    // var z = vec3{ 0, 0, 1.0 };

    cglm.glmc_mat4_identity(&matrix);

    cglm.glmc_translate(&matrix, @constCast(&pos));
    cglm.glmc_rotate(&matrix, rotation[0] * std.math.rad_per_deg, &x);
    // cglm.glmc_rotate(&matrix, rotation[1] * std.math.rad_per_deg, &y);
    // cglm.glmc_rotate(&matrix, rotation[2] * std.math.rad_per_deg, &z);
    cglm.glmc_scale(&matrix, @constCast(&scale));

    instance.matrix = matrix;

    const finalHandle = bl: {
        if (handle) |h| {
            self.handles.setIndex(h, index);

            break :bl h;
        } else {
            break :bl self.handles.createHandle(index, .instance);
        }
    };

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

pub fn upload(self: *Self, commands: *Commands, vulkan: *VkStruct, buffer: VkStruct.Buffer_t) !void {
    if (!self.updated) {
        return;
    }

    self.updated = false;

    const instances = self.instances.items[self.updateStart .. self.updateEnd + 1];

    const stagingBuffer = try vulkan.createBufferByUsage(
        instances.len * @sizeOf(Instance),
        0,
        .staging,
        false,
    );
    vulkan.buffers.copyDataToMapped(stagingBuffer, 0, Instance, instances);

    var copyRegion = [1]vk.VkBufferCopy2{.{
        .sType = vk.VK_STRUCTURE_TYPE_BUFFER_COPY_2,
        .pNext = null,
        .srcOffset = 0,
        .dstOffset = self.updateStart * @sizeOf(Instance),
        .size = instances.len * @sizeOf(Instance),
    }};

    try commands.cacheCommand(.{ .copyBuffer = .{
        .srcBuffer = stagingBuffer,
        .dstBuffer = buffer,
        .regions = &copyRegion,
    } });
}
