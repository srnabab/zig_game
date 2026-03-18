const cEnum = @import("enumFromC");
const std = @import("std");
const vk = @import("vulkan").vulkan;

pub const VkResult: type = cEnum.generateEnumFromC(vk, vk.VkResult, "VK_SUCCESS", "VK_RESULT_MAX_ENUM");

pub const VkError: type = blk: {
    // var error_names = std.ArrayList([]const u8).init(std.heap.comptime_allocator);
    var error_names: [1024]std.builtin.Type.Error = undefined;
    var count: u32 = 0;

    for (@typeInfo(VkResult).@"enum".fields) |field| {
        // 根据 Vulkan 规范，错误码是负数
        if (field.value < 0) {
            error_names[count].name = field.name;
            count += 1;
        }
    }

    // 使用 .ErrorSet 来创建 error 集合
    break :blk @Type(.{ .error_set = error_names[0..count] });
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
