const EntityID = u32;
const Atomic = @import("std").atomic;
const std = @import("std");

pub const Entity = struct {
    id: EntityID = 0,

    pub fn createEntity() Entity {
        return Entity{
            .id = AutoIncrcemetID.fetchAdd(1, .seq_cst),
        };
    }
};

var AutoIncrcemetID: Atomic.Value(u32) = Atomic.Value(u32).init(0);

fn multipleThreadCreateEntityTestFunc(index: usize) void {
    while (true) {
        const temp = Entity.createEntity();

        std.debug.print("thread: {d}, ID: {d}\n", .{ index, temp.id });
        std.time.sleep(std.crypto.random.int(u17));

        if (temp.id >= 100) break;
    }
}
test "multiple thread create Entity" {
    const Thread = @import("std").Thread;
    var threads: [16]Thread = undefined;

    for (0..threads.len) |i| {
        threads[i] = try Thread.spawn(.{}, multipleThreadCreateEntityTestFunc, .{i});
    }

    for (0..threads.len) |i| {
        threads[i].join();
    }
}
