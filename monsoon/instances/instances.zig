const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

const Handles = @import("handle");
const Handle = Handles.Handle;

const pass = @import("pass");
const vertices2D = @import("vertices");
const cglm = @import("cglm");
const textureSet = @import("textureSet");

const vec3 = cglm.vec3;

pub const instance = struct {
    pass: *pass.Pass,
    pos: vec3,
    scale: vec3,
    rotation: vec3,
    textures: []Handle,
    model: ?Handle = null,
};

const Self = @This();

instances: std.array_list.Managed(instance),
mutex: Io.Mutex = .init,

pub fn init(gpa: Allocator) Self {
    return Self{
        .instances = .init(gpa),
    };
}

pub fn deinit(self: *Self) void {
    self.instances.deinit();
}

pub fn add(self: *Self, io: Io, item: instance) !void {
    try self.mutex.lock(io);
    defer self.mutex.unlock(io);

    return self.instances.append(item);
}

pub fn load(
    self: *Self,
    io: Io,
    // passes: *pass,
    pTextureSet: *textureSet,
    vertices: *vertices2D,
) !void {
    try self.mutex.lock(io);
    defer self.mutex.unlock(io);

    for (self.instances.items) |item| {
        std.log.debug("item: pass {*}, pos {any}, scale {any}, rotation {any}, textures {any}, model {any}", .{
            item.pass,
            item.pos,
            item.scale,
            item.rotation,
            item.textures,
            item.model,
        });

        try item.pass.useTexture(@ptrCast(item.textures[0]), self.instances.allocator);
        const textureContent = pTextureSet.getTextureCotent(@ptrCast(item.textures[0]));
        _ = try vertices.addInstance(
            item.pos[0],
            item.pos[1],
            item.scale[0] * @as(f32, @floatFromInt(textureContent.source_width)),
            item.scale[1] * @as(f32, @floatFromInt(textureContent.source_height)),
            item.pos[2],
            pTextureSet.getDescriptorSetIndex(@ptrCast(item.textures[0])),
        );
    }

    for (self.instances.items) |item| {
        self.instances.allocator.free(item.textures);
    }
    self.instances.clearRetainingCapacity();
}
