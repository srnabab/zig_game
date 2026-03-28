const std = @import("std");

pub fn logStructSize(arg: anytype) void {
    const info = @typeInfo(arg);

    inline for (a: switch (info) {
        .@"struct" => break :a info.@"struct".decls,
        .@"union" => break :a info.@"union".decls,
        else => unreachable,
    }) |decl| {
        const Member = @field(arg, decl.name);

        if (@TypeOf(Member) == type) {
            switch (@typeInfo(Member)) {
                .@"struct" => {
                    const size = @sizeOf(Member);
                    std.log.debug("struct {s}, size: {d}", .{
                        decl.name,
                        size,
                    });
                },
                else => {},
            }
        }
    }
}
