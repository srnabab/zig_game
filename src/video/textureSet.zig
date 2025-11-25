const std = @import("std");
const Mutex = std.Thread.Mutex;
const Atomic = std.atomic;
const file = @import("fileSystem");
const stb_image = @import("stb_image").image;
const vk = @import("vulkan").vulkan;
const VkStruct = @import("video");
const global = @import("global");
const MemoryPool = @import("memoryPool").MemoryPoolSlice;
const tracy = @import("tracy");
const objectPool = @import("objectPool").ObjectPool;
const Handle = @import("handle").Handle;

const Self = @This();

const Offsets = struct {
    offset: u32,
    count: u32,
};

pub const Texture_t = Handle;

pub const Texture = struct {
    ID: u32 = std.math.maxInt(u32),

    source_width: u32,
    source_height: u32,
    format: vk.VkFormat,

    layouts: []vk.VkImageLayout,

    image: VkStruct.Image,
    imageView: vk.VkImageView,

    // offsets: []Offsets = &.{},

    pub fn changeTextureLayout(self: *Texture, baseLayer: u32, layerCount: u32, dstLayout: vk.VkImageLayout) void {
        const zone = tracy.initZone(@src(), .{ .name = "change texture layout" });
        defer zone.deinit();

        for (self.layouts[baseLayer .. baseLayer + layerCount]) |*value| {
            value.* = dstLayout;
        }
    }

    pub fn changeTextureQueue(self: *Texture, queueType: VkStruct.CommandPoolType) void {
        const zone = tracy.initZone(@src(), .{ .name = "change texture queue type" });
        defer zone.deinit();

        const queueIndex = switch (queueType) {
            .graphic => global.vulkan.graphicQueueFamily.familyIndice,
            .transfer => global.vulkan.transferQueueFamily.familyIndice,
            .compute => global.vulkan.computeQueueFamily.familyIndice,
            else => unreachable,
        };

        self.image.queueIndex = queueIndex;
    }
};

var mutex: Mutex = .{};

allocator: std.mem.Allocator,

array: std.array_list.Managed(Texture),

offsetsPool: objectPool(Offsets),
offsetRange: std.array_list.Managed(Offsets),

map: std.hash_map.AutoHashMap(u32, Texture_t),
layoutMemory: MemoryPool(vk.VkImageLayout),
descriptorSetIndices: std.array_list.Managed(u32),

tempTextureRecord: *Texture = undefined,

handles: *global.HandlesType,

pub fn init(allocator: std.mem.Allocator, handles: *global.HandlesType) Self {
    const zone = tracy.initZone(@src(), .{ .name = "init texture set" });
    defer zone.deinit();

    // std.log.debug("texture set init", .{});
    return .{
        .allocator = allocator,
        .map = .init(allocator),
        .array = .init(allocator),
        .layoutMemory = .init(allocator),
        .descriptorSetIndices = .init(allocator),
        .offsetsPool = .init(allocator),
        .offsetRange = .init(allocator),
        .handles = handles,
    };
}

pub fn deinit(self: *Self) void {
    const zone = tracy.initZone(@src(), .{ .name = "texture set deinit" });
    defer zone.deinit();

    global.vulkan.waitDevice() catch |err| {
        std.log.err("wait device error {s}\n", .{@errorName(err)});
    };

    // std.log.debug("texture deinit", .{});
    for (self.array.items) |texture| {
        global.vulkan.destroyImage(texture.image);
        global.vulkan.destroyImageView(texture.imageView);
    }

    std.log.debug("texture count {d}", .{self.array.capacity});

    self.map.deinit();
    self.offsetRange.deinit();
    self.offsetsPool.deinit();
    self.array.deinit();
    self.layoutMemory.deinit();
    self.descriptorSetIndices.deinit();
}

pub fn createImageTexture(self: *Self, fileID: u32, samplerType: VkStruct.Samplers.SamplerType) !Texture_t {
    const zone = tracy.initZone(@src(), .{ .name = "create image texutre from file" });
    defer zone.deinit();

    const ID = fileID;

    if (self.map.get(ID)) |value| {
        return value;
    }

    var texture_t: Texture_t = undefined;
    var texture: *Texture = undefined;
    var stagingBuffer: VkStruct.Buffer_t = undefined;
    var imgWidth: u32 = 0;
    var imgHeight: u32 = 0;
    var channel: u32 = 0;
    {
        mutex.lock();
        defer mutex.unlock();

        const img = try file.getImageLoadParam(@intCast(fileID));
        defer img.file.close();

        const imgStat = try img.file.stat();
        const fileMem = try global.gpa.alloc(u8, imgStat.size);
        defer global.gpa.free(fileMem);
        _ = try img.file.readAll(fileMem);

        const imageMem = stb_image.stbi_load_from_memory(
            @ptrCast(fileMem.ptr),
            @intCast(fileMem.len),
            @ptrCast(&imgWidth),
            @ptrCast(&imgHeight),
            @ptrCast(&channel),
            stb_image.STBI_rgb_alpha,
        );
        const pixelSize: u64 = @intCast(@sizeOf(u8) * imgWidth * imgHeight * channel);

        stagingBuffer = try global.vulkan.createStagingBuffer(pixelSize);
        errdefer global.vulkan.destroyBuffer(stagingBuffer);

        global.vulkan.buffers.copyDataToMapped(stagingBuffer, u8, imageMem[0..pixelSize]);
        // @memcpy(@as([*c]u8, @ptrCast(stagingBuffer.pMappedData.?)), imageMem[0..pixelSize]);

        const image = try global.vulkan.createImage2D(imgWidth, imgHeight, img.format, img.tiling, img.usage);
        errdefer global.vulkan.destroyImage(image);

        // texture = try self.memory.create();

        texture = try self.array.addOne();

        if (self.offsetRange.capacity < self.array.items.len) {
            try self.offsetRange.ensureTotalCapacity(self.array.items.len);
            self.offsetRange.expandToCapacity();
        }
        self.offsetRange.items[self.array.items.len - 1] = .{
            .offset = 0,
            .count = 0,
        };
        // errdefer self.array.giveBack(texture);

        const index: u32 = @intCast(self.array.items.len - 1);

        texture.* = .{
            .image = image,
            .ID = ID,
            .source_width = imgWidth,
            .source_height = imgHeight,
            .layouts = try self.layoutMemory.create(1),
            .imageView = null,
            .format = img.format,
        };
        for (0..texture.layouts.len) |i| {
            texture.layouts[i] = vk.VK_IMAGE_LAYOUT_UNDEFINED;
        }

        texture_t = self.handles.createHandle(index);

        try self.map.put(ID, texture_t);
    }
    // errdefer self.array.giveBack(texture);

    try global.graphic.addCommand(
        .copyBufferToImage,
        .{ .copyBufferToImage = .{
            .pTexture = texture_t,
            .dstImage = texture.image.vkImage,
            .width = texture.source_width,
            .height = texture.source_height,
            .buffer = stagingBuffer,
        } },
    );

    texture.imageView = try global.vulkan.createImageView2D(texture.image.vkImage, texture.format);

    const dstArrayElement = try self.getDescriptorSetIndex(ID);
    try global.vulkan.addWriteDescriptorSetImage(
        dstArrayElement,
        texture.imageView,
        global.vulkan.samplers.getDefaultSampler(samplerType),
    );

    return texture;
}

