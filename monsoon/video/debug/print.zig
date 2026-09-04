const std = @import("std");
const builtin = @import("builtin");

const global = @import("global");

const processRender = @import("processRender");
const Commands = processRender.commands;

const VulkanType = @import("vulkanType");
const VkStruct = @import("video");
const vk = VkStruct.vk;

const Pass = @import("pass").Pass;

const mvzr = @import("mvzr");

const regex: mvzr.Regex = mvzr.compile("0[xX][0-9a-fA-F]+").?;

pub var errorOccured: std.atomic.Value(u8) = .init(0);
var commands: *Commands = undefined;
var io: std.Io = undefined;

fn vkValueName(
    comptime E: type,
    scratch: []u8,
    val: @typeInfo(E).@"enum".tag_type,
) []const u8 {
    const EnumInfo = @typeInfo(E).@"enum";
    const Tag = EnumInfo.tag_type;

    // val == 0(无单 bit) -> 输出 0 值成员名(VK_*_NONE)
    if (val == 0) {
        return @tagName(@as(E, @enumFromInt(0)));
    }

    // 步骤1 把 val 拆成多个单 bit 为 1 的值, 存入数组
    var bitArr: [64]Tag = undefined;
    var count: usize = 0;
    var bits: Tag = val;
    while (bits != 0) {
        const b: Tag = bits & (~bits + 1);
        bits ^= b;
        bitArr[count] = b;
        count += 1;
    }

    // 步骤2 遍历数组, 逐个转枚举名字符串并拼接; 转不出来 -> 不处理, 先崩溃
    var len: usize = 0;
    for (bitArr[0..count]) |b| {
        const name = @tagName(@as(E, @enumFromInt(b)));

        if (len + name.len + 3 > scratch.len) {
            std.debug.panic("vkValueName: scratch too small for {s}", .{@typeName(E)});
        }

        if (len != 0) {
            @memcpy(scratch[len..][0..3], " | ");
            len += 3;
        }
        @memcpy(scratch[len .. len + name.len], name);
        len += name.len;
    }

    // 步骤3 返回完整字符串
    return scratch[0..len];
}

pub fn init(io_: std.Io, c: *Commands) void {
    commands = c;
    io = io_;
}

pub fn printToDot() void {
    const old1 = global.stopNodeDagPrint;
    const old2 = global.printDagToDot;

    defer {
        global.stopNodeDagPrint = old1;
        global.printDagToDot = old2;
    }

    global.stopNodeDagPrint = false;
    global.printDagToDot = true;
    processRender.nodeDagPrint(&commands.nodeDag, commands);
    // printAllInfoToTxt();
}

