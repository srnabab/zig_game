const vk = @cImport(@cInclude("vulkan/vulkan.h"));
const sdl = @cImport(@cInclude("SDL3/SDL_namespace.h"));
const std = @import("std");
const output = @import("output");
const Allocator = @import("std").mem.Allocator;
const VkError = @import("vulkanType.zig").VkError;
const VkResult = @import("vulkanType.zig").VkResult;
const VkResultToError = @import("resultToError.zig");

const layerNeeded = [_][*c]const u8{"VK_LAYER_KHRONOS_validation"};
const extensionNeeded = [_][*c]const u8{ "VK_KHR_surface", "VK_KHR_win32_surface" };

fn comptime_print(comptime format: []const u8, comptime args: anytype) void {
    @compileLog(std.fmt.comptimePrint(format, args));
}

pub const VkStruct = struct {
    const Self = @This();

    allocator: Allocator = undefined,
    allocCallBacks: vk.VkAllocationCallbacks = undefined,
    pAllocCallBacks: [*c]vk.VkAllocationCallbacks = null,
    window: *sdl.SDL_Window = undefined,
    instance: vk.VkInstance = null,
    surface: vk.VkSurfaceKHR = null,
    physicalDevice: vk.VkPhysicalDevice = null,

    pub fn init(allocator: Allocator) VkStruct {
        return VkStruct{ .allocator = allocator };
    }

    pub fn initVulkan(self: *Self) VkError!void {
        try self.*.createWindow();
        const version = try getVulkanVersion();
        printVersion(version);
        try self.createInstance();
        try self.createSurface();
        try self.pickPhysicalDevice();
    }

    pub fn deinit(self: *Self) void {
        sdl.SDL_Vulkan_DestroySurface(@ptrCast(self.*.instance), @ptrCast(self.*.surface), @ptrCast(self.*.pAllocCallBacks));
        vk.vkDestroyInstance(self.*.instance, self.*.pAllocCallBacks);
        sdl.SDL_DestroyWindow(self.*.window);
    }

    fn createWindow(self: *Self) !void {
        const temp = sdl.SDL_CreateWindow("window", 800, 600, sdl.SDL_WINDOW_VULKAN);
        if (temp) |window| {
            self.*.window = window;
        } else {
            return VkError.VK_ERROR_UNKNOWN;
        }
    }

    fn initAllocCallBacks(self: *Self) void {
        _ = self;
        // self.*.allocCallBacks.pUserData = null;
        // self.*.allocCallBacks.pfnAllocation = vkAlloc;
        // self.*.allocCallBacks.pfnReallocation = vkRealloc;
        // self.*.allocCallBacks.pfnFree = vkFree;
        // self.*.allocCallBacks.pfnInternalAllocation = null;
        // self.*.allocCallBacks.pfnInternalFree = null;
    }

    fn checkVkResult(result: vk.VkResult) VkError!void {
        VkResultToError.VkResultToError(@enumFromInt(result)) catch |err| {
            return err;
        };
    }

    fn getVulkanVersion() VkError!u32 {
        var apiVersion: c_uint = 0;
        try checkVkResult(vk.vkEnumerateInstanceVersion(&apiVersion));

        return apiVersion;
    }

    fn printVersion(apiVersion: u32) void {
        const major = vk.VK_VERSION_MAJOR(apiVersion);
        const minor = vk.VK_VERSION_MINOR(apiVersion);
        const patch = vk.VK_VERSION_PATCH(apiVersion);

        std.debug.print("Vulkan API Version: {d}.{d}.{d}\n", .{ major, minor, patch });
    }

    fn createInstance(self: *Self) VkError!void {
        var appInfo = vk.VkApplicationInfo{
            .sType = vk.VK_STRUCTURE_TYPE_APPLICATION_INFO,
            .pNext = null,
            .pApplicationName = "game",
            .applicationVersion = vk.VK_MAKE_API_VERSION(0, 1, 0, 0),
            .pEngineName = "engine",
            .engineVersion = vk.VK_MAKE_API_VERSION(0, 1, 0, 0),
            .apiVersion = vk.VK_API_VERSION_1_4,
        };

        const layers = try self.*.chooseEnabledLayers(vk.VkLayerProperties, "layerName", layerNeeded[0..layerNeeded.len]);
        defer layers.deinit();
        const extension = try self.*.chooseEnabledLayers(vk.VkExtensionProperties, "extensionName", extensionNeeded[0..extensionNeeded.len]);
        defer extension.deinit();

        const createInfo = self.*.allocator.create(vk.VkInstanceCreateInfo) catch |err| {
            std.debug.print("err: {s}\n", .{@errorName(err)});
            return VkError.VK_ERROR_OUT_OF_HOST_MEMORY;
        };
        defer self.*.allocator.destroy(createInfo);

        createInfo.*.sType = vk.VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
        createInfo.*.pNext = null;
        createInfo.*.flags = 0;
        createInfo.*.pApplicationInfo = &appInfo;
        createInfo.*.enabledLayerCount = @truncate(layers.items.len);
        createInfo.*.ppEnabledLayerNames = @ptrCast(layers.items.ptr);
        createInfo.*.enabledExtensionCount = @truncate(extension.items.len);
        // std.debug.print("len {d}\n", .{extension.items.len});
        createInfo.*.ppEnabledExtensionNames = @ptrCast(extension.items.ptr);

        try checkVkResult(vk.vkCreateInstance(createInfo, self.*.pAllocCallBacks, @ptrCast(&self.*.instance)));
    }

    fn chooseEnabledLayers(self: *Self, comptime fields: type, comptime field_name: []const u8, neededName: []const [*c]const u8) VkError!std.ArrayList([*c]const u8) {
        var namesEnabled = std.ArrayList([*c]const u8).init(self.*.allocator);

        var count: u32 = 0;
        var vulkanNames: []fields = undefined;
        switch (fields) {
            vk.VkLayerProperties => {
                try checkVkResult(vk.vkEnumerateInstanceLayerProperties(&count, null));
                vulkanNames = self.*.allocator.alloc(fields, count) catch |err| {
                    std.debug.print("err: {s}\n", .{@errorName(err)});
                    return VkError.VK_ERROR_OUT_OF_HOST_MEMORY;
                };
                try checkVkResult(vk.vkEnumerateInstanceLayerProperties(&count, vulkanNames.ptr));
            },
            vk.VkExtensionProperties => {
                try checkVkResult(vk.vkEnumerateInstanceExtensionProperties(null, &count, null));
                vulkanNames = self.*.allocator.alloc(fields, count) catch |err| {
                    std.debug.print("err: {s}\n", .{@errorName(err)});
                    return VkError.VK_ERROR_OUT_OF_HOST_MEMORY;
                };
                try checkVkResult(vk.vkEnumerateInstanceExtensionProperties(null, &count, vulkanNames.ptr));
            },
            else => {
                @compileError("not supported type");
            },
        }
        defer self.*.allocator.free(vulkanNames);

        for (neededName) |need| {
            var str: [256]u8 = undefined;
            const len = sdl.SDL_strlen(need);
            for (vulkanNames) |vulkan| {
                @memcpy(str[0..len], need);
                // std.debug.print("len: {d}, name1: {s}, name2: {s}\n", .{ len, str[0..len], @field(vulkan, field_name) });
                if (std.mem.eql(u8, str[0..len], @field(vulkan, field_name)[0..len])) {
                    namesEnabled.append(need) catch |err| {
                        std.debug.print("err: {s}\n", .{@errorName(err)});
                        return VkError.VK_ERROR_OUT_OF_HOST_MEMORY;
                    };
                    break;
                }
            }
        }
        return namesEnabled;
    }

    fn createSurface(self: *Self) VkError!void {
        if (sdl.SDL_Vulkan_CreateSurface(self.*.window, @ptrCast(self.*.instance), @ptrCast(self.*.pAllocCallBacks), @ptrCast(&self.*.surface)) == false) {
            std.debug.print("SDL error: {s}\n", .{sdl.SDL_GetError()});
            return VkError.VK_ERROR_UNKNOWN;
        }
    }

    fn pickPhysicalDevice(self: *Self) VkError!void {
        var deviceCount: u32 = 0;
        try checkVkResult(vk.vkEnumeratePhysicalDevices(self.*.instance, @ptrCast(&deviceCount), null));
        if (deviceCount == 0) {
            if (sdl.SDL_ShowSimpleMessageBox(sdl.SDL_MESSAGEBOX_ERROR, "vulkan not support", "you device is not support vulkan", self.*.window) == false) {
                std.log.err("show message box failed", .{});
            }
        }

        const physicalDevices = self.*.allocator.alloc(vk.VkPhysicalDevice, deviceCount) catch |err| {
            var buffer: [256]u8 = undefined;
            const buffers: []const u8 = std.fmt.bufPrint(&buffer, "memory alloc failed\nERROR: {s}\n", .{@errorName(err)}) catch |err2| blk: {
                std.log.warn("buffer is not big enough {s}\n", .{@errorName(err2)});
                const backupMessage = "error\n";
                break :blk backupMessage;
            };

            if (sdl.SDL_ShowSimpleMessageBox(sdl.SDL_MESSAGEBOX_ERROR, "memory alloc failed", @ptrCast(buffers.ptr), self.*.window) == false) {
                std.log.warn("show message box failed", .{});
            }

            return VkError.VK_ERROR_OUT_OF_HOST_MEMORY;
        };
        defer self.*.allocator.free(physicalDevices);
        try checkVkResult(vk.vkEnumeratePhysicalDevices(self.*.instance, @ptrCast(&deviceCount), @ptrCast(physicalDevices.ptr)));
    }
};
