const global = @import("global");

const resourceProcess = @import("resourceProcess");
const UserContext = resourceProcess.UserContext;

const resource = @import("resource");

pub fn process(
    resourceCtx: *const resource.ResourceCtx,
    uctx: *UserContext,
    updateEventQueue: *global.UpdateEventQueueType,
    states: *global.StateBufferingType.ArrayType,
) !void {
    _ = updateEventQueue;
    _ = states;
    try uctx.loadmaps.load(resourceCtx, 0, .{ 0, 0 });
}
