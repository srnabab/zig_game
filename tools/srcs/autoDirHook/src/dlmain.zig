const std = @import("std");
const windows = std.os.windows;
const ntdll = windows.ntdll;

const CREATE_NEW: windows.DWORD = 1;
const CREATE_ALWAYS: windows.DWORD = 2;
const OPEN_EXISTING: windows.DWORD = 3;
const OPEN_ALWAYS: windows.DWORD = 4;

const GENERIC_READ = 0x80000000;
const GENERIC_WRITE = 0x40000000;
const GENERIC_EXECUTE = 0x20000000;
const GENERIC_ALL = 0x10000000;

const FILE_WRITE_DATA = 0x0002;
const FILE_APPEND_DATA = 0x0004;

const DLL_PROCESS_ATTACH: windows.DWORD = 1;
const DLL_PROCESS_DETACH: windows.DWORD = 0;

extern "kernel32" fn CreateFileW(
    lpFileName: [*:0]const u16,
    dwDesiredAccess: windows.DWORD,
    dwShareMode: windows.DWORD,
    lpSecurityAttributes: ?*windows.SECURITY_ATTRIBUTES,
    dwCreationDisposition: windows.DWORD,
    dwFlagsAndAttributes: windows.DWORD,
    hTemplateFile: ?windows.HANDLE,
) callconv(.winapi) windows.HANDLE;

extern "kernel32" fn CreateProcessW(
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
) callconv(.winapi) windows.BOOL;

extern "kernel32" fn GetCurrentThread() callconv(.winapi) windows.HANDLE;
extern "kernel32" fn DisableThreadLibraryCalls(hLibModule: windows.HMODULE) callconv(.winapi) windows.BOOL;
extern "kernel32" fn GetModuleHandleW(lpModuleName: ?windows.LPCWSTR) callconv(.winapi) ?windows.HMODULE;

// FARPROC is `INT_PTR (WINAPI *)()`; keeping it as a function pointer (instead of
// *anyopaque) lets us `@ptrCast` between function pointers with matching alignment.
const FARPROC = ?*const fn () callconv(.winapi) isize;
extern "kernel32" fn GetProcAddress(hModule: windows.HMODULE, lpProcName: [*:0]const u8) callconv(.winapi) FARPROC;
extern "kernel32" fn GetModuleFileNameA(hModule: ?windows.HMODULE, lpFilename: [*]u8, nSize: windows.DWORD) callconv(.winapi) windows.DWORD;
extern "kernel32" fn GetFullPathNameW(lpFileName: [*:0]const u16, nBufferLength: windows.DWORD, lpBuffer: [*]u16, lpFilePart: ?*?[*:0]u16) callconv(.winapi) windows.DWORD;
// Creates the whole directory chain in one call. Returns ERROR_SUCCESS (0) or
// ERROR_ALREADY_EXISTS (183) on success.
extern "shell32" fn SHCreateDirectoryExW(hwnd: ?windows.HWND, pszPath: [*:0]const u16, psa: ?*const windows.SECURITY_ATTRIBUTES) callconv(.winapi) c_int;
extern "Pathcch" fn PathCchRemoveFileSpec(pszPath: [*:0]u16, cchPath: usize) callconv(.winapi) c_long;

extern fn DetourIsHelperProcess() callconv(.winapi) windows.BOOL;
extern fn DetourRestoreAfterWith() callconv(.winapi) windows.BOOL;
extern fn DetourTransactionBegin() callconv(.winapi) windows.LONG;
extern fn DetourUpdateThread(hThread: windows.HANDLE) callconv(.winapi) windows.LONG;
extern fn DetourTransactionCommit() callconv(.winapi) windows.LONG;
extern fn DetourAttach(ppPointer: *anyopaque, pDetour: *const anyopaque) callconv(.winapi) windows.LONG;
extern fn DetourDetach(ppPointer: *anyopaque, pDetour: *const anyopaque) callconv(.winapi) windows.LONG;

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

// NOTE: lpDllName is LPCSTR (ANSI) in the real Detours 4.0.1 ABI; see autodir_main.zig.
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

const CreateFileW_Fn = fn (
    [*:0]const u16,
    windows.DWORD,
    windows.DWORD,
    ?*windows.SECURITY_ATTRIBUTES,
    windows.DWORD,
    windows.DWORD,
    ?windows.HANDLE,
) callconv(.winapi) windows.HANDLE;

