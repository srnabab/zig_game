const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

const mstd = @import("std.zig");

const tracy = @import("tracy");

/// 双缓冲队列(无锁, 单生产者 + 单消费者, FIFO)
///
/// 两块 `std.Deque(T)` 数据区：
/// - 生产者只 push 进自己"拥有"的那块(`pushLastP`)；
/// - 消费者只动自己拥有的那块(`pushLastC`/`popFirst`)；
/// - 归属由 `state` 的 generation 奇偶决定：生产者侧 `prodIdx = (state >> 1) & 1`，
///   消费者的 `consumerIdx` 恒为 `1 - prodIdx`。
///
/// `swap` 由消费者调用，且调用时消费者不得操作队列。swap 只翻转归属，
/// **不清空**任何一块 —— 消费者没 drain 完的条目会随该块一起交给生产者，
/// 生产者新 push 追加在其后面(仍保持 FIFO 顺序)，下一轮 swap 回来再被消费。
///
/// 交换协议(seqlock 风格, 不用 Io.Mutex)：
/// - `state` bit0 = 1 表示 swap 进行中，高位为 generation；
/// - 生产者 `pushLastP` 先读 `state`，若 odd 则重试；否则 `writers += 1` 登记，
///   再复读 `state` 确认未被 swap 打断，之后才真正 push，最后 `writers -= 1`；
/// - `swap` 先把 `state` 置 odd(挡住新生产者)，自旋等 `writers == 0`(等在途 push
///   结束)，翻转 `consumerIdx`，再把 `state` 加回 even(generation + 1 → 归属翻转)。
///
/// 只支持单生产者：多生产者会共享同一块 deque，不安全。
pub fn doubleBufferQueue(T: type) type {
    return struct {
        const Self = @This();
        const Deque = mstd.FixedIndexArray(T);

        allocator: Allocator,
        queues: [2]Deque,

        consumerIdx: u32 = 1,

        /// bit0: 1 = swap 进行中; 高位: generation(奇偶即生产者侧队列归属)
        state: std.atomic.Value(u32) = .init(0),
        /// 正在 push 的生产者数(单生产者实现下恒为 0 或 1)
        writers: std.atomic.Value(u32) = .init(0),

        pub fn init(allocator: Allocator, io: Io) !Self {
            _ = io;

            return .{
                .allocator = allocator,
                .queues = .{ .init(allocator), .init(allocator) },
            };
        }

        pub fn deinit(self: *Self) void {
            for (&self.queues) |*queue| {
                queue.deinit();
            }
        }

        /// 生产者: 推入生产者拥有的队列尾部
        pub fn appendP(self: *Self, data: T) !void {
            const zone = tracy.initZone(@src(), .{ .name = "doubleBufferQueue pushLastP" });
            defer zone.deinit();

            while (true) {
                const s0 = self.state.load(.seq_cst);
                if (s0 & 1 != 0) {
                    std.atomic.spinLoopHint();
                    continue;
                }

                // 登记 "我要写了", 再复读 state: 若期间 swap 已开始则撤回重试
                _ = self.writers.fetchAdd(1, .seq_cst);
                if (self.state.load(.seq_cst) != s0) {
                    _ = self.writers.fetchSub(1, .seq_cst);
                    std.atomic.spinLoopHint();
                    continue;
                }

                const idx = (s0 >> 1) & 1;
                self.queues[idx].append(data) catch |err| {
                    _ = self.writers.fetchSub(1, .seq_cst);
                    return err;
                };
                _ = self.writers.fetchSub(1, .seq_cst);
                return;
            }
        }

        /// 消费者: 推入消费者拥有的队列尾部(与 popFirst 同一块, 单线程无原子)
        pub fn appendC(self: *Self, data: T) !void {
            try self.queues[self.consumerIdx].append(data);
        }

        pub fn iterateC(self: *Self) Deque.Iterator {
            return self.queues[self.consumerIdx].iterate();
        }

        pub fn removeAt(self: *Self, index: usize) void {
            self.queues[self.consumerIdx].remove(index);
        }

        /// 消费者: 交换两块队列的归属(调用时消费者不得操作队列)
        pub fn swap(self: *Self) void {
            const zone = tracy.initZone(@src(), .{ .name = "doubleBufferQueue swap" });
            defer zone.deinit();

            _ = self.state.fetchAdd(1, .seq_cst); // odd: 挡住新生产者
            while (self.writers.load(.seq_cst) != 0) {
                std.atomic.spinLoopHint();
            }

            self.consumerIdx = 1 - self.consumerIdx;

            _ = self.state.fetchAdd(1, .seq_cst); // even: generation + 1, 归属翻转
        }
    };
}
