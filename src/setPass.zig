const std = @import("std");
const renderFlow = @import("renderFlow");
const vk = @import("vulkan");
const vertexStruct = @import("vertexStruct");
const Pass = @import("pass").Pass;
const VTable = @import("renderFlow").Pass.VTable;
const VkStruct = @import("video");
const Commands = @import("processRender").commands;

const indirectPushConstant = struct {
    instanceBuffer: u64,
    instanceIDs: u64,
};

fn initIndirectDraw(
    userdata: ?*anyopaque,
    pass: *Pass,
    vulkan: *VkStruct,
    gpa: std.mem.Allocator,
) !void {
    _ = userdata;

    var values = indirectPushConstant{
        .instanceBuffer = vulkan.getBufferAddress(pass.buffer[1]),
        .instanceIDs = vulkan.getBufferAddress(pass.buffer[2]),
    };

    pass.setPushConstants(&values);

    var descriptorSets = [_]vk.VkDescriptorSet{
        vulkan.globalTextureDescriptorSet,
        vulkan.globalFixed2dMVPMatrixDescriptorSet,
    };

    try pass.setDescriptorSets(&descriptorSets, gpa);
}

fn setIndirectDrawPushConstant(userdata: ?*anyopaque, pValues: *anyopaque) void {
    const src: *indirectPushConstant = @ptrCast(@alignCast(userdata.?));
    const dst: *indirectPushConstant = @ptrCast(@alignCast(pValues));

    dst.* = src.*;
}

fn addCommand(userdata: ?*anyopaque, pass: *Pass, vulkan: *VkStruct, commands: *Commands) !void {
    _ = userdata;
    _ = vulkan;

    try commands.addCommand(.drawIndirect, .{
        .drawIndirect = .{
            .pipeline = pass.pipeline,
            .usedBuffers = pass.buffer[1..],
            .indirectBuffer = pass.buffer[0],
            .pTextures = pass.texture,
            .descriptorSets = pass.descriptorSet,
            .pushConstants = pass.pushConstant,
        },
    });
}

const vtableIndirectDraw = VTable{
    .init = initIndirectDraw,
    .addCommand = addCommand,
    .setPushConstants = setIndirectDrawPushConstant,
};

pub fn setting() !void {
    const buffer = try renderFlow.createBuffer(
        "indirectDrawCommand",
        @sizeOf(vk.VkDrawIndirectCommand),
        0,
        .indirect,
    );
    const buffer2 = try renderFlow.createBuffer(
        "instance2D",
        1000 * @sizeOf(vertexStruct.Instance),
        @sizeOf(vertexStruct.Instance),
        .storage,
    );
    const buffer3 = try renderFlow.createBuffer(
        "instanceID2D",
        1000 * @sizeOf(u32),
        @sizeOf(u32),
        .storage,
    );

    const pipe = try renderFlow.addPipeline("indirectDraw.pipeb", false);

    try renderFlow.createPass("indirect2D");
    try renderFlow.addPipelineToPass("indirect2D", pipe);
    try renderFlow.addBufferToPass("indirect2D", buffer);
    try renderFlow.addBufferToPass("indirect2D", buffer2);
    try renderFlow.addBufferToPass("indirect2D", buffer3);
    try renderFlow.setPushConstant("indirect2D", vk.VK_SHADER_STAGE_VERTEX_BIT, 16);

    try renderFlow.addVTableToPass("indirect2D", &vtableIndirectDraw);

    try renderFlow.appendPass("indirect2D");
}
