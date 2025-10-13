const vk = @import("vulkan").vulkan;
const file = @import("fileSystem");
const std = @import("std");
const global = @import("global");
const efc = @import("enumFromC");
const s = @import("translateBase.zig");
const tracy = @import("tracy");

pub const VulkanPipelineInfo = s.VulkanPipelineInfo;
pub const setLayoutLimit = s.setLayoutLimit;

fn haveBindless(flags: []u32) bool {
    for (flags) |fs| {
        if (fs != 0) return true;
    }
    return false;
}

pub fn toVulkan(partialFillInfo: *VulkanPipelineInfo, shaderCodes: [5][]u8, setLayouts: []vk.VkDescriptorSetLayout) !void {
    const zone = tracy.initZone(@src(), .{ .name = "translate middle struct to vulkan" });
    defer zone.deinit();

    for (0..partialFillInfo.shaderStageCount) |i| {
        const pEntryName = try global.vulkan.collectEntryName(&partialFillInfo.entryNames[i]);
        // std.log.debug("entry name {s} outer", .{pEntryName.*});
        partialFillInfo.shaderStageCreateInfo[i].pName = @ptrCast(pEntryName.ptr);
        partialFillInfo.shaderStageCreateInfo[i].module = try global.vulkan.createShaderModule(shaderCodes[i], &partialFillInfo.shaderName[i]);
    }
    // for (0..partialFillInfo.descriptorSetLayouts.setLayoutCount) |i| {
    //     if (haveBindless(&partialFillInfo.descriptorSetLayouts.bindingFlags[i])) {
    //         partialFillInfo.descriptorSetLayouts.bindingFlagInfo[i] = vk.VkDescriptorSetLayoutBindingFlagsCreateInfo{
    //             .sType = vk.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_BINDING_FLAGS_CREATE_INFO,
    //             .bindingCount = partialFillInfo.descriptorSetLayouts.setLayoutCreateInfos[i].bindingCount,
    //             .pBindingFlags = @ptrCast(&partialFillInfo.descriptorSetLayouts.bindingFlags[i]),
    //             .pNext = null,
    //         };
    //         partialFillInfo.descriptorSetLayouts.setLayoutCreateInfos[i].pNext = @ptrCast(&partialFillInfo.descriptorSetLayouts.bindingFlagInfo[i]);
    //     } else {
    //         partialFillInfo.descriptorSetLayouts.setLayoutCreateInfos[i].pNext = null;
    //     }
    //     partialFillInfo.descriptorSetLayouts.setLayoutCreateInfos[i].pBindings = @ptrCast(&partialFillInfo.descriptorSetLayouts.setLayoutBinding[i]);
    //     partialFillInfo.descriptorSetLayouts.setLayouts[i] = try global.vulkan.createDescriptorSetLayout(partialFillInfo.descriptorSetLayouts.setLayoutCreateInfos[i]);
    // }
    partialFillInfo.pipelineLayout.info.pPushConstantRanges = @ptrCast(&partialFillInfo.pipelineCreateInfoInfo.pushConstants);
    partialFillInfo.pipelineLayout.info.pSetLayouts = @ptrCast(setLayouts.ptr);
    if (partialFillInfo.pipelineLayout.info.setLayoutCount != @as(u32, @intCast(setLayouts.len)))
        std.debug.panic("setLayoutCount {d} != setLayouts.len {d}", .{ partialFillInfo.pipelineLayout.info.setLayoutCount, setLayouts.len });
    partialFillInfo.pipelineLayout.layout = try global.vulkan.createPipelineLayout(partialFillInfo.pipelineLayout.info);
}
