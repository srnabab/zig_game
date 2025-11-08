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
const stableArray = @import("stableArray").StableArray;
const objectPool = @import("objectPool").ObjectPool;

const Self = @This();

const Offsets = struct {
    offset: u32,
    count: u32,
};

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

        mutex.lock();
        defer mutex.unlock();

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
        };

        mutex.lock();
        defer mutex.unlock();

        self.image.queueIndex = queueIndex;
    }
};

var mutex: Mutex = .{};

allocator: std.mem.Allocator,

array: stableArray(Texture),

offsetsPool: objectPool(Offsets),
offsetRange: std.array_list.Managed(Offsets),

map: std.hash_map.AutoHashMap(u32, u32),
layoutMemory: MemoryPool(vk.VkImageLayout),
descriptorSetIndices: std.array_list.Managed(u32),

pub fn init(allocator: std.mem.Allocator) Self {
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
    };
}

pub fn deinit(self: *Self) void {
    const zone = tracy.initZone(@src(), .{ .name = "texture set deinit" });
    defer zone.deinit();

    global.vulkan.waitDevice() catch |err| {
        std.log.err("wait device error {s}\n", .{@errorName(err)});
    };

    // std.log.debug("texture deinit", .{});
    for (self.array.array.items) |texture| {
        global.vulkan.destroyImage(texture.image);
        global.vulkan.destroyImageView(texture.imageView);
    }

    std.log.debug("texture count {d}", .{self.array.array.capacity});

    self.map.deinit();
    self.offsetRange.deinit();
    self.offsetsPool.deinit();
    self.array.deinit();
    self.layoutMemory.deinit();
    self.descriptorSetIndices.deinit();
}

pub fn createImageTexture(self: *Self, fileID: u32, samplerType: VkStruct.SamplerType) !*Texture {
    const zone = tracy.initZone(@src(), .{ .name = "create image texutre from file" });
    defer zone.deinit();

    const ID = fileID;

    if (self.map.get(ID)) |value| {
        return self.array.get(value).?;
    }

    var texture: *Texture = undefined;
    var stagingBuffer: VkStruct.Buffer = undefined;
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

        @memcpy(@as([*c]u8, @ptrCast(stagingBuffer.info.pMappedData.?)), imageMem[0..pixelSize]);

        const image = try global.vulkan.createImage2D(imgWidth, imgHeight, img.format, img.tiling, img.usage);
        errdefer global.vulkan.destroyImage(image);

        // texture = try self.memory.create();

        texture = try self.array.add();

        if (self.offsetRange.capacity < self.array.array.items.len) {
            try self.offsetRange.ensureTotalCapacity(self.array.array.items.len);
            self.offsetRange.expandToCapacity();
        }
        self.offsetRange.items[self.array.array.items.len - 1] = .{
            .offset = 0,
            .count = 0,
        };
        // errdefer self.array.giveBack(texture);

        const index: u32 = @intCast(self.array.array.items.len - 1);

        texture.* = .{
            .image = image,
            .ID = ID,
            .source_width = imgWidth,
            .source_height = imgHeight,
            .layouts = try self.layoutMemory.create(1),
            .imageView = null,
            .format = img.format,
        };
        try self.map.put(ID, index);
        for (0..texture.layouts.len) |i| {
            texture.layouts[i] = vk.VK_IMAGE_LAYOUT_UNDEFINED;
        }
    }
    // errdefer self.array.giveBack(texture);

    try global.graphic.addCommand(
        .copyBufferToImage,
        .{ .copyBufferToImage = .{
            .pTexture = texture,
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
        global.vulkan.getDefaultSampler(samplerType),
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

pub fn createImageTextureEnsureWithErrorImage(self: *Self, fileID: u32, samplerType: VkStruct.SamplerType) *Texture {
    return self.createImageTexture(fileID, samplerType) catch |err| {
        std.log.err("create image {d} texture error {s} {d}", .{ fileID, @errorName(err), @sizeOf(Texture) });
        return self.createImageTexture(comptime file.comptimeGetID("non_exist.png"), .pixel2d) catch unreachable;
    };
}

pub fn getTexture(self: *Self, textureID: u32) ?*Texture {
    mutex.lock();
    defer mutex.unlock();

    const index = self.map.get(textureID);
    if (index) |_| {
        return self.array.get(index.?);
    }

    return null;
}

pub fn offsetsAdd(self: *Self, texture: *Texture, offset: u32) !void {
    const zone = tracy.initZone(@src(), .{ .name = "texture offsets add" });
    defer zone.deinit();

    const index = self.array.getIndex(texture);

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

pub fn giveBackTexture(self: *Self, texture: *Texture) void {
    self.array.giveBack(texture);
}
