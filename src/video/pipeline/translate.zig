const pipeline = @import("pipeline.zig");
const vk = @cImport(@cInclude("vulkan/vulkan.h"));
const file = @import("fileSystem");
const std = @import("std");
const global = @import("global");

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

    vertexInputInfo: vk.VkPipelineVertexInputStateCreateInfo,
    inputAssemblyInfo: vk.VkPipelineInputAssemblyStateCreateInfo,
    tessellationInfo: ?vk.VkPipelineTessellationStateCreateInfo,
    viewportInfo: vk.VkPipelineViewportStateCreateInfo,
    rasterizationInfo: vk.VkPipelineRasterizationStateCreateInfo,
    multisampleInfo: vk.VkPipelineMultisampleStateCreateInfo,
    depthStencilInfo: vk.VkPipelineDepthStencilStateCreateInfo,
    colorBlendInfo: vk.VkPipelineColorBlendStateCreateInfo,
    dynamicStateInfo: vk.VkPipelineDynamicStateCreateInfo,
    shaderStageCreateInfo: []vk.VkPipelineShaderStageCreateInfo,
    // pipelineLayout: vk.VkPipelineLayout,

    allocator: std.heap.ArenaAllocator,

    pub fn deinit(self: *Self) void {
        self.allocator.deinit();
    }
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
const VulkanVertexInputInfo = struct {
    createInfo: vk.VkPipelineVertexInputStateCreateInfo,
    bindings: []vk.VkVertexInputBindingDescription,
    attributes: []vk.VkVertexInputAttributeDescription,
};

const VulkanColorBlendInfo = struct {
    createInfo: vk.VkPipelineColorBlendStateCreateInfo,
    attachments: []vk.VkPipelineColorBlendAttachmentState,
};

const VulkanDynamicStateInfo = struct {
    createInfo: vk.VkPipelineDynamicStateCreateInfo,
    states: []vk.VkDynamicState,
};

