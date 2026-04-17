const std = @import("std");
const s = @import("spriv_reflect");
pub const vk = @import("vulkan");
const efc = @import("EnumC");
const assert = std.debug.assert;

pub const binding = struct {
    set: u32,
    binding: u32,
    descriptorCount: u32,
    descriptorType: vk.VkDescriptorType,
};

pub const input = struct {
    location: u32,
    varType: vk.VkFormat,
};

pub const pushConstantMemberType = enum {
    int,
    float,
    vec2,
    vec3,
    vec4,
    mat2,
    mat3,
    mat4,
    ivec2,
    ivec3,
    ivec4,
};

pub const pushConstantMember = struct {
    name: [64:0]u8,
    varType: pushConstantMemberType,
};

const shaderInfo = struct {
    const Self = @This();

    name: [64:0]u8,
    stage: vk.VkShaderStageFlagBits,
    pushConstantSize: u32,
    pushConstantName: [64:0]u8,
    pushConstantMemberCount: u32,
    pushConstantMembers: ?[]pushConstantMember,
    setCount: u32,
    bindingCount: u32,
    inputCount: u32,
    bindings: ?[]binding,
    inputs: ?[]input,
    outputCount: u32,
    outputs: ?[]input,

    pub fn deinit(self: Self, allocator: std.mem.Allocator) void {
        if (self.bindings) |ss| {
            allocator.free(ss);
        }
        if (self.inputs) |ss| {
            allocator.free(ss);
        }
        if (self.outputs) |ss| {
            allocator.free(ss);
        }
    }
};

