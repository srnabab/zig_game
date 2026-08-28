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

pub const Binary_Reader = struct {
    pub const Ctx = struct {};

    pub fn processResource(
        comptime fType: ProcessType,
        io: Io,
        gpa: Allocator,
        sqlite: sqlite3,
        vulkan: *VkStruct,
        fileID: i32,
        handle: Handle,
        buffers: ?[]VkStruct.Buffer_t,
        handles: *global.HandlesType,
        commands: *ExternalCommands,
        uctx: *Ctx,
    ) !void {
        _ = fType;
        _ = handle;
        _ = uctx;
        _ = handles;

        var bin_file = file.getFile(io, fileID, sqlite) catch return;
        defer bin_file.close(io);

        const stat = bin_file.stat(io) catch return;

        var buffer = [_]u8{0} ** 256;
        var fileReader = bin_file.reader(io, &buffer);
        const content = fileReader.interface.readAlloc(gpa, stat.size) catch |err| {
            std.log.err("{s}", .{@errorName(err)});
            return;
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
                return;
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

            try commands.externalCommand(.{
                .copyBuffer = .{
                    .srcBuffer = stagingBuffer,
                    .dstBuffer = bs[0],
                    .regions = &copyRegion,
                },
            });
        } else {
            std.debug.panic("not implemented", .{});
        }
    }
};
