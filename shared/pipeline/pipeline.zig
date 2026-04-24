const std = @import("std");
const json = std.json;
const fs = std.fs;

const pipelineType = enum {
    Graphics,
    Compute,
};

const binding = struct {
    bind: u32,
    stride: u32,
    inputRate: []const u8,
};

const attribute = struct {
    location: u32,
    binding: u32,
    format: []const u8,
    offset: u32,
};

pub const vertexInputStatepNext = union {};
pub const vertexInputState = struct {
    pNext: ?vertexInputStatepNext,
    flag: u32,
    vertexBindingDescriptionCount: u32,
    bindings: ?[]binding,
    vertexAttributeDescriptionCount: u32,
    attributes: ?[]attribute,
};

pub const inputAssemblyPNext = union {}; // New union for inputAssembly
pub const inputAssembly = struct {
    pNext: ?inputAssemblyPNext = null,
    flags: u32,
    topology: []const u8,
    primitiveRestartEnable: bool,
};

pub const tessellationStatePNext = union {}; // New union for tessellationState
pub const tessellationState = struct {
    pNext: ?tessellationStatePNext = null,
    flags: u32,
    patchControlPoints: u32,
};

const viewport = struct {
    x: f32,
    y: f32,
    width: u32,
    height: u32,
    minDepth: f32,
    maxDepth: f32,
};
const scissor = struct {
    offset: struct { x: i32, y: i32 },
    extent: struct { width: u32, height: u32 },
};
pub const viewportStatePNext = union {}; // New union for viewportState
pub const viewportState = struct {
    pNext: ?viewportStatePNext = null,
    flags: u32,
    viewports: []viewport,
    scissors: []scissor,
};

pub const rasterizationStatePNext = union {}; // New union for rasterizationState
pub const rasterizationState = struct {
    pNext: ?rasterizationStatePNext = null,
    flags: u32,
    depthClampEnable: bool,
    rasterizerDiscardEnable: bool,
    polygonMode: []const u8,
    cullMode: []const u8,
    frontFace: []const u8,
    depthBiasEnable: bool,
    depthBiasConstantFactor: f32,
    depthBiasClamp: f32,
    depthBiasSlopeFactor: f32,
    lineWidth: f32,
};

pub const multisampleStatePNext = union {}; // New union for multisampleState
pub const multisampleState = struct {
    pNext: ?multisampleStatePNext = null,
    flags: u32,
    rasterizationSamples: []const u8,
    sampleShadingEnable: bool,
    minSampleShading: f32,
    alphaToCoverageEnable: bool,
    alphaToOneEnable: bool,
};

const stencilOpState = struct {
    failOp: []const u8,
    passOp: []const u8,
    depthFailOp: []const u8,
    compareOp: []const u8,
    compareMask: u32,
    writeMask: u32,
    reference: u32,
};

pub const depthStencilStatePNext = union {}; // New union for depthStencilState
pub const depthStencilState = struct {
    pNext: ?depthStencilStatePNext = null,
    flags: u32,
    depthTestEnable: bool,
    depthWriteEnable: bool,
    depthCompareOp: []const u8,
    depthBoundsTestEnable: bool,
    stencilTestEnable: bool,
    front: ?stencilOpState,
    back: ?stencilOpState,
    minDepthBounds: f32,
    maxDepthBounds: f32,
};

pub const colorBlendAttachmentState = struct {
    blendEnable: bool,
    srcColorBlendFactor: []const u8,
    dstColorBlendFactor: []const u8,
    colorBlendOp: []const u8,
    srcAlphaBlendFactor: []const u8,
    dstAlphaBlendFactor: []const u8,
    alphaBlendOp: []const u8,
    colorWriteMask: []const []const u8,
};

pub const colorBlendStatePNext = union {}; // New union for colorBlendState
pub const colorBlendState = struct {
    pNext: ?colorBlendStatePNext = null,
    flags: u32,
    logicOpEnable: bool,
    logicOp: []const u8,
    attachments: []colorBlendAttachmentState,
    blendConstants: [4]f32,
};

pub const dynamicStatesPNext = union {}; // New union for dynamicStates
pub const dynamicStates = struct {
    pNext: ?dynamicStatesPNext = null,
    flags: u32,
    States: [][]const u8,
};

