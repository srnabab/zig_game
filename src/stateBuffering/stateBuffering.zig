const std = @import("std");

const State = enum(u32) {
    free,
    writing,
    ready,
    reading,
};

pub fn stateBuffering(bufferCount: usize, T: type) type {
    return struct {
        const Self = @This();
        const ArrayType = std.array_list.Managed(T);

        states: [bufferCount]std.atomic.Value(State),
        arrays: [bufferCount]ArrayType,

        pointerIndex: std.atomic.Value(u32) = .init(0),
        lastIndex: std.atomic.Value(i32) = .init(-1),

        pub fn init(gpa: std.mem.Allocator) Self {
            var arrays: [bufferCount]ArrayType = undefined;
            for (0..bufferCount) |i| {
                arrays[i] = .init(gpa);
            }
            var states: [bufferCount]std.atomic.Value(State) = undefined;
            for (0..bufferCount) |i| {
                states[i] = .init(.free);
            }

            return .{
                .states = states,
                .arrays = arrays,
            };
        }

        pub fn deinit(self: *Self) void {
            for (0..bufferCount) |i| {
                self.arrays[i].deinit();
            }
        }

        pub fn getWriteBuffer(self: *Self) *ArrayType {
            var i: u32 = self.pointerIndex.load(.acquire);
            while (true) {
                const current_state = self.states[i].load(.seq_cst);

                if ((current_state == .free or current_state == .ready) and
                    self.states[i].cmpxchgWeak(
                        current_state,
                        .writing,
                        .seq_cst,
                        .seq_cst,
                    ) == null)
                {
                    break;
                }

                i = (i + 1) % 3;
            }

            self.pointerIndex.store(i, .release);

            self.arrays[i].clearRetainingCapacity();
            return &self.arrays[i];
        }

        pub fn returnWriteBuffer(self: *Self, buffer: *ArrayType) void {
            _ = buffer;
            var i: u32 = self.pointerIndex.load(.acquire);

            self.states[i].store(.ready, .release);
            self.lastIndex.store(@intCast(i), .seq_cst);
            i = (i + 1) % 3;

            self.pointerIndex.store(i, .release);
        }

        pub fn getReadyBuffer(self: *Self) *ArrayType {
            while (true) {
                const target = self.lastIndex.load(.seq_cst);

                if (target == -1) continue;

                if (self.states[@intCast(target)].cmpxchgWeak(
                    .ready,
                    .reading,
                    .seq_cst,
                    .seq_cst,
                ) == null) {
                    return &self.arrays[@intCast(target)];
                }
            }
        }

        pub fn returnReadyBuffer(self: *Self, buffer: *ArrayType) void {
            const i = buffer - &self.arrays[0];

            buffer.clearRetainingCapacity();

            self.states[i].store(.free, .release);
        }
    };
}
