const Handles = @import("handle");
const cglm = @import("cglm");
const u8pack = @import("u8pack");

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

const test2d = struct {
    pos: vec3,
    scale: vec3,
    rotation: vec3,
    rdata: u8pack.Str,
    handle: Handles.Handle,
};

const test3d = struct {
    pos: vec3,
    scale: vec3,
    rotation: vec3,
    rdata: u8pack.Str,
    handle: Handles.Handle,
};