pub const renderingInfo = struct {
    colorAttachment: [10][]const u8,
    colorAttachmentCount: u32,
    depthAttachment: []const u8,
    stencilAttachment: []const u8,
};

pub const pipelineInfo = struct {
    const Self = @This();

    allocator: std.heap.ArenaAllocator,
    parser: std.json.Parsed(json.Value),
    name: []const u8,
    pipeType: pipelineType,
    shaderCount: u32,
    shaders: [5][]const u8,
    vertexInputstatee: vertexInputState,
    inputAssemblyy: inputAssembly,
    tessellationStatee: ?tessellationState,
    viewportStatee: viewportState,
    rasterizationStatee: rasterizationState,
    multisampleStatee: multisampleState,
    depthStencilStatee: depthStencilState,
    colorBlendStatee: colorBlendState,
    dynamicStatess: dynamicStates,
    rendering: ?renderingInfo,

    pub fn deinit(self: *Self) void {
        self.allocator.deinit();
        self.parser.deinit();
    }
};

fn parseName(jsonValue: json.Value, info: *pipelineInfo) void {
    const name_field = jsonValue.object.get("Name").?;
    const name = name_field.string;
    info.name = name;
    // std.log.debug("name {s}", .{info.name});
}

fn parsePipelineType(jsonValue: json.Value, info: *pipelineInfo) void {
    const pipelineType_field = jsonValue.object.get("PipelineType").?;
    const pipelineTypeName = pipelineType_field.string;
    inline for (@typeInfo(pipelineType).@"enum".fields) |field| {
        if (std.mem.eql(u8, pipelineTypeName, field.name)) {
            info.pipeType = @enumFromInt(field.value);
            break;
        }
    }
    // std.log.debug("type {s}", .{@tagName(info.pipeType)});
}

fn parseShaders(jsonValue: json.Value, info: *pipelineInfo) !void {
    const shaders_field = jsonValue.object.get("Shaders").?;
    const shaders = shaders_field.array;

    if (shaders.items.len > 5) return error.TooManyShaderInOnePipeline;

    for (shaders.items, 0..) |shader, i| {
        info.shaders[i] = shader.string;
        // std.log.debug("shader {s}", .{info.shaders[i]});
    }
    info.shaderCount = @intCast(shaders.items.len);
}

fn parseVertexInput(jsonValue: json.Value, info: *pipelineInfo) !void {
    const vertexInput_field = jsonValue.object.get("VertexInput").?;
    const vertexInput_obj = vertexInput_field.object;

    const bindings_field = vertexInput_obj.get("bindings");
    if (bindings_field) |bindings| {
        const array = bindings.array;
        info.vertexInputstatee.bindings = try info.allocator.allocator().alloc(binding, array.items.len);
        for (array.items, 0..) |value, i| {
            info.vertexInputstatee.bindings.?[i].bind = @intCast(value.object.get("binding").?.integer);
            info.vertexInputstatee.bindings.?[i].stride = @intCast(value.object.get("stride").?.integer);
            info.vertexInputstatee.bindings.?[i].inputRate = value.object.get("inputRate").?.string;
        }
    } else {
        info.vertexInputstatee.bindings = null;
    }

    const attributes_field = vertexInput_obj.get("attributes");
    if (attributes_field) |attributes| {
        const array = attributes.array;
        info.vertexInputstatee.attributes = try info.allocator.allocator().alloc(attribute, array.items.len);
        for (array.items, 0..) |value, i| {
            info.vertexInputstatee.attributes.?[i].location = @intCast(value.object.get("location").?.integer);
            info.vertexInputstatee.attributes.?[i].binding = @intCast(value.object.get("binding").?.integer);
            info.vertexInputstatee.attributes.?[i].format = value.object.get("format").?.string;
            info.vertexInputstatee.attributes.?[i].offset = @intCast(value.object.get("offset").?.integer);
        }
    } else {
        info.vertexInputstatee.attributes = null;
    }
}

