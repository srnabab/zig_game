pub const VkStruct = @import("video");
const std = @import("std");
const Allocator = std.mem.Allocator;

const mstd = @import("ms_std");

pub const Handles = @import("handle");
const vertexStruct = @import("vertexStruct");
const math = mstd.Math;

const stateBuffering = mstd.StateBuffering;

const event = @import("event.zig");
const cglm = @import("cglm");

pub const databaseName = "Content.db";

pub const OneStackMemorySize = 128 * 1024;
pub const StackMemorySize = OneStackMemorySize * 6;
pub const vertexCount = 4;
pub const indexCount = 6;
pub const LOGICAL_HEIGHT = 600;
pub const LOGICAL_WEIGHT = 800;

pub const HandlesType = Handles.Handles(1024, .Once);

pub const UpdateEventQueueType = mstd.Queue(event.UpdateEvent);
pub const RenderEventQueueType = mstd.Queue(event.RenderEvent);

const StateType = enum {
    _u32,
    _2d,
};
const State = union(StateType) {
    _u32: u32,
    _2d: struct {
        handle: Handles.Handle,
        pos: cglm.vec2,
    },
};

pub const StateBufferingType = stateBuffering(3, State);

pub const Name = "Game";
pub const AppVersionMajor = 0;
pub const AppVersionMinor = 2;
pub const AppVersionPatch = 125;

pub const EngineName = "Engine";
pub const EngineVersionMajor = 0;
pub const EngineVersionMinor = 2;
pub const EngineVersionPatch = 125;

pub const MaxFrameInFlight = 3;
pub var FrameInFlight: u32 = 2;

pub var stopNodeDagPrint = true;
pub var printDagToDot = false;
pub var stopNodeDagDetailPrint = true;
pub var stopExecuteNodePrint = true;
pub var storExecuteSequencePrint = true;

pub var game_end: std.atomic.Value(u8) = .init(0);
pub var resourceQueueIndex: std.atomic.Value(u8) = .init(0);
pub var resourceQueueMutexs: [2]std.Io.Mutex = .{ .init, .init };

pub var nodeChildrenAppendBreakPoint = false;

pub var SamplerNames = @import("samplerNames").names;
pub const TotalSamplerCount = SamplerNames.len;
