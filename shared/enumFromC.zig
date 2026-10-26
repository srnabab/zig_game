const std = @import("std");
const Type = std.lang.Type;

fn comptime_print(comptime format: []const u8, comptime args: anytype) void {
    @compileLog(std.fmt.comptimePrint(format, args));
}

/// depend on enum sequence
pub fn generateEnumFromC(
    comptime import: anytype,
    comptime tag_type: anytype,
    comptime startEnumMember: [:0]const u8,
    comptime endEnumMember: [:0]const u8,
    comptime exhaustive: Type.Enum.Mode,
) type {
    comptime var enum_fields_names: [1024][]const u8 = undefined;
    comptime var enum_fields_values: [1024]tag_type = undefined;
    comptime var count: u32 = 0;

    // comptime_print("start {s}, end {s}", .{ startEnumMember, endEnumMember });

    comptime var begin = false;
    @setEvalBranchQuota(100000);
    inline for (std.meta.declarations(import)) |decl| {
        if (begin == false) {
            if (std.mem.eql(u8, decl, startEnumMember)) {
                begin = true;
            } else {
                continue;
            }
        }
        // comptime_print("decl name: {s}", .{decl});

        comptime var has = false;
        comptime var i = count;
        while (i > 0) {
            i -= 1;
            if (enum_fields_values[i] == @field(import, decl)) {
                has = true;
                break;
            }
        }
        if (has == true) {
            if (std.mem.eql(u8, decl, endEnumMember)) {
                // comptime_print("{s}", .{decl});
                // comptime_print("{s}", .{endEnumMember});
                break;
            }
            continue;
        }

        enum_fields_names[count] = decl;
        enum_fields_values[count] = @field(import, decl);

        count += 1;
        // comptime_print("decl name: {s}", .{decl});
        if (count == 1024) {
            break;
        }

        if (std.mem.eql(u8, decl, endEnumMember)) {
            // comptime_print("{s}", .{decl});
            // comptime_print("{s}", .{endEnumMember});
            break;
        }
    }

    return @Enum(
        tag_type,
        exhaustive,
        enum_fields_names[0..count],
        enum_fields_values[0..count],
    );
}
