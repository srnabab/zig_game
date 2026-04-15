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
    "VK_KHR_maintenance5",
    "VK_KHR_synchronization2",
    "VK_KHR_timeline_semaphore",
    "VK_KHR_dynamic_rendering",
    "VK_EXT_extended_dynamic_state",
    "VK_EXT_robustness2",
    "VK_EXT_mesh_shader",
};
const deviceExtensionOptional = [_][*c]const u8{
    "VK_EXT_mesh_shader",
};

const featureNeed = [_][]const u8{
    "geometryShader",
    "independentBlend",
    "samplerAnisotropy",
    "logicOp",
    "depthClamp",
    "depthBiasClamp",
    "wideLines",
    "robustBufferAccess",
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
const featureMaintenance5Need = [_][]const u8{"maintenance5"};
const featureRobustness2Need = [_][]const u8{
    "robustBufferAccess2",
    "robustImageAccess2",
    "nullDescriptor",
};
const featureMeshShaderNeed = [_][]const u8{ "meshShader", "taskShader" };
const feature8BitStorageNeed = [_][]const u8{"storageBuffer8BitAccess"};

const typeNames = struct {
    featureType: type,
    names: []const []const u8,
};
const featureTypeAndNames = [_]typeNames{
    .{ .featureType = vk.VkPhysicalDeviceFeatures, .names = &featureNeed },
    .{ .featureType = vk.VkPhysicalDeviceDescriptorIndexingFeatures, .names = &featureIndexingNeed },
    .{ .featureType = vk.VkPhysicalDeviceTimelineSemaphoreFeatures, .names = &featureTimelineSemaphoreNeed },
    .{ .featureType = vk.VkPhysicalDeviceDynamicRenderingFeatures, .names = &featureDynamicRenderingNeed },
    .{ .featureType = vk.VkPhysicalDeviceSynchronization2Features, .names = &featureSynchronization2Need },
    .{ .featureType = vk.VkPhysicalDeviceMaintenance5Features, .names = &featureMaintenance5Need },
    .{ .featureType = vk.VkPhysicalDeviceRobustness2FeaturesEXT, .names = &featureRobustness2Need },
    .{ .featureType = vk.VkPhysicalDeviceMeshShaderFeaturesEXT, .names = &featureMeshShaderNeed },
    .{ .featureType = vk.VkPhysicalDevice8BitStorageFeatures, .names = &feature8BitStorageNeed },
};

const VkQueueFamily = types.VkQueueFamily;

fn featureNeededCheck(featurePack: anytype) bool {
    const featureType = @TypeOf(featurePack);

    var count: u32 = 0;
    var len: u32 = 0;

    comptime var fType = false;

    inline for (featureTypeAndNames) |value| {
        if (featureType == value.featureType) {
            fType = true;
            len = value.names.len;
            inline for (value.names) |feature| {
                count += @field(featurePack, feature);
            }
        }
    }

    if (!fType) @compileError(std.fmt.comptimePrint("unknow feature {s}", .{@typeName(featureType)}));

    return count == len;
}

const Features: type = t: {
    var fields: [1024]std.builtin.Type.StructField = undefined;
    var count: u32 = 0;

    @setEvalBranchQuota(10000);

    for (featureTypeAndNames) |value| {
        if (value.featureType == vk.VkPhysicalDeviceFeatures) continue;

        var name = @typeName(value.featureType);
        const needle = "VkPhysicalDevice";
        const index = std.mem.indexOf(u8, name, needle).?;
        const index2 = std.mem.indexOf(u8, name, "EXT");

        const fieldName = name[index + needle.len .. index2 orelse name.len];

        fields[count] = .{
            .name = std.fmt.comptimePrint("_{s}", .{fieldName}),
            .type = value.featureType,
            .default_value_ptr = null,
            .is_comptime = false,
            .alignment = @alignOf(value.featureType),
        };
        count += 1;
    }

    // getVkStructType(vk.VkPhysicalDeviceMeshShaderFeaturesNV);

    fields[count] = .{
        .name = "_Features2",
        .type = vk.VkPhysicalDeviceFeatures2,
        .default_value_ptr = null,
        .is_comptime = false,
        .alignment = @alignOf(vk.VkPhysicalDeviceFeatures2),
    };
    count += 1;

    break :t @Type(.{ .@"struct" = .{
        .layout = .auto,
        .fields = fields[0..count],
        .decls = &.{},
        .is_tuple = false,
    } });
};

// fn getVkStructType(sType: type) []const u8 {
//     comptime {
//         @setEvalBranchQuota(100000);
//         const KeywordList = [_][]const u8{
//             "Vk",
//             "Physical",
//             "Device",
//             "Features",
//             "2",
//             "Descriptor",
//             "Indexing",
//             "Timeline",
//             "Semaphore",
//             "Dynamic",
//             "Rendering",
//             "Synchronization",
//             "Maintenance",
//             "3",
//             "4",
//             "5",
//             "Robustness",
//             "Mesh",
//             "Shader",
//             "8Bit",
//             "Storage",
//             "EXT",
//         };
//         const Head = "VK_STRUCTURE_TYPE_";

//         var name = @typeName(sType);

//         const index_vk = std.mem.indexOf(u8, name, "Vk");
//         var pureName = name[index_vk.?..];

//         var StructTypeName = [_]u8{0} ** 512;
//         @memcpy(StructTypeName[0..Head.len], Head);

//         var name_cur = index_vk.?;
//         var sName_cur = Head.len;

//         while (name_cur < pureName.len) {
//             for (KeywordList) |keyword| {
//                 if (std.mem.indexOf(u8, pureName[name_cur..], keyword)) |sIdx| {
//                     if (sIdx == name_cur) {
//                         var upperBuffer = [_]u8{0} ** 64;
//                         for (keyword, 0..) |value, i| {
//                             upperBuffer[i] = std.ascii.toUpper(value);
//                         }

//                         @memcpy(StructTypeName[sName_cur .. sName_cur + keyword.len], upperBuffer[0..keyword.len]);
//                         name_cur += keyword.len;
//                         sName_cur += keyword.len;

//                         StructTypeName[sName_cur] = '_';
//                         sName_cur += 1;

//                         break;
//                     }
//                 }
//             }
//         }

//         StructTypeName[sName_cur] = 0;
//         sName_cur -= 1;

//         return StructTypeName[0..sName_cur];
//     }
// }

fn getSType(comptime T: type) vk.VkStructureType {
    return switch (T) {
        vk.VkPhysicalDeviceFeatures => vk.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FEATURES,
        vk.VkPhysicalDeviceTimelineSemaphoreFeatures => vk.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_TIMELINE_SEMAPHORE_FEATURES,
        vk.VkPhysicalDeviceDescriptorIndexingFeatures => vk.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DESCRIPTOR_INDEXING_FEATURES,
        vk.VkPhysicalDeviceDynamicRenderingFeatures => vk.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DYNAMIC_RENDERING_FEATURES,
        vk.VkPhysicalDeviceSynchronization2Features => vk.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SYNCHRONIZATION_2_FEATURES,
        vk.VkPhysicalDeviceMaintenance5Features => vk.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MAINTENANCE_5_FEATURES,
        vk.VkPhysicalDeviceRobustness2FeaturesEXT => vk.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_ROBUSTNESS_2_FEATURES_EXT,
        vk.VkPhysicalDeviceMeshShaderFeaturesEXT => vk.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MESH_SHADER_FEATURES_EXT,
        vk.VkPhysicalDevice8BitStorageFeatures => vk.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_8BIT_STORAGE_FEATURES,
        vk.VkPhysicalDeviceFeatures2 => vk.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FEATURES_2,
        // ... 在这里添加新类型的映射
        else => @compileError(std.fmt.comptimePrint("Unsupported feature type {s}", .{@typeName(T)})),
    };
}

fn initFeatures(allocator: std.mem.Allocator) !*Features {
    const self = try allocator.create(Features);
    const fields = @typeInfo(Features).@"struct".fields;

    // 假设最后一个字段是 features2 (入口)，之前的字段按顺序链接
    inline for (fields, 0..) |field, i| {
        const current_ptr = &@field(self.*, field.name);

        current_ptr.* = std.mem.zeroes(field.type);

        // 设置 sType
        current_ptr.sType = getSType(field.type);
        current_ptr.pNext = null;

        if (std.mem.eql(u8, field.name, "_Features2")) {
            // features2 作为头，它的 pNext 指向字段列表的第一个
            current_ptr.pNext = &@field(self.*, fields[0].name);
        } else if (i + 1 < fields.len and !std.mem.eql(u8, fields[i + 1].name, "_Features2")) {
            // 中间节点指向下一个字段
            current_ptr.pNext = &@field(self.*, fields[i + 1].name);
        } else {
            // 最后一个节点 (在 features2 之前的那个) 指向 null
            current_ptr.pNext = null;
        }
    }
    return self;
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
    gpuType: vk.VkPhysicalDeviceType,
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
    var gpuType: vk.VkPhysicalDeviceType = vk.VK_PHYSICAL_DEVICE_TYPE_OTHER;
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

        // const array2 = try chooseEnabledLayers(
        //     vk.VkExtensionProperties,
        //     "extensionName",
        //     deviceExtensionOptional[0..deviceExtensionOptional.len],
        //     deviceGroup.physicalDevices[0].?,
        //     allocator,
        // );
        // defer array2.deinit();

        var deviceProperty2 = vk.VkPhysicalDeviceProperties2{
            .sType = vk.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PROPERTIES_2,
            .pNext = null,
        };
        var deviceMemoryProperty2 = vk.VkPhysicalDeviceMemoryProperties2{
            .sType = vk.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MEMORY_PROPERTIES_2,
            .pNext = null,
        };

        var features = try initFeatures(allocator);
        defer allocator.destroy(features);

        vk.vkGetPhysicalDeviceProperties2(deviceGroup.physicalDevices[0].?, @ptrCast(&deviceProperty2));
        vk.vkGetPhysicalDeviceMemoryProperties2(deviceGroup.physicalDevices[0].?, @ptrCast(&deviceMemoryProperty2));
        vk.vkGetPhysicalDeviceFeatures2(deviceGroup.physicalDevices[0].?, @ptrCast(&features._Features2));

        // TODO memory requirement undeclared
        const memoryCount = calculateMemoryGPU(deviceMemoryProperty2.memoryProperties);
        if (memoryCount < biggestMemory) {
            continue;
        }

        const featureSupported = featureNeededCheck(features._Features2.features);
        const featureIndexingSupported = featureNeededCheck(features._DescriptorIndexingFeatures);
        const featureTimelineSemaphoreSupported = featureNeededCheck(features._TimelineSemaphoreFeatures);
        const featureDynamicRenderingSupported = featureNeededCheck(features._DynamicRenderingFeatures);
        const featureSynchronization2Supported = featureNeededCheck(features._Synchronization2Features);
        const featureMaintenance5Supported = featureNeededCheck(features._Maintenance5Features);
        const featureRobustnessSupported = featureNeededCheck(features._Robustness2Features);
        const featureMeshShaderSupported = featureNeededCheck(features._MeshShaderFeatures);
        const feature8BitStorageSupported = featureNeededCheck(features._8BitStorageFeatures);

        if (featureSupported and featureIndexingSupported and featureTimelineSemaphoreSupported and featureDynamicRenderingSupported and featureSynchronization2Supported and featureMaintenance5Supported and featureRobustnessSupported and featureMeshShaderSupported and feature8BitStorageSupported) {
            switch (deviceProperty2.properties.deviceType) {
                vk.VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU => {
                    resIndex = @intCast(i + 1);
                    biggestMemory = @max(biggestMemory, memoryCount);

                    gpuType = deviceProperty2.properties.deviceType;

                    std.log.debug("device: choosed {s}", .{@tagName(@as(VkPhysicalType, @enumFromInt(deviceProperty2.properties.deviceType)))});
                },
                vk.VK_PHYSICAL_DEVICE_TYPE_INTEGRATED_GPU => {
                    if (resIndex == 0) {
                        resIndex = @intCast(i + 1);
                        biggestMemory = @max(biggestMemory, memoryCount);

                        gpuType = deviceProperty2.properties.deviceType;

                        std.log.debug("device: choosed {s}", .{@tagName(@as(VkPhysicalType, @enumFromInt(deviceProperty2.properties.deviceType)))});
                    }
                },
                else => {
                    // TODO add warn message box
                    return VkError.VK_ERROR_UNKNOWN;
                },
            }
        } else {
            std.log.debug("feature2 {}", .{featureSupported});
            std.log.debug("indexing {}", .{featureIndexingSupported});
            std.log.debug("timeline {}", .{featureTimelineSemaphoreSupported});
            std.log.debug("dynamic rendering {}", .{featureDynamicRenderingSupported});
            std.log.debug("synchronization2 {}", .{featureSynchronization2Supported});
            std.log.debug("maintenance5 {}", .{featureMaintenance5Supported});
            std.log.debug("robustness {}", .{featureRobustnessSupported});
            std.log.debug("mesh shader {}", .{featureMeshShaderSupported});
            // std.debug.panic("", .{});
            std.log.debug("feature not supported", .{});
        }
    }

    physicalDeviceMemory.* = biggestMemory;
    std.log.debug("gpu memory: {d} GB", .{@as(f64, @floatFromInt(physicalDeviceMemory.*)) / (1024 * 1024 * 1024)});

    return .{
        .count = physicalDeviceGroups[resIndex - 1].physicalDeviceCount,
        .physicalDevices = physicalDeviceGroups[resIndex - 1].physicalDevices,
        .gpuType = gpuType,
    };
}

