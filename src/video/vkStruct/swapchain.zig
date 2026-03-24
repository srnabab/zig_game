const std = @import("std");

const sdl = @import("sdl").sdl;
const SDL_CheckResult = @import("sdl").SDL_CheckResult;

const vk = @import("vulkan").vulkan;
const types = @import("types");

const VkResultToError = @import("resultToError");
const checkVkResult = VkResultToError.checkVkResult;

const tracy = @import("tracy");

const SDR_SurfaceFormat = vk.VkSurfaceFormatKHR{
    // .format = vk.VK_FORMAT_R8G8B8A8_UNORM,
    .format = vk.VK_FORMAT_R8G8B8A8_SRGB,
    .colorSpace = vk.VK_COLOR_SPACE_SRGB_NONLINEAR_KHR,
};

const HDR_SurfaceFormat = vk.VkSurfaceFormatKHR{
    .format = vk.VK_FORMAT_R16G16B16A16_SFLOAT,
    .colorSpace = vk.VK_COLOR_SPACE_EXTENDED_SRGB_LINEAR_EXT,
};

const HDR10_SurfaceFormat = vk.VkSurfaceFormatKHR{
    .format = vk.VK_FORMAT_A2B10G10R10_UNORM_PACK32,
    .colorSpace = vk.VK_COLOR_SPACE_HDR10_ST2084_EXT,
};

pub fn createSurface(window: ?*sdl.SDL_Window, instance: vk.VkInstance, pAllocCallBacks: ?*vk.VkAllocationCallbacks) !vk.VkSurfaceKHR {
    var surface: vk.VkSurfaceKHR = null;

    try SDL_CheckResult(sdl.SDL_Vulkan_CreateSurface(
        window,
        @ptrCast(instance),
        @ptrCast(pAllocCallBacks),
        @ptrCast(&surface),
    ));

    return surface;
}

pub fn getSurfaceFormat(physicalDevice: vk.VkPhysicalDevice, surface: vk.VkSurfaceKHR, allocator: std.mem.Allocator) !types.SurfaceFormats {
    const zone = tracy.initZone(@src(), .{ .name = "get surface format" });
    defer zone.deinit();

    var sdr: i32 = -1;
    var hdr: i32 = -1;
    var hdr10: i32 = -1;

    var formatCount: u32 = 0;
    try checkVkResult(vk.vkGetPhysicalDeviceSurfaceFormatsKHR(
        physicalDevice,
        surface,
        @ptrCast(&formatCount),
        null,
    ));

    if (formatCount == 0) return error.NoSurfaceFormat;

    const formats = try allocator.alloc(vk.VkSurfaceFormatKHR, formatCount);
    try checkVkResult(vk.vkGetPhysicalDeviceSurfaceFormatsKHR(
        physicalDevice,
        surface,
        @ptrCast(&formatCount),
        @ptrCast(formats.ptr),
    ));

    for (0..formatCount) |i| {
        if (std.meta.eql(formats[i], SDR_SurfaceFormat)) {
            sdr = @intCast(i);
        }

        if (std.meta.eql(formats[i], HDR_SurfaceFormat)) {
            hdr = @intCast(i);
        }

        if (std.meta.eql(formats[i], HDR10_SurfaceFormat)) {
            hdr10 = @intCast(i);
        }
    }

    if (sdr < 0) {
        return error.NoSDRFormat;
    }

    return .{
        .formats = formats,
        .sdr = sdr,
        .hdr = hdr,
        .hdr10 = hdr10,
    };
}

