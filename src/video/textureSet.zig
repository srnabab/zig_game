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
const Handles = @import("handle");
const Handle = Handles.Handle;
const processRender = @import("processRender");
const OneTimeCommand = processRender.oneTimeCommand;
const hash = std.hash;

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
    // usage: processRender.drawC.TextureUsage,

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

        self.image.queueIndex = queueType;
    }

    pub fn changeTextureUsage(self: *Texture, usage: processRender.drawC.TextureUsage) void {
        const zone = tracy.initZone(@src(), .{ .name = "change texture usage" });
        defer zone.deinit();

        self.usage = usage;
    }
};

var mutex: Mutex = .{};

allocator: std.mem.Allocator,

array: std.array_list.Managed(Texture),

offsetsPool: objectPool(Offsets),
offsetRange: std.array_list.Managed(Offsets),

map: std.hash_map.AutoHashMap(u32, Texture_t),
layoutMemory: MemoryPool(vk.VkImageLayout),
descriptorSetIndices: std.AutoHashMap(u32, u32),

tempTextureRecord: *Texture = undefined,

handles: *global.HandlesType,

descriptorSetIndex: u32 = 0,
// vulkan: *VkStruct,
// graphic: *OneTimeCommand,

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
        // .vulkan = vulkan,
        // .graphic = graphic,
    };
}

pub fn deinit(self: *Self, vulkan: *VkStruct) void {
    const zone = tracy.initZone(@src(), .{ .name = "texture set deinit" });
    defer zone.deinit();

    vulkan.waitDevice() catch |err| {
        std.log.err("wait device error {s}\n", .{@errorName(err)});
    };

    // std.log.debug("texture deinit", .{});
    for (self.array.items) |texture| {
        vulkan.destroyImage(texture.image);
        vulkan.destroyImageView(texture.imageView);
    }

    std.log.debug("texture count {d}", .{self.array.capacity});

    self.map.deinit();
    self.offsetRange.deinit();
    self.offsetsPool.deinit();
    self.array.deinit();
    self.layoutMemory.deinit();
    self.descriptorSetIndices.deinit();
}

pub fn createImageTexture(self: *Self, fileID: u32, samplerType: VkStruct.Samplers.SamplerType, vulkan: *VkStruct, graphic: *OneTimeCommand) !Texture_t {
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
    var index: u32 = 0;
    {
        mutex.lock();
        defer mutex.unlock();

        const img = try file.getImageLoadParam(@intCast(fileID));
        defer img.file.close();

        const imgStat = try img.file.stat();
        const fileMem = try self.allocator.alloc(u8, imgStat.size);
        defer self.allocator.free(fileMem);
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

        stagingBuffer = try vulkan.createStagingBuffer(pixelSize);
        errdefer vulkan.destroyBuffer(stagingBuffer);

        vulkan.buffers.copyDataToMapped(stagingBuffer, u8, imageMem[0..pixelSize]);
        // @memcpy(@as([*c]u8, @ptrCast(stagingBuffer.pMappedData.?)), imageMem[0..pixelSize]);

        const image = try vulkan.createImage2D(imgWidth, imgHeight, img.format, img.tiling, img.usage);
        errdefer vulkan.destroyImage(image);

        // texture = try self.memory.create();

        // lock
        texture = try self.array.addOne();
        index = @intCast(self.array.items.len - 1);

        if (self.offsetRange.capacity < self.array.items.len) {
            try self.offsetRange.ensureTotalCapacity(self.array.items.len);
            self.offsetRange.expandToCapacity();
        }
        self.offsetRange.items[self.array.items.len - 1] = .{
            .offset = 0,
            .count = 0,
        };
        // unlock

        // errdefer self.array.giveBack(texture);

        texture.* = .{
            .image = image,
            .ID = ID,
            .source_width = imgWidth,
            .source_height = imgHeight,
            .layouts = try self.layoutMemory.create(1),
            .imageView = null,
            .format = img.format,
            // .usage = .shader,
        };
        for (0..texture.layouts.len) |i| {
            texture.layouts[i] = vk.VK_IMAGE_LAYOUT_UNDEFINED;
        }

        texture_t = self.handles.createHandle(index);

        try self.map.put(ID, texture_t);
    }
    // errdefer self.array.giveBack(texture);

    try graphic.addCommand(
        .copyBufferToImage,
        .{ .copyBufferToImage = .{
            .pTexture = texture_t,
            .pTextureSet = self,
            .dstImage = texture.image.vkImage,
            .width = texture.source_width,
            .height = texture.source_height,
            .buffer = stagingBuffer,
        } },
    );

    texture.imageView = try vulkan.createImageView2D(texture.image.vkImage, texture.format);

    const dstArrayElement = try self.acquireDescriptorSetIndex(ID);
    try vulkan.addWriteDescriptorSetImage(
        dstArrayElement,
        texture.imageView,
        vulkan.samplers.getDefaultSampler(samplerType),
        vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
        vulkan.globalTextureDescriptorSet,
        0,
        vk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
    );

    return texture_t;
}

