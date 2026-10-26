const std = @import("std");

pub fn logStructSize(arg: anytype) void {
    const info = @typeInfo(arg);

    inline for (a: switch (info) {
        .@"struct" => break :a info.@"struct".decl_names,
        .@"union" => break :a info.@"union".decl_names,
        else => unreachable,
    }) |decl_name| {
        const Member = @field(arg, decl_name);

        if (@TypeOf(Member) == type) {
            switch (@typeInfo(Member)) {
                .@"struct" => {
                    const size = @sizeOf(Member);
                    std.log.debug("struct {s}, size: {d}", .{
                        decl_name,
                        size,
                    });
                },
                else => {},
            }
        }
    }
}