pub fn getPresentMode(physicalDevice: vk.VkPhysicalDevice, surface: vk.VkSurfaceKHR, allocator: std.mem.Allocator) !types.PresentModes {
    const zone = tracy.initZone(@src(), .{ .name = "get present mode" });
    defer zone.deinit();

    var modeCount: u32 = 0;
    try checkVkResult(vk.vkGetPhysicalDeviceSurfacePresentModesKHR(physicalDevice, surface, @ptrCast(&modeCount), null));

    if (modeCount == 0) return error.NoPresentMode;

    const modes = try allocator.alloc(vk.VkPresentModeKHR, modeCount);
    try checkVkResult(vk.vkGetPhysicalDeviceSurfacePresentModesKHR(physicalDevice, surface, @ptrCast(&modeCount), @ptrCast(modes.ptr)));

    var MAILBOX: i32 = -1;
    var FIFO: i32 = -1;
    var IMMEDIATE: i32 = -1;

    for (0..modeCount) |i| {
        if (modes[i] == vk.VK_PRESENT_MODE_FIFO_KHR) {
            FIFO = @intCast(i);
        } else if (modes[i] == vk.VK_PRESENT_MODE_MAILBOX_KHR) {
            MAILBOX = @intCast(i);
        } else if (modes[i] == vk.VK_PRESENT_MODE_IMMEDIATE_KHR) {
            IMMEDIATE = @intCast(i);
        }
    }

    return .{
        .modes = modes,
        .mailbox = MAILBOX,
        .fifo = FIFO,
        .immediate = IMMEDIATE,
    };
}

pub fn createSwapchain(
    physicalDevice: vk.VkPhysicalDevice,
    device: vk.VkDevice,
    surface: vk.VkSurfaceKHR,
    surfaceFormat: vk.VkSurfaceFormatKHR,
    presentMode: vk.VkPresentModeKHR,
    windowWidth: u32,
    windowsHeight: u32,
    oldSwapchain: vk.VkSwapchainKHR,
    pAllocCallBacks: [*c]vk.VkAllocationCallbacks,
) !vk.VkSwapchainKHR {
    const zone = tracy.initZone(@src(), .{ .name = "create swapchain" });
    defer zone.deinit();

    var surfaceCapabilities: vk.VkSurfaceCapabilitiesKHR = .{};
    try checkVkResult(vk.vkGetPhysicalDeviceSurfaceCapabilitiesKHR(physicalDevice, surface, @ptrCast(&surfaceCapabilities)));

    var swapchain: vk.VkSwapchainKHR = null;
    const imageCount: u32 = @max(surfaceCapabilities.minImageCount + 1, surfaceCapabilities.maxImageCount);

    var createInfo = vk.VkSwapchainCreateInfoKHR{
        .sType = vk.VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR,
        .pNext = null,
        .flags = 0,
        .surface = surface,
        .minImageCount = imageCount,
        .imageFormat = surfaceFormat.format,
        .imageColorSpace = surfaceFormat.colorSpace,
        .imageExtent = vk.VkExtent2D{
            .width = windowWidth,
            .height = windowsHeight,
        },
        .imageArrayLayers = 1,
        .imageUsage = vk.VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT,
        .preTransform = surfaceCapabilities.currentTransform,
        .compositeAlpha = vk.VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR,
        .presentMode = presentMode,
        .clipped = vk.VK_TRUE,
        .oldSwapchain = oldSwapchain,
        .imageSharingMode = vk.VK_SHARING_MODE_EXCLUSIVE,
        .queueFamilyIndexCount = 0,
        .pQueueFamilyIndices = null,
    };

    try checkVkResult(vk.vkCreateSwapchainKHR(device, @ptrCast(&createInfo), pAllocCallBacks, @ptrCast(&swapchain)));

    return swapchain;
}

pub fn createSwapchainImages(device: vk.VkDevice, swapchain: vk.VkSwapchainKHR, allocator: std.mem.Allocator) ![]vk.VkImage {
    var count: u32 = 0;
    try checkVkResult(vk.vkGetSwapchainImagesKHR(device, swapchain, @ptrCast(&count), null));

    const images = try allocator.alloc(vk.VkImage, count);
    try checkVkResult(vk.vkGetSwapchainImagesKHR(device, swapchain, @ptrCast(&count), @ptrCast(images.ptr)));

    return images;
}
