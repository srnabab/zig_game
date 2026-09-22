const std = @import("std");
const Allocator = std.mem.Allocator;

const mstd = @import("ms_std");

pub const Pass = @import("pass.zig");
const vk = @import("vulkan");

const u8pack = @import("u8pack");
const Str = u8pack.Str;

var passMap: u8pack.HashMap(Pass.Pass) = undefined;
var passArray: std.array_list.Managed(Pass.Pass) = undefined;
var buffers: u8pack.HashMap(Pass.Buffer) = undefined;
var pipelines: u8pack.HashMap(Pass.Pipeline) = undefined;

var uboMap: u8pack.HashMap(Pass.UBO) = undefined;

var ubo_ui_count: u32 = 0;
var ubo_2d_count: u32 = 0;
var ubo_3d_count: u32 = 0;

var minUniformBufferOffsetAlignment: u32 = 256;

var allocator: std.heap.ArenaAllocator = undefined;

pub fn init(gpa: Allocator, uniformBufferOffsetAlignment: u32) void {
    passMap = .init(gpa);
    passArray = .init(gpa);
    buffers = .init(gpa);
    pipelines = .init(gpa);

    uboMap = .init(gpa);

    allocator = .init(gpa);

    minUniformBufferOffsetAlignment = uniformBufferOffsetAlignment;
}

pub fn deinit() void {
    passMap.deinit();
    passArray.deinit();
    buffers.deinit();
    pipelines.deinit();

    uboMap.deinit();

    allocator.deinit();
}

pub fn createBuffer(
    comptime ctx: ?*u8pack.CTX,
    comptime name: []const u8,
    initSize: u64,
    stride: u64,
    usage: Pass.BufferUsage,
    comptime isVirtualBlock: bool,
    comptime parentName: ?[]const u8,
) !Pass.Buffer {
    if (ctx != null) {
        ctx.?.buffers = ctx.?.buffers ++ .{name};

        return undefined;
    } else {
        var name_str = u8pack.toStr(name);
        if (buffers.get(name_str)) |buffer| {
            return buffer;
        }

        var offset: u64 = 0;

        if (isVirtualBlock) {
            if (parentName) |n| {
                const n_str = u8pack.toStr(n);
                if (buffers.getPtr(n_str)) |b| {
                    if (b.residuentCapacity < initSize) {
                        return error.OutOfMemory;
                    }
                    offset = b.initSize - b.residuentCapacity;

                    b.residuentCapacity -= initSize;
                } else {
                    return error.VirtualBlockWithoutParent;
                }
            } else {
                return error.VirtualBlockWithoutParent;
            }
        }

        const name_dupe = try allocator.allocator().dupe(u8, name);
        name_str.name = name_dupe;

        const buffer = Pass.Buffer{
            .name = name_str,
            .parentName = if (isVirtualBlock) u8pack.toStr(parentName.?) else null,
            .initSize = initSize,
            .usage = usage,
            .stride = stride,
            .residuentCapacity = initSize,
            .offset = offset,
        };

        try buffers.put(name_str, buffer);

        return buffer;
    }
}

pub fn addPipeline(comptime ctx: ?*u8pack.CTX, comptime name: []const u8, isMesh: bool) !Pass.Pipeline {
    if (ctx != null) return undefined;

    const name_dupe = try allocator.allocator().dupe(u8, name);
    var name_str = u8pack.toStr(name);
    name_str.name = name_dupe;

    const pipeline = Pass.Pipeline{
        .name = name_str,
        .isMesh = isMesh,
    };

    try pipelines.put(name_str, pipeline);

    return pipeline;
}

pub fn createPass(comptime ctx: ?*u8pack.CTX, comptime name: []const u8) !void {
    if (ctx != null) {
        ctx.?.passes = ctx.?.passes ++ .{name};
    } else {
        const name_dupe = try allocator.allocator().dupe(u8, name);
        var name_str = u8pack.toStr(name);
        name_str.name = name_dupe;

        const pass = Pass.Pass{
            .name = name_str,
            .buffers = &.{},
            .pipeline = null,
            .pushConstant = &.{},
        };

        try passMap.put(name_str, pass);
    }
}

pub fn addBufferToPass(comptime ctx: ?*u8pack.CTX, comptime passName: []const u8, buffer: Pass.Buffer) !void {
    if (ctx != null) return;

    const pass = passMap.getPtr(u8pack.toStr(passName)) orelse return error.PassNotFound;

    const buf = buffers.get(buffer.name) orelse return error.BufferNotFound;

    const index = pass.buffers.len;
    if (pass.buffers.len == 0) {
        pass.buffers = try allocator.allocator().alloc(Pass.Buffer, 1);
    } else {
        pass.buffers = try allocator.allocator().realloc(pass.buffers, pass.buffers.len + 1);
    }

    pass.buffers[index] = buf;
}

