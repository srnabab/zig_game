const pipeline = @import("pipeline.zig");
const std = @import("std");
const s = @import("translateBase.zig");

const VulkanPipelineInfo = s.VulkanPipelineInfo;

pub fn toVulkan2(info: *pipeline.pipelineInfo, allocator: std.mem.Allocator) !*VulkanPipelineInfo {
    var res = try allocator.create(VulkanPipelineInfo);
    res.* = std.mem.zeroes(VulkanPipelineInfo);

    s.createVertexInputInfo(&info.vertexInputstatee, res);
    res.vertexInputInfo.createInfo.pVertexAttributeDescriptions = null;
    res.vertexInputInfo.createInfo.pVertexBindingDescriptions = null;

    res.inputAssemblyInfo = s.createInputAssemblyInfo(&info.inputAssemblyy);
    s.createTessellationInfo(info.tessellationStatee, res);
    s.createViewportInfo(&info.viewportStatee, res);
    res.viewportInfo.info.pScissors = null;
    res.viewportInfo.info.pViewports = null;

    res.rasterizationInfo = s.createRasterizationInfo(&info.rasterizationStatee);
    res.multisampleInfo = s.createMultisampleInfo(&info.multisampleStatee);
    res.depthStencilInfo = s.createDepthStencilInfo(&info.depthStencilStatee);

    s.createColorBlendInfo(&info.colorBlendStatee, res);
    res.colorBlendInfo.createInfo.pAttachments = null;

    s.createDynamicStateInfo(&info.dynamicStatess, res);
    res.dynamicStateInfo.createInfo.pDynamicStates = null;

    s.createRenderingInfo(info.rendering, res);

    std.mem.copyForwards(u8, &res.name, info.name);
    res.shaderStageCount = info.shaderCount;

    // @breakpoint();
    for (0..info.shaderCount) |i| {
        std.mem.copyForwards(u8, res.shaderName[i][0..info.shaders[i].len], info.shaders[i]);
    }

    for (0..res.shaderStageCreateInfo.len) |i| {
        res.shaderStageCreateInfo[i] = std.mem.zeroes(s.vk.VkPipelineShaderStageCreateInfo);
    }
    res.descriptorSetLayouts = std.mem.zeroes(s.pipelineLayoutCreateInfo);
    res.pipelineLayout = null;

    return res;
}
