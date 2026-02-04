const std = @import("std");
const builtin = @import("builtin");
const global = @import("global");

const errorProcess = @import("error");

const vk = @import("vulkan").vulkan;

const tracy = @import("tracy");

const types = @import("types");

const VkResultToError = @import("resultToError");
const checkVkResult = VkResultToError.checkVkResult;
const vulkanType = VkResultToError.vulkanType;
const VkPhysicalType = vulkanType.VkPhysicalDeviceType;
pub const VkError = vulkanType.VkError;

const layerNeeded = layer: {
    break :layer switch (builtin.mode) {
        .Debug, .ReleaseSafe => [_][*c]const u8{"VK_LAYER_KHRONOS_validation"},
        .ReleaseFast, .ReleaseSmall => [_][*c]const u8{},
    };
};
const extensionNeeded = [_][*c]const u8{ "VK_KHR_surface", "VK_KHR_win32_surface" };
const deviceExtensionNeeded = [_][*c]const u8{
    "VK_KHR_swapchain",
    "VK_EXT_descriptor_indexing",
    "VK_KHR_maintenance3",
    "VK_KHR_synchronization2",
    "VK_KHR_timeline_semaphore",
    "VK_KHR_dynamic_rendering",
    "VK_EXT_extended_dynamic_state",
};
const featureNeed = [_][]const u8{
    "geometryShader",
    "independentBlend",
    "samplerAnisotropy",
    "logicOp",
    "depthClamp",
    "depthBiasClamp",
    "wideLines",
};
const featureIndexingNeed = [_][]const u8{
    "shaderUniformBufferArrayNonUniformIndexing",
    "shaderStorageBufferArrayNonUniformIndexing",
    "shaderSampledImageArrayNonUniformIndexing",
    "descriptorBindingUniformBufferUpdateAfterBind",
    "descriptorBindingSampledImageUpdateAfterBind",
    "descriptorBindingPartiallyBound",
    "runtimeDescriptorArray",
};
const featureTimelineSemaphoreNeed = [_][]const u8{"timelineSemaphore"};
const featureDynamicRenderingNeed = [_][]const u8{"dynamicRendering"};
const featureSynchronization2Need = [_][]const u8{"synchronization2"};

const VkQueueFamily = types.VkQueueFamily;

fn featureNeededCheck(comptime featureType: type, featurePack: anytype) bool {
    var count: u32 = 0;
    var len: u32 = 0;
    switch (featureType) {
        vk.VkPhysicalDeviceFeatures => {
            len = featureNeed.len;
            inline for (featureNeed) |feature| {
                count += @field(featurePack, feature);
            }
        },
        vk.VkPhysicalDeviceDescriptorIndexingFeatures => {
            len = featureIndexingNeed.len;
            inline for (featureIndexingNeed) |feature| {
                count += @field(featurePack, feature);
            }
        },
        vk.VkPhysicalDeviceTimelineSemaphoreFeatures => {
            len = featureTimelineSemaphoreNeed.len;
            inline for (featureTimelineSemaphoreNeed) |feature| {
                count += @field(featurePack, feature);
            }
        },
        vk.VkPhysicalDeviceDynamicRenderingFeatures => {
            len = featureDynamicRenderingNeed.len;
            inline for (featureDynamicRenderingNeed) |feature| {
                count += @field(featurePack, feature);
            }
        },
        vk.VkPhysicalDeviceSynchronization2Features => {
            len = featureSynchronization2Need.len;
            inline for (featureSynchronization2Need) |feature| {
                count += @field(featurePack, feature);
            }
        },
        else => {
            @compileError("unsupported");
        },
    }
    return count == len;
}

