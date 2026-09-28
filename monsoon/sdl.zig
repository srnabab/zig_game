const std = @import("std");

pub const sdl = @import("sdl");
const enumFromC = @import("enumFromC");

pub const SDL_EventType = enumFromC.generateEnumFromC(
    sdl,
    sdl.SDL_EventType,
    "SDL_EVENT_FIRST",
    "SDL_EVENT_ENUM_PADDING",
    .exhaustive,
);

pub const SDL_Keycode = enumFromC.generateEnumFromC(
    sdl,
    sdl.SDL_Keycode,
    "SDLK_UNKNOWN",
    "SDLK_RHYPER",
    .nonexhaustive,
);

pub const SDL_Scancode = enumFromC.generateEnumFromC(
    sdl,
    sdl.SDL_Scancode,
    "SDL_SCANCODE_UNKNOWN",
    "SDL_SCANCODE_COUNT",
    .nonexhaustive,
);

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
