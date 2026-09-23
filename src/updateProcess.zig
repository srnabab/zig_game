const resourceProcess = @import("resourceProcess");
const UserContext = resourceProcess.UserContext;

const resource = @import("resource");

pub fn process(resourceCtx: *const resource.ResourceCtx, uctx: *UserContext) !void {
    try uctx.loadmaps.load(resourceCtx, 0, .{ 0, 0 });
}
