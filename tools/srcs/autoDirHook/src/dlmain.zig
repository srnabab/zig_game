const std = @import("std");
const windows = std.os.windows;

const HANDLE = windows.HANDLE;
const ULONG = windows.ULONG;
const NTSTATUS = windows.NTSTATUS;
const OBJECT_ATTRIBUTES = windows.OBJECT.ATTRIBUTES;
const IO_STATUS_BLOCK = windows.IO_STATUS_BLOCK;
const LARGE_INTEGER = windows.LARGE_INTEGER;

const DLL_PROCESS_ATTACH: windows.DWORD = 1;
const DLL_PROCESS_DETACH: windows.DWORD = 0;

const FILE_ATTRIBUTE_DIRECTORY: windows.DWORD = 0x00000010;

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

extern "kernel32" fn GetCurrentThread() callconv(.winapi) HANDLE;
extern "kernel32" fn DisableThreadLibraryCalls(hLibModule: windows.HMODULE) callconv(.winapi) windows.BOOL;
extern "kernel32" fn GetModuleHandleW(lpModuleName: ?windows.LPCWSTR) callconv(.winapi) ?windows.HMODULE;

// FARPROC is `INT_PTR (WINAPI *)()`; keeping it as a function pointer (instead of
// *anyopaque) lets us `@ptrCast` between function pointers with matching alignment.
const FARPROC = ?*const fn () callconv(.winapi) isize;
extern "kernel32" fn GetProcAddress(hModule: windows.HMODULE, lpProcName: [*:0]const u8) callconv(.winapi) FARPROC;

extern "kernel32" fn GetModuleFileNameA(hModule: ?windows.HMODULE, lpFilename: [*]u8, nSize: windows.DWORD) callconv(.winapi) windows.DWORD;
extern "kernel32" fn GetFinalPathNameByHandleW(hFile: HANDLE, lpszFilePath: [*]u16, cchFilePath: windows.DWORD, dwFlags: windows.DWORD) callconv(.winapi) windows.DWORD;
extern "kernel32" fn GetFileAttributesW(lpFileName: [*:0]const u16) callconv(.winapi) windows.DWORD;

// Creates the whole directory chain in one call. Returns ERROR_SUCCESS (0) or
// ERROR_ALREADY_EXISTS (183) on success.
extern "shell32" fn SHCreateDirectoryExW(hwnd: ?windows.HWND, pszPath: [*:0]const u16, psa: ?*const windows.SECURITY_ATTRIBUTES) callconv(.winapi) c_int;

extern fn DetourIsHelperProcess() callconv(.winapi) windows.BOOL;
extern fn DetourRestoreAfterWith() callconv(.winapi) windows.BOOL;
extern fn DetourTransactionBegin() callconv(.winapi) windows.LONG;
extern fn DetourUpdateThread(hThread: HANDLE) callconv(.winapi) windows.LONG;
extern fn DetourTransactionCommit() callconv(.winapi) windows.LONG;
extern fn DetourAttach(ppPointer: *anyopaque, pDetour: *const anyopaque) callconv(.winapi) windows.LONG;
extern fn DetourDetach(ppPointer: *anyopaque, pDetour: *const anyopaque) callconv(.winapi) windows.LONG;

// Raw C-style NtCreateFile prototype. The flag arguments are passed through
// untouched, so plain ULONG is enough (the object-manager enums are ABI-compatible u32).
const NtCreateFile_Fn = fn (
    FileHandle: *HANDLE,
    DesiredAccess: ULONG,
    ObjectAttributes: ?*const OBJECT_ATTRIBUTES,
    IoStatusBlock: *IO_STATUS_BLOCK,
    AllocationSize: ?*LARGE_INTEGER,
    FileAttributes: ULONG,
    ShareAccess: ULONG,
    CreateDisposition: ULONG,
    CreateOptions: ULONG,
    EaBuffer: ?*anyopaque,
    EaLength: ULONG,
) callconv(.winapi) NTSTATUS;

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

const ntdll_dll = std.unicode.utf8ToUtf16LeStringLiteral("ntdll.dll");

// Resolved from ntdll.dll in DLL_PROCESS_ATTACH, then replaced by Detours with the trampoline.
var TrueNtCreateFile: ?*const NtCreateFile_Fn = null;
var TrueCreateProcessW: *const CreateProcessW_Fn = &CreateProcessW;

// ANSI path of this DLL, filled in DLL_PROCESS_ATTACH.
var g_dllPath: [windows.MAX_PATH + 1]u8 = [_]u8{0} ** (windows.MAX_PATH + 1);

// Reentrancy guard: SHCreateDirectoryExW itself performs NtCreateFile calls, which
// would otherwise re-enter HookedNtCreateFile and loop forever.
threadlocal var g_inside_hook: bool = false;

