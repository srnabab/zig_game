pub const Entity = @import("entity.zig").Entity;
const compent = @import("compent.zig");
const std = @import("std");

pub const CompentPool = compent.compentPool;

const ffff = struct { a: f32, b: f32, c: f32, d: f32 };
const ffffPool = compent.compentPool(ffff);
var mutex_multipleThreadRegisterTest: std.Thread.Mutex = .{};
fn multipleThreadRegisterTestFunc(pool: *ffffPool, list: *std.ArrayList(Entity)) !void {
    while (true) {
        const rad = std.crypto.random.boolean();
        if (rad or list.items.len == 0) {
            const ent = Entity.createEntity();

            mutex_multipleThreadRegisterTest.lock();
            defer mutex_multipleThreadRegisterTest.unlock();
            try list.append(ent);
        } else {
            const fff_data = ffff{
                .a = std.crypto.random.float(f32),
                .b = std.crypto.random.float(f32),
                .c = std.crypto.random.float(f32),
                .d = std.crypto.random.float(f32),
            };

            mutex_multipleThreadRegisterTest.lock();
            defer mutex_multipleThreadRegisterTest.unlock();
            try pool.register(list.items[std.crypto.random.int(usize) % list.items.len], fff_data);
        }

        std.time.sleep(10000000);

        if (list.items.len > 100) break;
    }
}
test "multiple thread register test" {
    var gpa_f = std.heap.DebugAllocator(.{}).init;
    const gpa = gpa_f.allocator();
    var pool = ffffPool.init(gpa);
    defer pool.deinit();
    var entityList = std.ArrayList(Entity).init(gpa);
    defer entityList.deinit();

    const entitty = Entity.createEntity();
    std.debug.print("id: {d}\n", .{entitty.id});

    var threads: [2]std.Thread = undefined;
    for (0..threads.len) |i| {
        threads[i] = try std.Thread.spawn(.{}, multipleThreadRegisterTestFunc, .{ &pool, &entityList });
    }

    for (0..threads.len) |i| {
        threads[i].join();
    }

    var dataa = try pool.getCompent(Entity{ .id = 1 });
    std.debug.print("id {d}: a {d}, b {d}, c {d}, d {d}\n\n", .{ 1, dataa.a, dataa.b, dataa.c, dataa.d });
    dataa.a = 1000.0;
    dataa.b = 1000.0;
    dataa.c = 1000.0;
    dataa.d = 1000.0;

    for (pool.dense_array.items, pool.dense_entity_array.items) |data, entity| {
        std.debug.print("id {d}: a {d}, b {d}, c {d}, d {d}\n", .{ entity.id, data.a, data.b, data.c, data.d });
    }
}
