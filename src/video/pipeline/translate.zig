const vk = @import("vulkan").vulkan;
const file = @import("fileSystem");
const std = @import("std");
const global = @import("global");
const efc = @import("enumFromC");
const s = @import("translateBase.zig");

pub const VulkanPipelineInfo = s.VulkanPipelineInfo;
pub const setLayoutLimit = s.setLayoutLimit;

// fn getPipelineShaderInfos(shaders: [5][64]u8, count: u32, allocator: std.mem.Allocator) ![]file.PipelineShaderInfo {
//     var infos = try allocator.alloc(file.PipelineShaderInfo, count);
//     errdefer allocator.free(infos);
//     var nameBuffer = [_]u8{0} ** 128;
//     var nameZ: [:0]u8 = undefined;
//     for (0..count) |i| {
//         nameZ = try std.fmt.bufPrintZ(&nameBuffer, "{s}", .{shaders[i]});
//         infos[i] = try file.getShaderLoadParameter(nameZ);
//     }
//     return infos;
// }

// fn createShaderStageCreateInfo(
//     shaderInfos: []file.PipelineShaderInfo,
//     shaderNames: [5][64]u8,
//     pipeRes: *VulkanPipelineInfo,
//     allocator: std.mem.Allocator,
// ) !void {
//     const res = &pipeRes.shaderStageCreateInfo;
//     const count = &pipeRes.shaderStageCount;
//     count.* = 0;

//     for (shaderInfos, 0..) |info, i| {
//         {
//             const shaderCode = try allocator.alloc(u8, info.fileSize);
//             defer allocator.free(shaderCode);
//             _ = try info.file.readAll(shaderCode);
//             defer info.file.close();

//             const entryName = try global.vulkan.collectEntryName(&info.entryName);

//             res.*[i].info = vk.VkPipelineShaderStageCreateInfo{
//                 .sType = vk.VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
//                 .pNext = null,
//                 .flags = 0,
//                 .stage = info.stage,
//                 .pName = @ptrCast(entryName.ptr),
//                 .module = try global.vulkan.createShaderModule(shaderCode, &shaderNames[i]),
//                 .pSpecializationInfo = null,
//             };
//             count.* += 1;
//         }
//     }
// }
// const VkDescriptorType: type = efc.generateEnumFromC(vk, vk.VkDescriptorType, "VK_DESCRIPTOR_TYPE_SAMPLER", "VK_DESCRIPTOR_TYPE_MAX_ENUM");
// fn descriptorCountByDescriptorType(descriptorType: VkDescriptorType) u32 {
//     switch (descriptorType) {
//         .VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER => return 1024,
//         else => {
//             std.debug.panic("not process", .{});
//         },
//     }
// }
// const bindingLimit: u32 = 5;
// fn createPipelineLayoutCreateInfo(shaderInfos: []file.PipelineShaderInfo, pipeRes: *VulkanPipelineInfo) !void {
//     const pushConstants = &pipeRes.descriptorSetLayouts.pushConstants;
//     const pushConstantCount = &pipeRes.descriptorSetLayouts.pushConstantCount;
//     pushConstantCount.* = 0;

//     var pushConstantOffset: u32 = 0;
//     const setCount = sc: {
//         var max: u32 = 0;
//         for (shaderInfos) |value| {
//             max = @max(value.setCount, max);
//         }
//         break :sc max;
//     };
//     var setLayouts: [s.setLayoutLimit][bindingLimit]vk.VkDescriptorSetLayoutBinding = undefined;
//     var bindingCount = [_]u32{0} ** bindingLimit;
//     var bindingFlags: [s.setLayoutLimit][bindingLimit]vk.VkDescriptorBindingFlags = undefined;
//     var bindless = [_]bool{false} ** bindingLimit;
//     const descriptorSetLayouts = &pipeRes.descriptorSetLayouts.setLayouts;
//     for (shaderInfos) |sInfo| {
//         if (sInfo.pushConstantSize > 0) {
//             pushConstants.*[pushConstantCount.*].stageFlags = sInfo.stage;
//             pushConstants.*[pushConstantCount.*].size = @intCast(sInfo.pushConstantSize);
//             pushConstants.*[pushConstantCount.*].offset = pushConstantOffset;
//             pushConstantOffset += pushConstants.*[pushConstantCount.*].size;
//             pushConstantCount.* += 1;
//         }
//         if (sInfo.bindings) |bindings| {
//             for (bindings) |binding| {
//                 setLayouts[binding.set][binding.binding] = vk.VkDescriptorSetLayoutBinding{
//                     .binding = binding.binding,
//                     .stageFlags = sInfo.stage,
//                     .descriptorType = binding.descriptorType,
//                     .descriptorCount = ct: {
//                         if (binding.descriptorCount == 0) {
//                             break :ct descriptorCountByDescriptorType(@enumFromInt(binding.descriptorType));
//                         } else {
//                             break :ct binding.descriptorCount;
//                         }
//                     },
//                 };
//                 if (binding.descriptorCount == 0) {
//                     bindless[binding.set] = true;
//                     bindingFlags[binding.set][binding.binding] = vk.VK_DESCRIPTOR_BINDING_PARTIALLY_BOUND_BIT_EXT |
//                         vk.VK_DESCRIPTOR_BINDING_UPDATE_AFTER_BIND_BIT_EXT;
//                 } else {
//                     bindingFlags[binding.set][binding.binding] = 0;
//                 }
//                 bindingCount[binding.set] += 1;
//             }
//         }
//     }
//     for (0..setCount) |i| {
//         var createInfo: vk.VkDescriptorSetLayoutCreateInfo = undefined;
//         createInfo.sType = vk.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO;

