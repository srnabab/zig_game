const HandleType = @import("handle").ResourceType;
pub const ProcessType_HandleType = struct {
    type1: ProcessType,
    type2: HandleType,
};

pub const ProcessType = enum {
    // add here
};

pub const Mappings = [_]ProcessType_HandleType{
    // add here
};
