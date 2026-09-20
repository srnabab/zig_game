const std = @import("std");
const Allocator = std.mem.Allocator;

const Handles = @import("handle");
const Handle = Handles.Handle;

const pass = @import("pass");
const u8pack = @import("u8pack");

pub const rData = struct {
    model: ?Handle = null,
    textures: []Handle = &.{},
    pass: *pass.Pass,
};

const Self = @This();

map: u8pack.HashMap(rData),

pub fn init(gpa: Allocator) Self {
    return .{
        .map = u8pack.HashMap(rData).init(gpa),
    };
}

pub fn deinit(self: *Self) void {
    var datas = self.map.iterator();
    while (datas.next()) |entry| {
        self.map.allocator.free(entry.value_ptr.textures);
    }
    self.map.deinit();
}

pub fn add(self: *Self, gpa: Allocator, name: u8pack.Str, data: rData) !void {
    // std.log.debug("add rdata {f}", .{name});

    if (self.map.contains(name)) return;

    // std.log.debug("2 add rdata {f}", .{name});

    const textures = try gpa.dupe(Handle, data.textures);
    errdefer gpa.free(textures);

    try self.map.put(name, .{
        .model = data.model,
        .textures = textures,
        .pass = data.pass,
    });
}

pub fn get(self: *Self, name: u8pack.Str) ?*rData {
    return self.map.getPtr(name);
}
