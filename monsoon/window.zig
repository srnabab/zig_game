const std = @import("std");
const sdl = @import("sdl").sdl;
const SDL_CheckResult = @import("sdl").SDL_CheckResult;

const tracy = @import("tracy");

const DefaultWindowWidth = 800;
const DefaultWindowHeight = 600;

pub fn createWindow(width: *u32, height: *u32) !*sdl.SDL_Window {
    const zone = tracy.initZone(@src(), .{ .name = "create window" });
    defer zone.deinit();

    if (width.* == 0) width.* = DefaultWindowWidth;

    if (height.* == 0) height.* = DefaultWindowHeight;

    const temp = sdl.SDL_CreateWindow("window", @intCast(width.*), @intCast(height.*), sdl.SDL_WINDOW_VULKAN);
    try SDL_CheckResult(temp);
    return temp.?;
}

pub fn destroyWindow(windows: ?*sdl.SDL_Window) void {
    sdl.SDL_DestroyWindow(windows);
}