pub fn create2DTexture(
    self: *Self,
    vulkan: *VkStruct,
    width: u32,
    height: u32,
    format: vk.VkFormat,
    tiling: vk.VkImageTiling,
    usage: vk.VkImageUsageFlags,
    name: []const u8,
) !Texture_t {
    mutex.lock();
    defer mutex.unlock();

    const image = try vulkan.createImage2D(width, height, format, tiling, usage);
    errdefer vulkan.destroyImage(image);

    // lock
    var texture = try self.array.addOne();
    const index: u32 = @intCast(self.array.items.len - 1);
    std.log.debug("index {d}", .{index});
    // unlock

    const ID = hash.CityHash32.hash(name);

    texture.* = .{
        .image = image,
        .ID = ID,
        .source_width = width,
        .source_height = height,
        .layouts = try self.layoutMemory.create(1),
        .imageView = null,
        .format = format,
        // .usage = .shader,
    };
    for (0..texture.layouts.len) |i| {
        texture.layouts[i] = vk.VK_IMAGE_LAYOUT_UNDEFINED;
    }

    const texture_t = self.handles.createHandle(index);

    try self.map.put(ID, texture_t);

    texture.imageView = try vulkan.createImageView2D(texture.image.vkImage, texture.format);

    return texture_t;
}

pub fn createTexturePackVkImage(
    self: *Self,
    width: u32,
    height: u32,
    format: vk.VkFormat,
    vkImage: vk.VkImage,
    vkImageView: vk.VkImageView,
    name: []const u8,
) !Texture_t {
    mutex.lock();
    defer mutex.unlock();

    var texture = try self.array.addOne();
    const index: u32 = @intCast(self.array.items.len - 1);

    const ID = hash.CityHash32.hash(name);

    texture.* = .{
        .image = .{
            .vkImage = vkImage,
            .allocation = null,
            .queueIndex = .init,
        },
        .ID = ID,
        .source_width = width,
        .source_height = height,
        .layouts = try self.layoutMemory.create(1),
        .imageView = vkImageView,
        .format = format,
        // .usage = .shader,
    };
    for (0..texture.layouts.len) |i| {
        texture.layouts[i] = vk.VK_IMAGE_LAYOUT_UNDEFINED;
    }

    const texture_t = self.handles.createHandle(index);

    try self.map.put(ID, texture_t);

    return texture_t;
}

fn acquireDescriptorSetIndex(self: *Self, ID: u32) !u32 {
    mutex.lock();
    defer mutex.unlock();

    try self.descriptorSetIndices.put(ID, self.descriptorSetIndex);
    defer self.descriptorSetIndex += 1;

    return self.descriptorSetIndex;
}

pub fn getDescriptorSetIndex(self: *Self, texture: Texture_t) !u32 {
    const ID = self.getTextureCotent(texture).ID;

    mutex.lock();
    defer mutex.unlock();

    const index = self.descriptorSetIndices.get(ID) orelse return error.not_found;

    return index;
}

pub fn createImageTextureEnsureWithErrorImage(self: *Self, fileID: u32, samplerType: VkStruct.Samplers.SamplerType, vulkan: *VkStruct, graphic: *OneTimeCommand) Texture_t {
    return self.createImageTexture(fileID, samplerType, vulkan, graphic) catch |err| {
        std.log.err("create image {d} texture error {s} {d}", .{ fileID, @errorName(err), @sizeOf(Texture) });
        return self.createImageTexture(comptime file.comptimeGetID("non_exist.png"), .pixel2d, vulkan, graphic) catch unreachable;
    };
}

