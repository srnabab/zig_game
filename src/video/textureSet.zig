const std = @import("std");
const Mutex = std.Thread.Mutex;
const Atomic = std.atomic;
const file = @import("fileSystem");
const stb_image = @import("stb_image").image;
const vk = @import("vulkan").vulkan;
const VkStruct = @import("video");
const global = @import("global");
const MemoryPool = @import("memoryPool").MemoryPoolSlice;

const Self = @This();

const Texture = struct {
    ID: u32 = std.math.maxInt(u32),

    layoutCount: u32,
    layouts: []vk.VkImageLayout,

    source_width: u32,
    source_height: u32,
    format: vk.VkFormat,

    image: VkStruct.Image,
    imageView: vk.VkImageView,

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
var AutoIncrecemetnID = Atomic.Value(u32).init(0);

memory: std.heap.MemoryPoolExtra(Texture, .{}),
map: std.hash_map.AutoHashMap(u32, Texture),
layoutMemory: MemoryPool(vk.VkImageLayout),
// var mutex = Mutex{};
// pub var textureSet: HashMapType = undefined;

pub fn init(allocator: std.mem.Allocator) Self {
    return .{
        .map = .init(allocator),
        .memory = .init(allocator),
        .layoutMemory = .init(allocator),
    };
}

pub fn createImageTexture(self: *Self, fileID: u32) !*Texture {
    const ID = AutoIncrecemetnID.fetchAdd(1, .seq_cst);

    var imgWidth: i32 = 0;
    var imgHeight: i32 = 0;
    var channel: i32 = 0;

    const img = try file.getImageLoadParam(fileID);
    errdefer img.file.close();

    const imgStat = try img.file.stat();
    const fileMem = try global.gpa.alloc(u8, imgStat.size);
    errdefer global.gpa.free(fileMem);
    _ = try img.file.readAll(fileMem);
    img.file.close();

    const imageMem = stb_image.stbi_load_from_memory(
        @ptrCast(fileMem.ptr),
        fileMem.len,
        @ptrCast(&imgWidth),
        @ptrCast(&imgHeight),
        @ptrCast(&channel),
        stb_image.STBI_rgb_alpha,
    );
    global.gpa.free(fileMem);

    const stagingBuffer = try global.vulkan.createStagingBuffer(imgStat.size);
    @memcpy(stagingBuffer.info.pMappedData, imageMem);
    const image = try global.vulkan.createImage2D(imgWidth, imgHeight, img.format, img.tiling, img.usage);

    const texture = try self.memory.create();
    texture.* = .{
        .image = image,
        .ID = ID,
        .source_width = imgWidth,
        .source_height = imgHeight,
        .layoutCount = 1,
        .layouts = try self.layoutMemory.create(1),
        .imageView = null,
        .format = img.format,
    };
    for (0..texture.layouts.len) |i| {
        texture.layouts[i] = vk.VK_IMAGE_LAYOUT_UNDEFINED;
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

    // global.vulkan.destroyBuffer(stagingBuffer);
}

pub fn deinit(self: *Self) void {
    self.map.deinit();
    self.memory.deinit();
}
