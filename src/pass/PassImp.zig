const std = @import("std");

const Texture_t = @import("textureSet").Texture_t;
const Buffer_t = @import("video").Buffer_t;
const Pipeline_t = @import("video").Pipeline_t;
const PushConstantPack = @import("processRender").drawC.PushConstantPack;
const Commands = @import("processRender").commands;
const vk = @import("vulkan");

const VkStruct = @import("video");
const file = @import("fileSystem");
const TextureSet = @import("textureSet");

const renderFlow = @import("renderFlow");

pub const VTable = renderFlow.Pass.VTable;

pub const Pass = struct {
    name: []const u8 = undefined,
    buffer: []Buffer_t = &.{},
    texture: []Texture_t = &.{},
    descriptorSet: []vk.VkDescriptorSet = &.{},
    pipeline: Pipeline_t = undefined,
    pushConstant: PushConstantPack = .{},
    userdata: ?*anyopaque = null,

    enabled: bool = false,

    vtable: *const VTable,

    pub fn init(
        self: *Pass,
        userdata: ?*anyopaque,
        vulkan: *VkStruct,
        gpa: std.mem.Allocator,
    ) !void {
        try self.vtable.init(userdata, self, vulkan, gpa);
    }

    pub fn setPushConstants(self: *Pass, userdata: ?*anyopaque) void {
        self.vtable.setPushConstants(userdata, self.pushConstant.pValues);
    }

    pub fn addCommand(
        self: *Pass,
        userdata: ?*anyopaque,
        vulkan: *VkStruct,
        textureSet: *TextureSet,
        commands: *Commands,
        gpa: std.mem.Allocator,
    ) !void {
        try self.vtable.addCommand(
            userdata,
            self,
            vulkan,
            textureSet,
            commands,
            gpa,
        );
    }

    /// this function is only used for tell dependency, you should set draw data by yourself
    pub fn useTexture(self: *Pass, texture: Texture_t, gpa: std.mem.Allocator) !void {
        self.texture = try gpa.realloc(self.texture, self.texture.len + 1);
        self.texture[self.texture.len - 1] = texture;
    }

    pub fn clearTexture(self: *Pass, gpa: std.mem.Allocator) void {
        gpa.free(self.texture);
        self.texture = &.{};
    }

    pub fn enable(self: *Pass) void {
        self.enabled = true;
    }

    pub fn disable(self: *Pass) void {
        self.enabled = false;
    }

    pub fn setUserdata(self: *Pass, userdata: *anyopaque) void {
        if (!self.enabled) self.userdata = userdata;
    }

    pub fn setDescriptorSets(self: *Pass, descriptorSets: []vk.VkDescriptorSet, gpa: std.mem.Allocator) !void {
        self.descriptorSet = try gpa.dupe(vk.VkDescriptorSet, descriptorSets);
    }
};

const Self = @This();

passMap: std.StringHashMap(*Pass),
passes: []Pass,

pub fn initFromRenderFlow(io: std.Io, gpa: std.mem.Allocator, vulkan: *VkStruct, sqlite: ?*file.sqlite.sqlite3) !Self {
    const passCount = renderFlow.getPassCount();

    const passes = try gpa.alloc(Pass, passCount);

    var bufferMap = std.StringHashMap(Buffer_t).init(gpa);
    defer bufferMap.deinit();

    var pipelineMap = std.StringHashMap(Pipeline_t).init(gpa);
    defer pipelineMap.deinit();

    var passMap = std.StringHashMap(*Pass).init(gpa);

    var skipCount: usize = 0;
    for (0..passCount) |i| {
        const pass = renderFlow.getPass(i);

        if (pass.pipeline == null) {
            skipCount += 1;
            continue;
        }

        const passedIndex = i - skipCount;

        passes[passedIndex] = .{ .vtable = pass.vtable };

        passes[passedIndex].pipeline = try vulkan.readPipelineFileAndAdd(
            io,
            file.getID(pass.pipeline.?.name),
            sqlite,
            pass.pipeline.?.isMesh,
        );

        passes[passedIndex].name = try gpa.dupe(u8, pass.name);
        passes[passedIndex].pushConstant = pass.pushConstant;
        const mem = try gpa.alloc(u8, passes[passedIndex].pushConstant.size);
        passes[passedIndex].pushConstant.pValues = @ptrCast(mem.ptr);
        // std.log.debug("len {d}", .{mem.len});

        if (pass.buffers.len > 0) {
            passes[passedIndex].buffer = try gpa.alloc(Buffer_t, pass.buffers.len);
            for (pass.buffers, 0..) |buffer, j| {
                const res = bufferMap.get(buffer.name);

                if (res == null) {
                    const buffer_t = try vulkan.createBufferByUsage(
                        buffer.initSize,
                        buffer.stride,
                        buffer.usage,
                        true,
                    );

                    try bufferMap.put(buffer.name, buffer_t);

                    passes[passedIndex].buffer[j] = buffer_t;
                } else {
                    passes[passedIndex].buffer[j] = res.?;
                }
            }
        }

        passes[passedIndex].enabled = false;

        try passMap.put(passes[passedIndex].name, &passes[passedIndex]);
    }
    const actualPassCount = passCount - skipCount;

    return .{
        .passes = try gpa.realloc(passes, actualPassCount),
        .passMap = passMap,
    };
}

pub fn deinit(self: *Self, gpa: std.mem.Allocator) void {
    self.passMap.deinit();

    for (self.passes) |pass| {
        gpa.free(pass.name);
        gpa.free(pass.buffer);
        gpa.free(pass.texture);
        gpa.free(@as([*]u8, @ptrCast(@alignCast(pass.pushConstant.pValues)))[0..pass.pushConstant.size]);
        gpa.free(pass.descriptorSet);
    }
    gpa.free(self.passes);
}

pub fn disablePass(self: Self, pass: []const u8) void {
    self.passMap.getPtr(pass).?.*.enabled = false;
}

pub fn enablePass(self: Self, pass: []const u8) void {
    self.passMap.getPtr(pass).?.*.enabled = true;
}