fn parseInputState(jsonValue: json.Value, info: *pipelineInfo) void {
    const inputState_field = jsonValue.object.get("InputState").?;
    const inputState_obj = inputState_field.object;

    const pNext = inputState_obj.get("pNext");
    if (pNext) |next| {
        if (next != .null) {
            std.log.err("pNext is not supported", .{});
            std.process.abort();
        }
    }
    info.vertexInputstatee.pNext = null;

    info.vertexInputstatee.flag = @intCast(inputState_obj.get("flag").?.integer);
    info.vertexInputstatee.vertexBindingDescriptionCount = @intCast(inputState_obj.get("vertexBindingDescriptionCount").?.integer);
    info.vertexInputstatee.vertexAttributeDescriptionCount = @intCast(inputState_obj.get("vertexAttributeDescriptionCount").?.integer);
}

fn parseInputAssembly(jsonValue: json.Value, info: *pipelineInfo) void {
    const field = jsonValue.object.get("InputAssembly").?;
    const obj = field.object;

    const pNext = obj.get("pNext");
    if (pNext) |next| {
        if (next != .null) {
            std.log.err("pNext is not supported for inputAssembly", .{});
            std.process.abort();
        }
    }

    info.inputAssemblyy = .{
        .pNext = null,
        .flags = @intCast(obj.get("flag").?.integer),
        .topology = obj.get("topology").?.string,
        .primitiveRestartEnable = obj.get("primitiveRestartEnable").?.bool,
    };
}

fn parseTessellationState(jsonValue: json.Value, info: *pipelineInfo) void {
    const field = jsonValue.object.get("TessellationState").?;
    if (field == .null) {
        info.tessellationStatee = null;
        return;
    }

    const obj = field.object;

    const pNext = obj.get("pNext");
    if (pNext) |next| {
        if (next != .null) {
            std.log.err("pNext is not supported for TessellationState", .{});
            std.process.abort();
        }
    }

    info.tessellationStatee = .{
        .pNext = null,
        .flags = @intCast(obj.get("flag").?.integer),
        .patchControlPoints = @intCast(obj.get("patchControlPoints").?.integer),
    };
}

fn parseViewport(obj: json.ObjectMap) viewport {
    return viewport{
        .x = @floatCast(obj.get("x").?.float),
        .y = @floatCast(obj.get("y").?.float),
        .width = @intCast(obj.get("width").?.integer),
        .height = @intCast(obj.get("height").?.integer),
        .minDepth = @floatCast(obj.get("minDepth").?.float),
        .maxDepth = @floatCast(obj.get("maxDepth").?.float),
    };
}
fn parseScissor(obj: json.ObjectMap) scissor {
    const offset = obj.get("offset").?.object;
    const extent = obj.get("extent").?.object;
    return scissor{ .offset = .{
        .x = @intCast(offset.get("x").?.integer),
        .y = @intCast(offset.get("y").?.integer),
    }, .extent = .{
        .width = @intCast(extent.get("width").?.integer),
        .height = @intCast(extent.get("height").?.integer),
    } };
}
fn parseViewportState(jsonValue: json.Value, info: *pipelineInfo) !void {
    const field = jsonValue.object.get("ViewportState").?;
    const obj = field.object;

    const pNext = obj.get("pNext");
    if (pNext) |next| {
        if (next != .null) {
            std.log.err("pNext is not supported for ViewportState", .{});
            std.process.abort();
        }
    }

    const viewports = obj.get("viewports").?.array;
    var vs = try info.allocator.allocator().alloc(viewport, viewports.items.len);
    for (viewports.items, 0..) |val, i| {
        vs[i] = parseViewport(val.object);
    }
    const scissors = obj.get("scissors").?.array;
    var ss = try info.allocator.allocator().alloc(scissor, scissors.items.len);
    for (scissors.items, 0..) |val, i| {
        ss[i] = parseScissor(val.object);
    }

    info.viewportStatee = .{
        .pNext = null,
        .flags = @intCast(obj.get("flag").?.integer),
        .viewports = vs,
        .scissors = ss,
    };
}

