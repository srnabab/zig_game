const std = @import("std");
pub const vk = @import("vulkan");
const pipeline = @import("pipeline.zig");

pub fn createStaticStringMap(
    comptime import: anytype,
    comptime tag_type: anytype,
    comptime startEnumMember: [:0]const u8,
    comptime endEnumMember: [:0]const u8,
    comptime prefix: [:0]const u8,
) std.StaticStringMap(tag_type) {
    return std.StaticStringMap(tag_type).initComptime(blk: {
        var entries: [10000]struct { []const u8, tag_type } = undefined;
        var count: u32 = 0;

        comptime var begin = false;
        @setEvalBranchQuota(100000);
        inline for (std.meta.declarations(import)) |decl| {
            if (begin == false) {
                if (std.mem.eql(u8, decl.name, startEnumMember)) {
                    begin = true;
                } else {
                    continue;
                }
            }

            const key = decl.name[prefix.len..];
            const value = @field(import, decl.name);

            entries[count].@"0" = key;
            entries[count].@"1" = value;
            count += 1;

            if (std.mem.eql(u8, decl.name, endEnumMember)) {
                break;
            }
        }

        break :blk entries[0..count];
    });
}

fn comptime_print(comptime format: []const u8, comptime args: anytype) void {
    @compileLog(std.fmt.comptimePrint(format, args));
}
const formatMap = createStaticStringMap(vk, vk.VkFormat, "VK_FORMAT_UNDEFINED", "VK_FORMAT_MAX_ENUM", "VK_FORMAT_");

const inputRateMap = createStaticStringMap(
    vk,
    vk.VkVertexInputRate,
    "VK_VERTEX_INPUT_RATE_VERTEX",
    "VK_VERTEX_INPUT_RATE_MAX_ENUM",
    "VK_VERTEX_INPUT_RATE_",
);

const stencilOpMap = createStaticStringMap(vk, vk.VkStencilOp, "VK_STENCIL_OP_KEEP", "VK_STENCIL_OP_MAX_ENUM", "VK_STENCIL_OP_");

const blendFactorMap = createStaticStringMap(vk, vk.VkBlendFactor, "VK_BLEND_FACTOR_ZERO", "VK_BLEND_FACTOR_MAX_ENUM", "VK_BLEND_FACTOR_");

const blendOpMap = createStaticStringMap(vk, vk.VkBlendOp, "VK_BLEND_OP_ADD", "VK_BLEND_OP_MAX_ENUM", "VK_BLEND_OP_");

const topologyMap = createStaticStringMap(vk, vk.VkPrimitiveTopology, "VK_PRIMITIVE_TOPOLOGY_POINT_LIST", "VK_PRIMITIVE_TOPOLOGY_MAX_ENUM", "VK_PRIMITIVE_TOPOLOGY_");

const polygonModeMap = createStaticStringMap(vk, vk.VkPolygonMode, "VK_POLYGON_MODE_FILL", "VK_POLYGON_MODE_MAX_ENUM", "VK_POLYGON_MODE_");
const cullModeMap = createStaticStringMap(vk, vk.VkCullModeFlagBits, "VK_CULL_MODE_NONE", "VK_CULL_MODE_FLAG_BITS_MAX_ENUM", "VK_CULL_MODE_");

const frontFaceMap = createStaticStringMap(vk, vk.VkFrontFace, "VK_FRONT_FACE_COUNTER_CLOCKWISE", "VK_FRONT_FACE_MAX_ENUM", "VK_FRONT_FACE_");

const sampleCountMap = createStaticStringMap(vk, vk.VkSampleCountFlagBits, "VK_SAMPLE_COUNT_1_BIT", "VK_SAMPLE_COUNT_FLAG_BITS_MAX_ENUM", "VK_SAMPLE_COUNT_");

const compareOpMap = createStaticStringMap(vk, vk.VkCompareOp, "VK_COMPARE_OP_NEVER", "VK_COMPARE_OP_MAX_ENUM", "VK_COMPARE_OP_");

