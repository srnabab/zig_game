const pipeline = @import("pipeline");
const vk = @import("vulkan").vulkan;
const file = @import("fileSystem");
const std = @import("std");
const global = @import("global");
const efc = @import("enumFromC");

fn comptime_print(comptime format: []const u8, comptime args: anytype) void {
    @compileLog(std.fmt.comptimePrint(format, args));
}
pub fn createStaticStringMap(
    comptime import: anytype,
    comptime tag_type: anytype,
    comptime startEnumMember: [:0]const u8,
    comptime endEnumMember: [:0]const u8,
    comptime prefix: [:0]const u8,
) std.StaticStringMap(tag_type) {
    return std.StaticStringMap(tag_type).initComptime(blk: {
        var entries: [10000]struct { []const u8, vk.VkFormat } = undefined;
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

pub const VulkanPipelineInfo = struct {
    const Self = @This();

    vertexInputInfo: VulkanVertexInputInfo,
    inputAssemblyInfo: vk.VkPipelineInputAssemblyStateCreateInfo,
    tessellationInfo: ?vk.VkPipelineTessellationStateCreateInfo,
    viewportInfo: vk.VkPipelineViewportStateCreateInfo,
    rasterizationInfo: vk.VkPipelineRasterizationStateCreateInfo,
    multisampleInfo: vk.VkPipelineMultisampleStateCreateInfo,
    depthStencilInfo: vk.VkPipelineDepthStencilStateCreateInfo,
    colorBlendInfo: VulkanColorBlendInfo,
    dynamicStateInfo: VulkanDynamicStateInfo,
    shaderStageCreateInfo: [5]vk.VkPipelineShaderStageCreateInfo,
    shaderStageCount: u32,
    descriptorSetLayouts: pipelineLayoutCreateInfo,
    pipelineLayout: vk.VkPipelineLayout,
    renderingInfo: ?vulkanRenderingInfo,
    name: [64]u8,
};

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
const VulkanVertexInputInfo = struct {
    createInfo: vk.VkPipelineVertexInputStateCreateInfo,
    bindingCount: u8,
    attributeCount: u8,
    bindings: [vertexInputBindingDescriptionLimit]vk.VkVertexInputBindingDescription,
    attributes: [vertexInputAttributeDescriptionLimit]vk.VkVertexInputAttributeDescription,
};

const colorBlendAttachmentStateLimit = 32;
const VulkanColorBlendInfo = struct {
    createInfo: vk.VkPipelineColorBlendStateCreateInfo,
    attachments: [colorBlendAttachmentStateLimit]vk.VkPipelineColorBlendAttachmentState,
    attachmentCount: u32,
};

const dynamicStateLimit = 16;
const VulkanDynamicStateInfo = struct {
    createInfo: vk.VkPipelineDynamicStateCreateInfo,
    states: [dynamicStateLimit]vk.VkDynamicState,
    stateCount: u32,
};

fn createVertexInputInfo(info: *const pipeline.vertexInputState, pipeRes: *VulkanPipelineInfo) void {
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

fn createInputAssemblyInfo(info: *const pipeline.inputAssembly) vk.VkPipelineInputAssemblyStateCreateInfo {
    return .{
        .sType = vk.VK_STRUCTURE_TYPE_PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO,
        .pNext = null,
        .flags = info.flags,
        .topology = topologyMap.get(info.topology).?,
        .primitiveRestartEnable = @intFromBool(info.primitiveRestartEnable),
    };
}

fn createTessellationInfo(info: ?pipeline.tessellationState) ?vk.VkPipelineTessellationStateCreateInfo {
    if (info) |tess_info| {
        return vk.VkPipelineTessellationStateCreateInfo{
            .sType = vk.VK_STRUCTURE_TYPE_PIPELINE_TESSELLATION_STATE_CREATE_INFO,
            .pNext = null,
            .flags = tess_info.flags,
            .patchControlPoints = tess_info.patchControlPoints,
        };
    }
    return null;
}

fn createViewportInfo(info: *const pipeline.viewportState) vk.VkPipelineViewportStateCreateInfo {
    return .{
        .sType = vk.VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_STATE_CREATE_INFO,
        .pNext = null,
        .flags = info.flags,
        .viewportCount = @intCast(info.viewports.len),
        .pViewports = @ptrCast(info.viewports.ptr), // dynamic
        .scissorCount = @intCast(info.scissors.len),
        .pScissors = @ptrCast(info.scissors.ptr), // dynamic
    };
}

fn createRasterizationInfo(info: *const pipeline.rasterizationState) vk.VkPipelineRasterizationStateCreateInfo {
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

fn createMultisampleInfo(info: *const pipeline.multisampleState) vk.VkPipelineMultisampleStateCreateInfo {
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

fn createDepthStencilInfo(info: *const pipeline.depthStencilState) vk.VkPipelineDepthStencilStateCreateInfo {
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

fn createColorBlendInfo(info: *const pipeline.colorBlendState, pipeRes: *VulkanPipelineInfo) void {
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

fn createDynamicStateInfo(info: *const pipeline.dynamicStates, pipeRes: *VulkanPipelineInfo) void {
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

fn getPipelineShaderInfos(shaders: [5][]const u8, count: u32, allocator: std.mem.Allocator) ![]file.PipelineShaderInfo {
    var infos = try allocator.alloc(file.PipelineShaderInfo, count);
    var nameBuffer = [_]u8{0} ** 256;
    var nameZ: [:0]u8 = undefined;
    for (0..count) |i| {
        nameZ = try std.fmt.bufPrintZ(&nameBuffer, "{s}", .{shaders[i]});
        infos[i] = try file.getShaderLoadParameter(nameZ);
    }
    return infos;
}

fn createShaderStageCreateInfo(
    shaderInfos: []file.PipelineShaderInfo,
    shaderNames: [5][]const u8,
    pipeRes: *VulkanPipelineInfo,
    allocator: std.mem.Allocator,
) !void {
    const res = &pipeRes.shaderStageCreateInfo;
    const count = &pipeRes.shaderStageCount;
    count.* = 0;

    for (shaderInfos, 0..) |info, i| {
        {
            const shaderCode = try allocator.alloc(u8, info.fileSize);
            defer allocator.free(shaderCode);
            _ = try info.file.readAll(shaderCode);
            defer info.file.close();

            const entryName = try global.vulkan.collectEntryName(&info.entryName);

            res.*[i] = vk.VkPipelineShaderStageCreateInfo{
                .sType = vk.VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
                .pNext = null,
                .flags = 0,
                .stage = info.stage,
                .pName = @ptrCast(entryName.ptr),
                .module = try global.vulkan.createShaderModule(shaderCode, shaderNames[i]),
                .pSpecializationInfo = null,
            };
            count.* += 1;
        }
    }
}
const VkDescriptorType: type = efc.generateEnumFromC(vk, vk.VkDescriptorType, "VK_DESCRIPTOR_TYPE_SAMPLER", "VK_DESCRIPTOR_TYPE_MAX_ENUM");
fn descriptorCountByDescriptorType(descriptorType: VkDescriptorType) u32 {
    switch (descriptorType) {
        .VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER => return 1024,
        else => {
            std.debug.panic("not process", .{});
        },
    }
}

const pushConstantRangeLimit = 16;
const setLayoutLimit = 8;
const pipelineLayoutCreateInfo = struct {
    pushConstantCount: u32,
    pushConstants: [pushConstantRangeLimit]vk.VkPushConstantRange,
    setLayoutCount: u32,
    setLayouts: [setLayoutLimit]vk.VkDescriptorSetLayout,
};
const bindingLimit: u32 = 5;
fn createPipelineLayoutCreateInfo(shaderInfos: []file.PipelineShaderInfo, pipeRes: *VulkanPipelineInfo) !void {
    const pushConstants = &pipeRes.descriptorSetLayouts.pushConstants;
    const pushConstantCount = &pipeRes.descriptorSetLayouts.pushConstantCount;
    pushConstantCount.* = 0;

    var pushConstantOffset: u32 = 0;
    const setCount = sc: {
        var max: u32 = 0;
        for (shaderInfos) |value| {
            max = @max(value.setCount, max);
        }
        break :sc max;
    };
    var setLayouts: [setLayoutLimit][bindingLimit]vk.VkDescriptorSetLayoutBinding = undefined;
    var bindingCount = [_]u32{0} ** bindingLimit;
    var bindingFlags: [setLayoutLimit][bindingLimit]vk.VkDescriptorBindingFlags = undefined;
    var bindless = [_]bool{false} ** bindingLimit;
    const descriptorSetLayouts = &pipeRes.descriptorSetLayouts.setLayouts;
    for (shaderInfos) |sInfo| {
        if (sInfo.pushConstantSize > 0) {
            pushConstants.*[pushConstantCount.*].stageFlags = sInfo.stage;
            pushConstants.*[pushConstantCount.*].size = @intCast(sInfo.pushConstantSize);
            pushConstants.*[pushConstantCount.*].offset = pushConstantOffset;
            pushConstantOffset += pushConstants.*[pushConstantCount.*].size;
            pushConstantCount.* += 1;
        }
        if (sInfo.bindings) |bindings| {
            for (bindings) |binding| {
                setLayouts[binding.set][binding.binding] = vk.VkDescriptorSetLayoutBinding{
                    .binding = binding.binding,
                    .stageFlags = sInfo.stage,
                    .descriptorType = binding.descriptorType,
                    .descriptorCount = ct: {
                        if (binding.descriptorCount == 0) {
                            break :ct descriptorCountByDescriptorType(@enumFromInt(binding.descriptorType));
                        } else {
                            break :ct binding.descriptorCount;
                        }
                    },
                };
                if (binding.descriptorCount == 0) {
                    bindless[binding.set] = true;
                    bindingFlags[binding.set][binding.binding] = vk.VK_DESCRIPTOR_BINDING_PARTIALLY_BOUND_BIT_EXT |
                        vk.VK_DESCRIPTOR_BINDING_UPDATE_AFTER_BIND_BIT_EXT;
                } else {
                    bindingFlags[binding.set][binding.binding] = 0;
                }
                bindingCount[binding.set] += 1;
            }
        }
    }
    for (0..setCount) |i| {
        var createInfo: vk.VkDescriptorSetLayoutCreateInfo = undefined;
        createInfo.sType = vk.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO;

        if (bindless[i]) {
            createInfo.flags = vk.VK_DESCRIPTOR_SET_LAYOUT_CREATE_UPDATE_AFTER_BIND_POOL_BIT;
            // createInfo.pNext =
        } else {
            createInfo.flags = 0;
            createInfo.pNext = null;
            createInfo.bindingCount = bindingCount[i];
            createInfo.pBindings = @ptrCast(&setLayouts[i]);

            descriptorSetLayouts.*[i] = try global.vulkan.createDescriptorSetLayout(createInfo);
        }
    }
    pipeRes.descriptorSetLayouts.setLayoutCount = setCount;
}

fn createPipelineLayout(pipeRes: *VulkanPipelineInfo) !vk.VkPipelineLayout {
    const createInfo = vk.VkPipelineLayoutCreateInfo{
        .sType = vk.VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO,
        .pNext = null,
        .flags = 0,
        .setLayoutCount = pipeRes.descriptorSetLayouts.setLayoutCount,
        .pSetLayouts = @ptrCast(&pipeRes.descriptorSetLayouts.setLayouts),
        .pushConstantRangeCount = pipeRes.descriptorSetLayouts.pushConstantCount,
        .pPushConstantRanges = @ptrCast(&pipeRes.descriptorSetLayouts.pushConstants),
    };
    return try global.vulkan.createPipelineLayout(createInfo);
}

const renderingColorAttachmentCount = 16;
const vulkanRenderingInfo = struct {
    colorAttachment: [renderingColorAttachmentCount]vk.VkFormat,
    info: vk.VkPipelineRenderingCreateInfo,
};
fn createRenderingInfo(renderingInfo: ?pipeline.renderingInfo, pipeRes: *VulkanPipelineInfo) void {
    const res = &pipeRes.renderingInfo;
    if (renderingInfo) |info| {
        for (renderingInfo.?.colorAttachment[0..renderingInfo.?.colorAttachmentCount], 0..) |value, i| {
            std.log.info("{s}", .{value});
            res.*.?.colorAttachment[i] = formatMap.get(value).?;
        }
        res.*.?.info = vk.VkPipelineRenderingCreateInfo{
            .sType = vk.VK_STRUCTURE_TYPE_PIPELINE_RENDERING_CREATE_INFO,
            .pNext = null,
            .viewMask = 0,
            .colorAttachmentCount = info.colorAttachmentCount,
            .pColorAttachmentFormats = @ptrCast(&res.*.?.colorAttachment),
            .depthAttachmentFormat = formatMap.get(info.depthAttachment).?,
            .stencilAttachmentFormat = formatMap.get(info.stencilAttachment).?,
        };
    } else {
        res.* = null;
    }
}

pub fn toVulkan(info: *pipeline.pipelineInfo, allocator: std.mem.Allocator) !*VulkanPipelineInfo {
    var res = try allocator.create(VulkanPipelineInfo);

    createVertexInputInfo(&info.vertexInputstatee, res);
    res.inputAssemblyInfo = createInputAssemblyInfo(&info.inputAssemblyy);
    res.tessellationInfo = createTessellationInfo(info.tessellationStatee);
    res.viewportInfo = createViewportInfo(&info.viewportStatee);
    res.rasterizationInfo = createRasterizationInfo(&info.rasterizationStatee);
    res.multisampleInfo = createMultisampleInfo(&info.multisampleStatee);
    res.depthStencilInfo = createDepthStencilInfo(&info.depthStencilStatee);
    createColorBlendInfo(&info.colorBlendStatee, res);
    createDynamicStateInfo(&info.dynamicStatess, res);

    var shaderInfos = try getPipelineShaderInfos(info.shaders, info.shaderCount, allocator);
    defer for (0..shaderInfos.len) |i| {
        shaderInfos[i].deinit();
    };
    try createShaderStageCreateInfo(shaderInfos, info.shaders, res, allocator);

    try createPipelineLayoutCreateInfo(shaderInfos, res);
    res.pipelineLayout = try createPipelineLayout(res);
    createRenderingInfo(info.rendering, res);

    std.mem.copyBackwards(u8, &res.name, info.name);

    return res;
}
