const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;

const global = @import("global");

const assert = std.debug.assert;

const resourceProcess = @import("../resourceProcess.zig");
const PreProcessParm = resourceProcess.PreProcessParm;
const ProcessType = resourceProcess.ProcessType;

const vk = @import("vulkan");
const file = @import("fileSystem");
const sqlite3 = ?*file.sqlite.sqlite3;
const VkStruct = @import("video");
const Handles = @import("handle");
const Handle = Handles.Handle;
const mstd = @import("ms_std");
const MutexArray = mstd.MutexArray;
const resource = @import("resource");
const Resource = resource.Resource;
const vertexStruct = @import("vertexStruct");
const Buffer_t = VkStruct.Buffer_t;
const ExternalCommands = @import("processRender").externalCommands;

const ResourceError = resource.ResourceError;

pub const Binary_Reader = struct {
    pub const Ctx = struct {};

    pub fn processResource(
        comptime fType: ProcessType,
        ctx: *const resource.ResourceCtx,
        sqlite: sqlite3,
        fileID: u32,
        handle: Handle,
        buffers: ?[]VkStruct.Buffer_t,
        commands: *ExternalCommands,
        uctx: *Ctx,
    ) ResourceError!u32 {
        _ = fType;
        _ = handle;
        _ = uctx;
        const io = ctx.io;
        const gpa = ctx.gpa;
        const vulkan = ctx.vulkan;

        var bin_file = file.getFile(io, fileID, sqlite) catch return Handles.WaitFill;
        defer bin_file.close(io);

        const stat = bin_file.stat(io) catch return Handles.WaitFill;

        var buffer = [_]u8{0} ** 256;
        var fileReader = bin_file.reader(io, &buffer);
        const content = fileReader.interface.readAlloc(gpa, stat.size) catch |err| {
            std.log.err("{s}", .{@errorName(err)});
            return Handles.WaitFill;
        };
        defer gpa.free(content);

        if (buffers) |bs| {
            const stagingBuffer = vulkan.createBufferByUsage(
                stat.size,
                0,
                .staging,
                false,
                null,
            ) catch |err| {
                std.log.err("{s}", .{@errorName(err)});
                return Handles.WaitFill;
            };
            errdefer vulkan.destroyBuffer(stagingBuffer);
            vulkan.buffers.copyDataToMapped(stagingBuffer, 0, u8, content);

            var copyRegion = [1]vk.VkBufferCopy2{.{
                .sType = vk.VK_STRUCTURE_TYPE_BUFFER_COPY_2,
                .pNext = null,
                .srcOffset = 0,
                .dstOffset = 0,
                .size = stat.size,
            }};

            commands.externalCommand(.{
                .copyBuffer = .{
                    .srcBuffer = stagingBuffer,
                    .dstBuffer = bs[0],
                    .regions = &copyRegion,
                },
            }) catch |err| {
                std.log.err("{s}", .{@errorName(err)});
                return Handles.WaitFill;
            };
        } else {
            std.debug.panic("not implemented", .{});
        }

        return Handles.WaitFill;
    }
};
