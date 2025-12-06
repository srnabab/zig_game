const std = @import("std");
const sdl = @import("sdl").sdl;

const tracy = @import("tracy");

const DefaultWindowWidth = 800;
const DefaultWindowHeight = 600;

pub fn createWindow(width: *u32, height: *u32) !*sdl.SDL_Window {
    const zone = tracy.initZone(@src(), .{ .name = "create window" });
    defer zone.deinit();

    if (width.* == 0) width.* = DefaultWindowWidth;

    if (height.* == 0) height.* = DefaultWindowHeight;

    const temp = sdl.SDL_CreateWindow("window", @intCast(width.*), @intCast(height.*), sdl.SDL_WINDOW_VULKAN);
    if (temp) |window| {
        return window;
    } else {
        std.log.err("SDL error {s}", .{sdl.SDL_GetError()});
        return error.ErrorSDL;
    }
}
