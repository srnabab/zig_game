const vk = @import("vulkan").vulkan;

const VkResultToError = @import("resultToError");
const vulkanType = VkResultToError.vulkanType;
pub const VkError = vulkanType.VkError;
const checkVkResult = VkResultToError.checkVkResult;

pub fn _createDescriptorPool(device: vk.VkDevice, pAllocCallBacks: [*c]vk.VkAllocationCallbacks, flag: vk.VkDescriptorPoolCreateFlags, poolSizes: []vk.VkDescriptorPoolSize, maxSets: u32) VkError!vk.VkDescriptorPool {
    var createInfo = vk.VkDescriptorPoolCreateInfo{
        .sType = vk.VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO,
        .pNext = null,
        .flags = flag,
        .pPoolSizes = @ptrCast(poolSizes.ptr),
        .poolSizeCount = @intCast(poolSizes.len),
        .maxSets = maxSets,
    };
    var pool: vk.VkDescriptorPool = null;

    try checkVkResult(vk.vkCreateDescriptorPool(device, &createInfo, pAllocCallBacks, &pool));

    return pool;
}

pub fn destroyDescriptorPool(device: vk.VkDevice, pAllocCallBacks: [*c]vk.VkAllocationCallbacks, pool: vk.VkDescriptorPool) void {
    vk.vkDestroyDescriptorPool(device, pool, pAllocCallBacks);
}
