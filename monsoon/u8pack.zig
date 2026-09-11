const std = @import("std");
const Allocator = std.mem.Allocator;
const hash_map = std.hash_map;
const Wyhash = std.hash.Wyhash;

const builtin = @import("builtin");

const debug = (builtin.mode == .Debug) or (builtin.mode == .ReleaseSafe);

const mstd = @import("ms_std");
const ComptimeAllocator = mstd.ComptimeAllocator;

const setPass = @import("setPass");
const file = @import("fileSystem");

pub const HashMapContext = if (debug) struct {
    pub fn hash(self: @This(), s: Str) u64 {
        _ = self;
        return hash_map.hashString(s.name);
    }
    pub fn eql(self: @This(), a: Str, b: Str) bool {
        _ = self;
        return hash_map.eqlString(a.name, b.name);
    }
} else struct {
    pub fn hash(self: @This(), s: Str) u64 {
        _ = self;
        return Wyhash.hash(0, std.mem.asBytes(&s.id));
    }
    pub fn eql(self: @This(), a: Str, b: Str) bool {
        _ = self;
        return a.id == b.id;
    }
};
pub fn HashMap(comptime V: type) type {
    return std.HashMap(Str, V, HashMapContext, 80);
}

const mapType = enum {
    passes,
    buffers,
};
const pass_buffer_map = struct {
    belongMap: std.StaticStringMap(mapType),

    passes: std.StaticStringMap(u32),
    buffers: std.StaticStringMap(u32),

    files: std.StaticStringMap(u32),
};
const maps = [_][]const u8{ "buffers", "passes" };

pub const CTX = struct {
    passes: []const []const u8,
    buffers: []const []const u8,
};
const str_maps: pass_buffer_map = l: {
    var res: pass_buffer_map = undefined;

    var ctx = CTX{
        .buffers = &.{},
        .passes = &.{},
    };

    setPass.setting(&ctx) catch {
        @compileError("error");
    };

    const Items = struct {
        buffers: []const []const u8,
        passes: []const []const u8,
    };

    const KV = struct { []const u8, u32 };
    const KV2 = struct { []const u8, mapType };

    var items: Items = undefined;

    var totalLen = 0;
    for (maps) |mapName| {
        totalLen += @field(ctx, mapName).len;
    }
    var belongs: [totalLen]KV2 = undefined;
    totalLen = 0;

    @setEvalBranchQuota(10000);

    for (maps, 0..) |mapName, mi| {
        var mut_buf: [@field(ctx, mapName).len][]const u8 = undefined;
        @memcpy(&mut_buf, @field(ctx, mapName));

        @field(items, mapName) = deduplicateStrings(&mut_buf);
        var KVs: [@field(items, mapName).len]KV = undefined;
        // var id: u32 = 0;

        for (@field(items, mapName), 0..) |name, i| {
            KVs[i] = KV{
                .@"0" = name,
                .@"1" = @intCast(i),
            };
            belongs[totalLen] = KV2{
                .@"0" = name,
                .@"1" = @enumFromInt(mi),
            };
            totalLen += 1;
        }

        @field(res, mapName) = .initComptime(KVs);
    }

    res.belongMap = .initComptime(belongs);
    res.files = file.fileNameID.FileNameIdHashMap;
    break :l res;
};

pub const Str = struct {
    id: u32,

    name: if (debug)
        []const u8
    else
        void,

    pub fn format(self: @This(), writer: *std.Io.Writer) !void {
        if (debug) try writer.print("name: {s}({d})", .{ self.name, self.id });
    }
};

pub fn ID(comptime str: []const u8) u32 {
    comptime {
        const mapT = str_maps.belongMap.get(str) orelse {
            return str_maps.files.get(str) orelse @compileError(std.fmt.comptimePrint("{s}", .{str}));
        };
        return @field(str_maps, maps[@intFromEnum(mapT)]).get(str) orelse @compileError(std.fmt.comptimePrint("{s}", .{str}));
    }
}

pub fn toStr(comptime str: []const u8) Str {
    return comptime .{
        .name = if (debug) str else void{},
        .id = ID(str),
    };
}

const Error = error{unknownName};
const Str2 = if (debug) []const u8 else u32;

pub fn ID2(str: []const u8) Error!u32 {
    const mapT = str_maps.belongMap.get(str) orelse {
        return str_maps.files.get(str) orelse return Error.unknownName;
    };
    switch (mapT) {
        inline else => |t| {
            return @field(str_maps, maps[@intFromEnum(t)]).get(str) orelse return Error.unknownName;
        },
    }
}

pub fn toStr2(str: Str2) Str {
    if (debug) {
        return .{
            .name = str,
            .id = ID2(str) catch id: {
                std.log.err("unknow name {s}", .{str});
                break :id std.math.maxInt(u32);
            },
        };
    } else {
        return .{
            .name = void{},
            .id = str,
        };
    }
}

fn deduplicateStrings(items: [][]const u8) [][]const u8 {
    if (items.len <= 1) return items;

    std.mem.sort([]const u8, items, {}, struct {
        fn lessThan(_: void, a: []const u8, b: []const u8) bool {
            return std.mem.order(u8, a, b) == .lt;
        }
    }.lessThan);

    var unique_idx: usize = 1;
    for (items[1..]) |item| {
        if (!std.mem.eql(u8, item, items[unique_idx - 1])) {
            items[unique_idx] = item;
            unique_idx += 1;
        }
    }

    return items[0..unique_idx];
}
pub fn dupe(gpa: Allocator, str: Str) !Str {
    if (debug) {
        return .{
            .name = try gpa.dupe(u8, str.name),
            .id = str.id,
        };
    } else {
        return str;
    }
}
pub fn free(gpa: Allocator, str: Str) void {
    if (debug) {
        gpa.free(str.name);
    }
}

pub fn eql(a: Str, b: Str) bool {
    if (debug) {
        return std.mem.eql(u8, a.name, b.name) and a.id == b.id;
    } else {
        return a.id == b.id;
    }
}

// pub fn StrAutoHashMap(comptime V: type) type {
//     if (debug) {
//         return std.StringHashMap(V);
//     } else {
//         return std.AutoHashMap(u32, V);
//     }
// }
