const std = @import("std");

pub const Pass = @import("pass.zig");
const vk = @import("vulkan");

const Allocator = std.mem.Allocator;

var passMap: std.StringHashMap(Pass.Pass) = undefined;
var passArray: std.array_list.Managed(Pass.Pass) = undefined;
var buffers: std.StringHashMap(Pass.Buffer) = undefined;
var pipelines: std.StringHashMap(Pass.Pipeline) = undefined;
var allocator: std.heap.ArenaAllocator = undefined;

pub fn init(gpa: Allocator) void {
    passMap = .init(gpa);
    passArray = .init(gpa);
    buffers = .init(gpa);
    pipelines = .init(gpa);
    allocator = .init(gpa);
}

pub fn deinit() void {
    passMap.deinit();
    passArray.deinit();
    buffers.deinit();
    pipelines.deinit();
    allocator.deinit();
}

pub fn createBuffer(name: []const u8, initSize: u64, stride: u64, usage: Pass.BufferUsage) !Pass.Buffer {
    const name_dupe = try allocator.allocator().dupe(u8, name);

    const buffer = Pass.Buffer{
        .name = name_dupe,
        .initSize = initSize,
        .usage = usage,
        .stride = stride,
    };

    try buffers.put(name_dupe, buffer);

    return buffer;
}

pub fn addPipeline(name: []const u8, isMesh: bool) !Pass.Pipeline {
    const name_dupe = try allocator.allocator().dupe(u8, name);

    const pipeline = Pass.Pipeline{
        .name = name_dupe,
        .isMesh = isMesh,
    };

    try pipelines.put(name_dupe, pipeline);

    return pipeline;
}

pub fn createPass(name: []const u8) !void {
    const name_dupe = try allocator.allocator().dupe(u8, name);

    const pass = Pass.Pass{
        .name = name_dupe,
        .buffers = &.{},
        .pipeline = null,
        .pushConstant = .{},
    };

    try passMap.put(name_dupe, pass);
}

pub fn addBufferToPass(passName: []const u8, buffer: Pass.Buffer) !void {
    const pass = passMap.getPtr(passName) orelse return error.PassNotFound;

    const buf = buffers.get(buffer.name) orelse return error.BufferNotFound;

    const index = pass.buffers.len;
    if (pass.buffers.len == 0) {
        pass.buffers = try allocator.allocator().alloc(Pass.Buffer, 1);
    } else {
        pass.buffers = try allocator.allocator().realloc(pass.buffers, pass.buffers.len + 1);
    }

    pass.buffers[index] = buf;
}

pub fn addPipelineToPass(passName: []const u8, pipeline: Pass.Pipeline) !void {
    const pass = passMap.getPtr(passName) orelse return error.PassNotFound;

    const pip = pipelines.get(pipeline.name) orelse return error.PipelineNotFound;

    pass.pipeline = pip;
}

pub fn addVTableToPass(passName: []const u8, vtable: *const Pass.VTable) !void {
    const pass = passMap.getPtr(passName) orelse return error.PassNotFound;

    pass.vtable = vtable;
}

pub fn setPushConstant(passName: []const u8, stage: vk.VkShaderStageFlags, size: u16) !void {
    const pass = passMap.getPtr(passName) orelse return error.PassNotFound;

    pass.pushConstant.stageFlag = stage;
    pass.pushConstant.size = size;
    pass.pushConstant.offset = 0;
}
pub fn appendPass(passName: []const u8) !void {
    const pass = passMap.get(passName) orelse return error.PassNotFound;

    try passArray.append(pass);
}

pub fn getPassCount() usize {
    return passArray.items.len;
}

pub fn getPass(index: usize) Pass.Pass {
    return passArray.items[index];
}