pub fn createInstance(pAllocCallBacks: [*c]vk.VkAllocationCallbacks, allocator: std.mem.Allocator) VkError!vk.VkInstance {
    const zone = tracy.initZone(@src(), .{ .name = "create instance" });
    defer zone.deinit();

    var appInfo = vk.VkApplicationInfo{
        .sType = vk.VK_STRUCTURE_TYPE_APPLICATION_INFO,
        .pNext = null,
        .pApplicationName = global.Name,
        .applicationVersion = vk.VK_MAKE_API_VERSION(
            0,
            global.AppVersionMajor,
            global.AppVersionMinor,
            global.AppVersionPatch,
        ),
        .pEngineName = global.EngineName,
        .engineVersion = vk.VK_MAKE_API_VERSION(
            0,
            global.EngineVersionMajor,
            global.EngineVersionMinor,
            global.EngineVersionPatch,
        ),
        .apiVersion = vk.VK_API_VERSION_1_4,
    };

    const layers = try chooseEnabledLayers(
        vk.VkLayerProperties,
        "layerName",
        layerNeeded[0..layerNeeded.len],
        null,
        allocator,
    );
    defer layers.deinit();
    const extension = try chooseEnabledLayers(
        vk.VkExtensionProperties,
        "extensionName",
        extensionNeeded[0..extensionNeeded.len],
        null,
        allocator,
    );
    defer extension.deinit();

    const createInfo = vk.VkInstanceCreateInfo{
        .sType = vk.VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
        .pNext = null,
        .flags = 0,
        .pApplicationInfo = &appInfo,
        .enabledLayerCount = @truncate(layers.items.len),
        .ppEnabledLayerNames = @ptrCast(layers.items.ptr),
        .enabledExtensionCount = @truncate(extension.items.len),
        .ppEnabledExtensionNames = @ptrCast(extension.items.ptr),
    };

    var instance: vk.VkInstance = null;
    try checkVkResult(vk.vkCreateInstance(&createInfo, pAllocCallBacks, @ptrCast(&instance)));

    return instance;
}

fn chooseEnabledLayers(comptime fields: type, comptime field_name: []const u8, neededName: []const [*c]const u8, physicalDevice: vk.VkPhysicalDevice, allocator: std.mem.Allocator) VkError!std.array_list.Managed([*c]const u8) {
    var namesEnabled: std.array_list.Managed([*c]const u8) = .init(allocator);

    var count: u32 = 0;
    var vulkanNames: []fields = undefined;
    switch (fields) {
        vk.VkLayerProperties => {
            try checkVkResult(vk.vkEnumerateInstanceLayerProperties(&count, null));
            vulkanNames = allocator.alloc(fields, count) catch |err| {
                std.debug.print("err: {s}\n", .{@errorName(err)});
                return VkError.VK_ERROR_OUT_OF_HOST_MEMORY;
            };
            try checkVkResult(vk.vkEnumerateInstanceLayerProperties(&count, vulkanNames.ptr));
        },
        vk.VkExtensionProperties => {
            if (physicalDevice) |device| {
                try checkVkResult(vk.vkEnumerateDeviceExtensionProperties(device, null, &count, null));
                vulkanNames = allocator.alloc(fields, count) catch |err| {
                    std.debug.print("err: {s}\n", .{@errorName(err)});
                    return VkError.VK_ERROR_OUT_OF_HOST_MEMORY;
                };
                try checkVkResult(vk.vkEnumerateDeviceExtensionProperties(device, null, &count, vulkanNames.ptr));
            } else {
                try checkVkResult(vk.vkEnumerateInstanceExtensionProperties(null, &count, null));
                vulkanNames = allocator.alloc(fields, count) catch |err| {
                    std.debug.print("err: {s}\n", .{@errorName(err)});
                    return VkError.VK_ERROR_OUT_OF_HOST_MEMORY;
                };
                try checkVkResult(vk.vkEnumerateInstanceExtensionProperties(null, &count, vulkanNames.ptr));
            }
        },
        else => {
            @compileError("not supported type");
        },
    }
    defer allocator.free(vulkanNames);

    for (neededName) |need| {
        const len = std.mem.len(need);
        for (vulkanNames) |vulkan| {
            if (std.mem.eql(u8, need[0..len], @field(vulkan, field_name)[0..len])) {
                namesEnabled.append(need) catch |err| {
                    std.debug.print("err: {s}\n", .{@errorName(err)});
                    return VkError.VK_ERROR_OUT_OF_HOST_MEMORY;
                };
                break;
            }
        }
    }
    return namesEnabled;
}

