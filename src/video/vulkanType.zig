const cEnum = @import("enumFromC");
const std = @import("std");
const vk = @import("vulkan");

pub const VkResult: type = cEnum.generateEnumFromC(vk, vk.VkResult, "VK_SUCCESS", "VK_RESULT_MAX_ENUM");

pub const VkError = error{
    VkError,
};

pub const VkPhysicalDeviceType: type = cEnum.generateEnumFromC(
    vk,
    vk.VkPhysicalDeviceType,
    "VK_PHYSICAL_DEVICE_TYPE_OTHER",
    "VK_PHYSICAL_DEVICE_TYPE_MAX_ENUM",
);

pub const VkFormat: type = cEnum.generateEnumFromC(
    vk,
    vk.VkFormat,
    "VK_FORMAT_UNDEFINED",
    "VK_FORMAT_MAX_ENUM",
);
pub const VkColorSpaceKHR: type = cEnum.generateEnumFromC(
    vk,
    vk.VkColorSpaceKHR,
    "VK_COLOR_SPACE_SRGB_NONLINEAR_KHR",
    "VK_COLOR_SPACE_MAX_ENUM_KHR",
);

pub const VkPipelineStageFlagBits2: type = cEnum.generateEnumFromC(
    vk,
    vk.VkPipelineStageFlagBits2,
    "VK_PIPELINE_STAGE_2_NONE",
    "VK_PIPELINE_STAGE_2_OPTICAL_FLOW_BIT_NV",
);

pub const VkImageLayout: type = cEnum.generateEnumFromC(
    vk,
    vk.VkImageLayout,
    "VK_IMAGE_LAYOUT_UNDEFINED",
    "VK_IMAGE_LAYOUT_MAX_ENUM",
);