fn parseRasterizationState(jsonValue: json.Value, info: *pipelineInfo) void {
    const field = jsonValue.object.get("RasterizationState").?;
    const obj = field.object;

    const pNext = obj.get("pNext");
    if (pNext) |next| {
        if (next != .null) {
            std.log.err("pNext is not supported for rasterizationState", .{});
            std.process.abort();
        }
    }

    info.rasterizationStatee = .{
        .pNext = null,
        .flags = @intCast(obj.get("flag").?.integer),
        .depthClampEnable = obj.get("depthClampEnable").?.bool,
        .rasterizerDiscardEnable = obj.get("rasterizerDiscardEnable").?.bool,
        .polygonMode = obj.get("polygonMode").?.string,
        .cullMode = obj.get("cullMode").?.string,
        .frontFace = obj.get("frontFace").?.string,
        .depthBiasEnable = obj.get("depthBiasEnable").?.bool,
        .depthBiasConstantFactor = @floatCast(obj.get("depthBiasConstantFactor").?.float),
        .depthBiasClamp = @floatCast(obj.get("depthBiasClamp").?.float),
        .depthBiasSlopeFactor = @floatCast(obj.get("depthBiasSlopeFactor").?.float),
        .lineWidth = @floatCast(obj.get("lineWidth").?.float),
    };
}

fn parseMultisampleState(jsonValue: json.Value, info: *pipelineInfo) void {
    const field = jsonValue.object.get("MultisampleState").?;
    const obj = field.object;

    const pNext = obj.get("pNext");
    if (pNext) |next| {
        if (next != .null) {
            std.log.err("pNext is not supported for multisampleState", .{});
            std.process.abort();
        }
    }

    info.multisampleStatee = .{
        .pNext = null,
        .flags = @intCast(obj.get("flag").?.integer),
        .rasterizationSamples = obj.get("rasterizationSamples").?.string,
        .sampleShadingEnable = obj.get("sampleShadingEnable").?.bool,
        .minSampleShading = @floatCast(obj.get("minSampleShading").?.float),
        .alphaToCoverageEnable = obj.get("alphaToCoverageEnable").?.bool,
        .alphaToOneEnable = obj.get("alphaToOneEnable").?.bool,
    };
}

fn parseStencilOpState(value: json.Value) stencilOpState {
    const obj = value.object;
    return .{
        .failOp = obj.get("failOp").?.string,
        .passOp = obj.get("passOp").?.string,
        .depthFailOp = obj.get("depthFailOp").?.string,
        .compareOp = obj.get("compareOp").?.string,
        .compareMask = @intCast(obj.get("compareMask").?.integer),
        .writeMask = @intCast(obj.get("writeMask").?.integer),
        .reference = @intCast(obj.get("reference").?.integer),
    };
}

fn parseDepthStencilState(jsonValue: json.Value, info: *pipelineInfo) void {
    const field = jsonValue.object.get("DepthStencilState").?;
    const obj = field.object;

    const pNext = obj.get("pNext");
    if (pNext) |next| {
        if (next != .null) {
            std.log.err("pNext is not supported for depthStencilState", .{});
            std.process.abort();
        }
    }

    var back: ?stencilOpState = null;
    if (obj.get("back")) |back_val| {
        if (back_val != .null) {
            back = parseStencilOpState(back_val);
        }
    }
    var front: ?stencilOpState = null;
    if (obj.get("front")) |front_val| {
        if (front_val != .null) {
            front = parseStencilOpState(front_val);
        }
    }

    info.depthStencilStatee = .{
        .pNext = null,
        .flags = @intCast(obj.get("flag").?.integer),
        .depthTestEnable = obj.get("depthTestEnable").?.bool,
        .depthWriteEnable = obj.get("depthWriteEnable").?.bool,
        .depthCompareOp = obj.get("depthCompareOp").?.string,
        .depthBoundsTestEnable = obj.get("depthBoundsTestEnable").?.bool,
        .stencilTestEnable = obj.get("stencilTestEnable").?.bool,
        .front = front,
        .back = back,
        .minDepthBounds = @floatCast(obj.get("minDepthBounds").?.float),
        .maxDepthBounds = @floatCast(obj.get("maxDepthBounds").?.float),
    };
}

