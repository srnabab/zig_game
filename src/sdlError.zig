const sdl = @cImport(@cInclude("SDL3/SDL_namespace.h"));
const std = @import("std");

const SDL_Error = error{
    ErrorSDL,
};
pub fn SDL_CheckResult(result: bool) !void {
    if (result) {
        return;
    } else {
        std.log.err("SDL error: {s}", .{sdl.SDL_GetError()});
        return SDL_Error.ErrorSDL;
    }
}