pub fn getTexture(self: *Self, textureID: u32) ?Texture_t {
    mutex.lock();
    defer mutex.unlock();

    const index = self.map.get(textureID);
    if (index) |_| {
        return index.?;
    }

    return null;
}

pub fn getTextureCotent(self: *Self, texture: Texture_t) Texture {
    mutex.lock();
    defer mutex.unlock();

    const index: u32 = Handles.getIndex(texture);
    return self.array.items[index];
}

pub fn offsetsAdd(self: *Self, texture: Texture_t, offset: u32) !void {
    const zone = tracy.initZone(@src(), .{ .name = "texture offsets add" });
    defer zone.deinit();

    const index: u32 = ix: {
        const ptr: *u32 = @ptrCast(@alignCast(texture));

        break :ix ptr.*;
    };

    const offsetRange = self.offsetRange.items[index];
    if (offsetRange.count > 0 and self.offsetsPool.items[offsetRange.offset..][offsetRange.count - 1].offset + self.offsetsPool.items[offsetRange.offset..][offsetRange.count - 1].count * global.vertexCount == offset) {
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

pub fn getTextureOffsets(self: *Self, texture: Texture_t) ![]Offsets {
    const zone = tracy.initZone(@src(), .{ .name = "texture offsets get" });
    defer zone.deinit();

    mutex.lock();
    defer mutex.unlock();

    const index = Handles.getIndex(texture);

    return self.offsetsPool.items[self.offsetRange.items[index].offset..][0..self.offsetRange.items[index].count];
}

pub fn changeTextureLayout(self: *Self, texture: Texture_t, baseLayer: u32, layerCount: u32, layout: vk.VkImageLayout) void {
    mutex.lock();
    defer mutex.unlock();

    const index = Handles.getIndex(texture);
    const tex = &self.array.items[index];

    tex.changeTextureLayout(baseLayer, layerCount, layout);
}

pub fn getCurrentLayouts(self: *Self, texture: Texture_t) []vk.VkImageLayout {
    const tex = self.getTextureCotent(texture);

    return tex.layouts;
}
pub fn changeTextureQueue(self: *Self, texture: Texture_t, queueType: VkStruct.CommandPoolType) void {
    mutex.lock();
    defer mutex.unlock();

    const index = Handles.getIndex(texture);
    const tex = &self.array.items[index];

    tex.changeTextureQueue(queueType);
}

pub fn getVkImage(self: *Self, texture: Texture_t) vk.VkImage {
    const tex = self.getTextureCotent(texture);

    return tex.image.vkImage;
}

pub fn getVkImageView(self: *Self, texture: Texture_t) vk.VkImageView {
    const tex = self.getTextureCotent(texture);

    return tex.imageView;
}

pub fn getImageQueueType(self: *Self, texture: Texture_t) VkStruct.CommandPoolType {
    const tex = self.getTextureCotent(texture);

    return tex.image.queueIndex;
}

pub fn updateTexture(self: *Self, args: anytype, texture: Texture_t) void {
    const zone = tracy.initZone(@src(), .{ .name = "update texture" });
    defer zone.deinit();

    const args_type = @TypeOf(args);
    const args_info = @typeInfo(args_type);

    // std.log.debug("{s}", .{@typeName(args_type)});

    if (args_info != .@"struct") {
        @compileError("argument must be a struct");
    }

    mutex.lock();
    defer mutex.unlock();

    const index = Handles.getIndex(texture);
    const temp = &self.array.items[index];

    inline for (args_info.@"struct".fields) |field| {
        if (!@hasField(Texture, field.name)) {
            @compileError("struct has no field named '" ++ field.name ++ "'");
        }

        @field(temp, field.name) = @field(args, field.name);
    }
}

pub fn logImagePtr(self: *Self) void {
    for (self.array.items) |value| {
        std.log.debug("{*} {*} {d}", .{ value.image.vkImage, value.imageView, value.ID });
    }
}
