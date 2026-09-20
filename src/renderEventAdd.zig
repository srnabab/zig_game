const std = @import("std");

const global = @import("global");

const u8pack = @import("u8pack");
const toStr = u8pack.toStr;

const resourceProcess = @import("resourceProcess");
const UserContext = resourceProcess.UserContext;

pub fn addEvent(uctx: *UserContext, updateEventQueue: *global.UpdateEventQueueType) !void {
    var it = uctx.layoutQueue.iterate();
    while (it.next()) |p| {
        const item = p.ptr;
        const name = item.name;
        const rdata = uctx.renderData.get(name) orelse continue;

        if (u8pack.eql(toStr("indirect2D"), rdata.pass.name)) {
            updateEventQueue.appendC(.{ .createTest2d = .{
                .pos = item.pos,
                .scale = item.scale,
                .rotation = item.rotation,
                .rdata = name,
                .handle = item.handle,
            } }) catch |err| {
                std.log.err("layout push createTest2d {s}", .{@errorName(err)});
                continue;
            };
        } else if (u8pack.eql(toStr("i_feather"), rdata.pass.name)) {
            updateEventQueue.appendC(.{ .createTest3d = .{
                .pos = item.pos,
                .scale = item.scale,
                .rotation = item.rotation,
                .rdata = name,
                .handle = item.handle,
            } }) catch |err| {
                std.log.err("layout push createTest3d {s}", .{@errorName(err)});
                continue;
            };
        }
        uctx.layoutQueue.remove(p.index);
    }
}
