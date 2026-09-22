const std = @import("std");
const Allocator = std.mem.Allocator;

const Texture_t = @import("textureSet").Texture_t;
const Buffer_t = @import("video").Buffer_t;
const Pipeline_t = @import("video").Pipeline_t;
const PushConstantPack = @import("processRender").drawC.PushConstantPack;
const Commands = @import("processRender").commands;
const ExternalCommands = @import("processRender").externalCommands;
const vk = @import("vulkan");

const VkStruct = @import("video");
const file = @import("fileSystem");
const TextureSet = @import("textureSet");

const renderFlow = @import("renderFlow");

const u8pack = @import("u8pack");
const Str = u8pack.Str;

pub const VTable = renderFlow.Pass.VTable;

pub const Pass = struct {
    name: Str = undefined,
    buffer: []Buffer_t = &.{},
    texture: []Texture_t = &.{},
    descriptorSet: []vk.VkDescriptorSet = &.{},
    pipeline: []Pipeline_t = &.{},
    pushConstant: []PushConstantPack = &.{},
    userdata: ?*anyopaque = null,

    enabled: u8 = 0,

    vtable: *const VTable,

    pub fn init(
        self: *Pass,
        vulkan: *VkStruct,
        commands: *ExternalCommands,
        gpa: std.mem.Allocator,
    ) !void {
        try self.vtable.init(&self.userdata, self, vulkan, commands, gpa);
    }

    pub fn setPushConstants(self: *Pass, index: u32, mem: []u8, offset: u16) void {
        if (self.pushConstant.len == 0)
            std.debug.panic("setPushConstants called on pass without push constant", .{});
        const pack = &self.pushConstant[index];

        if (offset > pack.size)
            std.debug.panic("offset {d} > pushconstant size {d}", .{ offset, pack.size });

        const dst: []u8 = @as([*]u8, @ptrCast(@alignCast(pack.pValues)))[0..pack.size];
        const end = offset + @as(u16, @intCast(mem.len));

        @memcpy(dst[offset..end], mem);
    }

    pub fn addCommand(
        self: *Pass,
        vulkan: *VkStruct,
        textureSet: *TextureSet,
        commands: *Commands,
        gpa: std.mem.Allocator,
    ) !void {
        try self.vtable.addCommand(
            self.userdata,
            self,
            vulkan,
            textureSet,
            commands,
            gpa,
        );
    }

    /// this function is only used for tell dependency
    pub fn useTexture(self: *Pass, texture: Texture_t, gpa: std.mem.Allocator) !void {
        self.texture = try gpa.realloc(self.texture, self.texture.len + 1);
        self.texture[self.texture.len - 1] = texture;
    }

    pub fn clearTexture(self: *Pass, gpa: std.mem.Allocator) void {
        if (self.texture.len == 0) return;

        gpa.free(self.texture);
        self.texture = &.{};
    }

    pub fn enable(self: *Pass) void {
        self.enabled += 1;
    }

    pub fn disable(self: *Pass) void {
        self.enabled -= 1;
    }

    pub fn setUserdata(self: *Pass, userdata: *anyopaque) void {
        if (self.enabled == 0) self.userdata = userdata;
    }

    pub fn setDescriptorSets(self: *Pass, descriptorSets: []vk.VkDescriptorSet, gpa: std.mem.Allocator) !void {
        self.descriptorSet = try gpa.dupe(vk.VkDescriptorSet, descriptorSets);
    }
};

const Self = @This();

passMap: u8pack.HashMap(*Pass),
passes: []Pass,

