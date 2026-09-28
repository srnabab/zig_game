const cEnum = @import("enumFromC");
const std = @import("std");
const vk = @import("vulkan");

pub const VkResult: type = cEnum.generateEnumFromC(
    vk,
    vk.VkResult,
    "VK_SUCCESS",
    "VK_RESULT_MAX_ENUM",
    .nonexhaustive,
);

pub const VkError = error{
    VkError,
};

pub const VkPhysicalDeviceType: type = cEnum.generateEnumFromC(
    vk,
    vk.VkPhysicalDeviceType,
    "VK_PHYSICAL_DEVICE_TYPE_OTHER",
    "VK_PHYSICAL_DEVICE_TYPE_MAX_ENUM",
    .nonexhaustive,
);

pub const VkFormat: type = cEnum.generateEnumFromC(
    vk,
    vk.VkFormat,
    "VK_FORMAT_UNDEFINED",
    "VK_FORMAT_MAX_ENUM",
    .nonexhaustive,
);
pub const VkColorSpaceKHR: type = cEnum.generateEnumFromC(
    vk,
    vk.VkColorSpaceKHR,
    "VK_COLOR_SPACE_SRGB_NONLINEAR_KHR",
    "VK_COLOR_SPACE_MAX_ENUM_KHR",
    .nonexhaustive,
);

pub const VkPipelineStageFlagBits2: type = cEnum.generateEnumFromC(
    vk,
    vk.VkPipelineStageFlagBits2,
    "VK_PIPELINE_STAGE_2_NONE",
    "VK_PIPELINE_STAGE_2_OPTICAL_FLOW_BIT_NV",
    .nonexhaustive,
);

pub const VkAccessFlagBits2: type = cEnum.generateEnumFromC(
    vk,
    vk.VkAccessFlagBits2,
    "VK_ACCESS_2_NONE",
    "VK_ACCESS_2_MEMORY_DECOMPRESSION_WRITE_BIT_EXT",
    .nonexhaustive,
);

pub const VkImageLayout: type = cEnum.generateEnumFromC(
    vk,
    vk.VkImageLayout,
    "VK_IMAGE_LAYOUT_UNDEFINED",
    "VK_IMAGE_LAYOUT_MAX_ENUM",
    .nonexhaustive,
);
