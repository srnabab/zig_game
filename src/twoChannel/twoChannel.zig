const std = @import("std");
const ringBuffer = @import("ringBuffer");

/// one thread use getEmpty and pushReady
/// another thread use getReady and pushEmpty
pub fn twoChannel(T: type, singleChannelSize: u32) type {
    return struct {
        const Self = @This();

        emptyChannel: ringBuffer.RingBuffer(T, singleChannelSize),
        readyChannel: ringBuffer.RingBuffer(T, singleChannelSize),

        pub fn init() Self {
            return .{
                .emptyChannel = .init(),
                .readyChannel = .init(),
            };
        }

        /// not thread safe
        pub fn putDataIntoChannel(self: *Self, data: []T) bool {
            for (data) |value| {
                if (!self.emptyChannel.push(value)) {
                    return false;
                }
            }

            return true;
        }

        pub fn getEmpty(self: *Self) ?T {
            return self.emptyChannel.pop();
        }

        pub fn pushReady(self: *Self, item: T) void {
            while (self.readyChannel.push(item) == false) {}
        }

        pub fn getReady(self: *Self) ?T {
            return self.readyChannel.pop();
        }

        pub fn pushEmpty(self: *Self, item: T) void {
            while (self.emptyChannel.push(item) == false) {}
        }
    };
}
