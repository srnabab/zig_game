const pipeline = @import("pipeline.zig");
const std = @import("std");
const s = @import("translateBase.zig");
const vk = @import("vulkan").vulkan;
const reflect = @import("reflect");
const efc = @import("enumFromC");

pub const VulkanPipelineInfo = s.VulkanPipelineInfo;
const setLayoutLimit = s.setLayoutLimit;
const bindingLimit = s.bindingLimit;

pub const PipelineShaderInfo = struct {
    const Self = @This();

    const binding = struct {
        set: u32,
        binding: u32,
        descriptorCount: u32,
        descriptorType: vk.VkDescriptorType,
    };

    fileSize: u64,
    shaderCode: []u8,
    entryName: [64]u8 = std.mem.zeroes([64]u8),
    stage: vk.VkShaderStageFlags,
    setCount: u32,
    bindingCount: u32,
    bindings: ?[]binding,
    pushConstantSize: u64,
    pushConstants: ?PushConstants,

    pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
        if (self.bindings) |mem| {
            allocator.free(mem);
        }
    }
};

const PushConstants = struct {
    stage: vk.VkShaderStageFlags,
    pushConstantName: [64:0]u8,
    pushConstantMemberCount: u32,
    pushConstantMembers: ?[]reflect.pushConstantMember,
};

const PushConstantMember = struct {
    name: []const u8,
    memberType: reflect.pushConstantMemberType,
};
const PushConstantAndStage = struct {
    stage: vk.VkShaderStageFlags,
    members: []PushConstantMember,
};
const PipelineNameAndPushConstantsByStage = struct {
    name: []const u8,
    stagePushConstants: []PushConstantAndStage,
};
pub const PipelinePushConstatsJson = struct {
    ?[]PipelineNameAndPushConstantsByStage,
};

fn getPipelineShaderInfos(shaders: [5][]const u8, count: u32, shaderFolder: []const u8, allocator: std.mem.Allocator) ![]PipelineShaderInfo {
    var infos = try allocator.alloc(PipelineShaderInfo, count);
    errdefer allocator.free(infos);

    var nameBuffer = [_]u8{0} ** 128;
    var nameZ: [:0]u8 = undefined;

    var folder = try std.fs.cwd().openDir(shaderFolder, .{});
    defer folder.close();

    var file: std.fs.File = undefined;

    for (0..count) |i| {
        nameZ = try std.fmt.bufPrintZ(&nameBuffer, "{s}", .{shaders[i]});

        {
            file = try folder.openFile(shaders[i], .{});
            defer file.close();

            const cc = try file.stat();
            // std.log.debug("file size {d}", .{cc.size});
            const content = try allocator.alloc(u8, cc.size);
            errdefer allocator.free(content);
            _ = try file.readAll(content);

            const res = try reflect.reflect(allocator, cc, content);
            defer res.deinit(allocator);

            if (res.pushConstantSize > 0) {}

            var bindings = try allocator.alloc(PipelineShaderInfo.binding, res.bindingCount);
            if (res.bindings) |bbs| {
                for (bbs, 0..) |value, j| {
                    bindings[j] = PipelineShaderInfo.binding{
                        .binding = value.binding,
                        .set = value.set,
                        .descriptorCount = value.descriptorCount,
                        .descriptorType = value.descriptorType,
                    };
                }
            }

            infos[i] = PipelineShaderInfo{
                .pushConstantSize = res.pushConstantSize,
                .stage = res.stage,
                .setCount = res.setCount,
                .bindings = bindings,
                .bindingCount = res.bindingCount,
                .fileSize = cc.size,
                .shaderCode = content,
                .pushConstants = if (res.pushConstantSize > 0) blk: {
                    break :blk PushConstants{
                        .stage = res.stage,
                        .pushConstantName = undefined,
                        .pushConstantMemberCount = res.bindingCount,
                        .pushConstantMembers = res.pushConstantMembers,
                    };
                } else null,
            };

            if (infos[i].pushConstants) |_| @memcpy(&infos[i].pushConstants.?.pushConstantName, &res.pushConstantName);
            @memcpy(&infos[i].entryName, &res.name);
        }
    }
    return infos;
}

