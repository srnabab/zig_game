const InputRegister = @import("inputRegister");
const u8pack = @import("u8pack");

pub fn setInput(comptime ctx: ?*u8pack.CTX) !void {
    _ = try InputRegister.createInputAction(ctx, "press_Q", true, false, false, false, 1);
    _ = try InputRegister.createInputAction(ctx, "press_E", true, false, false, false, 1);
    _ = try InputRegister.createInputAction(ctx, "exit", true, false, false, false, 1);
    _ = try InputRegister.createInputAction(ctx, "Add", true, false, false, false, 1);
}