const logicOpMap = createStaticStringMap(vk, vk.VkLogicOp, "VK_LOGIC_OP_CLEAR", "VK_LOGIC_OP_MAX_ENUM", "VK_LOGIC_OP_");

const dynamicStateMap = createStaticStringMap(vk, vk.VkDynamicState, "VK_DYNAMIC_STATE_VIEWPORT", "VK_DYNAMIC_STATE_MAX_ENUM", "VK_DYNAMIC_STATE_");

fn translateColorWriteMask(mask_slice: []const []const u8) vk.VkColorComponentFlags {
    var flags: vk.VkColorComponentFlags = 0;
    for (mask_slice) |mask| {
        if (std.mem.eql(u8, mask, "R")) {
            flags |= vk.VK_COLOR_COMPONENT_R_BIT;
        } else if (std.mem.eql(u8, mask, "G")) {
            flags |= vk.VK_COLOR_COMPONENT_G_BIT;
        } else if (std.mem.eql(u8, mask, "B")) {
            flags |= vk.VK_COLOR_COMPONENT_B_BIT;
        } else if (std.mem.eql(u8, mask, "A")) {
            flags |= vk.VK_COLOR_COMPONENT_A_BIT;
        }
    }
    return flags;
}

const vertexInputBindingDescriptionLimit = 16;
const vertexInputAttributeDescriptionLimit = 64;
const VulkanVertexInputInfo = extern struct {
    createInfo: vk.VkPipelineVertexInputStateCreateInfo,
    bindings: [vertexInputBindingDescriptionLimit]vk.VkVertexInputBindingDescription,
    attributes: [vertexInputAttributeDescriptionLimit]vk.VkVertexInputAttributeDescription,
    bindingCount: u8,
    attributeCount: u8,
};

const colorBlendAttachmentStateLimit = 32;
const VulkanColorBlendInfo = extern struct {
    createInfo: vk.VkPipelineColorBlendStateCreateInfo,
    attachments: [colorBlendAttachmentStateLimit]vk.VkPipelineColorBlendAttachmentState,
    attachmentCount: u32,
};

const dynamicStateLimit = 16;
const VulkanDynamicStateInfo = extern struct {
    createInfo: vk.VkPipelineDynamicStateCreateInfo,
    states: [dynamicStateLimit]vk.VkDynamicState,
    stateCount: u32,
};

const vulkanViewport = extern struct {
    viewports: [8]vk.VkViewport,
    scissors: [8]vk.VkRect2D,
    info: vk.VkPipelineViewportStateCreateInfo,
};

const pushConstantRangeLimit = 16;
pub const setLayoutLimit = 8;
pub const bindingLimit = 5;
pub const pipelineLayoutCreateInfo = extern struct {
    pushConstantCount: u32,
    pushConstants: [pushConstantRangeLimit]vk.VkPushConstantRange,
    setLayoutCount: u32,
    // setLayoutBinding: [setLayoutLimit][bindingLimit]vk.VkDescriptorSetLayoutBinding,
    // bindingFlags: [setLayoutLimit][bindingLimit]vk.VkDescriptorBindingFlags,
    // bindingFlagInfo: [setLayoutLimit]vk.VkDescriptorSetLayoutBindingFlagsCreateInfo,
    // setLayoutCreateInfos: [setLayoutLimit]vk.VkDescriptorSetLayoutCreateInfo,
    // setLayouts: [setLayoutLimit]vk.VkDescriptorSetLayout,
};

const renderingColorAttachmentCount = 16;
const vulkanRenderingInfo = extern struct {
    colorAttachment: [renderingColorAttachmentCount]vk.VkFormat,
    info: vk.VkPipelineRenderingCreateInfo,
};

const pipelineLayout = extern struct {
    info: vk.VkPipelineLayoutCreateInfo,
    layout: vk.VkPipelineLayout,
};

const Output = extern struct {
    location: u32,
    var_type: vk.VkFormat,
};

