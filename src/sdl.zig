const std = @import("std");

pub const sdl = @cImport(@cInclude("SDL3/SDL_namespace.h"));

const SDL_Error = error{
    ErrorSDL,
};

pub fn SDL_CheckResult(result: anytype) !void {
    switch (@typeInfo(@TypeOf(result))) {
        .bool => {
            if (result)
                return;
        },
        .optional => {
            if (result) |_|
                return;
        },
        else => {
            @compileError(std.fmt.comptimePrint("type {s} not supported", .{@tagName(@typeInfo(result))}));
        },
    }

    std.log.err("SDL error: {s}", .{sdl.SDL_GetError()});
    return SDL_Error.ErrorSDL;
}
