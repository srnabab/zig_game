const HandleType = @import("handle").ResourceType;
pub const ProcessType_HandleType = struct {
    type1: ProcessType,
    type2: HandleType,
};

pub const ProcessType = enum {
    DIR,
    OBJ,
    MTL,
    PNG,
    TSDI,
    TSD,
    TTF,
    WAV,
    SPV,
    TXT,
    GLTF,
    VTX,
    HASHTABLE,
    Shader,
    Pipeline,
    PipeB,
    Sampler,
    SamplerB,
    KTX2,
    UNKNOWN,
    // add here
};

const KV = struct {
    []const u8,
    ProcessType,
};
pub const list = [_]KV{
    .{ "", ProcessType.DIR },
    .{ ".obj", ProcessType.OBJ },
    .{ ".mtl", ProcessType.MTL },
    .{ ".png", ProcessType.PNG },
    .{ ".tsdI", ProcessType.TSDI },
    .{ ".tsd", ProcessType.TSD },
    .{ ".ttf", ProcessType.TTF },
    .{ ".wav", ProcessType.WAV },
    .{ ".spv", ProcessType.SPV },
    .{ ".txt", ProcessType.TXT },
    .{ ".gltf", ProcessType.GLTF },
    .{ ".glb", ProcessType.GLTF },
    .{ ".vtx", ProcessType.VTX },
    .{ ".frag", ProcessType.Shader },
    .{ ".vert", ProcessType.Shader },
    .{ ".comp", ProcessType.Shader },
    .{ ".mesh", ProcessType.Shader },
    .{ ".task", ProcessType.Shader },
    .{ ".pipe", ProcessType.Pipeline },
    .{ ".samp", ProcessType.Sampler },
    .{ ".pipeb", ProcessType.PipeB },
    .{ ".sampler", ProcessType.SamplerB },
    .{ ".ktx2", ProcessType.KTX2 },
};

pub const Mappings = [_]ProcessType_HandleType{
    // add here
};
