pub const FileType = enum {
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
    UNKNOWN,
};

pub const NodeType = enum {
    Pipeline,
    Shader,
};
