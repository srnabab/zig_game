const std = @import("std");

fn comptime_print(comptime format: []const u8, comptime args: anytype) void {
    @compileLog(std.fmt.comptimePrint(format, args));
}

/// depend on enum sequence
pub fn generateEnumFromC(comptime import: anytype, comptime tag_type: anytype, comptime startEnumMember: [:0]const u8, comptime endEnumMember: [:0]const u8) type {
    comptime var enum_fields: [1024]std.builtin.Type.EnumField = undefined;
    comptime var count: u32 = 0;

    // comptime_print("start {s}, end {s}", .{ startEnumMember, endEnumMember });

    comptime var begin = false;
    @setEvalBranchQuota(10000);
    inline for (std.meta.declarations(import)) |decl| {
        if (begin == false) {
            if (std.mem.eql(u8, decl.name, startEnumMember)) {
                begin = true;
            } else {
                continue;
            }
        }
        // comptime_print("decl name: {s}", .{decl.name});

        comptime var has = false;
        comptime var i = count;
        while (i > 0) {
            i -= 1;
            if (enum_fields[i].value == @field(import, decl.name)) {
                has = true;
                break;
            }
        }
        if (has == true) {
            if (std.mem.eql(u8, decl.name, endEnumMember)) {
                // comptime_print("{s}", .{decl.name});
                // comptime_print("{s}", .{endEnumMember});
                break;
            }
            continue;
        }

        enum_fields[count] = .{
            .name = decl.name,
            .value = @field(import, decl.name),
        };

        count += 1;
        // comptime_print("decl name: {s}", .{decl.name});
        if (count == 1024) {
            break;
        }

        if (std.mem.eql(u8, decl.name, endEnumMember)) {
            // comptime_print("{s}", .{decl.name});
            // comptime_print("{s}", .{endEnumMember});
            break;
        }
    }

    return @Type(.{
        .@"enum" = .{
            .tag_type = tag_type,
            .fields = enum_fields[0..count],
            .decls = &.{},
            .is_exhaustive = false,
        },
    });
}