fn HookedNtCreateFile(
    FileHandle: *HANDLE,
    DesiredAccess: ULONG,
    ObjectAttributes: ?*const OBJECT_ATTRIBUTES,
    IoStatusBlock: *IO_STATUS_BLOCK,
    AllocationSize: ?*LARGE_INTEGER,
    FileAttributes: ULONG,
    ShareAccess: ULONG,
    CreateDisposition: ULONG,
    CreateOptions: ULONG,
    EaBuffer: ?*anyopaque,
    EaLength: ULONG,
) callconv(.winapi) NTSTATUS {
    if (!g_inside_hook) {
        if (ObjectAttributes) |oa| {
            if (oa.ObjectName) |uPath| {
                if (uPath.Buffer != null and uPath.Length != 0) {
                    g_inside_hook = true;
                    defer g_inside_hook = false;

                    // Use Length (bytes) rather than relying on a NUL terminator.
                    const raw_path = uPath.slice();
                    const gpa = std.heap.c_allocator;
                    var resolved: std.ArrayListUnmanaged(u16) = .empty;
                    defer resolved.deinit(gpa);

                    // Paths opened relative to an already-open directory handle.
                    if (oa.RootDirectory) |root| {
                        var root_buf: [windows.MAX_PATH * 2]u16 = undefined;
                        const ret = GetFinalPathNameByHandleW(root, &root_buf, root_buf.len, 0);
                        if (ret > 0 and ret < root_buf.len) {
                            var root_path: []const u16 = root_buf[0..ret];
                            // Drop the \\?\ prefix.
                            if (root_path.len >= 4 and
                                root_path[0] == '\\' and root_path[1] == '\\' and
                                root_path[2] == '?' and root_path[3] == '\\')
                            {
                                root_path = root_path[4..];
                            }
                            resolved.appendSlice(gpa, root_path) catch {};
                            if (resolved.items.len != 0 and resolved.items[resolved.items.len - 1] != '\\') {
                                resolved.append(gpa, '\\') catch {};
                            }
                        }
                    }

                    // NT native absolute prefix `\??\` (e.g. \??\C:\...) overrides the root.
                    if (raw_path.len >= 4 and
                        raw_path[0] == '\\' and raw_path[1] == '?' and
                        raw_path[2] == '?' and raw_path[3] == '\\')
                    {
                        resolved.clearRetainingCapacity();
                        resolved.appendSlice(gpa, raw_path[4..]) catch {};
                    } else {
                        resolved.appendSlice(gpa, raw_path) catch {};
                    }

                    // Strip the file name to obtain the parent directory.
                    if (resolved.items.len != 0) {
                        var last_slash: ?usize = null;
                        var k = resolved.items.len;
                        while (k > 0) {
                            k -= 1;
                            const c = resolved.items[k];
                            if (c == '\\' or c == '/') {
                                last_slash = k;
                                break;
                            }
                        }
                        if (last_slash) |ls| {
                            // Skip drive roots such as "C:\".
                            const is_drive_root = ls <= 2 and resolved.items.len >= 2 and resolved.items[1] == ':';
                            if (!is_drive_root) {
                                resolved.shrinkRetainingCapacity(ls);
                                resolved.append(gpa, 0) catch {};
                                if (resolved.items.len == ls + 1) {
                                    const parent_path: [*:0]const u16 = @ptrCast(resolved.items.ptr);
                                    const attrs = GetFileAttributesW(parent_path);
                                    // Missing, or existing but not a directory.
                                    if (attrs == windows.INVALID_FILE_ATTRIBUTES or (attrs & FILE_ATTRIBUTE_DIRECTORY) == 0) {
                                        _ = SHCreateDirectoryExW(null, parent_path, null);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Pass through to the original NtCreateFile.
    return TrueNtCreateFile.?(FileHandle, DesiredAccess, ObjectAttributes, IoStatusBlock, AllocationSize, FileAttributes, ShareAccess, CreateDisposition, CreateOptions, EaBuffer, EaLength);
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

    if (lpApplicationName) |name| {
        const len = std.mem.len(name);
        const size = std.unicode.wtf16LeToWtf8Alloc(std.heap.c_allocator, name[0..len]) catch &.{};

        defer std.heap.c_allocator.free(size);

        std.log.debug("hook sub process {s}", .{size});
    }

    const dllPathZ: [*:0]const u8 = @ptrCast(&g_dllPath);
    const res = DetourCreateProcessWithDllExW(
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

    std.log.debug("hook {}", .{res.toBool()});

    return res;
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

        // NtCreateFile is the syscall gate in ntdll.dll.
        const h_ntdll = GetModuleHandleW(ntdll_dll);
        if (h_ntdll) |mod| {
            if (GetProcAddress(mod, "NtCreateFile")) |proc| {
                TrueNtCreateFile = @ptrCast(proc);
            }
        }

        _ = DetourRestoreAfterWith();
        _ = DetourTransactionBegin();
        _ = DetourUpdateThread(GetCurrentThread());
        if (TrueNtCreateFile != null) {
            _ = DetourAttach(@ptrCast(&TrueNtCreateFile), @ptrCast(&HookedNtCreateFile));
        }
        _ = DetourAttach(@ptrCast(&TrueCreateProcessW), @ptrCast(&HookedCreateProcessW));
        _ = DetourTransactionCommit();
    } else if (ul_reason_for_call == DLL_PROCESS_DETACH) {
        _ = DetourTransactionBegin();
        _ = DetourUpdateThread(GetCurrentThread());
        if (TrueNtCreateFile != null) {
            _ = DetourDetach(@ptrCast(&TrueNtCreateFile), @ptrCast(&HookedNtCreateFile));
        }
        _ = DetourDetach(@ptrCast(&TrueCreateProcessW), @ptrCast(&HookedCreateProcessW));
        _ = DetourTransactionCommit();
    }

    return .TRUE;
}
