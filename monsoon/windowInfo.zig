const std = @import("std");
const atomic = std.atomic;

var width: atomic.Value(u32) = .init(400);
var height: atomic.Value(u32) = .init(300);

var scale: atomic.Value(f32) = .init(1.0);

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

pub fn setScale(num: f32) void {
    scale.store(num, .release);
}
