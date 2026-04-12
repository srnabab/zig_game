pub const cgltf = @cImport(@cInclude("cgltf/cgltf.h"));

const std = @import("std");

const vertexStruct = @import("vertexStruct");

const enumFromC = @import("enumFromC");

const UUID = @import("UUID");

const cgltf_result = enumFromC.generateEnumFromC(
    cgltf,
    cgltf.cgltf_result,
    "cgltf_result_success",
    "cgltf_result_max_enum",
);
const cgltf_compent_type = enumFromC.generateEnumFromC(
    cgltf,
    cgltf.cgltf_component_type,
    "cgltf_component_type_invalid",
    "cgltf_component_type_max_enum",
);
const cgltf_type = enumFromC.generateEnumFromC(
    cgltf,
    cgltf.cgltf_type,
    "cgltf_type_invalid",
    "cgltf_type_max_enum",
);
const cgltf_attribute_type = enumFromC.generateEnumFromC(
    cgltf,
    cgltf.cgltf_attribute_type,
    "cgltf_attribute_type_invalid",
    "cgltf_attribute_type_max_enum",
);

const cgltf_error = error{
    cgltf_result_data_too_short,
    cgltf_result_unknown_format,
    cgltf_result_invalid_json,
    cgltf_result_invalid_gltf,
    cgltf_result_invalid_options,
    cgltf_result_file_not_found,
    cgltf_result_io_error,
    cgltf_result_out_of_memory,
    cgltf_result_legacy_gltf,
    cgltf_result_max_enum,
};

fn cgltf_parse(
    option: [*c]cgltf.cgltf_options,
    buffer: ?*const anyopaque,
    arg_size: usize,
    arg_out_data: [*c][*c]cgltf.cgltf_data,
) !void {
    const res: cgltf_result =
        @enumFromInt(
            cgltf.cgltf_parse(option, buffer, arg_size, arg_out_data),
        );

    if (res == .cgltf_result_success) {
        return;
    }

    const fields = @typeInfo(cgltf_error);
    inline for (fields.error_set.?) |field| {
        if (res == @field(cgltf_result, field.name)) {
            return @field(cgltf_error, field.name);
        }
    }
}

pub fn loadGltfFile(fileMem: []const u8, fileStat: std.fs.File.Stat, allocator: std.mem.Allocator) !struct {
    // name: []u8,
    vertex: vertexStruct.Vertex,
} {
    // var gltf = try std.fs.cwd().openFile(fileName, .{});
    // defer gltf.close();

    // const fileStat = try gltf.stat();
    // const fileMem = try allocator.alloc(u8, fileStat.size);
    // defer allocator.free(fileMem);
    // _ = try gltf.readAll(fileMem);

    var options = cgltf.cgltf_options{};

    var data: [*c]cgltf.cgltf_data = null;
    try cgltf_parse(&options, fileMem.ptr, fileStat.size, &data);
    defer cgltf.cgltf_free(data);

    _ = cgltf.cgltf_load_buffers(&options, data, null);
    // std.log.debug("{}", .{data.*});

    const scenes = data.*.scenes;
    const scenes_count = data.*.scenes_count;
    for (0..scenes_count) |i| {
        const scene = scenes[i];
        const scene_name = blk: {
            if (scene.name) |name| {
                const len = std.mem.len(name);

                break :blk try allocator.dupe(u8, name[0..len]);
            } else {
                const buf = try allocator.alloc(u8, UUID.len);
                try UUID.createNewUUID(buf.ptr);
                break :blk buf;
            }
        };
        defer allocator.free(scene_name);
        std.log.debug("scene name: {s}", .{scene_name});

        const nodes = scene.nodes;
        const nodes_count = scene.nodes_count;
        for (0..nodes_count) |j| {
            const node = nodes[j];
            const mesh = node.*.mesh;

            const primitives = mesh.*.primitives;
            const primitives_count = mesh.*.primitives_count;
            for (0..primitives_count) |l| {
                const primitive = primitives[l];
                const attributes = primitive.attributes;
                const attributes_count = primitive.attributes_count;
                _ = attributes;
                _ = attributes_count;
            }
        }
    }

    const attributes_count = data.*.meshes[0].primitives[0].attributes_count;
    const attributes = data.*.meshes[0].primitives[0].attributes;

    for (0..attributes_count) |i| {
        const type_enum: cgltf_attribute_type = @enumFromInt(attributes[i].type);
        // std.log.debug("type {s}", .{@tagName(type_enum)});
        switch (type_enum) {
            .cgltf_attribute_type_position => {
                for (0..attributes[i].data.*.count) |j| {
                    var pos: [3]f32 = undefined;

                    _ = cgltf.cgltf_accessor_read_float(&data.*.accessors[i], j, &pos, 3);
                    // std.log.debug("{d}, {d}, {d}", .{ pos[0], pos[1], pos[2] });
                }
            },
            .cgltf_attribute_type_normal => {
                for (0..attributes[i].data.*.count) |j| {
                    var pos: [3]f32 = undefined;

                    _ = cgltf.cgltf_accessor_read_float(&data.*.accessors[i], j, &pos, 3);
                    // std.log.debug("{d}, {d}, {d}", .{ pos[0], pos[1], pos[2] });
                }
            },
            .cgltf_attribute_type_texcoord => {
                for (0..attributes[i].data.*.count) |j| {
                    var pos: [2]f32 = undefined;

                    _ = cgltf.cgltf_accessor_read_float(&data.*.accessors[i], j, &pos, 2);
                    // std.log.debug("{d}, {d}", .{ pos[0], pos[1] });
                }
            },
            else => {
                std.debug.panic("{s} not supported", .{@tagName(type_enum)});
            },
        }
    }

    for (0..data.*.meshes[0].primitives[0].indices.*.count) |i| {
        const index = cgltf.cgltf_accessor_read_index(data.*.meshes[0].primitives[0].indices, i);
        _ = index;
        // std.log.debug("{d}", .{index});
    }

    // for (0..data.*.accessors_count) |i| {
    //     std.log.debug("component type {s}, type {s}, offset {d}, count {d}, stride {d}, size {d}", .{
    //         @tagName(@as(cgltf_compent_type, @enumFromInt(data.*.accessors[i].component_type))),
    //         @tagName(@as(cgltf_type, @enumFromInt(data.*.accessors[i].type))),
    //         data.*.accessors[i].offset,
    //         data.*.accessors[i].count,
    //         data.*.accessors[i].stride,
    //         data.*.accessors[i].buffer_view.*.size,
    //     });
    // }
    const vType = judgePrimitiveVertexType(&data.*.meshes[0].primitives[0]);
    std.log.debug("{s}", .{@tagName(vType)});
    return .{
        // .name = " ",
        .vertex = vertexStruct.Vertex{ .f3pf3nf2u = &.{} },
    };
}

