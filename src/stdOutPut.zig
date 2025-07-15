const Writer = @import("std").fs.File.Writer;
const io = @import("std").io;
const debug = @import("std").debug;
const std = @import("std");

pub var out: Writer = undefined;
pub var err: Writer = undefined;

pub fn init() void {
    out = io.getStdOut().writer();
    err = io.getStdErr().writer();
}