pub fn addPipelineToPass(comptime ctx: ?*u8pack.CTX, comptime passName: []const u8, pipeline: Pass.Pipeline) !void {
    if (ctx != null) return;

    const pass = passMap.getPtr(u8pack.toStr(passName)) orelse return error.PassNotFound;

    const pip = pipelines.get(pipeline.name) orelse return error.PipelineNotFound;

    if (pass.pipeline == null) {
        pass.pipeline = try allocator.allocator().alloc(Pass.Pipeline, 1);
    } else {
        pass.pipeline = try allocator.allocator().realloc(pass.pipeline.?, pass.pipeline.?.len + 1);
    }
    pass.pipeline.?[pass.pipeline.?.len - 1] = pip;
}

pub fn addVTableToPass(comptime ctx: ?*u8pack.CTX, comptime passName: []const u8, vtable: *const Pass.VTable) !void {
    if (ctx != null) return;

    const pass = passMap.getPtr(u8pack.toStr(passName)) orelse return error.PassNotFound;

    pass.vtable = vtable;
}

pub fn setPushConstant(comptime ctx: ?*u8pack.CTX, comptime passName: []const u8, stage: vk.VkShaderStageFlags, size: u16) !void {
    if (ctx != null) return;

    const pass = passMap.getPtr(u8pack.toStr(passName)) orelse return error.PassNotFound;

    if (pass.pushConstant.len == 0) {
        pass.pushConstant = try allocator.allocator().alloc(Pass.PushConstantPack, 1);
    } else {
        pass.pushConstant = try allocator.allocator().realloc(pass.pushConstant, pass.pushConstant.len + 1);
    }
    pass.pushConstant[pass.pushConstant.len - 1] = .{
        .stageFlag = stage,
        .size = size,
        .offset = 0,
    };
}
pub fn appendPass(comptime ctx: ?*u8pack.CTX, comptime passName: []const u8) !void {
    if (ctx != null) return;

    const pass = passMap.get(u8pack.toStr(passName)) orelse return error.PassNotFound;

    try passArray.append(pass);
}

pub fn getPassCount() usize {
    return passArray.items.len;
}

pub fn getPass(index: usize) Pass.Pass {
    return passArray.items[index];
}

pub fn addUbo(comptime ctx: ?*u8pack.CTX, comptime name: []const u8, size: u64, slot: Pass.uboSlot) !void {
    if (ctx != null) {
        ctx.?.ubos = ctx.?.ubos ++ .{name};
        return;
    }

    const str = u8pack.toStr(name);
    const gop = try uboMap.getOrPut(str);

    if (gop.found_existing) return;

    gop.value_ptr.* = .{
        .name = str,
        .size = mstd.Math.round(minUniformBufferOffsetAlignment, size),
        .slot = slot,
    };
}

pub fn createUboBuffer(comptime ctx: ?*u8pack.CTX) !void {
    if (ctx != null) {
        _ = try createBuffer(ctx, "ubo_ui", 0, 0, .uniform, false, null);
        _ = try createBuffer(ctx, "ubo_2d", 0, 0, .uniform, false, null);
        _ = try createBuffer(ctx, "ubo_3d", 0, 0, .uniform, false, null);
    } else {
        var totalLen_ui: u64 = 0;
        var totalLen_2d: u64 = 0;
        var totalLen_3d: u64 = 0;

        var it = uboMap.iterator();
        while (it.next()) |e| {
            std.log.debug("{s} ({d})", .{ e.key_ptr.name, e.key_ptr.id });
            switch (e.value_ptr.slot) {
                .ui => {
                    totalLen_ui += e.value_ptr.size;
                    ubo_ui_count += 1;
                },
                .@"2d" => {
                    totalLen_2d += e.value_ptr.size;
                    ubo_2d_count += 1;
                },
                .@"3d" => {
                    totalLen_3d += e.value_ptr.size;
                    ubo_3d_count += 1;
                },
            }
        }

        _ = try createBuffer(ctx, "ubo_ui", totalLen_ui, 0, .uniform, false, null);
        _ = try createBuffer(ctx, "ubo_2d", totalLen_2d, 0, .uniform, false, null);
        _ = try createBuffer(ctx, "ubo_3d", totalLen_3d, 0, .uniform, false, null);
    }
}

pub fn iterateUbos() u8pack.HashMap(Pass.UBO).Iterator {
    return uboMap.iterator();
}

pub fn getUboCounts() [3]u32 {
    return [3]u32{ ubo_ui_count, ubo_2d_count, ubo_3d_count };
}

pub fn getUboBuffers() [3]Pass.Buffer {
    return [3]Pass.Buffer{
        buffers.get(u8pack.toStr("ubo_ui")) orelse std.debug.panic("incorrect position to call this function", .{}),
        buffers.get(u8pack.toStr("ubo_2d")) orelse std.debug.panic("incorrect position to call this function", .{}),
        buffers.get(u8pack.toStr("ubo_3d")) orelse std.debug.panic("incorrect position to call this function", .{}),
    };
}
