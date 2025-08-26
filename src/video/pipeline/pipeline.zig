const std = @import("std");
const json = std.json;
const fs = std.fs;
const file = @import("fileSystem");
const global = @import("global");

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

const vertexInput = struct {
    bindings: ?[]binding,
    attributes: ?[]attribute,
};

const testStruct = struct { a: u32, pNext: ?*inputStatepNext };
const testStruct2 = struct { b: u32, pNext: ?*inputStatepNext };

const inputStatepNext = union { a: testStruct, b: testStruct2 };

const inputState = struct {
    pNext: ?inputStatepNext,
    flag: u32,
    vertexBindingDescriptionCount: u32,
    vertexAttributeDescriptionCount: u32,
};
const inputAssemblyPNext = union {}; // New union for inputAssembly
const inputAssembly = struct {
    pNext: ?inputAssemblyPNext = null,
    flags: u32,
    topology: []const u8,
    primitiveRestartEnable: bool,
};

const tessellationStatePNext = union {}; // New union for tessellationState
const tessellationState = struct {
    pNext: ?tessellationStatePNext = null,
    flags: u32,
    patchControlPoints: u32,
};

const viewportStatePNext = union {}; // New union for viewportState
const viewportState = struct {
    pNext: ?viewportStatePNext = null,
    flags: u32,
    viewportCount: u32,
    scissorCount: u32,
};

