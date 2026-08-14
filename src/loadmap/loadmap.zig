const std = @import("std");
const Allocator = std.mem.Allocator;

const Self = @This();

const GridLayer = struct {
    row: u32,
    col: u32,
    gridLength: u32,

    leftUp: [2]i32,

    grids: []Grid,
};

const Pass = struct {
    start: u32,
    len: u32,
};

const Grid = struct {
    // leftUp: [2]i32,
    items: []Item,
    passes: []Pass,

    haveSub: bool,
};

const Item = struct {
    name: []u8,
    isGpu: bool,
    bufferName: ?[]u8 = null,
};

layers: []GridLayer,

grids: []Grid,
items: []Item,
passes: []Pass,
strs: []u8,

pub fn loadLoadmap(gpa: Allocator, mem: []u8) !Self {
    const depth = try std.mem.readInt(u32, mem[4..8], .native);
    const totalGridCount = try std.mem.readInt(u32, mem[8..12], .native);
    const totalItemCount = try std.mem.readInt(u32, mem[12..16], .native);
    const totalPassCount = try std.mem.readInt(u32, mem[16..20], .native);
    const totalU8Count = try std.mem.readInt(u32, mem[20..24], .native);

    var offsets = try gpa.alloc(u32, depth);
    defer gpa.free(offsets);

    for (0..depth) |i| {
        const offset = 24 + i * 4;
        offsets[i] = try std.mem.readInt(u32, mem[offset .. offset + 4], .native);
    }

    const totalLen = depth * @sizeOf(GridLayer) + totalGridCount * @sizeOf(Grid) +
        totalItemCount * @sizeOf(Item) + totalPassCount * @sizeOf(Pass) +
        totalU8Count * @sizeOf(u8);

    const memory = try gpa.alloc(u8, totalLen);
}