pub const VulkanPipelineInfo = extern struct {
    const Self = @This();

    compute: bool,
    shaderStageCount: u32,

    name: [64:0]u8 = std.mem.zeroes([64:0]u8),
    shaderName: [5][64:0]u8 = std.mem.zeroes([5][64:0]u8),

    /// need create runtime resources
    shaderStageCreateInfo: [5]vk.VkPipelineShaderStageCreateInfo,
    entryNames: [5][64]u8,
    /// need create runtime resources
    pipelineCreateInfoInfo: pipelineLayoutCreateInfo,
    /// need create runtime resources
    pipelineLayout: pipelineLayout,

    // compile time comfirmed need runtime pointer
    vertexInputInfo: VulkanVertexInputInfo,
    haveTessella: bool,
    hasRendering: bool,
    inputAssemblyInfo: vk.VkPipelineInputAssemblyStateCreateInfo,
    tessellationInfo: vk.VkPipelineTessellationStateCreateInfo,
    viewportInfo: vulkanViewport,
    rasterizationInfo: vk.VkPipelineRasterizationStateCreateInfo,
    multisampleInfo: vk.VkPipelineMultisampleStateCreateInfo,
    depthStencilInfo: vk.VkPipelineDepthStencilStateCreateInfo,
    colorBlendInfo: VulkanColorBlendInfo,
    dynamicStateInfo: VulkanDynamicStateInfo,
    renderingInfo: vulkanRenderingInfo,
    outputCount: u32,
    outputs: [10]Output,
};

pub fn createVertexInputInfo(info: *const pipeline.vertexInputState, pipeRes: *VulkanPipelineInfo) void {
    var res = &pipeRes.vertexInputInfo;
    res.bindingCount = 0;
    res.attributeCount = 0;

    if (info.bindings != null) {
        for (info.bindings.?, 0..) |binding, i| {
            res.bindings[i] = .{
                .binding = binding.bind,
                .stride = binding.stride,
                .inputRate = inputRateMap.get(binding.inputRate).?,
            };
            res.bindingCount += 1;
        }
    }

    if (info.attributes != null) {
        for (info.attributes.?, 0..) |attribute, i| {
            res.attributes[i] = .{
                .location = attribute.location,
                .binding = attribute.binding,
                .format = formatMap.get(attribute.format).?,
                .offset = attribute.offset,
            };
            res.attributeCount += 1;
        }
    }

    res.createInfo = .{
        .sType = vk.VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO,
        .pNext = null,
        .flags = info.flag,
        .vertexBindingDescriptionCount = @intCast(res.bindingCount),
        .pVertexBindingDescriptions = @ptrCast(&res.bindings),
        .vertexAttributeDescriptionCount = @intCast(res.attributeCount),
        .pVertexAttributeDescriptions = @ptrCast(&res.attributes),
    };
}

pub fn createInputAssemblyInfo(info: *const pipeline.inputAssembly) vk.VkPipelineInputAssemblyStateCreateInfo {
    return .{
        .sType = vk.VK_STRUCTURE_TYPE_PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO,
        .pNext = null,
        .flags = info.flags,
        .topology = topologyMap.get(info.topology).?,
        .primitiveRestartEnable = @intFromBool(info.primitiveRestartEnable),
    };
}

pub fn createTessellationInfo(info: ?pipeline.tessellationState, pipeRes: *VulkanPipelineInfo) void {
    if (info) |tess_info| {
        pipeRes.tessellationInfo = vk.VkPipelineTessellationStateCreateInfo{
            .sType = vk.VK_STRUCTURE_TYPE_PIPELINE_TESSELLATION_STATE_CREATE_INFO,
            .pNext = null,
            .flags = tess_info.flags,
            .patchControlPoints = tess_info.patchControlPoints,
        };
        pipeRes.haveTessella = true;
    } else {
        pipeRes.tessellationInfo = vk.VkPipelineTessellationStateCreateInfo{};
        pipeRes.haveTessella = false;
    }
}