pub fn pickPhysicalDevice(instance: vk.VkInstance, allocator: std.mem.Allocator, physicalDeviceMemory: *vk.VkDeviceSize) !struct {
    count: u32,
    physicalDevices: [32]vk.VkPhysicalDevice,
} {
    const zone = tracy.initZone(@src(), .{ .name = "pick physical device" });
    defer zone.deinit();

    // var physicalDevices: [*c]vk.VkPhysicalDevice = null;

    var deviceGroupCount: u32 = 0;
    try checkVkResult(vk.vkEnumeratePhysicalDeviceGroups(instance, @ptrCast(&deviceGroupCount), null));
    if (deviceGroupCount == 0) {
        errorProcess.showErrorWithMessageBox("you device is not support vulkan");
    }

    const physicalDeviceGroups: []vk.VkPhysicalDeviceGroupProperties = allocator.alloc(vk.VkPhysicalDeviceGroupProperties, deviceGroupCount) catch |err| {
        errorProcess.showErrorWithMessageBox(@errorName(err));

        return VkError.VK_ERROR_OUT_OF_HOST_MEMORY;
    };
    defer allocator.free(physicalDeviceGroups);
    for (physicalDeviceGroups) |*deviceGroup| {
        deviceGroup.* = vk.VkPhysicalDeviceGroupProperties{
            .sType = vk.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_GROUP_PROPERTIES,
        };
    }

    std.log.debug("device group count: {d}", .{deviceGroupCount});
    try checkVkResult(vk.vkEnumeratePhysicalDeviceGroups(instance, @ptrCast(&deviceGroupCount), @ptrCast(physicalDeviceGroups.ptr)));

    var biggestMemory: u64 = 0;
    var resIndex: u32 = 0;
    for (physicalDeviceGroups, 0..) |deviceGroup, i| {
        const array = try chooseEnabledLayers(
            vk.VkExtensionProperties,
            "extensionName",
            deviceExtensionNeeded[0..deviceExtensionNeeded.len],
            deviceGroup.physicalDevices[0].?,
            allocator,
        );
        defer array.deinit();
        if (array.items.len != deviceExtensionNeeded.len) {
            continue;
        }
        var deviceProperty2 = vk.VkPhysicalDeviceProperties2{
            .sType = vk.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PROPERTIES_2,
            .pNext = null,
        };
        var deviceMemoryProperty2 = vk.VkPhysicalDeviceMemoryProperties2{
            .sType = vk.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MEMORY_PROPERTIES_2,
            .pNext = null,
        };

        var renderingFeature = vk.VkPhysicalDeviceDynamicRenderingFeatures{
            .sType = vk.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DYNAMIC_RENDERING_FEATURES,
            .pNext = null,
        };
        var timelineFeature = vk.VkPhysicalDeviceTimelineSemaphoreFeatures{
            .sType = vk.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_TIMELINE_SEMAPHORE_FEATURES,
            .pNext = &renderingFeature,
        };
        var indexingFeature = vk.VkPhysicalDeviceDescriptorIndexingFeatures{
            .sType = vk.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DESCRIPTOR_INDEXING_FEATURES,
            .pNext = &timelineFeature,
        };
        var synchronization2Feature = vk.VkPhysicalDeviceSynchronization2Features{
            .sType = vk.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SYNCHRONIZATION_2_FEATURES,
            .pNext = &indexingFeature,
        };
        var deviceFeatures2 = vk.VkPhysicalDeviceFeatures2{
            .sType = vk.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FEATURES_2,
            .pNext = &synchronization2Feature,
        };

        vk.vkGetPhysicalDeviceProperties2(deviceGroup.physicalDevices[0].?, @ptrCast(&deviceProperty2));
        vk.vkGetPhysicalDeviceMemoryProperties2(deviceGroup.physicalDevices[0].?, @ptrCast(&deviceMemoryProperty2));
        vk.vkGetPhysicalDeviceFeatures2(deviceGroup.physicalDevices[0].?, @ptrCast(&deviceFeatures2));

        // TODO memory requirement undeclared
        const memoryCount = calculateMemoryGPU(deviceMemoryProperty2.memoryProperties);
        if (memoryCount < biggestMemory) {
            continue;
        }

        const featureSupported = featureNeededCheck(vk.VkPhysicalDeviceFeatures, deviceFeatures2.features);
        const featureIndexingSupported = featureNeededCheck(vk.VkPhysicalDeviceDescriptorIndexingFeatures, indexingFeature);
        const featureTimelineSemaphoreSupported = featureNeededCheck(vk.VkPhysicalDeviceTimelineSemaphoreFeatures, timelineFeature);
        const featureDynamicRenderingSupported = featureNeededCheck(vk.VkPhysicalDeviceDynamicRenderingFeatures, renderingFeature);
        const featureSynchronization2Supported = featureNeededCheck(vk.VkPhysicalDeviceSynchronization2Features, synchronization2Feature);

        if (featureSupported and featureIndexingSupported and featureTimelineSemaphoreSupported and featureDynamicRenderingSupported and featureSynchronization2Supported) {
            switch (deviceProperty2.properties.deviceType) {
                vk.VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU => {
                    resIndex = @intCast(i + 1);
                    biggestMemory = @max(biggestMemory, memoryCount);

                    std.log.debug("device: choosed {s}", .{@tagName(@as(VkPhysicalType, @enumFromInt(deviceProperty2.properties.deviceType)))});
                },
                vk.VK_PHYSICAL_DEVICE_TYPE_INTEGRATED_GPU => {
                    if (resIndex == 0) {
                        resIndex = @intCast(i + 1);
                        biggestMemory = @max(biggestMemory, memoryCount);

                        std.log.debug("device: choosed {s}", .{@tagName(@as(VkPhysicalType, @enumFromInt(deviceProperty2.properties.deviceType)))});
                    }
                },
                else => {
                    // TODO add warn message box
                    return VkError.VK_ERROR_UNKNOWN;
                },
            }
        } else {
            std.debug.panic("feature not supported", .{});
        }
    }

    physicalDeviceMemory.* = biggestMemory;
    std.log.debug("gpu memory: {d} GB", .{@as(f64, @floatFromInt(physicalDeviceMemory.*)) / (1024 * 1024 * 1024)});

    return .{
        .count = physicalDeviceGroups[resIndex - 1].physicalDeviceCount,
        .physicalDevices = physicalDeviceGroups[resIndex - 1].physicalDevices,
    };
}

