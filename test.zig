const std = @import("std");

pub fn main() !void {
    var atomic_val: u32 = 10;

    // Try to change atomic_val from 10 to 20
    const result = @cmpxchgStrong(
        u32,
        &atomic_val,
        10,
        20,
        .seq_cst, // Success ordering
        .seq_cst, // Failure ordering
    );

    if (result == null) {
        std.debug.print("Successfully changed value to {d}\n", .{atomic_val});
    } else {
        std.debug.print("Failed to change value. Actual value was {d}\n", .{result.?});
    }

    // Another attempt, expecting 20 but it's already 20
    const result2 = @cmpxchgStrong(
        u32,
        &atomic_val,
        20,
        30,
        .seq_cst,
        .seq_cst,
    );

    if (result2 == null) {
        std.debug.print("Successfully changed value to {d}\n", .{atomic_val});
    } else {
        std.debug.print("Failed to change value. Actual value was {d}\n", .{result2.?});
    }
}