fn parseColorBlendState(jsonValue: json.Value, info: *pipelineInfo) !void {
    const field = jsonValue.object.get("ColorBlendState").?;
    const obj = field.object;

    const pNext = obj.get("pNext");
    if (pNext) |next| {
        if (next != .null) {
            std.log.err("pNext is not supported for colorBlendState", .{});
            std.process.abort();
        }
    }

    const attachments_array = obj.get("attachments").?.array;
    const attachments_slice = try info.allocator.allocator().alloc(colorBlendAttachmentState, attachments_array.items.len);

    for (attachments_array.items, 0..) |item, i| {
        const attach_obj = item.object;
        const mask_array = attach_obj.get("colorWriteMask").?.array;
        const mask_slice = try info.allocator.allocator().alloc([]const u8, mask_array.items.len);
        for (mask_array.items, 0..) |mask_item, j| {
            mask_slice[j] = mask_item.string;
        }

        attachments_slice[i] = .{
            .blendEnable = attach_obj.get("blendEnable").?.bool,
            .srcColorBlendFactor = attach_obj.get("srcColorBlendFactor").?.string,
            .dstColorBlendFactor = attach_obj.get("dstColorBlendFactor").?.string,
            .colorBlendOp = attach_obj.get("colorBlendOp").?.string,
            .srcAlphaBlendFactor = attach_obj.get("srcAlphaBlendFactor").?.string,
            .dstAlphaBlendFactor = attach_obj.get("dstAlphaBlendFactor").?.string,
            .alphaBlendOp = attach_obj.get("alphaBlendOp").?.string,
            .colorWriteMask = mask_slice,
        };
    }

    const constants_array = obj.get("blendConstants").?.array;
    var blend_constants: [4]f32 = undefined;
    for (constants_array.items, 0..) |item, i| {
        blend_constants[i] = @floatCast(item.float);
    }

    info.colorBlendStatee = .{
        .pNext = null,
        .flags = @intCast(obj.get("flag").?.integer),
        .logicOpEnable = obj.get("logicOpEnable").?.bool,
        .logicOp = obj.get("logicOp").?.string,
        .attachments = attachments_slice,
        .blendConstants = blend_constants,
    };
}

fn parseDynamicStates(jsonValue: json.Value, info: *pipelineInfo) !void {
    const field = jsonValue.object.get("DynamicStates").?;
    const obj = field.object;

    const pNext = obj.get("pNext");
    if (pNext) |next| {
        if (next != .null) {
            std.log.err("pNext is not supported for dynamicStates", .{});
            std.process.abort();
        }
    }

    const states_array = obj.get("States").?.array;
    const states_slice = try info.allocator.allocator().alloc([]const u8, states_array.items.len);
    for (states_array.items, 0..) |item, i| {
        states_slice[i] = item.string;
    }

    info.dynamicStatess.pNext = null;
    info.dynamicStatess.States = states_slice;
}

fn parseRendering(jsonValue: json.Value, info: *pipelineInfo) void {
    const field = jsonValue.object.get("PipelineRendering").?;
    if (field == .null) {
        info.rendering = null;
    } else {
        const obj = field.object;
        const color = obj.get("color").?;
        if (color == .null) {
            info.rendering.?.colorAttachmentCount = 0;
        } else {
            const array = color.array;
            if (array.items.len > 10) {
                std.debug.panic("not supported", .{});
            }
            for (array.items, 0..) |value, i| {
                info.rendering.?.colorAttachment[i] = value.string;
            }
            info.rendering.?.colorAttachmentCount = @intCast(array.items.len);
        }
        info.rendering.?.depthAttachment = obj.get("depth").?.string;
        info.rendering.?.stencilAttachment = obj.get("stencil").?.string;
    }
}

pub fn parse(content: []const u8, allocator: std.mem.Allocator) !pipelineInfo {
    var res: pipelineInfo = undefined;

    const parser = try json.parseFromSlice(json.Value, allocator, content, .{});
    res.parser = parser;
    res.allocator = std.heap.ArenaAllocator.init(allocator);

    const jsonValue = parser.value;

    if (jsonValue == .object) {
        parseName(jsonValue, &res);
        parsePipelineType(jsonValue, &res);
        try parseShaders(jsonValue, &res);
        try parseVertexInput(jsonValue, &res);
        parseInputState(jsonValue, &res);
        parseInputAssembly(jsonValue, &res);
        parseTessellationState(jsonValue, &res);
        try parseViewportState(jsonValue, &res);
        parseRasterizationState(jsonValue, &res);
        parseMultisampleState(jsonValue, &res);
        parseDepthStencilState(jsonValue, &res);
        try parseColorBlendState(jsonValue, &res);
        try parseDynamicStates(jsonValue, &res);
        parseRendering(jsonValue, &res);
    }

    return res;
}
