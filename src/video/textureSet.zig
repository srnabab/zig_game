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

const Self = @This();

pub const Texture = struct {
    ID: u32 = std.math.maxInt(u32),

    layouts: []vk.VkImageLayout,

    source_width: u32,
    source_height: u32,
    format: vk.VkFormat,

    image: VkStruct.Image,
    imageView: vk.VkImageView,

    pub fn changeTextureLayout(self: *Texture, baseLayer: u32, layerCount: u32, dstLayout: vk.VkImageLayout) void {
        const zone = tracy.initZone(@src(), .{ .name = "change texture layout" });
        defer zone.deinit();

        mutex.lock();
        defer mutex.unlock();

        for (self.layouts[baseLayer .. baseLayer + layerCount]) |*value| {
            value.* = dstLayout;
        }
    }
    // pDescriptorSet: []vk.VkDescriptorSet,
    // pShadowDescriptorSet: []vk.VkDescriptorSet,

    // offsetSize: u32,
    // refCount: u32,
    // offsets: []struct {
    //     offset: u32,
    //     count: u32,
    // },
};

// const memType = std.heap.MemoryPoolExtra(Node, .{ .alignment = @alignOf(Node) });
// var mem: memType = undefined;
// var AutoIncrecemetnID = Atomic.Value(u32).init(0);
var mutex: Mutex = .{};

memory: std.heap.MemoryPoolExtra(Texture, .{}),
map: std.hash_map.AutoHashMap(u32, *Texture),
layoutMemory: MemoryPool(vk.VkImageLayout),
// pub var textureSet: HashMapType = undefined;

pub fn init(allocator: std.mem.Allocator) Self {
    const zone = tracy.initZone(@src(), .{ .name = "init texture set" });
    defer zone.deinit();

    // std.log.debug("texture set init", .{});
    return .{
        .map = .init(allocator),
        .memory = .init(allocator),
        .layoutMemory = .init(allocator),
    };
}

pub fn deinit(self: *Self) void {
    const zone = tracy.initZone(@src(), .{ .name = "texture set deinit" });
    defer zone.deinit();

    global.vulkan.waitDevice() catch |err| {
        std.log.err("wait device error {s}\n", .{@errorName(err)});
    };

    // std.log.debug("texture deinit", .{});
    var itt = self.map.valueIterator();
    while (itt.next()) |texture| {
        global.vulkan.destroyImage(texture.*.image);
    }

    self.map.deinit();
    self.memory.deinit();
    self.layoutMemory.deinit();
}

pub fn createImageTexture(self: *Self, fileID: u32) !*Texture {
    const zone = tracy.initZone(@src(), .{ .name = "create image texutre from file" });
    defer zone.deinit();

    var texture: *Texture = undefined;
    var stagingBuffer: VkStruct.Buffer = undefined;

    const ID = fileID;

    if (self.map.get(ID)) |value| {
        return value;
    }

    var imgWidth: u32 = 0;
    var imgHeight: u32 = 0;
    var channel: u32 = 0;
    {
        mutex.lock();
        defer mutex.unlock();

        const img = try file.getImageLoadParam(@intCast(fileID));
        errdefer img.file.close();

        const imgStat = try img.file.stat();
        const fileMem = try global.gpa.alloc(u8, imgStat.size);
        errdefer global.gpa.free(fileMem);
        _ = try img.file.readAll(fileMem);
        img.file.close();

        const imageMem = stb_image.stbi_load_from_memory(
            @ptrCast(fileMem.ptr),
            @intCast(fileMem.len),
            @ptrCast(&imgWidth),
            @ptrCast(&imgHeight),
            @ptrCast(&channel),
            stb_image.STBI_rgb_alpha,
        );
        global.gpa.free(fileMem);
        const pixelSize: u64 = @intCast(@sizeOf(u8) * imgWidth * imgHeight * channel);

        stagingBuffer = try global.vulkan.createStagingBuffer(pixelSize);
        @memcpy(@as([*c]u8, @ptrCast(stagingBuffer.info.pMappedData.?)), imageMem[0..pixelSize]);
        const image = try global.vulkan.createImage2D(imgWidth, imgHeight, img.format, img.tiling, img.usage);

        texture = try self.memory.create();
        texture.* = .{
            .image = image,
            .ID = ID,
            .source_width = imgWidth,
            .source_height = imgHeight,
            .layouts = try self.layoutMemory.create(1),
            .imageView = null,
            .format = img.format,
        };
        try self.map.put(ID, texture);
        for (0..texture.layouts.len) |i| {
            texture.layouts[i] = vk.VK_IMAGE_LAYOUT_UNDEFINED;
        }
    }

    try global.graphic.addCommand(
        .copyBufferToImage,
        .{ .copyBufferToImage = .{
            .pTexture = texture,
            .width = texture.source_width,
            .height = texture.source_height,
            .buffer = stagingBuffer,
        } },
    );

    return texture;
}