pub fn reflect(allocator: std.mem.Allocator, cc: std.Io.File.Stat, content: []const u8) !shaderInfo {
    var res: shaderInfo = undefined;

    var spv_result: s.SpvReflectResult = 0;
    var module: s.SpvReflectShaderModule = undefined;

    spv_result = s.spvReflectCreateShaderModule(@intCast(cc.size), @ptrCast(content.ptr), @ptrCast(&module));
    defer s.spvReflectDestroyShaderModule(@ptrCast(&module));
    assert(spv_result == s.SPV_REFLECT_RESULT_SUCCESS);

    _ = try std.fmt.bufPrintZ(&res.name, "{s}", .{module.entry_point_name});
    res.stage = module.shader_stage;

    var biggerstSet: i32 = -1;

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
            biggerstSet = @max(@as(i32, @intCast(bbb.*.set)), biggerstSet);
            bs[i].descriptorType = bbb.*.descriptor_type;
            bs[i].descriptorCount = bbb.*.count;
        }
        res.bindingCount = var_count;
        res.bindings = bs;
    } else {
        res.bindingCount = 0;
        res.bindings = null;
    }

    res.setCount = @intCast(biggerstSet + 1);

    var_count = 0;
    spv_result = s.spvReflectEnumeratePushConstantBlocks(@ptrCast(&module), @ptrCast(&var_count), null);
    assert(spv_result == s.SPV_REFLECT_RESULT_SUCCESS);

    // std.log.debug("var_count: {d}", .{var_count});
    if (var_count != 0) {
        const pushconstants: [][*c]s.SpvReflectBlockVariable = try allocator.alloc([*c]s.SpvReflectBlockVariable, var_count);
        defer allocator.free(pushconstants);
        spv_result = s.spvReflectEnumeratePushConstantBlocks(@ptrCast(&module), @ptrCast(&var_count), @ptrCast(pushconstants.ptr));
        assert(spv_result == s.SPV_REFLECT_RESULT_SUCCESS);
        res.pushConstantSize = pushconstants[0].*.size;

        const nameLen = std.mem.len(pushconstants[0].*.type_description.*.type_name);
        @memcpy(res.pushConstantName[0..nameLen], pushconstants[0].*.type_description.*.type_name[0..nameLen]);
        res.pushConstantMemberCount = pushconstants[0].*.type_description.*.member_count;

        res.pushConstantMembers = try allocator.alloc(pushConstantMember, res.pushConstantMemberCount);
        for (0..res.pushConstantMemberCount) |j| {
            @memset(&res.pushConstantMembers.?[j].name, 0);
            const nameLen2 = std.mem.len(pushconstants[0].*.type_description.*.members[j].struct_member_name);
            @memcpy(res.pushConstantMembers.?[j].name[0..nameLen2], pushconstants[0].*.type_description.*.members[j].struct_member_name[0..nameLen2]);
            if (pushconstants[0].*.type_description.*.members[j].type_flags == s.SPV_REFLECT_TYPE_FLAG_VECTOR | s.SPV_REFLECT_TYPE_FLAG_FLOAT) {
                res.pushConstantMembers.?[j].varType = switch (pushconstants[0].*.type_description.*.members[j].traits.numeric.vector.component_count) {
                    2 => pushConstantMemberType.vec2,
                    3 => pushConstantMemberType.vec3,
                    4 => pushConstantMemberType.vec4,
                    else => unreachable,
                };
            } else if (pushconstants[0].*.type_description.*.members[j].type_flags == s.SPV_REFLECT_TYPE_FLAG_VECTOR | s.SPV_REFLECT_TYPE_FLAG_INT) {
                res.pushConstantMembers.?[j].varType = switch (pushconstants[0].*.type_description.*.members[j].traits.numeric.vector.component_count) {
                    2 => pushConstantMemberType.ivec2,
                    3 => pushConstantMemberType.ivec3,
                    4 => pushConstantMemberType.ivec4,
                    else => unreachable,
                };
            } else if (pushconstants[0].*.type_description.*.members[j].type_flags == s.SPV_REFLECT_TYPE_FLAG_MATRIX | s.SPV_REFLECT_TYPE_FLAG_VECTOR | s.SPV_REFLECT_TYPE_FLAG_FLOAT) {
                res.pushConstantMembers.?[j].varType = switch (pushconstants[0].*.type_description.*.members[j].traits.numeric.vector.component_count) {
                    2 => pushConstantMemberType.mat2,
                    3 => pushConstantMemberType.mat3,
                    4 => pushConstantMemberType.mat4,
                    else => unreachable,
                };
            } else if (pushconstants[0].*.type_description.*.members[j].type_flags == s.SPV_REFLECT_TYPE_FLAG_FLOAT) {
                res.pushConstantMembers.?[j].varType = pushConstantMemberType.float;
            } else if (pushconstants[0].*.type_description.*.members[j].type_flags == s.SPV_REFLECT_TYPE_FLAG_INT) {
                res.pushConstantMembers.?[j].varType = pushConstantMemberType.int;
            } else {
                std.debug.panic("not supported type", .{});
            }
            // std.log.debug("var type {}", .{res.pushConstantMembers.?[j].varType});
        }

        // std.log.info("{}\n", .{pushconstants[0].*.type_description.*});
        // std.log.info("{s}\n", .{pushconstants[0].*.type_description.*.type_name});
        // std.log.info("{}\n", .{pushconstants[0].*.type_description.*.members.*});
        // std.log.info("{s}\n", .{pushconstants[0].*.type_description.*.members.*.struct_member_name});
        // std.log.info("{}\n", .{pushconstants[0].*.type_description.*.members.*.traits});
    } else {
        res.pushConstantSize = 0;
        res.pushConstantMembers = null;
    }

    var_count = 0;
    spv_result = s.spvReflectEnumerateInputVariables(@ptrCast(&module), @ptrCast(&var_count), null);
    assert(spv_result == s.SPV_REFLECT_RESULT_SUCCESS);

    if (var_count != 0) {
        const is = try allocator.alloc(input, var_count);
        const inputs = try allocator.alloc([*c]s.SpvReflectInterfaceVariable, var_count);
        defer allocator.free(inputs);

        spv_result = s.spvReflectEnumerateInputVariables(@ptrCast(&module), @ptrCast(&var_count), @ptrCast(inputs.ptr));
        assert(spv_result == s.SPV_REFLECT_RESULT_SUCCESS);

        for (inputs, 0..) |bbb, i| {
            is[i].location = bbb.*.location;
            is[i].varType = bbb.*.format;
        }
        res.inputs = is;
        res.inputCount = var_count;
    } else {
        res.inputs = null;
        res.inputCount = 0;
    }

    var_count = 0;
    spv_result = s.spvReflectEnumerateOutputVariables(@ptrCast(&module), @ptrCast(&var_count), null);
    assert(spv_result == s.SPV_REFLECT_RESULT_SUCCESS);

    if (var_count != 0) {
        const is = try allocator.alloc(input, var_count);
        const inputs = try allocator.alloc([*c]s.SpvReflectInterfaceVariable, var_count);
        defer allocator.free(inputs);

        spv_result = s.spvReflectEnumerateOutputVariables(@ptrCast(&module), @ptrCast(&var_count), @ptrCast(inputs.ptr));
        assert(spv_result == s.SPV_REFLECT_RESULT_SUCCESS);

        for (inputs, 0..) |bbb, i| {
            is[i].location = bbb.*.location;
            is[i].varType = bbb.*.format;
        }
        res.outputs = is;
        res.outputCount = var_count;
    } else {
        res.outputs = null;
        res.outputCount = 0;
    }

    return res;
}
