const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

const Handles = @import("handle");
const Handle = Handles.Handle;

const pass = @import("pass");
const vertices2D = @import("vertices");
const cglm = @import("cglm");
const textureSet = @import("textureSet");
const instances1 = @import("instance");
const PassGroupMapping = @import("passGroupMapping");

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
    passes: *pass,
    pTextureSet: *textureSet,
    vertices: *vertices2D,
    instances: *instances1,
    passGroupMapping: *PassGroupMapping,
) !void {
    try self.mutex.lock(io);
    defer self.mutex.unlock(io);

    for (self.instances.items) |item| {
        // std.log.debug("item: pass {*}, pos {any}, scale {any}, rotation {any}, textures {any}, model {any}", .{
        //     item.pass,
        //     item.pos,
        //     item.scale,
        //     item.rotation,
        //     item.textures,
        //     item.model,
        // });

        if (std.mem.eql(u8, "indirect2D", item.pass.name)) {
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
        } else if (std.mem.eql(u8, "i_feather", item.pass.name)) {
            const ins = try instances.add(
                null,
                item.pos,
                item.rotation,
                item.scale,
                null,
            );
            const idx1 = Handles.getIndex(@ptrCast(ins)) orelse continue;
            const idx2 = Handles.getIndex(item.model.?) orelse continue;

            const tidx = pTextureSet.getDescriptorSetIndex(@ptrCast(item.textures[0]));

            const cs_mesh_drawCount = try passGroupMapping.add(item.pass.name, .{
                .instanceID = idx1,
                .meshID = idx2,
            });
            const pU32 = @as(*u32, @ptrCast(@alignCast(item.pass.userdata.?)));
            pU32.* = cs_mesh_drawCount;

            item.pass.setPushConstants(2, @constCast(&std.mem.toBytes(tidx)), 64);
            passes.enablePass("i_feather");
        }
    }

    for (self.instances.items) |item| {
        self.instances.allocator.free(item.textures);
    }
    self.instances.clearRetainingCapacity();
}
