const std = @import("std");
const Mutex = std.Io.Mutex;

const errorProcess = @import("error");

const vk = @import("vulkan");
const checkVkResult = @import("resultToError").checkVkResult;

const tracy = @import("tracy");

const types = @import("types");

pub const VkQueueFamily = types.VkQueueFamily;
pub const VkTheadQueue = struct { queue: vk.VkQueue = null, mutex: Mutex = .init };

pub fn setQueueFamilies(physicalDevice: vk.VkPhysicalDevice, allocator: std.mem.Allocator, surface: vk.VkSurfaceKHR) !struct {
    graphic: VkQueueFamily = .{},
    compute: VkQueueFamily = .{},
    transfer: VkQueueFamily = .{},
} {
    const zone = tracy.initZone(@src(), .{ .name = "set queue families" });
    defer zone.deinit();

    var queueFamilyCount: u32 = 0;
    vk.vkGetPhysicalDeviceQueueFamilyProperties2(physicalDevice, &queueFamilyCount, null);

    const queueFamilys: []vk.VkQueueFamilyProperties2 = try allocator.alloc(vk.VkQueueFamilyProperties2, queueFamilyCount);
    defer allocator.free(queueFamilys);

    for (queueFamilys) |*v| {
        v.* = .{
            .sType = vk.VK_STRUCTURE_TYPE_QUEUE_FAMILY_PROPERTIES_2,
            .pNext = null,
        };
    }

    vk.vkGetPhysicalDeviceQueueFamilyProperties2(physicalDevice, &queueFamilyCount, @ptrCast(queueFamilys.ptr));

    var graphicQueue: VkQueueFamily = .{};
    var computeQueue: VkQueueFamily = .{};
    var transferQueue: VkQueueFamily = .{};

    var graphic: bool = false;
    var compute: bool = false;
    var transfer: bool = false;
    var present: bool = false;
    var sparse: bool = false;
    var encode: bool = false;
    var decode: bool = false;
    for (queueFamilys, 0..queueFamilyCount) |queueFamily2, i_usize| {
        const i: u32 = @truncate(i_usize);
        const i_i32 = @as(i32, @bitCast(i));
        const queueFamily = queueFamily2.queueFamilyProperties;
        graphic = false;
        transfer = false;
        present = false;
        compute = false;
        sparse = false;
        encode = false;
        decode = false;
        if ((queueFamily.queueFlags & vk.VK_QUEUE_GRAPHICS_BIT) != 0) {
            graphic = true;
        }
        if ((queueFamily.queueFlags & vk.VK_QUEUE_COMPUTE_BIT) != 0) {
            compute = true;
        }
        if ((queueFamily.queueFlags & vk.VK_QUEUE_TRANSFER_BIT) != 0) {
            transfer = true;
        }
        if ((queueFamily.queueFlags & vk.VK_QUEUE_SPARSE_BINDING_BIT) != 0) {
            sparse = true;
        }
        if ((queueFamily.queueFlags & vk.VK_QUEUE_VIDEO_ENCODE_BIT_KHR) != 0) {
            encode = true;
        }
        if ((queueFamily.queueFlags & vk.VK_QUEUE_VIDEO_DECODE_BIT_KHR) != 0) {
            decode = true;
        }
        var presentSupport: u32 = 0;
        try checkVkResult(vk.vkGetPhysicalDeviceSurfaceSupportKHR(physicalDevice, i, surface, @ptrCast(&presentSupport)));
        if (presentSupport == 1) {
            present = true;
        }

        if (graphic and present) {
            graphicQueue.familyIndice = i_i32;
            graphicQueue.queueCount = queueFamily.queueCount;
        }

        if (compute and !graphic) {
            computeQueue.familyIndice = i_i32;
            computeQueue.queueCount = queueFamily.queueCount;
        }

        if (transfer and !graphic and !compute and !decode and !encode) {
            transferQueue.familyIndice = i_i32;
            transferQueue.queueCount = queueFamily.queueCount;
        }
    }

    return .{
        .graphic = graphicQueue,
        .compute = computeQueue,
        .transfer = transferQueue,
    };
}

pub fn createQueues(
    graphicQueueFamily: *VkQueueFamily,
    computeQueueFamily: *VkQueueFamily,
    transferQueueFamily: *VkQueueFamily,
    graphicQueue: *VkTheadQueue,
    computeQueue: *VkTheadQueue,
    transferQueue: *VkTheadQueue,
    device: vk.VkDevice,
) void {
    const zone = tracy.initZone(@src(), .{ .name = "create queues" });
    defer zone.deinit();

    const families = [3]*VkQueueFamily{ graphicQueueFamily, computeQueueFamily, transferQueueFamily };
    const queuess = [3]*VkTheadQueue{ graphicQueue, computeQueue, transferQueue };
    for (families, queuess, 0..) |family, queues, i| {
        if (family.familyIndice != -1) {
            vk.vkGetDeviceQueue(
                device,
                @bitCast(family.familyIndice),
                @intCast(family.familyIndice),
                @ptrCast(&queues.queue),
            );
        } else {
            families[i].* = families[0].*;
            queuess[i].* = queuess[0].*;
        }
    }
}