pub fn initFromRenderFlow(io: std.Io, gpa: std.mem.Allocator, vulkan: *VkStruct, sqlite: ?*file.sqlite.sqlite3) !Self {
    const passCount = renderFlow.getPassCount();

    const passes = try gpa.alloc(Pass, passCount);

    var bufferMap = u8pack.HashMap(Buffer_t).init(gpa);
    defer bufferMap.deinit();

    var pipelineMap = std.StringHashMap(Pipeline_t).init(gpa);
    defer pipelineMap.deinit();

    var passMap = u8pack.HashMap(*Pass).init(gpa);

    var skipCount: usize = 0;
    for (0..passCount) |i| {
        const pass = renderFlow.getPass(i);
        // std.log.debug("pass {s}", .{pass.name});

        if (pass.pipeline == null) {
            skipCount += 1;
            continue;
        }

        const passedIndex = i - skipCount;

        passes[passedIndex] = .{ .vtable = pass.vtable };

        passes[passedIndex].pipeline = try gpa.alloc(Pipeline_t, pass.pipeline.?.len);
        for (pass.pipeline.?, 0..) |p, k| {
            passes[passedIndex].pipeline[k] = try vulkan.readPipelineFileAndAdd(
                io,
                file.getID(p.name.name),
                sqlite,
                p.isMesh,
            );
        }

        passes[passedIndex].name = try u8pack.dupe(gpa, pass.name);
        passes[passedIndex].pushConstant = try gpa.alloc(PushConstantPack, pass.pushConstant.len);
        for (pass.pushConstant, 0..) |pc, k| {
            passes[passedIndex].pushConstant[k] = pc;
            const mem = try gpa.alignedAlloc(u8, .@"8", pc.size);
            passes[passedIndex].pushConstant[k].pValues = @ptrCast(mem.ptr);
        }

        if (pass.buffers.len > 0) {
            passes[passedIndex].buffer = try gpa.alloc(Buffer_t, pass.buffers.len);
            for (pass.buffers, 0..) |buffer, j| {
                const res = bufferMap.get(buffer.name);

                if (res == null) {
                    var buffer_t: Buffer_t = undefined;

                    if (buffer.parentName) |p| {
                        if (bufferMap.get(p)) |parent| {
                            buffer_t = try vulkan.createVirtualBlockBuffer(
                                0,
                                buffer.initSize,
                                parent,
                                buffer.offset,
                                buffer.stride,
                                buffer.name,
                            );
                        } else {
                            return error.VirtualBlockWithoutParent;
                        }
                    } else {
                        buffer_t = try vulkan.createBufferByUsage(
                            buffer.initSize,
                            buffer.stride,
                            buffer.usage,
                            true,
                            buffer.name,
                        );
                    }

                    try bufferMap.put(buffer.name, buffer_t);

                    passes[passedIndex].buffer[j] = buffer_t;
                } else {
                    passes[passedIndex].buffer[j] = res.?;
                }
            }
        }

        passes[passedIndex].enabled = 0;

        try passMap.put(passes[passedIndex].name, &passes[passedIndex]);
    }
    const actualPassCount = passCount - skipCount;

    for (0..passCount) |i| {
        const pass = renderFlow.getPass(i);

        if (pass.pipeline == null) {
            skipCount += 1;
            continue;
        }
    }

    const uboBuffers = renderFlow.getUboBuffers();
    for (0..3) |i| {
        if (uboBuffers[i].initSize == 0) continue;

        _ = try vulkan.createBufferByUsage(
            uboBuffers[i].initSize,
            uboBuffers[i].stride,
            uboBuffers[i].usage,
            false,
            uboBuffers[i].name,
        );
    }

    const uboCounts = renderFlow.getUboCounts();
    const totalCount = uboCounts[0] + uboCounts[1] + uboCounts[2];

    vulkan.uboDynamicOffsets = try gpa.alloc(u32, totalCount);

    var count: u32 = 0;

    var offset_ui: u32 = 0;
    var offset_2d: u32 = 0;
    var offset_3d: u32 = 0;

    var uboIt = renderFlow.iterateUbos();
    while (uboIt.next()) |e| {
        switch (e.value_ptr.slot) {
            .ui => {
                vulkan.uboDynamicOffsets[count] = offset_ui;
                offset_ui += @intCast(e.value_ptr.size);
                count += 1;
            },
            .@"2d" => {
                vulkan.uboDynamicOffsets[count] = offset_2d;
                offset_2d += @intCast(e.value_ptr.size);
                count += 1;
            },
            .@"3d" => {
                vulkan.uboDynamicOffsets[count] = offset_3d;
                offset_3d += @intCast(e.value_ptr.size);
                count += 1;
            },
        }
    }

    return .{
        .passes = try gpa.realloc(passes, actualPassCount),
        .passMap = passMap,
    };
}

pub fn deinit(self: *Self, gpa: std.mem.Allocator) void {
    self.passMap.deinit();

    for (self.passes) |pass| {
        u8pack.free(gpa, pass.name);
        gpa.free(pass.buffer);
        gpa.free(pass.texture);
        gpa.free(pass.pipeline);
        for (pass.pushConstant) |pc| {
            gpa.free(@as([*]u8, @ptrCast(@alignCast(pc.pValues)))[0..pc.size]);
        }
        gpa.free(pass.pushConstant);
        gpa.free(pass.descriptorSet);
    }
    gpa.free(self.passes);
}

pub fn disablePass(self: Self, pass: Str) void {
    self.passMap.getPtr(pass).?.*.enabled -= 1;
}

pub fn enablePass(self: Self, pass: Str) void {
    // std.log.debug("11111111111111111111", .{});
    self.passMap.getPtr(pass).?.*.enabled += 1;
}
