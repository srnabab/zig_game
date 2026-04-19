pub const VkStruct = @import("video");
const std = @import("std");
const Allocator = std.mem.Allocator;
const OneTimeCommand = @import("processRender").oneTimeCommand;
const TextureSet = @import("textureSet");
const Handles = @import("handle");
const vertexStruct = @import("vertexStruct");
const math = @import("math");

pub const databaseName = "Content.db";

pub const OneStackMemorySize = 128 * 1024;
pub const StackMemorySize = OneStackMemorySize * 6;
pub const vertexCount = 4;
pub const indexCount = 6;
pub const LOGICAL_HEIGHT = 600;
pub const LOGICAL_WEIGHT = 800;

pub const HandlesType = Handles.Handles(10240, .Once);

pub const Name = "Game";
pub const AppVersionMajor = 0;
pub const AppVersionMinor = 1;
pub const AppVersionPatch = 125;

pub const EngineName = "Engine";
pub const EngineVersionMajor = 0;
pub const EngineVersionMinor = 1;
pub const EngineVersionPatch = 125;

pub const MaxFrameInFlight = 3;

pub const StorageBufferVerticesSize = math.round(16, @sizeOf(vertexStruct.Vertex_f3pf3nf2u) * 4000);
pub const StorageBufferMeshletsSize = math.round(16, @sizeOf(vertexStruct.Meshlet) * 4000);
pub const StorageBufferMeshletVerticesSize = math.round(16, @sizeOf(u32) * 4000);
pub const StorageBufferMeshletTrianglesSize = math.round(16, @sizeOf(u8) * 4000);

pub const StorageBufferMeshletsEnd = StorageBufferMeshletsSize;
pub const StorageBufferVerticesEnd = StorageBufferVerticesSize + StorageBufferMeshletsEnd;
pub const StorageBufferMeshletVerticesEnd = StorageBufferMeshletVerticesSize + StorageBufferVerticesEnd;
pub const StorageBufferMeshletTrianglesEnd = StorageBufferMeshletTrianglesSize + StorageBufferMeshletVerticesEnd;

pub const MeshletStorageBufferSize = StorageBufferMeshletTrianglesEnd;

pub var FrameInFlight: u32 = 2;

pub var stopNodeDagPrint = true;
pub var stopNodeDagDetailPrint = true;
pub var stopExecuteNodePrint = true;

pub var game_end: std.atomic.Value(u8) = .init(0);