pub fn printAllInfoToTxt() void {
    const epochSeconds = std.time.epoch.EpochSeconds{
        .secs = @intCast(std.Io.Timestamp.now(io, .real).toSeconds()),
    };
    const epochDay = epochSeconds.getEpochDay();
    const daySeconds = epochSeconds.getDaySeconds();

    const year = epochDay.calculateYearDay().year;
    const month = epochDay.calculateYearDay().calculateMonthDay().month;
    const day = epochDay.calculateYearDay().calculateMonthDay().day_index;
    const hour = daySeconds.getHoursIntoDay();
    const minute = daySeconds.getMinutesIntoHour();
    const second = daySeconds.getSecondsIntoMinute();

    const frame = commands.vulkan.totalFrame.load(.monotonic);

    var pathBuffer = [_]u8{0} ** 40;
    const path = std.fmt.bufPrint(&pathBuffer, "{d}-{s}-{d}-{d}_{d}_{d}-{d}.txt", .{
        year,
        @tagName(month),
        day,
        hour,
        minute,
        second,
        frame,
    }) catch |err| {
        std.log.err("write err: {s} 6", .{@errorName(err)});
        return;
    };
    var file = std.Io.Dir.cwd().createFile(io, path, .{}) catch |err| {
        std.log.err("write err: {s} 7", .{@errorName(err)});
        return;
    };
    defer file.close(io);

    var writeBuffer = [_]u8{0} ** 1024;
    var fileWriter = file.writer(io, &writeBuffer);

    var it = commands.nodeDag.map.iterator();
    while (it.next()) |entry| {
        const com = commands.queue.getPtr(entry.key_ptr.*);
        if (com == null) continue;

        var infoBuffer = [_]u8{0} ** 10240;
        var len: usize = 0;
        switch (com.?.command) {
            // .beginRendering => |r| {
            //     _ = r;
            // },
            .copyBufferToImageRecord => |r| {
                const info = std.fmt.bufPrint(
                    &infoBuffer,
                    "ID: {d}\nbuffer = {*}, texture = {*}, dst image layout = {s}({d})\n\n",
                    .{
                        entry.key_ptr.*,
                        commands.vulkan.buffers.getVkBuffer(r.buffer),
                        commands.pTextureSet.getVkImage(r.texture),
                        @tagName(@as(VulkanType.VkImageLayout, @enumFromInt(r.dstImageLayout))),
                        r.dstImageLayout,
                    },
                ) catch continue;
                len = info.len;
            },
            .computeRecord => |r| {
                const info = std.fmt.bufPrint(
                    &infoBuffer,
                    "ID: {d}\ngroup count = {d}\n\n",
                    .{ entry.key_ptr.*, r.groupCount },
                ) catch continue;
                len = info.len;
            },
            .computeIndirectRecord => |r| {
                const info = std.fmt.bufPrint(
                    &infoBuffer,
                    "ID: {d}\nbuffer = {*}, offset = {d}\n\n",
                    .{ entry.key_ptr.*, r.buffer, r.offset },
                ) catch continue;
                len = info.len;
            },
            .copyBuffer => |r| {
                const info = std.fmt.bufPrint(
                    &infoBuffer,
                    "ID: {d}\nsrc: {*}, size {d}\ndst: {*}, size {d}\nregion: src offset {d}, dst offset {d}, size {d}\n\n",
                    .{
                        entry.key_ptr.*,
                        commands.vulkan.buffers.getVkBuffer(r.srcBuffer),
                        commands.vulkan.buffers.getBufferSize(r.srcBuffer),
                        commands.vulkan.buffers.getVkBuffer(r.dstBuffer),
                        commands.vulkan.buffers.getBufferSize(r.dstBuffer),
                        r.regions[0].srcOffset,
                        r.regions[0].dstOffset,
                        r.regions[0].size,
                    },
                ) catch continue;
                len = info.len;
            },
            .pipelineBarrier => |r| {
                for (r.barriers) |value| {
                    var info: []u8 = &.{};
                    switch (value) {
                        .bufferMemory => |b| {
                            var srcStageName: [512]u8 = undefined;
                            var srcAccessName: [512]u8 = undefined;
                            var dstStageName: [512]u8 = undefined;
                            var dstAccessName: [512]u8 = undefined;
                            info = std.fmt.bufPrint(
                                infoBuffer[len..],
                                "ID: {d}\nsrcStageMask = {s}({d}), srcAccessMask = {s}({d}), dstStageMask = {s}({d}), dstAccessMask = {s}({d}), srcQueueFamilyIndex = {s}" ++
                                    ", dstQueueFamilyIndex = {s}, buffer = {*}, offset = {d}, size = {d}\n\n",
                                .{
                                    entry.key_ptr.*,
                                    vkValueName(VulkanType.VkPipelineStageFlagBits2, &srcStageName, b.srcStageMask),
                                    b.srcStageMask,
                                    vkValueName(VulkanType.VkAccessFlagBits2, &srcAccessName, b.srcAccessMask),
                                    b.srcAccessMask,
                                    vkValueName(VulkanType.VkPipelineStageFlagBits2, &dstStageName, b.dstStageMask),
                                    b.dstStageMask,
                                    vkValueName(VulkanType.VkAccessFlagBits2, &dstAccessName, b.dstAccessMask),
                                    b.dstAccessMask,
                                    @tagName(commands.vulkan.getQueueType(b.srcQueueFamilyIndex)),
                                    @tagName(commands.vulkan.getQueueType(b.dstQueueFamilyIndex)),
                                    b.buffer,
                                    b.offset,
                                    b.size,
                                },
                            ) catch continue;
                        },
                        .imageMemory => |b| {
                            var srcStageName: [512]u8 = undefined;
                            var srcAccessName: [512]u8 = undefined;
                            var dstStageName: [512]u8 = undefined;
                            var dstAccessName: [512]u8 = undefined;
                            info = std.fmt.bufPrint(
                                infoBuffer[len..],
                                "ID: {d}\nsrcStageMask = {s}({d}), srcAccessMask = {s}({d}), dstStageMask = {s}({d}), dstAccessMask = {s}({d}), oldLayout = {s}({d})" ++
                                    ", newLayout = {s}({d}), srcQueueFamilyIndex = {s}, dstQueueFamilyIndex = {s}, image = {*}, subresourceRange ={}\n\n",
                                .{
                                    entry.key_ptr.*,
                                    vkValueName(VulkanType.VkPipelineStageFlagBits2, &srcStageName, b.srcStageMask),
                                    b.srcStageMask,
                                    vkValueName(VulkanType.VkAccessFlagBits2, &srcAccessName, b.srcAccessMask),
                                    b.srcAccessMask,
                                    vkValueName(VulkanType.VkPipelineStageFlagBits2, &dstStageName, b.dstStageMask),
                                    b.dstStageMask,
                                    vkValueName(VulkanType.VkAccessFlagBits2, &dstAccessName, b.dstAccessMask),
                                    b.dstAccessMask,
                                    @tagName(@as(VulkanType.VkImageLayout, @enumFromInt(b.oldLayout))),
                                    b.oldLayout,
                                    @tagName(@as(VulkanType.VkImageLayout, @enumFromInt(b.newLayout))),
                                    b.newLayout,
                                    @tagName(commands.vulkan.getQueueType(b.srcQueueFamilyIndex)),
                                    @tagName(commands.vulkan.getQueueType(b.dstQueueFamilyIndex)),
                                    b.image,
                                    b.subresourceRange,
                                },
                            ) catch continue;
                        },
                        else => continue,
                    }
                    len += info.len;
                }
            },
            .fillBuffer => |f| {
                const info = std.fmt.bufPrint(
                    &infoBuffer,
                    "ID: {d}\nbuffer: {*}, size {d}, offset {d}, value {d}\n\n",
                    .{
                        entry.key_ptr.*,
                        commands.vulkan.buffers.getVkBuffer(f.buffer),
                        f.size,
                        f.offset,
                        f.value,
                    },
                ) catch continue;
                len = info.len;
            },
            .bindDescriptorSets => |r| {
                const info = std.fmt.bufPrint(
                    &infoBuffer,
                    "ID: {d}\ndescriptor set count: {d}\n\n",
                    .{
                        entry.key_ptr.*,
                        r.bindDescriptorSetsInfo.descriptorSetCount,
                    },
                ) catch continue;
                len = info.len;
            },
            else => continue,
        }

        fileWriter.interface.print("{s} {s} {s}", .{
            @tagName(com.?.command),
            @tagName(entry.value_ptr.*.data.commandPoolType),
            infoBuffer[0..len],
        }) catch |err| {
            std.log.err("write err: {s} 8", .{@errorName(err)});
            return;
        };
    }

    for (commands.pTextureSet.array.items) |tex| {
        fileWriter.interface.print("\ntexture ID {d}, image {*}", .{
            tex.ID,
            @as(vk.VkImage, @ptrFromInt(tex.image.vkImage)),
        }) catch |err| {
            std.log.err("write err: {s} 8", .{@errorName(err)});
            return;
        };
        fileWriter.flush() catch |err| {
            std.log.err("write err: {s} 8", .{@errorName(err)});
            return;
        };
    }

    fileWriter.flush() catch |err| {
        std.log.err("write err: {s} 8", .{@errorName(err)});
        return;
    };
}

