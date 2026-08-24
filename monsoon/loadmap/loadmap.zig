const std = @import("std");
const Allocator = std.mem.Allocator;
const atomic = std.atomic;

const cglm = @import("cglm");

const Self = @This();

const GridLayer = struct {
    row: u32,
    col: u32,
    gridLength: u32,

    leftUp: [2]i32,

    grids: []Grid,

    pub fn getGridIndex(self: *const GridLayer, x: i32, y: i32) ?u32 {
        const X: u32 = cglm.abs(x - self.leftUp[0]) / self.gridLength;
        const Y: u32 = cglm.abs(y - self.leftUp[1]) / self.gridLength;

        if (X >= 0 and X < self.col and Y >= 0 and Y < self.row) {
            return Y * self.col + X;
        }

        return null;
    }
};

const Pass = struct {
    start: u32,
    len: u32,
};

const GridState = enum(u8) {
    unloaded,
    loading,
    loaded,
    unloading,
};

const Grid = struct {
    // leftUp: [2]i32,
    items: []Item = &.{},
    passes: []Pass = &.{},

    state: GridState = .unloaded,
    haveSub: bool = false,
};

const Item = struct {
    name: []u8,
    isGpu: bool,
    bufferName: [][]u8 = &.{},
};

const Loading = struct {
    grid: *Grid,
    progress: atomic.Value(u32) = .init(0),
    done: bool = false,
};

layers: []GridLayer,

grids: []Grid,
items: []Item,
bufferNames: [][]u8,
passes: []Pass,
strs: []u8,

allocator: Allocator,
loadingQueue: std.ArrayList(Loading),

pub const empty = Self{
    .layers = &.{},
    .grids = &.{},
    .items = &.{},
    .bufferNames = &.{},
    .passes = &.{},
    .strs = &.{},
    .allocator = undefined,
    .loadingQueue = .empty,
};

