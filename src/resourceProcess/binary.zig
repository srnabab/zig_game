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

var Empty = Binary_Reader.Child{};

pub const Binary_Reader = struct {
    const Self = @This();

    pub const Ctx = struct {};

    pub const Child = struct {
        pub const Parent = Binary_Reader;
    };

    pub fn read(
        comptime fType: ProcessType,
        ctx: *const resource.ResourceCtx,
        sqlite: sqlite3,
        fileID: u32,
        buffers: ?[]VkStruct.Buffer_t,
        commands: *ExternalCommands,
    ) ResourceError!resource.ReaderReturnType {
        _ = fType;
        const io = ctx.io;
        const gpa = ctx.gpa;
        const vulkan = ctx.vulkan;

        var bin_file = file.getFile(io, fileID, sqlite) catch return ResourceError.Invalid;
        defer bin_file.close(io);

        const stat = bin_file.stat(io) catch return ResourceError.Unavaliable;

        var buffer = [_]u8{0} ** 256;
        var fileReader = bin_file.reader(io, &buffer);
        const content = fileReader.interface.readAlloc(gpa, stat.size) catch |err| {
            std.log.err("{s}", .{@errorName(err)});
            return ResourceError.Unavaliable;
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
                return ResourceError.Unavaliable;
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
                return ResourceError.Unavaliable;
            };
        } else {
            std.debug.panic("not implemented", .{});
        }

        return .{
            .rType = .update,
            .pointer = resourceProcess.UnionInit(Self, &Empty),
        };
    }
};