//         if (bindless[i]) {
//             createInfo.flags = vk.VK_DESCRIPTOR_SET_LAYOUT_CREATE_UPDATE_AFTER_BIND_POOL_BIT;
//             // createInfo.pNext =
//         } else {
//             createInfo.flags = 0;
//             createInfo.pNext = null;
//             createInfo.bindingCount = bindingCount[i];
//             createInfo.pBindings = @ptrCast(&setLayouts[i]);

//             descriptorSetLayouts.*[i] = try global.vulkan.createDescriptorSetLayout(createInfo);
//         }
//     }
//     pipeRes.descriptorSetLayouts.setLayoutCount = setCount;
// }

// fn createPipelineLayout(pipeRes: *VulkanPipelineInfo) !vk.VkPipelineLayout {
//     const createInfo = vk.VkPipelineLayoutCreateInfo{
//         .sType = vk.VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO,
//         .pNext = null,
//         .flags = 0,
//         .setLayoutCount = pipeRes.descriptorSetLayouts.setLayoutCount,
//         .pSetLayouts = @ptrCast(&pipeRes.descriptorSetLayouts.setLayouts),
//         .pushConstantRangeCount = pipeRes.descriptorSetLayouts.pushConstantCount,
//         .pPushConstantRanges = @ptrCast(&pipeRes.descriptorSetLayouts.pushConstants),
//     };
//     return try global.vulkan.createPipelineLayout(createInfo);
// }//

fn haveBindless(flags: []u32) bool {
    for (flags) |fs| {
        if (fs != 0) return true;
    }
    return false;
}
pub fn toVulkan(partialFillInfo: *VulkanPipelineInfo, shaderCodes: [5][]u8) !void {
    for (0..partialFillInfo.shaderStageCount) |i| {
        const pEntryName = try global.vulkan.collectEntryName(&partialFillInfo.entryNames[i]);
        std.log.debug("entry name {s} outer", .{pEntryName.*});
        partialFillInfo.shaderStageCreateInfo[i].pName = @ptrCast(pEntryName.ptr);
        partialFillInfo.shaderStageCreateInfo[i].module = try global.vulkan.createShaderModule(shaderCodes[i], &partialFillInfo.shaderName[i]);
    }
    for (0..partialFillInfo.descriptorSetLayouts.setLayoutCount) |i| {
        if (haveBindless(&partialFillInfo.descriptorSetLayouts.bindingFlags[i])) {
            partialFillInfo.descriptorSetLayouts.bindingFlagInfo[i] = vk.VkDescriptorSetLayoutBindingFlagsCreateInfo{
                .sType = vk.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_BINDING_FLAGS_CREATE_INFO,
                .bindingCount = partialFillInfo.descriptorSetLayouts.setLayoutCreateInfos[i].bindingCount,
                .pBindingFlags = @ptrCast(&partialFillInfo.descriptorSetLayouts.bindingFlags[i]),
                .pNext = null,
            };
            partialFillInfo.descriptorSetLayouts.setLayoutCreateInfos[i].pNext = @ptrCast(&partialFillInfo.descriptorSetLayouts.bindingFlagInfo[i]);
        } else {
            partialFillInfo.descriptorSetLayouts.setLayoutCreateInfos[i].pNext = null;
        }
        partialFillInfo.descriptorSetLayouts.setLayoutCreateInfos[i].pBindings = @ptrCast(&partialFillInfo.descriptorSetLayouts.setLayoutBinding[i]);
        partialFillInfo.descriptorSetLayouts.setLayouts[i] = try global.vulkan.createDescriptorSetLayout(partialFillInfo.descriptorSetLayouts.setLayoutCreateInfos[i]);
    }
    partialFillInfo.pipelineLayout.info.pPushConstantRanges = @ptrCast(&partialFillInfo.descriptorSetLayouts.pushConstants);
    partialFillInfo.pipelineLayout.info.pSetLayouts = @ptrCast(&partialFillInfo.descriptorSetLayouts.setLayouts);
    partialFillInfo.pipelineLayout.layout = try global.vulkan.createPipelineLayout(partialFillInfo.pipelineLayout.info);
}