fn getDescriptorSetIndex(self: *Self, ID: u32) !u32 {
    const zone = tracy.initZone(@src(), .{ .name = "get descriptor set index" });
    defer zone.deinit();

    const index = self.descriptorSetIndices.items.len;

    try self.descriptorSetIndices.append(ID);

    return @intCast(index);
}

pub fn createImageTextureEnsureWithErrorImage(self: *Self, fileID: u32, samplerType: VkStruct.Samplers.SamplerType) Texture_t {
    return self.createImageTexture(fileID, samplerType) catch |err| {
        std.log.err("create image {d} texture error {s} {d}", .{ fileID, @errorName(err), @sizeOf(Texture) });
        return self.createImageTexture(comptime file.comptimeGetID("non_exist.png"), .pixel2d) catch unreachable;
    };
}

fn getTexture(self: *Self, textureID: u32) ?Texture_t {
    mutex.lock();
    defer mutex.unlock();

    const index = self.map.get(textureID);
    if (index) |_| {
        return index.?;
    }

    return null;
}

fn getTextureCotent(self: *Self, texture: Texture_t) *Texture {
    mutex.lock();

    const index: u32 = ix: {
        const ptr: *u32 = @ptrCast(@alignCast(texture));

        break :ix ptr.*;
    };

    self.tempTextureRecord = &self.array.items[index];

    return self.tempTextureRecord;
}

pub fn releaseTextureContent(self: *Self, texture: *Texture) void {
    if (self.tempTextureRecord == texture) {
        mutex.unlock();
    }
}

pub fn offsetsAdd(self: *Self, texture: Texture_t, offset: u32) !void {
    const zone = tracy.initZone(@src(), .{ .name = "texture offsets add" });
    defer zone.deinit();

    const index: u32 = ix: {
        const ptr: *u32 = @ptrCast(@alignCast(texture));

        break :ix ptr.*;
    };

    const offsetRange = self.offsetRange.items[index];
    if (offsetRange.count > 0 and self.offsetsPool.items[offsetRange.offset..][offsetRange.count - 1].offset + self.offsetsPool[offsetRange.offset..][offsetRange.count - 1].count * global.vertexCount == offset) {
        self.offsetsPool.items[offsetRange.offset..][offsetRange.count - 1].count += 1;
    } else {
        if (offsetRange.count == 0) {
            const temp = try self.offsetsPool.alloc(1);
            self.offsetsPool.items[temp.offset..][0] = Offsets{ .offset = offset, .count = 1 };
            self.offsetRange.items[index] = .{ .offset = temp.offset, .count = temp.count };
        } else {
            const temp = try self.offsetsPool.realloc(.{
                .offset = offsetRange.offset,
                .count = offsetRange.count,
            }, offsetRange.count + 1);
            self.offsetsPool.items[temp.offset..][offsetRange.count] = Offsets{ .offset = offset, .count = 1 };
            self.offsetRange.items[index] = .{ .offset = temp.offset, .count = temp.count };
        }
    }
}

pub fn changeTextureLayout(self: *Self, texture: Texture_t, baseLayer: u32, layerCount: u32, layout: vk.VkImageLayout) void {
    const tex = self.getTextureCotent(texture);
    defer self.releaseTextureContent(tex);

    tex.changeTextureLayout(baseLayer, layerCount, layout);
}
pub fn getCurrentLayouts(self: *Self, texture: Texture_t) []vk.VkImageLayout {
    const tex = self.getTextureCotent(texture);
    defer self.releaseTextureContent(tex);

    return tex.layouts;
}
pub fn changeTextureQueue(self: *Self, texture: Texture_t, queueType: VkStruct.CommandPoolType) void {
    const tex = self.getTextureCotent(texture);
    defer self.releaseTextureContent(tex);

    tex.changeTextureQueue(queueType);
}
pub fn getVkImage(self: *Self, texture: Texture_t) vk.VkImage {
    const tex = self.getTextureCotent(texture);
    defer self.releaseTextureContent(tex);

    return tex.image.vkImage;
}
