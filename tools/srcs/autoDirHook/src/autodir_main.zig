const std = @import("std");
const windows = std.os.windows;

const INVALID_FILE_ATTRIBUTES: windows.DWORD = 0xFFFFFFFF;
const INFINITE: windows.DWORD = 0xFFFFFFFF;

extern "kernel32" fn GetCommandLineW() callconv(.winapi) [*:0]u16;
extern "kernel32" fn GetModuleFileNameA(hModule: ?windows.HMODULE, lpFilename: [*]u8, nSize: windows.DWORD) callconv(.winapi) windows.DWORD;
extern "kernel32" fn GetFileAttributesA(lpFileName: [*:0]const u8) callconv(.winapi) windows.DWORD;
extern "kernel32" fn WaitForSingleObject(hHandle: windows.HANDLE, dwMilliseconds: windows.DWORD) callconv(.winapi) windows.DWORD;
extern "kernel32" fn GetExitCodeProcess(hProcess: windows.HANDLE, lpExitCode: *windows.DWORD) callconv(.winapi) windows.BOOL;
extern "kernel32" fn CloseHandle(hObject: windows.HANDLE) callconv(.winapi) windows.BOOL;
extern "kernel32" fn GetLastError() callconv(.winapi) windows.DWORD;
extern "kernel32" fn ExitProcess(uExitCode: windows.UINT) callconv(.winapi) noreturn;

const CreateProcessW_Fn = fn (
    ?windows.LPCWSTR,
    ?windows.LPWSTR,
    ?*windows.SECURITY_ATTRIBUTES,
    ?*windows.SECURITY_ATTRIBUTES,
    windows.BOOL,
    windows.DWORD,
    ?*anyopaque,
    ?windows.LPCWSTR,
    *windows.STARTUPINFOW,
    *windows.PROCESS.INFORMATION,
) callconv(.winapi) windows.BOOL;

// NOTE: the real Detours 4.0.1 ABI takes lpDllName as LPCSTR (ANSI), even in the
// Wide variant (it is later embedded into a `%hs` rundll32 command). We therefore
// resolve the DLL path with GetModuleFileNameA below.
extern fn DetourCreateProcessWithDllExW(
    lpApplicationName: ?windows.LPCWSTR,
    lpCommandLine: ?windows.LPWSTR,
    lpProcessAttributes: ?*windows.SECURITY_ATTRIBUTES,
    lpThreadAttributes: ?*windows.SECURITY_ATTRIBUTES,
    bInheritHandles: windows.BOOL,
    dwCreationFlags: windows.DWORD,
    lpEnvironment: ?*anyopaque,
    lpCurrentDirectory: ?windows.LPCWSTR,
    lpStartupInfo: *windows.STARTUPINFOW,
    lpProcessInformation: *windows.PROCESS.INFORMATION,
    lpDllName: ?[*:0]const u8,
    pfCreateProcessW: ?*const CreateProcessW_Fn,
) callconv(.winapi) windows.BOOL;

pub fn main() noreturn {
    // Skip "autoDir.exe" inside the raw command line so that quoting/spacing of
    // the real command is preserved 100% (no argv re-joining).
    var cmd: [*:0]u16 = GetCommandLineW();
    while (cmd[0] == ' ' or cmd[0] == '\t') cmd += 1;
    if (cmd[0] == '"') {
        cmd += 1;
        while (cmd[0] != 0 and cmd[0] != '"') cmd += 1;
        if (cmd[0] == '"') cmd += 1;
    } else {
        while (cmd[0] != 0 and cmd[0] != ' ' and cmd[0] != '\t') cmd += 1;
    }
    while (cmd[0] == ' ' or cmd[0] == '\t') cmd += 1;
    const sub: [*:0]const u16 = cmd;

    if (sub[0] == 0) {
        std.debug.print(
            \\AutoDir - interceptor create missing folder
            \\usage:
            \\  autoDir.exe <program> [args...]
            \\
            \\example:
            \\  autoDir.exe python script.py
            \\  autoDir.exe ffmpeg -i input.mp4 output/sub/video.mp4
            \\
        , .{});
        ExitProcess(1);
    }

    // Build the ANSI path of the hook DLL that sits next to autoDir.exe.
    var dllPath: [windows.MAX_PATH + 1]u8 = [_]u8{0} ** (windows.MAX_PATH + 1);
    {
        const n = GetModuleFileNameA(null, &dllPath, windows.MAX_PATH);
        if (n == 0 or n >= windows.MAX_PATH) {
            std.debug.print("[AutoDir Error] cannot reslove self path\n", .{});
            ExitProcess(1);
        }
        var i: usize = n;
        while (i > 0 and dllPath[i - 1] != '\\' and dllPath[i - 1] != '/') i -= 1;
        const dllName = "autoDirHook.dll";
        if (i + dllName.len > windows.MAX_PATH) {
            std.debug.print("[AutoDir Error] Hook Path too long\n", .{});
            ExitProcess(1);
        }
        @memcpy(dllPath[i .. i + dllName.len], dllName);
        dllPath[i + dllName.len] = 0;
    }

    if (GetFileAttributesA(@ptrCast(&dllPath)) == INVALID_FILE_ATTRIBUTES) {
        std.debug.print("[AutoDir Error] can't find Hook module: {s}\n", .{std.mem.sliceTo(&dllPath, 0)});
        ExitProcess(1);
    }

    // CreateProcessW requires a writable command-line buffer.
    const subLen = std.mem.len(sub);
    const gpa = std.heap.c_allocator;
    const cmdBuf = gpa.alloc(u16, subLen + 1) catch {
        std.debug.print("[AutoDir Error] OOM\n", .{});
        ExitProcess(1);
    };
    @memcpy(cmdBuf[0..subLen], sub[0..subLen]);
    cmdBuf[subLen] = 0;
    const cmdLine: [*:0]u16 = @ptrCast(cmdBuf.ptr);

    var si = std.mem.zeroes(windows.STARTUPINFOW);
    si.cb = @sizeOf(windows.STARTUPINFOW);
    var pi = std.mem.zeroes(windows.PROCESS.INFORMATION);

    const dllNameZ: [*:0]const u8 = @ptrCast(&dllPath);

    // Launch the child with the hook DLL force-injected. bInheritHandles=TRUE
    // lets the child keep the console (stdin/stdout/stderr).
    if (DetourCreateProcessWithDllExW(
        null,
        cmdLine,
        null,
        null,
        .TRUE,
        0,
        null,
        null,
        &si,
        &pi,
        dllNameZ,
        null,
    ) == .FALSE) {
        const err = GetLastError();
        std.debug.print("[AutoDir Error] program can't be executed (error code: {d})\n", .{err});
        ExitProcess(if (err == 0) 1 else err);
    }

    _ = WaitForSingleObject(pi.hProcess, INFINITE);
    var exitCode: windows.DWORD = 0;
    _ = GetExitCodeProcess(pi.hProcess, &exitCode);
    _ = CloseHandle(pi.hProcess);
    _ = CloseHandle(pi.hThread);

    // Forward the child exit code so the CLI stays fully transparent.
    ExitProcess(exitCode);
}
