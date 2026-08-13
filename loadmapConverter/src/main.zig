const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;

const json = std.json;

const Root = struct {
    @"$schema": []u8,
    depth: u32,
    leftUp: LeftUp,
    gridLength: u32,
    items: []item,
    grids: []Grid,
    passes: [][]u8,
};

const item = struct {
    name: []u8,
    isGpu: bool,
    bufferName: ?[]u8 = null,
};

const Grid = struct {
    leftUp: LeftUp,
    items: []item,
    passes: [][]u8,
    gridLength: u32,
    grids: []Grid,
};

const LeftUp = struct { x: i32, y: i32 };

const GridLayer = struct {
    gridLength: u32,
    gridCount: u32,
};

const GridAndDepth = struct {
    grid: *Grid,
    depth: u32,
};

const magic = "lMap";

pub fn main(init: std.process.Init) !void {
    const gpa = init.gpa;
    const io = init.io;

    var args = try init.minimal.args.iterateAllocator(gpa);
    defer args.deinit();

    _ = args.skip();
    const path = args.next() orelse {
        std.log.info(".exe [path] [out]", .{});
        return;
    };
    const outPath = args.next() orelse {
        std.log.info(".exe [path] [out]", .{});
        return;
    };

    var file = Io.Dir.cwd().openFile(io, path, .{ .allow_directory = false }) catch |err| bl: {
        switch (err) {
            error.BadPathName => {
                break :bl Io.Dir.openFileAbsolute(io, path, .{ .allow_directory = false }) catch |err2| {
                    std.log.err("open file error: {s}", .{@errorName(err2)});
                    return err2;
                };
            },
            else => {
                return err;
            },
        }
    };
    defer file.close(io);

    var buffer = [_]u8{0} ** 256;
    var reader = file.reader(io, &buffer);
    const stat = try file.stat(io);

    const s = try reader.interface.readAlloc(gpa, stat.size);
    defer gpa.free(s);

    const jsonSource = try json.parseFromSlice(Root, gpa, s, .{});
    defer jsonSource.deinit();

    const depth = jsonSource.value.depth;

    var resFile = Io.Dir.cwd().createFile(io, outPath, .{}) catch |err| bl: {
        switch (err) {
            error.BadPathName => {
                break :bl Io.Dir.createFileAbsolute(io, outPath, .{}) catch |err2| {
                    std.log.err("open file error: {s}", .{@errorName(err2)});
                    return err2;
                };
            },
            else => {
                return err;
            },
        }
    };
    defer resFile.close(io);

    var offsets = try gpa.alloc(u32, depth + 1);
    defer gpa.free(offsets);

    var gridLayers = try gpa.alloc(GridLayer, depth + 1);
    defer gpa.free(gridLayers);

    @memset(gridLayers, GridLayer{ .gridCount = 0, .gridLength = 0 });

    var gridsByLayer = try gpa.alloc(std.array_list.Managed(*Grid), depth + 1);
    defer gpa.free(gridsByLayer);

    for (gridsByLayer) |*value| {
        value.* = .init(gpa);
    }
    defer for (gridsByLayer) |*value| {
        value.deinit();
    };

    var gridStack = std.array_list.Managed(GridAndDepth).init(gpa);
    defer gridStack.deinit();

    gridLayers[0] = GridLayer{
        .gridLength = jsonSource.value.gridLength,
        .gridCount = @intCast(jsonSource.value.grids.len),
    };

    for (jsonSource.value.grids) |*g| {
        try gridStack.append(.{ .grid = g, .depth = 0 });
        try gridsByLayer[1].append(g);
    }

    while (gridStack.pop()) |g| {
        gridLayers[g.depth + 1].gridCount += @intCast(g.grid.grids.len);

        if (gridLayers[g.depth + 1].gridLength != 0 and gridLayers[g.depth + 1].gridLength != g.grid.gridLength) {
            std.debug.panic("grid length at depth {d}: {d} != {d}", .{ g.depth, gridLayers[g.depth + 1].gridLength, g.grid.gridLength });
        } else {
            gridLayers[g.depth + 1].gridLength = g.grid.gridLength;
        }

        for (g.grid.grids) |*g2| {
            try gridStack.append(.{ .grid = g2, .depth = g.depth + 1 });
            try gridsByLayer[g.depth + 1].append(g2);
        }
    }

    var writeBuffer = [_]u8{0} ** 10240;
    var writer = resFile.writer(io, &writeBuffer);

    _ = try writer.interface.write(magic);
    _ = try writer.interface.writeInt(u32, depth, .native);

    for (0..depth + 1) |_| {
        _ = try writer.interface.writeInt(u32, 0, .native);
    }

    var grid0_special = Grid{
        .gridLength = jsonSource.value.gridLength,
        .grids = jsonSource.value.grids,
        .items = jsonSource.value.items,
        .leftUp = jsonSource.value.leftUp,
        .passes = jsonSource.value.passes,
    };
    try gridsByLayer[0].append(&grid0_special);

    for (gridLayers, 0..) |l, d| {
        // _ = l;
        offsets[d] = @intCast(writer.logicalPos());

        _ = try writer.interface.writeInt(u32, l.gridLength, .native);
        _ = try writer.interface.writeInt(u32, l.gridCount, .native);
        // std.log.debug("pos {d}", .{writer.logicalPos()});

        std.sort.insertion(*Grid, gridsByLayer[d].items, void{}, leftUpLessThan);

        while (gridsByLayer[d].pop()) |g| {
            _ = try writer.interface.writeInt(i32, g.leftUp.x, .native);
            _ = try writer.interface.writeInt(i32, g.leftUp.y, .native);

            _ = try writer.interface.writeInt(u32, @intCast(g.items.len), .native);
            for (g.items) |i| {
                _ = try writer.interface.writeInt(u32, @intCast(i.name.len), .native);
                _ = try writer.interface.write(i.name);
                _ = try writer.interface.writeByte(@intFromBool(i.isGpu));

                if (i.bufferName) |n| {
                    _ = try writer.interface.writeInt(u32, @intCast(n.len), .native);
                    _ = try writer.interface.write(n);
                } else {
                    _ = try writer.interface.writeInt(u32, 0, .native);
                }
            }

            _ = try writer.interface.writeInt(u32, @intCast(g.passes.len), .native);
            for (g.passes) |p| {
                _ = try writer.interface.writeInt(u32, @intCast(p.len), .native);
                _ = try writer.interface.write(p);
            }
        }
    }

    try writer.seekTo(8);
    for (offsets) |o| {
        _ = try writer.interface.writeInt(u32, o, .native);
    }

    try writer.flush();
}

fn leftUpLessThan(_: void, a: *Grid, b: *Grid) bool {
    if (a.leftUp.x > b.leftUp.x) {
        return true;
    } else if (a.leftUp.x == b.leftUp.x) {
        if (a.leftUp.y > b.leftUp.y) return true;
    }

    return false;
}
