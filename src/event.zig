const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;

const global = @import("global");

const Handles = @import("handle");
const cglm = @import("cglm");
const u8pack = @import("u8pack");

const resourceProcess = @import("resourceProcess");
const UserContext = resourceProcess.UserContext;

const ViewBoundsAndTotalSpriteCount = @import("setPass").ViewBoundsAndTotalSpriteCount;

const vec3 = cglm.vec3;

const UpdateEventType = enum(u32) {
    createTest2d,
    createTest3d,
};

pub const UpdateEvent = union(UpdateEventType) {
    createTest2d: test2d,
    createTest3d: test3d,
};

const RenderEventType = enum(u32) {
    createStaticInteractableStub,
};

pub const RenderEvent = union(RenderEventType) {
    createStaticInteractableStub: staticInteractableStub,
};

const staticInteractableStub = struct {
    handle: Handles.Handle,
    pos: vec3,
};

pub const test2d = struct {
    pos: vec3,
    scale: vec3,
    rotation: vec3,
    rdata: u8pack.Str,
    handle: Handles.Handle,

    pub fn process(self: *const test2d, io: Io, gpa: Allocator, handles: *global.HandlesType, uctx: *UserContext) !void {
        const rdata = uctx.renderData.get(self.rdata) orelse return error.ReAdd;
        const viewBoundsAndTotalSpriteCount: *ViewBoundsAndTotalSpriteCount = @ptrCast(@alignCast(rdata.pass.userdata));

        try rdata.pass.useTexture(@ptrCast(rdata.textures[0]), gpa);
        const textureContent = uctx.pTextureSet.getTextureCotent(@ptrCast(rdata.textures[0]));
        const index = try uctx.vertices.addInstance(
            io,
            self.pos[0],
            self.pos[1],
            self.scale[0] * @as(f32, @floatFromInt(textureContent.source_width)),
            self.scale[1] * @as(f32, @floatFromInt(textureContent.source_height)),
            self.pos[2],
            uctx.pTextureSet.getDescriptorSetIndex(@ptrCast(rdata.textures[0])),
        );
        viewBoundsAndTotalSpriteCount.totalSpriteCount = uctx.vertices.getTotalCount();
        handles.setIndex(self.handle, index);
    }
};

const test3d = struct {
    pos: vec3,
    scale: vec3,
    rotation: vec3,
    rdata: u8pack.Str,
    handle: Handles.Handle,

    pub fn process(self: *const test3d, io: Io, gpa: Allocator, handles: *global.HandlesType, uctx: *UserContext) !void {
        _ = gpa;
        _ = handles;
        const rdata = uctx.renderData.get(self.rdata) orelse return error.ReAdd;

        const ins = try uctx.instances1.add(
            io,
            null,
            self.pos,
            self.scale,
            self.rotation,
            self.handle,
        );
        const idx1 = Handles.getIndex(@ptrCast(ins)) orelse return error.ReAdd;
        const idx2 = Handles.getIndex(rdata.model.?) orelse return error.ReAdd;

        const tidx = uctx.pTextureSet.getDescriptorSetIndex(@ptrCast(rdata.textures[0]));

        const cs_mesh_drawCount = try uctx.passGroupMapping.add(io, rdata.pass.name, .{
            .instanceID = idx1,
            .meshID = idx2,
        });
        const pU32 = @as(*u32, @ptrCast(@alignCast(rdata.pass.userdata.?)));
        pU32.* = cs_mesh_drawCount;

        rdata.pass.setPushConstants(2, @constCast(&std.mem.toBytes(tidx)), 64);
    }
};
