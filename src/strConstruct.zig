const std = @import("std");

/// 由 u8pack 在 comptime 逐个调用 `@field(construct, <name>)()`,
/// 每张表提供一个 `pub fn <name>() std.StaticStringMap(u32)`。
/// 名字也会进入 u8pack 的 belongMap(与 pass/buffer/file 名共用一张查名表),
/// 所以**不要与 pass/buffer/file 名重名**。
pub const maps = [_][]const u8{
    "rdatas",
};

/// rdata item 名(即 `Assets/rdata/*.rdata` 里每个 item 的 `"name"`)。
/// 手写表过渡方案: 新增/改名 rdata item 必须同步这里, 否则运行期 u8pack.ID2 查不到。
/// id 用本表内部下标(0, 1, ...), 只在本表内唯一。
pub fn rdatas() std.StaticStringMap(u32) {
    return .initComptime(.{
        .{ "sprite", 0 },
        .{ "feather", 1 },
    });
}
