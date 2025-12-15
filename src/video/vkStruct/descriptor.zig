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

pub fn createDescriptorSetLayout(device: vk.VkDevice, pAllocCallBacks: [*c]vk.VkAllocationCallbacks, pNext: ?*anyopaque, flags: vk.VkDescriptorSetLayoutCreateFlags, bindingCount: u32, pBindings: [*]vk.VkDescriptorSetLayoutBinding) !vk.VkDescriptorSetLayout {
    var setLayoutCreateInfo = vk.VkDescriptorSetLayoutCreateInfo{
        .sType = vk.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO,
        .pNext = pNext,
        .flags = flags,
        .bindingCount = bindingCount,
        .pBindings = @ptrCast(pBindings),
    };
    var res: vk.VkDescriptorSetLayout = undefined;
    try checkVkResult(vk.vkCreateDescriptorSetLayout(device, @ptrCast(&setLayoutCreateInfo), pAllocCallBacks, @ptrCast(&res)));
    return res;
}

pub fn destroyDescriptorSetLayout(device: vk.VkDevice, pAllocCallBacks: [*c]vk.VkAllocationCallbacks, descriptorSetLayout: vk.VkDescriptorSetLayout) void {
    vk.vkDestroyDescriptorSetLayout(device, descriptorSetLayout, pAllocCallBacks);
}

pub fn allocateDescriptorSets(device: vk.VkDevice, pool: vk.VkDescriptorPool, setLayouts: []vk.VkDescriptorSetLayout, descriptorSets: [*]vk.VkDescriptorSet) !void {
    var allocaInfo = vk.VkDescriptorSetAllocateInfo{
        .sType = vk.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO,
        .pNext = null,
        .descriptorPool = pool,
        .descriptorSetCount = @intCast(setLayouts.len),
        .pSetLayouts = @ptrCast(setLayouts.ptr),
    };

    try checkVkResult(vk.vkAllocateDescriptorSets(device, @ptrCast(&allocaInfo), @ptrCast(descriptorSets)));
}
