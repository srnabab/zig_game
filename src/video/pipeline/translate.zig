const pipeline = @import("pipeline.zig");
const vk = @cImport(@cInclude("vulkan/vulkan.h"));
const efc = @import("enumFromC");
const std = @import("std");

fn comptime_print(comptime format: []const u8, comptime args: anytype) void {
    @compileLog(std.fmt.comptimePrint(format, args));
}
// 使用编译期元编程来自动生成formatMap
pub fn createStaticStringMap(
    comptime import: anytype,
    comptime tag_type: anytype,
    comptime startEnumMember: [:0]const u8,
    comptime endEnumMember: [:0]const u8,
    comptime prefix: [:0]const u8,
) std.StaticStringMap(tag_type) {
    return std.StaticStringMap(tag_type).initComptime(blk: {
        // 1. 创建一个临时的、空的条目切片
        var entries: [10000]struct { []const u8, vk.VkFormat } = undefined;
        var count: u32 = 0;

        // 2. 使用`inline for`在编译时遍历Vulkan绑定文件中的所有声明
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
            // comptime_print("decl name: {s}", .{decl.name});

            const key = decl.name[prefix.len..];
            const value = @field(import, decl.name);

            // comptime_print("{s}", .{key});

            entries[count].@"0" = key;
            entries[count].@"1" = value;
            count += 1;

            if (std.mem.eql(u8, decl.name, endEnumMember)) {
                break;
            }
        }

        // 6. `break`语句将最终的条目列表作为 comptime 块的结果返回
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
    // shaderStageCreateInfo: vk.VkPipelineShaderStageCreateInfo,
    // pipelineLayout: vk.VkPipelineLayout,

    // Store slices that the Vulkan structs point to
    allocator: std.mem.Allocator,
    vertexBindings: []vk.VkVertexInputBindingDescription,
    vertexAttributes: []vk.VkVertexInputAttributeDescription,
    colorBlendAttachments: []vk.VkPipelineColorBlendAttachmentState,
    dynamicStates: []vk.VkDynamicState,

    pub fn deinit(self: *Self) void {
        self.allocator.free(self.vertexBindings);
        self.allocator.free(self.vertexAttributes);
        self.allocator.free(self.colorBlendAttachments);
        self.allocator.free(self.dynamicStates);
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

pub fn toVulkan(info: *pipeline.pipelineInfo, allocator: std.mem.Allocator) !VulkanPipelineInfo {
    // Vertex Input
    const vertexBindings = try allocator.alloc(vk.VkVertexInputBindingDescription, info.vertexInputstatee.bindings.?.len);
    for (info.vertexInputstatee.bindings.?, 0..) |binding, i| {
        vertexBindings[i] = .{
            .binding = binding.bind,
            .stride = binding.stride,
            .inputRate = inputRateMap.get(binding.inputRate).?,
        };
    }

    const vertexAttributes = try allocator.alloc(vk.VkVertexInputAttributeDescription, info.vertexInputstatee.attributes.?.len);
    for (info.vertexInputstatee.attributes.?, 0..) |attribute, i| {
        vertexAttributes[i] = .{
            .location = attribute.location,
            .binding = attribute.binding,
            .format = formatMap.get(attribute.format).?,
            .offset = attribute.offset,
        };
    }

    const vertexInputInfo: vk.VkPipelineVertexInputStateCreateInfo = .{
        .sType = vk.VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO,
        .pNext = null,
        .flags = info.vertexInputstatee.flag,
        .vertexBindingDescriptionCount = @intCast(vertexBindings.len),
        .pVertexBindingDescriptions = vertexBindings.ptr,
        .vertexAttributeDescriptionCount = @intCast(vertexAttributes.len),
        .pVertexAttributeDescriptions = vertexAttributes.ptr,
    };

    // Input Assembly
    const inputAssemblyInfo: vk.VkPipelineInputAssemblyStateCreateInfo = .{
        .sType = vk.VK_STRUCTURE_TYPE_PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO,
        .pNext = null,
        .flags = info.inputAssemblyy.flags,
        .topology = topologyMap.get(info.inputAssemblyy.topology).?,
        .primitiveRestartEnable = @intFromBool(info.inputAssemblyy.primitiveRestartEnable),
    };

    // Tessellation
    var tessellationInfo: ?vk.VkPipelineTessellationStateCreateInfo = null;
    if (info.tessellationStatee) |tessellationStatee| {
        tessellationInfo = .{
            .sType = vk.VK_STRUCTURE_TYPE_PIPELINE_TESSELLATION_STATE_CREATE_INFO,
            .pNext = null,
            .flags = tessellationStatee.flags,
            .patchControlPoints = tessellationStatee.patchControlPoints,
        };
    }

    // Viewport
    const viewportInfo: vk.VkPipelineViewportStateCreateInfo = .{
        .sType = vk.VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_STATE_CREATE_INFO,
        .pNext = null,
        .flags = info.viewportStatee.flags,
        .viewportCount = info.viewportStatee.viewportCount,
        .pViewports = null, // Dynamic state
        .scissorCount = info.viewportStatee.scissorCount,
        .pScissors = null, // Dynamic state
    };

    // Rasterization
    const rasterizationInfo: vk.VkPipelineRasterizationStateCreateInfo = .{
        .sType = vk.VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_STATE_CREATE_INFO,
        .pNext = null,
        .flags = info.rasterizationStatee.flags,
        .depthClampEnable = @intFromBool(info.rasterizationStatee.depthClampEnable),
        .rasterizerDiscardEnable = @intFromBool(info.rasterizationStatee.rasterizerDiscardEnable),
        .polygonMode = polygonModeMap.get(info.rasterizationStatee.polygonMode).?,
        .cullMode = cullModeMap.get(info.rasterizationStatee.cullMode).?,
        .frontFace = frontFaceMap.get(info.rasterizationStatee.frontFace).?,
        .depthBiasEnable = @intFromBool(info.rasterizationStatee.depthBiasEnable),
        .depthBiasConstantFactor = info.rasterizationStatee.depthBiasConstantFactor,
        .depthBiasClamp = info.rasterizationStatee.depthBiasClamp,
        .depthBiasSlopeFactor = info.rasterizationStatee.depthBiasSlopeFactor,
        .lineWidth = info.rasterizationStatee.lineWidth,
    };

    // Multisample
    const multisampleInfo: vk.VkPipelineMultisampleStateCreateInfo = .{
        .sType = vk.VK_STRUCTURE_TYPE_PIPELINE_MULTISAMPLE_STATE_CREATE_INFO,
        .pNext = null,
        .flags = info.multisampleStatee.flags,
        .rasterizationSamples = sampleCountMap.get(info.multisampleStatee.rasterizationSamples).?,
        .sampleShadingEnable = @intFromBool(info.multisampleStatee.sampleShadingEnable),
        .minSampleShading = info.multisampleStatee.minSampleShading,
        .pSampleMask = null,
        .alphaToCoverageEnable = @intFromBool(info.multisampleStatee.alphaToCoverageEnable),
        .alphaToOneEnable = @intFromBool(info.multisampleStatee.alphaToOneEnable),
    };

    // Depth Stencil
    const depthStencilInfo: vk.VkPipelineDepthStencilStateCreateInfo = .{
        .sType = vk.VK_STRUCTURE_TYPE_PIPELINE_DEPTH_STENCIL_STATE_CREATE_INFO,
        .pNext = null,
        .flags = info.depthStencilStatee.flags,
        .depthTestEnable = @intFromBool(info.depthStencilStatee.depthTestEnable),
        .depthWriteEnable = @intFromBool(info.depthStencilStatee.depthWriteEnable),
        .depthCompareOp = compareOpMap.get(info.depthStencilStatee.depthCompareOp).?,
        .depthBoundsTestEnable = @intFromBool(info.depthStencilStatee.depthBoundsTestEnable),
        .stencilTestEnable = @intFromBool(info.depthStencilStatee.stencilTestEnable),
        .front = if (info.depthStencilStatee.front) |front| .{
            .failOp = stencilOpMap.get(front.failOp).?,
            .passOp = stencilOpMap.get(front.passOp).?,
            .depthFailOp = stencilOpMap.get(front.depthFailOp).?,
            .compareOp = compareOpMap.get(front.compareOp).?,
            .compareMask = front.compareMask,
            .writeMask = front.writeMask,
            .reference = front.reference,
        } else .{},
        .back = if (info.depthStencilStatee.back) |back| .{
            .failOp = stencilOpMap.get(back.failOp).?,
            .passOp = stencilOpMap.get(back.passOp).?,
            .depthFailOp = stencilOpMap.get(back.depthFailOp).?,
            .compareOp = compareOpMap.get(back.compareOp).?,
            .compareMask = back.compareMask,
            .writeMask = back.writeMask,
            .reference = back.reference,
        } else .{},
        .minDepthBounds = info.depthStencilStatee.minDepthBounds,
        .maxDepthBounds = info.depthStencilStatee.maxDepthBounds,
    };

    // Color Blend
    const colorBlendAttachments = try allocator.alloc(vk.VkPipelineColorBlendAttachmentState, info.colorBlendStatee.attachments.len);
    for (info.colorBlendStatee.attachments, 0..) |attachment, i| {
        colorBlendAttachments[i] = .{
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

    const colorBlendInfo: vk.VkPipelineColorBlendStateCreateInfo = .{
        .sType = vk.VK_STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_STATE_CREATE_INFO,
        .pNext = null,
        .flags = info.colorBlendStatee.flags,
        .logicOpEnable = @intFromBool(info.colorBlendStatee.logicOpEnable),
        .logicOp = logicOpMap.get(info.colorBlendStatee.logicOp).?,
        .attachmentCount = @intCast(colorBlendAttachments.len),
        .pAttachments = colorBlendAttachments.ptr,
        .blendConstants = info.colorBlendStatee.blendConstants,
    };

    // Dynamic State
    const dynamicStates = try allocator.alloc(vk.VkDynamicState, info.dynamicStatess.States.len);
    for (info.dynamicStatess.States, 0..) |state, i| {
        dynamicStates[i] = dynamicStateMap.get(state).?;
    }

    const dynamicStateInfo: vk.VkPipelineDynamicStateCreateInfo = .{
        .sType = vk.VK_STRUCTURE_TYPE_PIPELINE_DYNAMIC_STATE_CREATE_INFO,
        .pNext = null,
        .flags = 0,
        .dynamicStateCount = @intCast(dynamicStates.len),
        .pDynamicStates = dynamicStates.ptr,
    };

    return VulkanPipelineInfo{
        .vertexInputInfo = vertexInputInfo,
        .inputAssemblyInfo = inputAssemblyInfo,
        .tessellationInfo = tessellationInfo,
        .viewportInfo = viewportInfo,
        .rasterizationInfo = rasterizationInfo,
        .multisampleInfo = multisampleInfo,
        .depthStencilInfo = depthStencilInfo,
        .colorBlendInfo = colorBlendInfo,
        .dynamicStateInfo = dynamicStateInfo,
        // .pipelineLayout = ,
        // .shaderStageCreateInfo = ,
        .allocator = allocator,
        .vertexBindings = vertexBindings,
        .vertexAttributes = vertexAttributes,
        .colorBlendAttachments = colorBlendAttachments,
        .dynamicStates = dynamicStates,
    };
}