const rasterizationStatePNext = union {}; // New union for rasterizationState
const rasterizationState = struct {
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

const multisampleStatePNext = union {}; // New union for multisampleState
const multisampleState = struct {
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

const depthStencilStatePNext = union {}; // New union for depthStencilState
const depthStencilState = struct {
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

const colorBlendAttachmentState = struct {
    blendEnable: bool,
    srcColorBlendFactor: []const u8,
    dstColorBlendFactor: []const u8,
    colorBlendOp: []const u8,
    srcAlphaBlendFactor: []const u8,
    dstAlphaBlendFactor: []const u8,
    alphaBlendOp: []const u8,
    colorWriteMask: []const []const u8,
};

const colorBlendStatePNext = union {}; // New union for colorBlendState
const colorBlendState = struct {
    pNext: ?colorBlendStatePNext = null,
    flags: u32,
    logicOpEnable: bool,
    logicOp: []const u8,
    attachments: []colorBlendAttachmentState,
    blendConstants: [4]f32,
};

const dynamicStatesPNext = union {}; // New union for dynamicStates
const dynamicStates = struct {
    pNext: ?dynamicStatesPNext = null,
    flags: u32,
    States: [][]const u8,
};

pub const pipelineInfo = struct {
    const Self = @This();

    allocator: std.heap.ArenaAllocator,
    parser: std.json.Parsed(json.Value),
    name: []const u8,
    pipeType: pipelineType,
    shaders: [5][]const u8,
    vertexInputt: vertexInput,
    inputStatee: inputState,
    inputAssemblyy: inputAssembly,
    tessellationStatee: tessellationState,
    viewportStatee: viewportState,
    rasterizationStatee: rasterizationState,
    multisampleStatee: multisampleState,
    depthStencilStatee: depthStencilState,
    colorBlendStatee: colorBlendState,
    dynamicStatess: dynamicStates,

    pub fn deinit(self: *Self) void {
        self.allocator.deinit();
        self.parser.deinit();
    }
};

fn parseName(jsonValue: json.Value, info: *pipelineInfo) void {
    const name_field = jsonValue.object.get("name").?;
    const name = name_field.string;
    info.name = name;
    std.log.debug("name {s}", .{info.name});
}

fn parsePipelineType(jsonValue: json.Value, info: *pipelineInfo) void {
    const pipelineType_field = jsonValue.object.get("pipelineType").?;
    const pipelineTypeName = pipelineType_field.string;
    inline for (@typeInfo(pipelineType).@"enum".fields) |field| {
        if (std.mem.eql(u8, pipelineTypeName, field.name)) {
            info.pipeType = @enumFromInt(field.value);
            break;
        }
    }
    std.log.debug("type {s}", .{@tagName(info.pipeType)});
}

fn parseShaders(jsonValue: json.Value, info: *pipelineInfo) !void {
    const shaders_field = jsonValue.object.get("shaders").?;
    const shaders = shaders_field.array;

    if (shaders.items.len > 5) return error.TooManyShaderInOnePipeline;

    for (shaders.items, 0..) |shader, i| {
        info.shaders[i] = shader.string;
        std.log.debug("shader {s}", .{info.shaders[i]});
    }
}

fn parseVertexInput(jsonValue: json.Value, info: *pipelineInfo) !void {
    const vertexInput_field = jsonValue.object.get("vertexInput").?;
    const vertexInput_obj = vertexInput_field.object;

    const bindings_field = vertexInput_obj.get("bindings");
    if (bindings_field) |bindings| {
        const array = bindings.array;
        info.vertexInputt.bindings = try info.allocator.allocator().alloc(binding, array.items.len);
        for (array.items, 0..) |value, i| {
            info.vertexInputt.bindings.?[i].bind = @intCast(value.object.get("binding").?.integer);
            info.vertexInputt.bindings.?[i].stride = @intCast(value.object.get("stride").?.integer);
            info.vertexInputt.bindings.?[i].inputRate = value.object.get("inputRate").?.string;
        }
    } else {
        info.vertexInputt.bindings = null;
    }

    const attributes_field = vertexInput_obj.get("attributes");
    if (attributes_field) |attributes| {
        const array = attributes.array;
        info.vertexInputt.attributes = try info.allocator.allocator().alloc(attribute, array.items.len);
        for (array.items, 0..) |value, i| {
            info.vertexInputt.attributes.?[i].location = @intCast(value.object.get("location").?.integer);
            info.vertexInputt.attributes.?[i].binding = @intCast(value.object.get("binding").?.integer);
            info.vertexInputt.attributes.?[i].format = value.object.get("format").?.string;
            info.vertexInputt.attributes.?[i].offset = @intCast(value.object.get("offset").?.integer);
        }
    } else {
        info.vertexInputt.attributes = null;
    }
}

fn parseInputState(jsonValue: json.Value, info: *pipelineInfo) void {
    const inputState_field = jsonValue.object.get("inputState").?;
    const inputState_obj = inputState_field.object;

    const pNext = inputState_obj.get("pNext");
    if (pNext) |next| {
        if (next != .null) {
            std.log.err("pNext is not supported", .{});
            std.process.abort();
        }
    }
    info.inputStatee.pNext = null;

    info.inputStatee.flag = @intCast(inputState_obj.get("flag").?.integer);
    info.inputStatee.vertexBindingDescriptionCount = @intCast(inputState_obj.get("vertexBindingDescriptionCount").?.integer);
    info.inputStatee.vertexAttributeDescriptionCount = @intCast(inputState_obj.get("vertexAttributeDescriptionCount").?.integer);
}

fn parseInputAssembly(jsonValue: json.Value, info: *pipelineInfo) void {
    const field = jsonValue.object.get("inputAssembly").?;
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

fn parseViewportState(jsonValue: json.Value, info: *pipelineInfo) void {
    const field = jsonValue.object.get("ViewportState").?;
    const obj = field.object;

    const pNext = obj.get("pNext");
    if (pNext) |next| {
        if (next != .null) {
            std.log.err("pNext is not supported for ViewportState", .{});
            std.process.abort();
        }
    }

    info.viewportStatee = .{
        .pNext = null,
        .flags = @intCast(obj.get("flag").?.integer),
        .viewportCount = @intCast(obj.get("viewportCount").?.integer),
        .scissorCount = @intCast(obj.get("scissorCount").?.integer),
    };
}

fn parseRasterizationState(jsonValue: json.Value, info: *pipelineInfo) void {
    const field = jsonValue.object.get("rasterizationState").?;
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
    const field = jsonValue.object.get("multisampleState").?;
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
    const field = jsonValue.object.get("depthStencilState").?;
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
    const field = jsonValue.object.get("colorBlendState").?;
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
    const field = jsonValue.object.get("dynamicStates").?;
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

pub fn parse(pipelineFileName: []const u8) !pipelineInfo {
    const pipelineFile = try file.getFile(pipelineFileName);
    defer pipelineFile.close();

    var res: pipelineInfo = undefined;

    const metadata = try pipelineFile.metadata();
    var content = try global.gpa.alloc(u8, metadata.size());
    defer global.gpa.free(content);

    _ = try pipelineFile.readAll(content[0..metadata.size()]);

    const parser = try json.parseFromSlice(json.Value, global.gpa, content, .{});
    res.parser = parser;
    res.allocator = std.heap.ArenaAllocator.init(global.gpa);

    const jsonValue = parser.value;

    if (jsonValue == .object) {
        parseName(jsonValue, &res);

        parsePipelineType(jsonValue, &res);

        try parseShaders(jsonValue, &res);

        try parseVertexInput(jsonValue, &res);

        parseInputState(jsonValue, &res);

        parseInputAssembly(jsonValue, &res);

        parseTessellationState(jsonValue, &res);

        parseViewportState(jsonValue, &res);

        parseRasterizationState(jsonValue, &res);

        parseMultisampleState(jsonValue, &res);

        parseDepthStencilState(jsonValue, &res);

        try parseColorBlendState(jsonValue, &res);

        try parseDynamicStates(jsonValue, &res);
    }

    return res;
}