// CreateFileW is a forwarder in kernel32.dll; hook the real KernelBase.dll
// implementation so that callers which bypass the forwarder are caught too.
const kernel_base_dll = std.unicode.utf8ToUtf16LeStringLiteral("KernelBase.dll");
const kernel32_dll = std.unicode.utf8ToUtf16LeStringLiteral("kernel32.dll");

var TrueCreateFileW: *const CreateFileW_Fn = &CreateFileW;
var TrueCreateProcessW: *const CreateProcessW_Fn = &CreateProcessW;

// ANSI path of this DLL, filled in DLL_PROCESS_ATTACH.
var g_dllPath: [windows.MAX_PATH + 1]u8 = [_]u8{0} ** (windows.MAX_PATH + 1);

// std.AutoHashMap rejects slice keys, so provide a content-based context for the
// wide (UTF-16) parent-directory keys.
const U16SliceContext = struct {
    pub fn hash(_: U16SliceContext, s: []const u16) u64 {
        return std.hash.Wyhash.hash(0, std.mem.sliceAsBytes(s));
    }

    pub fn eql(_: U16SliceContext, a: []const u16, b: []const u16) bool {
        return std.mem.eql(u16, a, b);
    }
};

// Memoized set of parent directories already confirmed to exist.
// Guarded by a Slim Reader/Writer lock (no Io instance is available in a DLL hook).
var g_knownDirs: std.HashMapUnmanaged([]const u16, void, U16SliceContext, std.hash_map.default_max_load_percentage) = .empty;
var g_cacheLock: windows.SRWLOCK = windows.SRWLOCK_INIT;

fn HookedCreateFileW(
    lpFileName: [*:0]const u16,
    dwDesiredAccess: windows.DWORD,
    dwShareMode: windows.DWORD,
    lpSecurityAttributes: ?*windows.SECURITY_ATTRIBUTES,
    dwCreationDisposition: windows.DWORD,
    dwFlagsAndAttributes: windows.DWORD,
    hTemplateFile: ?windows.HANDLE,
) callconv(.winapi) windows.HANDLE {
    // Only act when the caller explicitly intends to create/overwrite.
    // var isWrite = false;

    // if (dwCreationDisposition == CREATE_ALWAYS or
    //     dwCreationDisposition == CREATE_NEW or
    //     dwCreationDisposition == OPEN_ALWAYS)
    // {
    //     isWrite = true;
    // }

    // std.log.debug("{d}", .{dwDesiredAccess});

    // if (dwCreationDisposition == OPEN_EXISTING and dwDesiredAccess & (GENERIC_WRITE | FILE_WRITE_DATA | FILE_APPEND_DATA) != 0) {
    //     isWrite = true;
    // }

    if (lpFileName[0] != 0 and !(lpFileName[0] == '\\' and lpFileName[1] == '\\' and lpFileName[2] == '.')) {
        var initMem: [512:0]u16 = undefined;
        const len = GetFullPathNameW(lpFileName, 512, &initMem, null);
        var full: [:0]u16 = undefined;

        if (len < 512) {
            full = initMem[0..len :0];
        } else {
            full = std.heap.c_allocator.allocSentinel(u16, len, 0) catch return TrueCreateFileW(lpFileName, dwDesiredAccess, dwShareMode, lpSecurityAttributes, dwCreationDisposition, dwFlagsAndAttributes, hTemplateFile);
            _ = GetFullPathNameW(lpFileName, len, full.ptr, null);
        }

        // const size = std.unicode.wtf16LeToWtf8Alloc(std.heap.c_allocator, full[0..len]) catch return TrueCreateFileW(lpFileName, dwDesiredAccess, dwShareMode, lpSecurityAttributes, dwCreationDisposition, dwFlagsAndAttributes, hTemplateFile);
        // std.log.debug(" res {d}: {s}", .{ 0, size });
        // std.log.debug("lpFileName: {s}", .{size});

        if (len != 0 and len < windows.MAX_PATH) {

            // Locate the parent directory (everything before the last separator).
            const removeRes = PathCchRemoveFileSpec(full.ptr, len);

            // S_OK
            if (removeRes == 0) {
                ntdll.RtlAcquireSRWLockExclusive(&g_cacheLock);
                defer ntdll.RtlReleaseSRWLockExclusive(&g_cacheLock);

                const newLen = std.mem.len(full.ptr);

                if (!g_knownDirs.contains(full[0..newLen])) {
                    // Temporarily NUL-terminate the parent path inside `full`,
                    // then let shell32 create the whole chain at once.

                    const res = SHCreateDirectoryExW(null, @ptrCast(full[0..newLen].ptr), null);

                    // ERROR_SUCCESS (0) or ERROR_ALREADY_EXISTS (183) count as success.
                    if (res == 0 or res == 183) {
                        const key = std.heap.c_allocator.dupe(u16, full[0..newLen]) catch return TrueCreateFileW(lpFileName, dwDesiredAccess, dwShareMode, lpSecurityAttributes, dwCreationDisposition, dwFlagsAndAttributes, hTemplateFile);
                        g_knownDirs.put(std.heap.c_allocator, key, {}) catch {
                            std.heap.c_allocator.free(key);
                        };
                    }
                }
            }
        }
    }

    return TrueCreateFileW(lpFileName, dwDesiredAccess, dwShareMode, lpSecurityAttributes, dwCreationDisposition, dwFlagsAndAttributes, hTemplateFile);
}