pub fn printPassInfo(vulkan: *VkStruct, pass: *Pass) void {
    std.log.debug("Pass: {s}", .{pass.name});

    for (pass.buffer) |value| {
        const bufferContent = vulkan.buffers.getBufferContent(value);
        std.log.debug("buffer: {*}, type: {s}, size: {d}, usage {s}, writedType: {s}, queue: {s}", .{
            bufferContent.vkBuffer,
            @tagName(bufferContent.allocation),
            bufferContent.size,
            @tagName(bufferContent.usage),
            @tagName(bufferContent.writedType),
            @tagName(vulkan.buffers.getBufferQueueType(value)),
        });
    }
}

pub fn debugCallback(
    messageSeverity: vk.VkDebugUtilsMessageSeverityFlagBitsEXT,
    messageType: vk.VkDebugUtilsMessageTypeFlagsEXT,
    pCallbackData: [*c]const vk.VkDebugUtilsMessengerCallbackDataEXT,
    pUserData: ?*anyopaque,
) callconv(.c) vk.VkBool32 {
    _ = messageType;
    _ = pUserData;

    if (messageSeverity >= vk.VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT) {
        std.log.err("{s}", .{pCallbackData.*.pMessage});

        // for (0..pCallbackData.*.objectCount) |i| {
        //     std.log.debug("{s}", .{std.fmt.hex(pCallbackData.*.pObjects[i].objectHandle)});
        // }

        // @breakpoint();
        errorOccured.store(1, .monotonic);
    } else {
        std.log.debug("{s}", .{pCallbackData.*.pMessage});
    }

    return vk.VK_FALSE;
}

pub fn setObjectName(
    device: vk.VkDevice,
    objectType: vk.VkObjectType,
    handle: u64,
    name: [:0]const u8,
) void {
    if (builtin.mode == .Debug or builtin.mode == .ReleaseSafe) {
        var info = vk.VkDebugUtilsObjectNameInfoEXT{
            .sType = vk.VK_STRUCTURE_TYPE_DEBUG_UTILS_OBJECT_NAME_INFO_EXT,
            .pNext = null,
            .objectType = objectType,
            .objectHandle = handle,
            .pObjectName = name.ptr,
        };

        _ = VkStruct.vkSetDebugUtilsObjectNameEXT.?(device, &info);
    }
}