fn createShaderStageCreateInfo(
    shaderInfos: []PipelineShaderInfo,
    pipeRes: *VulkanPipelineInfo,
) !void {
    const res = &pipeRes.shaderStageCreateInfo;
    const names = &pipeRes.entryNames;
    const count = &pipeRes.shaderStageCount;
    count.* = 0;

    for (shaderInfos, 0..) |info, i| {
        {
            res.*[i] = vk.VkPipelineShaderStageCreateInfo{
                .sType = vk.VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
                .pNext = null,
                .flags = 0,
                .stage = info.stage,
                .pName = null,
                .module = null,
                .pSpecializationInfo = null,
            };
            std.mem.copyForwards(u8, &names.*[i], &shaderInfos[i].entryName);
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
fn createPipelineLayoutCreateInfo(shaderInfos: []PipelineShaderInfo, pipeRes: *VulkanPipelineInfo) !void {
    const pushConstants = &pipeRes.pipelineCreateInfoInfo.pushConstants;
    const pushConstantCount = &pipeRes.pipelineCreateInfoInfo.pushConstantCount;
    pushConstantCount.* = 0;

    var pushConstantOffset: u32 = 0;
    const setCount = sc: {
        var max: u32 = 0;
        for (shaderInfos) |value| {
            max = @max(value.setCount, max);
        }
        break :sc max;
    };
    for (shaderInfos) |sInfo| {
        if (sInfo.pushConstantSize > 0) {
            pushConstants.*[pushConstantCount.*].stageFlags = sInfo.stage;
            pushConstants.*[pushConstantCount.*].size = @intCast(sInfo.pushConstantSize);
            pushConstants.*[pushConstantCount.*].offset = pushConstantOffset;
            pushConstantOffset += pushConstants.*[pushConstantCount.*].size;
            pushConstantCount.* += 1;
        }
    }
    pipeRes.pipelineCreateInfoInfo.setLayoutCount = setCount;
}

fn createPipelineLayout(pipeRes: *VulkanPipelineInfo) !void {
    pipeRes.pipelineLayout.info = vk.VkPipelineLayoutCreateInfo{
        .sType = vk.VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO,
        .pNext = null,
        .flags = 0,
        .setLayoutCount = pipeRes.pipelineCreateInfoInfo.setLayoutCount,
        .pSetLayouts = null,
        .pushConstantRangeCount = pipeRes.pipelineCreateInfoInfo.pushConstantCount,
        .pPushConstantRanges = null,
    };
    pipeRes.pipelineLayout.layout = null;
}

pub fn toVulkan2(info: *pipeline.pipelineInfo, shaderFolder: []const u8, allocator: std.mem.Allocator) !struct {
    info: *VulkanPipelineInfo,
    shaderCodes: [][]u8,
    pushConstantInfo: []PushConstants,
} {
    var res = try allocator.create(VulkanPipelineInfo);
    errdefer allocator.destroy(res);
    res.* = std.mem.zeroes(VulkanPipelineInfo);

    var shaderInfos = try getPipelineShaderInfos(
        info.shaders,
        info.shaderCount,
        shaderFolder,
        allocator,
    );
    defer {
        for (0..shaderInfos.len) |i| {
            shaderInfos[i].deinit(allocator);
        }
        allocator.free(shaderInfos);
    }

    const pushconstantCount = sc: {
        var count: u32 = 0;
        for (shaderInfos) |value| {
            if (value.pushConstants) |_| {
                count += 1;
            }
        }
        break :sc count;
    };
    var pushConstantInfos = try allocator.alloc(PushConstants, pushconstantCount);
    var pushConstantInfoCount: u32 = 0;
    for (shaderInfos) |value| {
        if (value.pushConstants) |pushConstant| {
            pushConstantInfos[pushConstantInfoCount] = pushConstant;
            pushConstantInfoCount += 1;
        }
    }

    var codes = try allocator.alloc([]u8, info.shaderCount);
    for (0..codes.len) |i| {
        codes[i] = shaderInfos[i].shaderCode;
    }

    try createShaderStageCreateInfo(shaderInfos, res);
    try createPipelineLayoutCreateInfo(shaderInfos, res);
    try createPipelineLayout(res);

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

    return .{
        .info = res,
        .shaderCodes = codes,
        .pushConstantInfo = pushConstantInfos,
    };
}