pub fn createDevice(
    physicalDeviceCount: u32,
    physicalDevices: [*c]vk.VkPhysicalDevice,
    pAllocCallBacks: [*c]vk.VkAllocationCallbacks,
    graphicQueueFamily: VkQueueFamily,
    computeQueueFamily: VkQueueFamily,
    transferQueueFamily: VkQueueFamily,
    allocator: std.mem.Allocator,
) !vk.VkDevice {
    const zone = tracy.initZone(@src(), .{ .name = "create logical device" });
    defer zone.deinit();

    var groupCreateInfo = vk.VkDeviceGroupDeviceCreateInfo{
        .sType = vk.VK_STRUCTURE_TYPE_DEVICE_GROUP_DEVICE_CREATE_INFO,
        .pNext = null,
        .physicalDeviceCount = physicalDeviceCount,
        .pPhysicalDevices = physicalDevices,
    };

    const featuresFields = @typeInfo(Features).@"struct".fields;
    const features = try initFeatures(allocator);
    defer allocator.destroy(features);

    inline for (featuresFields) |field| {
        inline for (featureTypeAndNames) |value| {
            if (value.featureType == field.type) {
                inline for (value.names) |name| {
                    @field(@field(features.*, field.name), name) = 1;
                }
            }
        }
        if (@field(features.*, field.name).pNext == null) {
            @field(features.*, field.name).pNext = &groupCreateInfo;
        }
    }
    inline for (featureNeed) |feature| {
        @field(features.*._Features2.features, feature) = 1;
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
        .pNext = &features._Features2,
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
