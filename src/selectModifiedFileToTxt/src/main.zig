const std = @import("std");

const git2 = @cImport(@cInclude("git2.h"));

pub fn main() !void {
    const initTimes = git2.git_libgit2_init();

    for (0..@intCast(initTimes)) |_| {
        _ = git2.git_libgit2_shutdown();
    }
}