pub fn createViewportInfo(info: *const pipeline.viewportState, pipeRes: *VulkanPipelineInfo) void {
    var res = &pipeRes.viewportInfo;
    for (info.viewports, 0..) |value, i| {
        res.viewports[i] = vk.VkViewport{
            .x = value.x,
            .y = value.y,
            .width = @floatFromInt(value.width),
            .height = @floatFromInt(value.height),
            .minDepth = value.minDepth,
            .maxDepth = value.maxDepth,
        };
    }
    for (info.scissors, 0..) |value, i| {
        res.scissors[i] = vk.VkRect2D{
            .offset = .{
                .x = value.offset.x,
                .y = value.offset.y,
            },
            .extent = .{
                .width = value.extent.width,
                .height = value.extent.height,
            },
        };
    }

    res.info = vk.VkPipelineViewportStateCreateInfo{
        .sType = vk.VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_STATE_CREATE_INFO,
        .pNext = null,
        .flags = info.flags,
        .viewportCount = @intCast(info.viewports.len),
        .pViewports = @ptrCast(&res.viewports), // dynamic
        .scissorCount = @intCast(info.scissors.len),
        .pScissors = @ptrCast(&res.scissors), // dynamic
    };
}

pub fn createRasterizationInfo(info: *const pipeline.rasterizationState) vk.VkPipelineRasterizationStateCreateInfo {
    return .{
        .sType = vk.VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_STATE_CREATE_INFO,
        .pNext = null,
        .flags = info.flags,
        .depthClampEnable = @intFromBool(info.depthClampEnable),
        .rasterizerDiscardEnable = @intFromBool(info.rasterizerDiscardEnable),
        .polygonMode = polygonModeMap.get(info.polygonMode).?,
        .cullMode = cullModeMap.get(info.cullMode).?,
        .frontFace = frontFaceMap.get(info.frontFace).?,
        .depthBiasEnable = @intFromBool(info.depthBiasEnable),
        .depthBiasConstantFactor = info.depthBiasConstantFactor,
        .depthBiasClamp = info.depthBiasClamp,
        .depthBiasSlopeFactor = info.depthBiasSlopeFactor,
        .lineWidth = info.lineWidth,
    };
}

pub fn createMultisampleInfo(info: *const pipeline.multisampleState) vk.VkPipelineMultisampleStateCreateInfo {
    return .{
        .sType = vk.VK_STRUCTURE_TYPE_PIPELINE_MULTISAMPLE_STATE_CREATE_INFO,
        .pNext = null,
        .flags = info.flags,
        .rasterizationSamples = sampleCountMap.get(info.rasterizationSamples).?,
        .sampleShadingEnable = @intFromBool(info.sampleShadingEnable),
        .minSampleShading = info.minSampleShading,
        .pSampleMask = null,
        .alphaToCoverageEnable = @intFromBool(info.alphaToCoverageEnable),
        .alphaToOneEnable = @intFromBool(info.alphaToOneEnable),
    };
}

pub fn createDepthStencilInfo(info: *const pipeline.depthStencilState) vk.VkPipelineDepthStencilStateCreateInfo {
    return .{
        .sType = vk.VK_STRUCTURE_TYPE_PIPELINE_DEPTH_STENCIL_STATE_CREATE_INFO,
        .pNext = null,
        .flags = info.flags,
        .depthTestEnable = @intFromBool(info.depthTestEnable),
        .depthWriteEnable = @intFromBool(info.depthWriteEnable),
        .depthCompareOp = compareOpMap.get(info.depthCompareOp).?,
        .depthBoundsTestEnable = @intFromBool(info.depthBoundsTestEnable),
        .stencilTestEnable = @intFromBool(info.stencilTestEnable),
        .front = if (info.front) |front| .{
            .failOp = stencilOpMap.get(front.failOp).?,
            .passOp = stencilOpMap.get(front.passOp).?,
            .depthFailOp = stencilOpMap.get(front.depthFailOp).?,
            .compareOp = compareOpMap.get(front.compareOp).?,
            .compareMask = front.compareMask,
            .writeMask = front.writeMask,
            .reference = front.reference,
        } else .{},
        .back = if (info.back) |back| .{
            .failOp = stencilOpMap.get(back.failOp).?,
            .passOp = stencilOpMap.get(back.passOp).?,
            .depthFailOp = stencilOpMap.get(back.depthFailOp).?,
            .compareOp = compareOpMap.get(back.compareOp).?,
            .compareMask = back.compareMask,
            .writeMask = back.writeMask,
            .reference = back.reference,
        } else .{},
        .minDepthBounds = info.minDepthBounds,
        .maxDepthBounds = info.maxDepthBounds,
    };
}

