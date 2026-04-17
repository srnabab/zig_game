const vk = @import("vulkan");

const VkResultToError = @import("resultToError");
const checkVkResult = VkResultToError.checkVkResult;

const tracy = @import("tracy");

pub fn createBinarySemaphore(device: vk.VkDevice, pAllocCallBacks: [*c]vk.VkAllocationCallbacks, flags: vk.VkSemaphoreCreateFlags, pSemaphore: []vk.VkSemaphore) !void {
    const zone = tracy.initZone(@src(), .{ .name = "create semaphores" });
    defer zone.deinit();

    try _createSemaphore(device, pAllocCallBacks, null, flags, pSemaphore);
}

pub fn createTimelineSemaphore(device: vk.VkDevice, pAllocCallBacks: [*c]vk.VkAllocationCallbacks, flags: vk.VkSemaphoreCreateFlags, pSemaphore: []vk.VkSemaphore, initialValue: u64) !void {
    const zone = tracy.initZone(@src(), .{ .name = "create semaphores" });
    defer zone.deinit();

    var createInfo = vk.VkSemaphoreTypeCreateInfo{
        .sType = vk.VK_STRUCTURE_TYPE_SEMAPHORE_TYPE_CREATE_INFO,
        .pNext = null,
        .semaphoreType = vk.VK_SEMAPHORE_TYPE_TIMELINE,
        .initialValue = initialValue,
    };

    try _createSemaphore(device, pAllocCallBacks, &createInfo, flags, pSemaphore);
}

pub fn _createSemaphore(device: vk.VkDevice, pAllocCallBacks: [*c]vk.VkAllocationCallbacks, pNext: ?*anyopaque, flags: vk.VkSemaphoreCreateFlags, pSemaphore: []vk.VkSemaphore) !void {
    var createInfo = vk.VkSemaphoreCreateInfo{
        .sType = vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO,
        .pNext = pNext,
        .flags = flags,
    };

    for (0..pSemaphore.len) |i|
        try checkVkResult(vk.vkCreateSemaphore(device, @ptrCast(&createInfo), pAllocCallBacks, @ptrCast(&pSemaphore[i])));
}
