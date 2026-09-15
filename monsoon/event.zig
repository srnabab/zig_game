const Handles = @import("handle");
const cglm = @import("cglm");

const vec3 = cglm.vec3;

const EventType = enum(u32) {
    createStaticInteractableStub,
    createTest2d,
};
pub const Event = union(EventType) {
    createStaticInteractableStub: staticInteractableStub,
    createTest2d: test2d,
};

const staticInteractableStub = struct {
    handle: Handles.Handle,
    pos: vec3,
};

const test2d = struct {
    pos: vec3,
    scale: vec3,
    rotation: vec3,
};