fn HookedCreateProcessW(
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
) callconv(.winapi) windows.BOOL {
    // Let grandchildren inherit the hook too.
    const dllPathZ: [*:0]const u8 = @ptrCast(&g_dllPath);
    return DetourCreateProcessWithDllExW(
        lpApplicationName,
        lpCommandLine,
        lpProcessAttributes,
        lpThreadAttributes,
        bInheritHandles,
        dwCreationFlags,
        lpEnvironment,
        lpCurrentDirectory,
        lpStartupInfo,
        lpProcessInformation,
        dllPathZ,
        TrueCreateProcessW,
    );
}

// The only reason this exists: Detours requires the injected DLL to export at
// least one function.
pub export fn AutoDirMarker() callconv(.c) void {}

pub export fn DllMain(
    hinstDLL: windows.HINSTANCE,
    ul_reason_for_call: windows.DWORD,
    lpReserved: windows.LPVOID,
) callconv(.winapi) windows.BOOL {
    _ = lpReserved;

    if (DetourIsHelperProcess() != .FALSE) return .TRUE;

    if (ul_reason_for_call == DLL_PROCESS_ATTACH) {
        std.log.debug("AutoDir Hook injected", .{});

        _ = DisableThreadLibraryCalls(@as(windows.HMODULE, @ptrCast(hinstDLL)));
        const n = GetModuleFileNameA(@as(?windows.HMODULE, @ptrCast(hinstDLL)), &g_dllPath, windows.MAX_PATH);
        if (n < windows.MAX_PATH) g_dllPath[n] = 0;

        // Resolve CreateFileW from KernelBase.dll (fall back to kernel32.dll).
        var h_kernel_base = GetModuleHandleW(kernel_base_dll);
        if (h_kernel_base == null) h_kernel_base = GetModuleHandleW(kernel32_dll);
        if (h_kernel_base) |mod| {
            if (GetProcAddress(mod, "CreateFileW")) |proc| {
                TrueCreateFileW = @ptrCast(proc);
            }
        }

        _ = DetourRestoreAfterWith();
        _ = DetourTransactionBegin();
        _ = DetourUpdateThread(GetCurrentThread());
        _ = DetourAttach(@ptrCast(&TrueCreateFileW), @ptrCast(&HookedCreateFileW));
        _ = DetourAttach(@ptrCast(&TrueCreateProcessW), @ptrCast(&HookedCreateProcessW));
        _ = DetourTransactionCommit();
    } else if (ul_reason_for_call == DLL_PROCESS_DETACH) {
        _ = DetourTransactionBegin();
        _ = DetourUpdateThread(GetCurrentThread());
        _ = DetourDetach(@ptrCast(&TrueCreateFileW), @ptrCast(&HookedCreateFileW));
        _ = DetourDetach(@ptrCast(&TrueCreateProcessW), @ptrCast(&HookedCreateProcessW));
        _ = DetourTransactionCommit();
    }

    return .TRUE;
}