fn createVertexInputInfo(info: *const pipeline.vertexInputState, allocator: *std.heap.ArenaAllocator) !VulkanVertexInputInfo {
    const bindings = try allocator.allocator().alloc(vk.VkVertexInputBindingDescription, info.bindings.?.len);
    for (info.bindings.?, 0..) |binding, i| {
        bindings[i] = .{
            .binding = binding.bind,
            .stride = binding.stride,
            .inputRate = inputRateMap.get(binding.inputRate).?,
        };
    }

    const attributes = try allocator.allocator().alloc(vk.VkVertexInputAttributeDescription, info.attributes.?.len);
    for (info.attributes.?, 0..) |attribute, i| {
        attributes[i] = .{
            .location = attribute.location,
            .binding = attribute.binding,
            .format = formatMap.get(attribute.format).?,
            .offset = attribute.offset,
        };
    }

    const createInfo: vk.VkPipelineVertexInputStateCreateInfo = .{
        .sType = vk.VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO,
        .pNext = null,
        .flags = info.flag,
        .vertexBindingDescriptionCount = @intCast(bindings.len),
        .pVertexBindingDescriptions = bindings.ptr,
        .vertexAttributeDescriptionCount = @intCast(attributes.len),
        .pVertexAttributeDescriptions = attributes.ptr,
    };

    return .{
        .createInfo = createInfo,
        .bindings = bindings,
        .attributes = attributes,
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
        .viewportCount = info.viewportCount,
        .pViewports = null, // dynamic
        .scissorCount = info.scissorCount,
        .pScissors = null, // dynamic
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

fn createColorBlendInfo(info: *const pipeline.colorBlendState, allocator: *std.heap.ArenaAllocator) !VulkanColorBlendInfo {
    const attachments = try allocator.allocator().alloc(vk.VkPipelineColorBlendAttachmentState, info.attachments.len);
    for (info.attachments, 0..) |attachment, i| {
        attachments[i] = .{
            .blendEnable = @intFromBool(attachment.blendEnable),
            .srcColorBlendFactor = blendFactorMap.get(attachment.srcColorBlendFactor).?,
            .dstColorBlendFactor = blendFactorMap.get(attachment.dstColorBlendFactor).?,
            .colorBlendOp = blendOpMap.get(attachment.colorBlendOp).?,
            .srcAlphaBlendFactor = blendFactorMap.get(attachment.srcAlphaBlendFactor).?,
            .dstAlphaBlendFactor = blendFactorMap.get(attachment.dstAlphaBlendFactor).?,
            .alphaBlendOp = blendOpMap.get(attachment.alphaBlendOp).?,
            .colorWriteMask = translateColorWriteMask(attachment.colorWriteMask),
        };
    }

    const createInfo: vk.VkPipelineColorBlendStateCreateInfo = .{
        .sType = vk.VK_STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_STATE_CREATE_INFO,
        .pNext = null,
        .flags = info.flags,
        .logicOpEnable = @intFromBool(info.logicOpEnable),
        .logicOp = logicOpMap.get(info.logicOp).?,
        .attachmentCount = @intCast(attachments.len),
        .pAttachments = attachments.ptr,
        .blendConstants = info.blendConstants,
    };

    return .{
        .createInfo = createInfo,
        .attachments = attachments,
    };
}

fn createDynamicStateInfo(info: *const pipeline.dynamicStates, allocator: *std.heap.ArenaAllocator) !VulkanDynamicStateInfo {
    const states = try allocator.allocator().alloc(vk.VkDynamicState, info.States.len);
    for (info.States, 0..) |state, i| {
        states[i] = dynamicStateMap.get(state).?;
    }

    const createInfo: vk.VkPipelineDynamicStateCreateInfo = .{
        .sType = vk.VK_STRUCTURE_TYPE_PIPELINE_DYNAMIC_STATE_CREATE_INFO,
        .pNext = null,
        .flags = 0,
        .dynamicStateCount = @intCast(states.len),
        .pDynamicStates = states.ptr,
    };

    return .{
        .createInfo = createInfo,
        .states = states,
    };
}

fn getPipelineShaderInfos(shaders: [5][]const u8, count: u32, allocator: *std.heap.ArenaAllocator) ![]file.PipelineShaderInfo {
    var infos = try allocator.allocator().alloc(file.PipelineShaderInfo, count);
    var nameBuffer = [_]u8{0} ** 256;
    var nameZ: [:0]u8 = undefined;
    for (0..count) |i| {
        nameZ = try std.fmt.bufPrintZ(&nameBuffer, "{s}", .{shaders[i]});
        infos[i] = try file.getShaderLoadParameter(nameZ);
    }
    return infos;
}

fn createShaderStageCreateInfo(shaderInfos: []file.PipelineShaderInfo, shaderNames: [5][]const u8, allocator: *std.heap.ArenaAllocator) ![]vk.VkPipelineShaderStageCreateInfo {
    var createInfo = try allocator.allocator().alloc(vk.VkPipelineShaderStageCreateInfo, shaderInfos.len);
    for (shaderInfos, 0..) |info, i| {
        {
            const shaderCode = try allocator.allocator().alloc(u8, info.fileSize);
            defer allocator.allocator().free(shaderCode);
            _ = try info.file.readAll(shaderCode);
            defer info.file.close();

            const entryName = (try global.vulkan.collectEntryName(&info.entryName));

            createInfo[i] = vk.VkPipelineShaderStageCreateInfo{
                .sType = vk.VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
                .pNext = null,
                .flags = 0,
                .stage = info.stage,
                .pName = @ptrCast(entryName.ptr),
                .module = try global.vulkan.createShaderModule(shaderCode, shaderNames[i]),
                .pSpecializationInfo = null,
            };
        }
    }
    return createInfo;
}

pub fn toVulkan(info: *pipeline.pipelineInfo, allocator: std.mem.Allocator) !VulkanPipelineInfo {
    var arena = std.heap.ArenaAllocator.init(allocator);

    const vertexInput = try createVertexInputInfo(&info.vertexInputstatee, &arena);
    const colorBlend = try createColorBlendInfo(&info.colorBlendStatee, &arena);
    const dynamicState = try createDynamicStateInfo(&info.dynamicStatess, &arena);

    var shaderInfos = try getPipelineShaderInfos(info.shaders, info.shaderCount, &arena);
    defer for (0..shaderInfos.len) |i| {
        shaderInfos[i].deinit();
    };
    const shaderStageCreateInfo = try createShaderStageCreateInfo(shaderInfos, info.shaders, &arena);

    return VulkanPipelineInfo{
        .vertexInputInfo = vertexInput.createInfo,
        .inputAssemblyInfo = createInputAssemblyInfo(&info.inputAssemblyy),
        .tessellationInfo = createTessellationInfo(info.tessellationStatee),
        .viewportInfo = createViewportInfo(&info.viewportStatee),
        .rasterizationInfo = createRasterizationInfo(&info.rasterizationStatee),
        .multisampleInfo = createMultisampleInfo(&info.multisampleStatee),
        .depthStencilInfo = createDepthStencilInfo(&info.depthStencilStatee),
        .colorBlendInfo = colorBlend.createInfo,
        .dynamicStateInfo = dynamicState.createInfo,
        .shaderStageCreateInfo = shaderStageCreateInfo,

        .allocator = arena,
    };
}