pub fn createColorBlendInfo(info: *const pipeline.colorBlendState, pipeRes: *VulkanPipelineInfo) void {
    var res = &pipeRes.colorBlendInfo;
    res.attachmentCount = 0;

    for (info.attachments, 0..) |attachment, i| {
        res.attachments[i] = .{
            .blendEnable = @intFromBool(attachment.blendEnable),
            .srcColorBlendFactor = blendFactorMap.get(attachment.srcColorBlendFactor).?,
            .dstColorBlendFactor = blendFactorMap.get(attachment.dstColorBlendFactor).?,
            .colorBlendOp = blendOpMap.get(attachment.colorBlendOp).?,
            .srcAlphaBlendFactor = blendFactorMap.get(attachment.srcAlphaBlendFactor).?,
            .dstAlphaBlendFactor = blendFactorMap.get(attachment.dstAlphaBlendFactor).?,
            .alphaBlendOp = blendOpMap.get(attachment.alphaBlendOp).?,
            .colorWriteMask = translateColorWriteMask(attachment.colorWriteMask),
        };
        res.attachmentCount += 1;
    }

    res.createInfo = .{
        .sType = vk.VK_STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_STATE_CREATE_INFO,
        .pNext = null,
        .flags = info.flags,
        .logicOpEnable = @intFromBool(info.logicOpEnable),
        .logicOp = logicOpMap.get(info.logicOp).?,
        .attachmentCount = @intCast(res.attachmentCount),
        .pAttachments = @ptrCast(&res.attachments),
        .blendConstants = info.blendConstants,
    };
}

pub fn createDynamicStateInfo(info: *const pipeline.dynamicStates, pipeRes: *VulkanPipelineInfo) void {
    var res = &pipeRes.dynamicStateInfo;
    res.stateCount = 0;

    for (info.States, 0..) |state, i| {
        res.states[i] = dynamicStateMap.get(state).?;
        res.stateCount += 1;
    }

    res.createInfo = .{
        .sType = vk.VK_STRUCTURE_TYPE_PIPELINE_DYNAMIC_STATE_CREATE_INFO,
        .pNext = null,
        .flags = 0,
        .dynamicStateCount = @intCast(res.stateCount),
        .pDynamicStates = @ptrCast(&res.states),
    };
}

pub fn createRenderingInfo(renderingInfo: ?pipeline.renderingInfo, pipeRes: *VulkanPipelineInfo) void {
    const res = &pipeRes.renderingInfo;
    if (renderingInfo) |info| {
        for (renderingInfo.?.colorAttachment[0..renderingInfo.?.colorAttachmentCount], 0..) |value, i| {
            // std.log.info("{s}", .{value});
            res.*.colorAttachment[i] = formatMap.get(value).?;
        }
        res.*.info = vk.VkPipelineRenderingCreateInfo{
            .sType = vk.VK_STRUCTURE_TYPE_PIPELINE_RENDERING_CREATE_INFO,
            .pNext = null,
            .viewMask = 0,
            .colorAttachmentCount = info.colorAttachmentCount,
            .pColorAttachmentFormats = null,
            .depthAttachmentFormat = formatMap.get(info.depthAttachment).?,
            .stencilAttachmentFormat = formatMap.get(info.stencilAttachment).?,
        };
        pipeRes.hasRendering = true;
    } else {
        pipeRes.hasRendering = false;
    }
}
