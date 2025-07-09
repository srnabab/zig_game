const std = @import("std");

/// depend on enum sequence
pub fn generateEnumFromC(comptime import: anytype, comptime tag_type: anytype, comptime startEnumMember: []const u8, comptime endEnumMember: []const u8) type {
    comptime var enum_fields: [1024]std.builtin.Type.EnumField = undefined;
    comptime var count = 0;

    comptime var begin = false;
    inline for (std.meta.declarations(import)) |decl| {
        if (begin == false) {
            // comptime_print("decl name: {s}", .{decl.name});
            if (std.mem.eql(u8, decl.name, startEnumMember)) {
                begin = true;
            } else {
                continue;
            }
        }

        @setEvalBranchQuota(20000);
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
            break;
        }
    }

    return @Type(.{
        .@"enum" = .{
            .tag_type = tag_type,
            .fields = enum_fields[0..count],
            .decls = &.{},
            .is_exhaustive = true,
        },
    });
}
