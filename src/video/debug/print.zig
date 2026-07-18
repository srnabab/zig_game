const std = @import("std");
const builtin = @import("builtin");

const global = @import("global");

const processRender = @import("processRender");
const Commands = processRender.commands;

const VkStruct = @import("video");
const vk = VkStruct.vk;

const mvzr = @import("mvzr");

const regex: mvzr.Regex = mvzr.compile("0[xX][0-9a-fA-F]+").?;

pub var errorOccured: std.atomic.Value(u8) = .init(0);
var commands: *Commands = undefined;
var io: std.Io = undefined;

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

    const rng_impl: std.Random.IoSource = .{ .io = io };
    const rng = rng_impl.interface();
    const ri = rng.int(u6);

    var pathBuffer = [_]u8{0} ** 29;
    const path = std.fmt.bufPrint(&pathBuffer, "{d}-{s}-{d}-{d}_{d}_{d}-{d}.txt", .{
        year,
        @tagName(month),
        day,
        hour,
        minute,
        second,
        ri,
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
            .computeRecord => |r| {
                const info = std.fmt.bufPrint(
                    &infoBuffer,
                    "ID: {d}\ngroup count = {d}\n\n",
                    .{ entry.key_ptr.*, r.groupCount },
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
                            info = std.fmt.bufPrint(
                                infoBuffer[len..],
                                "ID: {d}\n{}\n\n",
                                .{ entry.key_ptr.*, b },
                            ) catch continue;
                        },
                        .imageMemory => |b| {
                            info = std.fmt.bufPrint(
                                infoBuffer[len..],
                                "ID: {d}\n{}\n\n",
                                .{ entry.key_ptr.*, b },
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

        fileWriter.interface.print("{d} {s} {s}", .{
            entry.key_ptr.*,
            @tagName(entry.value_ptr.*.data.commandPoolType),
            infoBuffer[0..len],
        }) catch |err| {
            std.log.err("write err: {s} 8", .{@errorName(err)});
            return;
        };
    }

    fileWriter.flush() catch |err| {
        std.log.err("write err: {s} 8", .{@errorName(err)});
        return;
    };
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
