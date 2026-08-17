const std = @import("std");

const sdl = @import("sdl").sdl;
const SDL_CheckResult = @import("sdl").SDL_CheckResult;

pub fn showErrorWithMessageBox(err: []const u8) void {
    SDL_CheckResult(sdl.SDL_ShowSimpleMessageBox(
        sdl.SDL_MESSAGEBOX_ERROR,
        "ERROR",
        @ptrCast(err.ptr),
        null,
    )) catch |err3| {
        std.log.err("{s}\n{s}", .{ @errorName(err3), err });
    };
}
