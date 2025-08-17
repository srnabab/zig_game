const std = @import("std");
const s = @cImport(@cInclude("spirv_reflect/spirv_reflect.h"));
const v = @cImport(@cInclude("vulkan/vulkan.h"));
const efc = @import("EnumC");
const assert = std.debug.assert;

const VkShaderStageFlagBits: type = efc.generateEnumFromC(v, v.VkShaderStageFlagBits, "VK_SHADER_STAGE_VERTEX_BIT", "VK_SHADER_STAGE_FLAG_BITS_MAX_ENUM");
const VkDescriptorType: type = efc.generateEnumFromC(v, v.VkDescriptorType, "VK_DESCRIPTOR_TYPE_SAMPLER", "VK_DESCRIPTOR_TYPE_MAX_ENUM");

pub const binding = struct {
    set: u32,
    binding: u32,
    descriptorCount: u32,
    descriptorType: VkDescriptorType,
};

const shaderInfo = struct {
    name: [64:0]u8,
    pushConstantSize: u32,
    bindingCount: u32,
    stage: VkShaderStageFlagBits,
    bindings: ?[]binding,
};

pub fn reflect(allocator: std.mem.Allocator, cc: std.fs.File.Metadata, content: []const u8) !shaderInfo {
    var res: shaderInfo = undefined;

    var spv_result: s.SpvReflectResult = 0;
    var module: s.SpvReflectShaderModule = undefined;

    spv_result = s.spvReflectCreateShaderModule(@intCast(cc.size()), @ptrCast(content.ptr), @ptrCast(&module));
    defer s.spvReflectDestroyShaderModule(@ptrCast(&module));
    assert(spv_result == s.SPV_REFLECT_RESULT_SUCCESS);

    _ = try std.fmt.bufPrintZ(&res.name, "{s}", .{module.entry_point_name});
    res.stage = @enumFromInt(module.shader_stage);

    var var_count: u32 = 0;
    spv_result = s.spvReflectEnumerateDescriptorBindings(@ptrCast(&module), @ptrCast(&var_count), null);
    assert(spv_result == s.SPV_REFLECT_RESULT_SUCCESS);

    if (var_count != 0) {
        const bs = try allocator.alloc(binding, var_count);
        const bindings = try allocator.alloc([*c]s.SpvReflectDescriptorBinding, var_count);
        defer allocator.free(bindings);
        spv_result = s.spvReflectEnumerateDescriptorBindings(@ptrCast(&module), @ptrCast(&var_count), @ptrCast(bindings.ptr));
        assert(spv_result == s.SPV_REFLECT_RESULT_SUCCESS);

        for (bindings, 0..) |bbb, i| {
            bs[i].binding = bbb.*.binding;
            bs[i].set = bbb.*.set;
            bs[i].descriptorType = @enumFromInt(bbb.*.descriptor_type);
            bs[i].descriptorCount = bbb.*.count;
        }
        res.bindingCount = var_count;
        res.bindings = bs;
    } else {
        res.bindingCount = 0;
        res.bindings = null;
    }

    var_count = 0;
    spv_result = s.spvReflectEnumeratePushConstantBlocks(@ptrCast(&module), @ptrCast(&var_count), null);
    assert(spv_result == s.SPV_REFLECT_RESULT_SUCCESS);

    if (var_count != 0) {
        const pushconstants: [][*c]s.SpvReflectBlockVariable = try allocator.alloc([*c]s.SpvReflectBlockVariable, var_count);
        defer allocator.free(pushconstants);
        spv_result = s.spvReflectEnumeratePushConstantBlocks(@ptrCast(&module), @ptrCast(&var_count), @ptrCast(pushconstants.ptr));
        assert(spv_result == s.SPV_REFLECT_RESULT_SUCCESS);
        res.pushConstantSize = pushconstants[0].*.size;
    } else {
        res.pushConstantSize = 0;
    }

    return res;
}