pub fn createDevice(
    physicalDeviceCount: u32,
    physicalDevices: [*c]vk.VkPhysicalDevice,
    pAllocCallBacks: [*c]vk.VkAllocationCallbacks,
    graphicQueueFamily: VkQueueFamily,
    computeQueueFamily: VkQueueFamily,
    transferQueueFamily: VkQueueFamily,
) !vk.VkDevice {
    const zone = tracy.initZone(@src(), .{ .name = "create logical device" });
    defer zone.deinit();

    var groupCreateInfo = vk.VkDeviceGroupDeviceCreateInfo{
        .sType = vk.VK_STRUCTURE_TYPE_DEVICE_GROUP_DEVICE_CREATE_INFO,
        .pNext = null,
        .physicalDeviceCount = physicalDeviceCount,
        .pPhysicalDevices = physicalDevices,
    };

    var synchronization2Feature = vk.VkPhysicalDeviceSynchronization2Features{
        .sType = vk.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SYNCHRONIZATION_2_FEATURES,
        .pNext = &groupCreateInfo,
    };
    inline for (featureSynchronization2Need) |feature| {
        @field(synchronization2Feature, feature) = 1;
    }
    var dynamicRenderingFeature = vk.VkPhysicalDeviceDynamicRenderingFeatures{
        .sType = vk.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DYNAMIC_RENDERING_FEATURES,
        .pNext = &synchronization2Feature,
    };
    inline for (featureDynamicRenderingNeed) |feature| {
        @field(dynamicRenderingFeature, feature) = 1;
    }
    var timelineSemaphoreFeature = vk.VkPhysicalDeviceTimelineSemaphoreFeatures{
        .sType = vk.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_TIMELINE_SEMAPHORE_FEATURES,
        .pNext = &dynamicRenderingFeature,
    };
    inline for (featureTimelineSemaphoreNeed) |feature| {
        @field(timelineSemaphoreFeature, feature) = 1;
    }
    var indexingFeature = vk.VkPhysicalDeviceDescriptorIndexingFeatures{
        .sType = vk.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DESCRIPTOR_INDEXING_FEATURES,
        .pNext = &timelineSemaphoreFeature,
    };
    inline for (featureIndexingNeed) |feature| {
        @field(indexingFeature, feature) = 1;
    }
    var feature2 = vk.VkPhysicalDeviceFeatures2{
        .sType = vk.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FEATURES_2,
        .pNext = &indexingFeature,
    };
    inline for (featureNeed) |feature| {
        @field(feature2.features, feature) = 1;
    }

    const queueCreateInfo, const queueCount = blk: {
        const queuePriorities = [_]f32{0.0} ** 16;
        var count: u32 = 0;
        var createInfos: [3]vk.VkDeviceQueueCreateInfo = undefined;
        const queueFamilies: [3]VkQueueFamily = .{ graphicQueueFamily, computeQueueFamily, transferQueueFamily };
        for (queueFamilies) |queue| {
            if (queue.familyIndice != -1) {
                createInfos[count].sType = vk.VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO;
                createInfos[count].pNext = null;
                createInfos[count].flags = 0;
                createInfos[count].queueCount = queue.queueCount;
                createInfos[count].queueFamilyIndex = @bitCast(queue.familyIndice);
                createInfos[count].pQueuePriorities = @ptrCast(&queuePriorities);
                count += 1;
            }
        }
        break :blk .{ createInfos, count };
    };

    var createInfo = vk.VkDeviceCreateInfo{
        .sType = vk.VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO,
        .pNext = &feature2,
        .flags = 0,
        .queueCreateInfoCount = queueCount,
        .pQueueCreateInfos = @ptrCast(&queueCreateInfo),
        .enabledLayerCount = @truncate(layerNeeded.len),
        .ppEnabledLayerNames = @ptrCast(&layerNeeded),
        .enabledExtensionCount = @truncate(deviceExtensionNeeded.len),
        .ppEnabledExtensionNames = @ptrCast(&deviceExtensionNeeded),
        .pEnabledFeatures = null,
    };

    var device: vk.VkDevice = null;
    try checkVkResult(vk.vkCreateDevice(physicalDevices[0], @ptrCast(&createInfo), pAllocCallBacks, @ptrCast(&device)));

    return device;
}

fn calculateMemoryGPU(memoryProperty: vk.VkPhysicalDeviceMemoryProperties) u64 {
    var totalCount: u64 = 0;
    for (0..memoryProperty.memoryHeapCount) |i| {
        if (memoryProperty.memoryHeaps[i].flags & vk.VK_MEMORY_HEAP_DEVICE_LOCAL_BIT != 0) {
            totalCount += memoryProperty.memoryHeaps[i].size;
        }
    }
    return totalCount;
}
