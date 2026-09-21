const std = @import("std");
const Allocator = std.mem.Allocator;
const hash_map = std.hash_map;
const Wyhash = std.hash.Wyhash;

const builtin = @import("builtin");

const debug = (builtin.mode == .Debug) or (builtin.mode == .ReleaseSafe);

const mstd = @import("ms_std");
const ComptimeAllocator = mstd.ComptimeAllocator;

const setPass = @import("setPass");
const setUbo = @import("setUbo");
const renderFlow = @import("renderFlow");
const file = @import("fileSystem");

const construct = @import("strConstruct");

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

const ctxMaps = [_][]const u8{ "buffers", "passes", "ubos" };
const constructMaps = construct.maps;

const totalMaps = l: {
    var names: []const []const u8 = &.{};

    for (ctxMaps) |value| {
        names = names ++ .{value};
    }

    names = names ++ .{"files"};

    for (constructMaps) |value| {
        names = names ++ .{value};
    }

    break :l names;
};

const StrMap = std.StaticStringMap(u32);

const KV = struct { []const u8, u32 };

const StrMaps = l: {
    const f_names = a: {
        var names: []const []const u8 = &.{};
        names = names ++ .{"belongMap"};

        for (totalMaps) |name| {
            names = names ++ .{name};
        }

        break :a names;
    };

    break :l @Struct(
        .auto,
        null,
        f_names,
        a: {
            var types: [f_names.len]type = undefined;

            for (0..f_names.len) |i| {
                types[i] = StrMap;
            }

            break :a &types;
        },
        &@splat(.{}),
    );
};

pub const CTX = struct {
    passes: []const []const u8,
    buffers: []const []const u8,
    ubos: []const []const u8,
};

const str_maps: StrMaps = l: {
    var res: StrMaps = undefined;

    var ctx = CTX{
        .buffers = &.{},
        .passes = &.{},
        .ubos = &.{},
    };

    setUbo.setUbo(&ctx) catch {
        @compileError("error");
    };
    renderFlow.createUboBuffer(&ctx) catch {
        @compileError("error");
    };
    setPass.setting(&ctx) catch {
        @compileError("error");
    };

    @setEvalBranchQuota(10000);

    // ctx 驱动的表(buffers/passes): 去重后按去重数组下标当 id
    for (ctxMaps) |mapName| {
        var mut_buf: [@field(ctx, mapName).len][]const u8 = undefined;
        @memcpy(&mut_buf, @field(ctx, mapName));

        const items = deduplicateStrings(&mut_buf);
        var KVs: [items.len]KV = undefined;

        for (items, 0..) |name, i| {
            KVs[i] = KV{
                .@"0" = name,
                .@"1" = @intCast(i),
            };
        }

        @field(res, mapName) = .initComptime(KVs);
    }

    // 生成文件表(fileNameID.zig)
    res.files = file.fileNameID.FileNameIdHashMap;

    // strConstruct 里手写的表(每个表提供一个 <name>() std.StaticStringMap(u32))
    for (constructMaps) |mapName| {
        @field(res, mapName) = @field(construct, mapName)();
    }

    var totalLen = 0;
    for (totalMaps) |mapName| {
        totalLen += @field(res, mapName).kvs.len;
    }
    var belongs: [totalLen]KV = undefined;

    var count = 0;

    for (totalMaps, 0..) |mapName, mi| {
        for (@field(res, mapName).keys()) |value| {
            belongs[count] = KV{
                .@"0" = value,
                .@"1" = @intCast(mi),
            };
            count += 1;
        }
    }
    res.belongMap = .initComptime(belongs);

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
        const mapT = str_maps.belongMap.get(str) orelse @compileError(std.fmt.comptimePrint("{s}", .{str}));
        return @field(str_maps, totalMaps[mapT]).get(str) orelse @compileError(std.fmt.comptimePrint("{s}", .{str}));
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
    const mapT = str_maps.belongMap.get(str) orelse return Error.unknownName;

    switch (mapT) {
        inline 0...totalMaps.len - 1 => |t| {
            return @field(str_maps, totalMaps[t]).get(str) orelse return Error.unknownName;
        },
        else => {
            return Error.unknownName;
        },
    }
}

fn replaceName(str: []const u8) ![]const u8 {
    const mapT = str_maps.belongMap.get(str) orelse return Error.unknownName;

    switch (mapT) {
        inline 0...totalMaps.len - 1 => |t| {
            return @field(str_maps, totalMaps[t]).keys()[@field(str_maps, totalMaps[t]).getIndex(str) orelse return Error.unknownName];
        },
        else => {
            return Error.unknownName;
        },
    }
}

pub fn toStr2(str: Str2) Str {
    if (debug) {
        const id = ID2(str) catch {
            std.debug.panic("unknow name {s}", .{str});
        };

        return .{
            .name = replaceName(str) catch unreachable,
            .id = id,
        };
    } else {
        // ReleaseFast 下 Str2 就是 id, 不存在字符串
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
