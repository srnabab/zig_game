const vk = @import("vulkan");

pub const VkQueueFamily = struct {
    familyIndice: i32 = -1,
    queueCount: u32 = 0,
};

pub const SurfaceFormats = struct {
    formats: []vk.VkSurfaceFormatKHR,
    sdr: i32,
    hdr: i32,
    hdr10: i32,
};

pub const PresentModes = struct {
    modes: []vk.VkPresentModeKHR,
    mailbox: i32,
    fifo: i32,
    immediate: i32,
};
