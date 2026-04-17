const pipeline = @import("pipeline.zig");
const std = @import("std");
const s = @import("translateBase.zig");
const vk = @import("vulkan");
const reflect = @import("reflect");
const efc = @import("enumFromC");

const VkFormat = efc.generateEnumFromC(vk, vk.VkFormat, "VK_FORMAT_UNDEFINED", "VK_FORMAT_MAX_ENUM");
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
    outputCount: u32,
    outputs: ?[]reflect.input,

    pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
        if (self.bindings) |mem| {
            allocator.free(mem);
        }
    }
};

const PushConstants = struct {
    stage: vk.VkShaderStageFlags,
    pushConstantName: [64:0]u8,
    pushConstantMembers: []reflect.pushConstantMember,
};

pub const PushConstantMember = struct {
    name: []const u8,
    memberType: reflect.pushConstantMemberType,
};
pub const PushConstantAndStage = struct {
    stage: vk.VkShaderStageFlags,
    members: []PushConstantMember,
};
pub const PipelineNameAndPushConstantsByStage = struct {
    name: []const u8,
    stagePushConstants: []PushConstantAndStage,
};
pub const PipelinePushConstatsJson = struct {
    ?[]PipelineNameAndPushConstantsByStage,
};

fn getPipelineShaderInfos(io: std.Io, shaders: [5][]const u8, count: u32, shaderFolder: []const u8, allocator: std.mem.Allocator) ![]PipelineShaderInfo {
    var infos = try allocator.alloc(PipelineShaderInfo, count);
    errdefer allocator.free(infos);

    var nameBuffer = [_]u8{0} ** 128;
    var nameZ: [:0]u8 = undefined;

    var folder = try std.Io.Dir.cwd().openDir(io, shaderFolder, .{});
    defer folder.close(io);

    var file: std.Io.File = undefined;

    for (0..count) |i| {
        nameZ = try std.fmt.bufPrintZ(&nameBuffer, "{s}", .{shaders[i]});

        {
            var frag = false;
            if (std.mem.endsWith(u8, shaders[i], ".frag.spv")) {
                frag = true;
                std.log.debug("{s}", .{shaders[i]});
            } else {
                std.log.debug("{s}", .{shaders[i]});
            }

            file = try folder.openFile(io, shaders[i], .{});
            defer file.close(io);

            const cc = try file.stat(io);
            // std.log.debug("file size {d}", .{cc.size});
            var buffer = [_]u8{0} ** 256;
            var fileReader = file.reader(io, &buffer);

            const content = try fileReader.interface.readAlloc(allocator, cc.size);
            errdefer allocator.free(content);

            const res = try reflect.reflect(allocator, cc, content);
            defer res.deinit(allocator);

            // if (frag) {
            //     if (res.outputs) |os| {
            //         for (os) |ss| {
            //             std.log.debug("location {d}, {d} {s}", .{
            //                 ss.location,
            //                 ss.varType,
            //                 @tagName(@as(VkFormat, @enumFromInt(ss.varType))),
            //             });
            //         }
            //     }
            // }

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
                .outputCount = if (frag) res.outputCount else 0,
                .outputs = if (frag) try allocator.dupe(reflect.input, res.outputs.?) else null,
                .pushConstants = if (res.pushConstantSize > 0) blk: {
                    break :blk PushConstants{
                        .stage = res.stage,
                        .pushConstantName = undefined,
                        .pushConstantMembers = res.pushConstantMembers.?,
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
    std.log.debug("set count {d}", .{setCount});
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

pub fn toVulkan2(io: std.Io, info: *pipeline.pipelineInfo, shaderFolder: []const u8, allocator: std.mem.Allocator) !struct {
    info: *VulkanPipelineInfo,
    shaderCodes: [][]u8,
    pushConstantInfo: ?[]PushConstants,
} {
    var res = try allocator.create(VulkanPipelineInfo);
    errdefer allocator.destroy(res);
    res.* = std.mem.zeroes(VulkanPipelineInfo);

    var shaderInfos = try getPipelineShaderInfos(
        io,
        info.shaders,
        info.shaderCount,
        shaderFolder,
        allocator,
    );
    defer {
        for (0..shaderInfos.len) |i| {
            shaderInfos[i].deinit(allocator);
            if (shaderInfos[i].outputCount > 0)
                allocator.free(shaderInfos[i].outputs.?);
        }
        allocator.free(shaderInfos);
    }

    // std.log.debug("point 1", .{});
    for (shaderInfos) |value| {
        if (value.outputCount > 0) {
            // std.log.debug("point 2", .{});
            std.debug.assert(value.outputCount <= 10);
            // std.log.debug("point 3", .{});
            for (0..value.outputCount) |i| {
                res.outputs[i] = .{
                    .location = value.outputs.?[i].location,
                    .var_type = value.outputs.?[i].varType,
                };
                // _ = i;
            }
            res.outputCount = value.outputCount;
            break;
        }
    }
    // std.log.debug("point 4", .{});

    const pushconstantCount = sc: {
        var count: u32 = 0;
        for (shaderInfos) |value| {
            if (value.pushConstants) |_| {
                count += 1;
                // std.log.debug("var type {}", .{value.pushConstants.?.pushConstantMembers[0].varType});
            }
        }
        break :sc count;
    };
    var pushConstantInfos: ?[]PushConstants = null;

    if (pushconstantCount > 0) {
        pushConstantInfos = try allocator.alloc(PushConstants, pushconstantCount);
        var pushConstantInfoCount: u32 = 0;

        for (shaderInfos) |value| {
            if (value.pushConstants) |pushConstant| {
                pushConstantInfos.?[pushConstantInfoCount] = pushConstant;
                pushConstantInfoCount += 1;
            }
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
