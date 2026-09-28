const std = @import("std");
const atomic = std.atomic;

var width: atomic.Value(u32) = .init(800);
var height: atomic.Value(u32) = .init(600);

pub fn getWidth() u32 {
    return width.load(.acquire);
}

pub fn getHeight() u32 {
    return height.load(.acquire);
}

pub fn setWidth(num: u32) void {
    width.store(num, .release);
}

pub fn setHeight(num: u32) void {
    height.store(num, .release);
}