pub fn loadLoadmap(gpa: Allocator, mem: []u8) !Self {
    if (mem.len < 64) return .empty;

    const depth = std.mem.readInt(u32, mem[4..8], .native);
    const totalGridCount = std.mem.readInt(u32, mem[8..12], .native);
    const totalItemCount = std.mem.readInt(u32, mem[12..16], .native);
    const totalPassCount = std.mem.readInt(u32, mem[16..20], .native);
    const totalU8Count = std.mem.readInt(u32, mem[20..24], .native);
    const totalBufferNameCount = std.mem.readInt(u32, mem[24..28], .native);

    var offsets = try gpa.alloc(u32, depth + 1);
    defer gpa.free(offsets);

    for (0..depth + 1) |i| {
        const offset = 28 + i * 4;
        offsets[i] = std.mem.readInt(u32, @ptrCast(mem[offset .. offset + 4]), .native);
    }

    const totalLen = @as(usize, depth + 1) * @sizeOf(GridLayer) +
        @as(usize, totalGridCount) * @sizeOf(Grid) +
        @as(usize, totalItemCount) * @sizeOf(Item) +
        @as(usize, totalBufferNameCount) * @sizeOf([]u8) +
        @as(usize, totalPassCount) * @sizeOf(Pass) +
        @as(usize, totalU8Count) * @sizeOf(u8);

    const memory = try gpa.alignedAlloc(u8, .of(GridLayer), totalLen);

    const layersBytes = memory[0 .. @as(usize, depth + 1) * @sizeOf(GridLayer)];
    const gridsBytes = memory[layersBytes.len..][0 .. @as(usize, totalGridCount) * @sizeOf(Grid)];
    const itemsBytes = memory[gridsBytes.len + layersBytes.len ..][0 .. @as(usize, totalItemCount) * @sizeOf(Item)];
    const bufferNamesBytes = memory[gridsBytes.len + layersBytes.len + itemsBytes.len ..][0 .. @as(usize, totalBufferNameCount) * @sizeOf([]u8)];
    const passesBytes = memory[gridsBytes.len + layersBytes.len + itemsBytes.len + bufferNamesBytes.len ..][0 .. @as(usize, totalPassCount) * @sizeOf(Pass)];

    const layers: []GridLayer = @alignCast(std.mem.bytesAsSlice(GridLayer, layersBytes));
    const grids: []Grid = @alignCast(std.mem.bytesAsSlice(Grid, gridsBytes));
    const items: []Item = @alignCast(std.mem.bytesAsSlice(Item, itemsBytes));
    const bufferNames: [][]u8 = @alignCast(std.mem.bytesAsSlice([]u8, bufferNamesBytes));
    const passes: []Pass = @alignCast(std.mem.bytesAsSlice(Pass, passesBytes));
    const strs = memory[memory.len - @as(usize, totalU8Count) ..];

    var gridIdx: usize = 0;
    var itemIdx: usize = 0;
    var bufferNameIdx: usize = 0;
    var passIdx: usize = 0;
    var strPos: usize = 0;

    for (0..@as(usize, depth + 1)) |d| {
        var pos: usize = offsets[d];

        const layer = &layers[d];
        layer.row = std.mem.readInt(u32, mem[pos..][0..4], .native);
        pos += 4;
        layer.col = std.mem.readInt(u32, mem[pos..][0..4], .native);
        pos += 4;
        layer.leftUp[0] = std.mem.readInt(i32, mem[pos..][0..4], .native);
        pos += 4;
        layer.leftUp[1] = std.mem.readInt(i32, mem[pos..][0..4], .native);
        pos += 4;
        layer.gridLength = std.mem.readInt(u32, mem[pos..][0..4], .native);
        pos += 4;
        const gridCount = std.mem.readInt(u32, mem[pos..][0..4], .native);
        pos += 4;

        const area = @as(usize, layer.row) * @as(usize, layer.col);
        layer.grids = grids[gridIdx .. gridIdx + area];
        gridIdx += area;
        @memset(layer.grids, @as(Grid, .{}));

        for (0..gridCount) |_| {
            const x = std.mem.readInt(i32, mem[pos..][0..4], .native);
            pos += 4;
            const y = std.mem.readInt(i32, mem[pos..][0..4], .native);
            pos += 4;

            const itemCount = std.mem.readInt(u32, mem[pos..][0..4], .native);
            pos += 4;

            const gridItems = items[itemIdx .. itemIdx + @as(usize, itemCount)];
            itemIdx += @intCast(itemCount);

            for (0..itemCount) |ii| {
                const nameLen = std.mem.readInt(u32, mem[pos..][0..4], .native);
                pos += 4;

                gridItems[ii].name = strs[strPos .. strPos + @as(usize, nameLen)];
                @memcpy(gridItems[ii].name, mem[pos..][0..@as(usize, nameLen)]);
                pos += @intCast(nameLen);
                strPos += @intCast(nameLen);

                gridItems[ii].isGpu = mem[pos] != 0;
                pos += 1;

                const bufferNameCount = std.mem.readInt(u32, mem[pos..][0..4], .native);
                pos += 4;

                gridItems[ii].bufferName = bufferNames[bufferNameIdx .. bufferNameIdx + @as(usize, bufferNameCount)];
                bufferNameIdx += @intCast(bufferNameCount);

                for (0..bufferNameCount) |bi| {
                    const bufferNameLen = std.mem.readInt(u32, mem[pos..][0..4], .native);
                    pos += 4;

                    gridItems[ii].bufferName[bi] = strs[strPos .. strPos + @as(usize, bufferNameLen)];
                    @memcpy(gridItems[ii].bufferName[bi], mem[pos..][0..@as(usize, bufferNameLen)]);
                    pos += @intCast(bufferNameLen);
                    strPos += @intCast(bufferNameLen);
                }
            }

            const passCount = std.mem.readInt(u32, mem[pos..][0..4], .native);
            pos += 4;

            const gridPasses = passes[passIdx .. passIdx + @as(usize, passCount)];
            passIdx += @as(usize, passCount);

            for (0..passCount) |pi| {
                const passLen = std.mem.readInt(u32, mem[pos..][0..4], .native);
                pos += 4;

                gridPasses[pi] = .{ .start = @intCast(strPos), .len = passLen };
                @memcpy(strs[strPos .. strPos + @as(usize, passLen)], mem[pos..][0..@as(usize, passLen)]);
                pos += @as(usize, passLen);
                strPos += @as(usize, passLen);
            }

            const gx = @as(u32, @intCast(x - layer.leftUp[0])) / layer.gridLength;
            const gy = @as(u32, @intCast(y - layer.leftUp[1])) / layer.gridLength;

            const grid = &layer.grids[gy * layer.col + gx];
            grid.* = .{
                .items = gridItems,
                .passes = gridPasses,
                .haveSub = false,
            };
        }
    }

    return .{
        .layers = layers,
        .grids = grids,
        .items = items,
        .bufferNames = bufferNames,
        .passes = passes,
        .strs = strs,
        .loadingQueue = try .initCapacity(gpa, 4),
        .allocator = gpa,
    };
}

pub fn loadResource(self: *Self, pos: cglm.vec2) !void {
    const x: i32 = @intCast(pos[0]);
    const y: i32 = @intCast(pos[1]);

    for (self.layers) |layer| {
        const center = layer.getGridIndex(x, y) orelse return;

        switch (layer.grids[center].state) {
            .unloaded => {
                try self.loadingQueue.append(self.allocator, .{ .grid = &layer.grids[center] });
                layer.grids[center].state = .loading;
            },
            .loading, .loaded => {
                continue;
            },
            .unloading => {
                // cancel
            },
        }
    }
}