const Flag_VertexType = struct {
    flag: u64,
    _type: vertexStruct.VertexType,
};
const list = [_]Flag_VertexType{
    .{ .flag = 0x8000000000000000, ._type = vertexStruct.VertexType.f3p },
    .{ .flag = 0xC000000000000000, ._type = vertexStruct.VertexType.f3pf3n },
    .{ .flag = 0xA000000000000000, ._type = vertexStruct.VertexType.f3pf2u },
    .{ .flag = 0xE000000000000000, ._type = vertexStruct.VertexType.f3pf3nf2u },
};

pub fn judgePrimitiveVertexType(primitives: [*c]cgltf.cgltf_primitive) vertexStruct.VertexType {
    const attributes_count = primitives.*.attributes_count;
    const attributes = primitives.*.attributes;

    const FlagLength = 1 + 1 + 8 + 8 + 8 + 8 + 30;

    const Position = FlagLength - 1;
    const Normal = Position - 1;
    const TexCoordStart = Normal - 1;
    const ColorStart = TexCoordStart - 8;
    const JointStart = ColorStart - 8;
    const WeightStart = JointStart - 8;

    const FlagType = std.bit_set.IntegerBitSet(FlagLength);
    var flag = FlagType.initEmpty();

    // const p = 0x8000000000000000;
    // const pn = 0xC000000000000000;
    // const pt = 0xA000000000000000;
    // const pnt = 0xE000000000000000;

    var texcoordsCount: u32 = 0;

    var colorCount: u32 = 0;

    var jointsCount: u32 = 0;

    var weightsCount: u32 = 0;

    for (0..attributes_count) |i| {
        const type_enum: cgltf_attribute_type = @enumFromInt(attributes[i].type);
        std.log.debug("type {s}", .{@tagName(type_enum)});
        switch (type_enum) {
            .cgltf_attribute_type_position => {
                flag.set(Position);
            },
            .cgltf_attribute_type_normal => {
                flag.set(Normal);
            },
            .cgltf_attribute_type_texcoord => {
                flag.set(TexCoordStart - texcoordsCount);
                texcoordsCount += 1;

                if (texcoordsCount >= 16) {
                    std.debug.panic("too much texcoord(over 16)", .{});
                }
            },
            .cgltf_attribute_type_color => {
                flag.set(ColorStart - colorCount);
                colorCount += 1;

                if (colorCount >= 16) {
                    std.debug.panic("too much color(over 16)", .{});
                }
            },
            .cgltf_attribute_type_joints => {
                flag.set(JointStart - jointsCount);
                jointsCount += 1;

                if (jointsCount >= 16) {
                    std.debug.panic("too much joint(over 16)", .{});
                }
            },
            .cgltf_attribute_type_weights => {
                flag.set(WeightStart - weightsCount);
                weightsCount += 1;

                if (weightsCount >= 16) {
                    std.debug.panic("too much weight(over 16)", .{});
                }
            },
            else => {
                std.debug.panic("{s} not supported", .{@tagName(type_enum)});
            },
        }
    }

    inline for (list) |value| {
        if (value.flag ^ flag.mask == 0) {
            return value._type;
        }
    }

    return .none;
}

fn autoName() ![]u8 {
    const randInt = std.crypto.random.int(u32);
    _ = randInt;
}
