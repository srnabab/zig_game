pub const cgltf = @cImport(@cInclude("cgltf/cgltf.h"));

const std = @import("std");

const vertexStruct = @import("vertexStruct");
const vec3 = vertexStruct.vec3;
const vec2 = vertexStruct.vec2;
const mat3 = vertexStruct.mat3;
const mat4 = vertexStruct.mat4;

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

const Node = struct {
    name: []u8,
    primitiveNames: [][]u8,
    transform: vertexStruct.mat4,
};

pub const Scene = struct {
    name: []u8,
    nodes: []Node,
};

const Primitive = struct {
    name: []u8,
    vertex: vertexStruct.Vertex,
    index: []u32,
};

fn getName(name: [*c]u8, allocator: std.mem.Allocator) ![]u8 {
    if (name) |n| {
        const len = std.mem.len(n);

        return try allocator.dupe(u8, n[0..len]);
    } else {
        const buf = try allocator.alloc(u8, UUID.len);
        try UUID.createNewUUID(buf.ptr);
        return buf;
    }
}

fn setTransform(node: [*c]cgltf.cgltf_node, nodePtr: *Node) void {
    if (node.*.has_matrix == 1) {
        for (0..nodePtr.transform.len, 0..) |i, k| {
            nodePtr.transform[i][0] = node.*.matrix[k * 4 + 0];
            nodePtr.transform[i][1] = node.*.matrix[k * 4 + 1];
            nodePtr.transform[i][2] = node.*.matrix[k * 4 + 2];
            nodePtr.transform[i][3] = node.*.matrix[k * 4 + 3];
        }
    } else {
        var matrix: vertexStruct.mat3 align(16) = undefined;
        vertexStruct.cglm.glmc_mat3_identity(&matrix);

        if (node.*.has_rotation == 1) {
            var rotation: vertexStruct.vec4 align(16) = node.*.rotation;
            vertexStruct.cglm.glmc_quat_mat3(&rotation, &matrix);
        }

        if (node.*.has_scale == 1) {
            vertexStruct.cglm.glmc_vec3_scale(&matrix[0], node.*.scale[0], &matrix[0]);
            vertexStruct.cglm.glmc_vec3_scale(&matrix[1], node.*.scale[1], &matrix[1]);
            vertexStruct.cglm.glmc_vec3_scale(&matrix[2], node.*.scale[2], &matrix[2]);
        }

        if (node.*.has_translation == 1) {
            nodePtr.transform[3][0] = node.*.translation[0];
            nodePtr.transform[3][1] = node.*.translation[1];
            nodePtr.transform[3][2] = node.*.translation[2];
        } else {
            nodePtr.transform[3][0] = 0.0;
            nodePtr.transform[3][1] = 0.0;
            nodePtr.transform[3][2] = 0.0;
        }

        nodePtr.transform[0][3] = 0.0;
        nodePtr.transform[1][3] = 0.0;
        nodePtr.transform[2][3] = 0.0;
        nodePtr.transform[3][3] = 1.0;

        for (matrix, 0..) |value, k| {
            nodePtr.transform[k][0] = value[0];
            nodePtr.transform[k][1] = value[1];
            nodePtr.transform[k][2] = value[2];
        }
    }
}

pub fn loadGltfFile(fileMem: []const u8, fileStat: std.fs.File.Stat, allocator: std.mem.Allocator) !struct {
    scenes: []Scene,
    primitives: []Primitive,
    arenaAllocator: std.heap.ArenaAllocator,
} {
    var options = cgltf.cgltf_options{};

    var data: [*c]cgltf.cgltf_data = null;
    try cgltf_parse(&options, fileMem.ptr, fileStat.size, &data);
    defer cgltf.cgltf_free(data);

    var arenAllocator = std.heap.ArenaAllocator.init(allocator);
    const arena = arenAllocator.allocator();
    errdefer arenAllocator.deinit();

    var primitive_array: std.array_list.Managed(Primitive) = .init(arena);
    defer primitive_array.deinit();

    var node_array: std.array_list.Managed(Node) = .init(arena);
    defer node_array.deinit();

    var name_array: std.array_list.Managed([]u8) = .init(arena);
    defer name_array.deinit();

    _ = cgltf.cgltf_load_buffers(&options, data, null);
    // std.log.debug("{}", .{data.*});

    const startMeshPtr = data.*.meshes;
    const meshProcessed = try arena.alloc(bool, data.*.meshes_count);
    defer arena.free(meshProcessed);

    const scenes = data.*.scenes;
    const scenes_count = data.*.scenes_count;

    var scene_array = try arena.alloc(Scene, scenes_count);

    for (0..scenes_count) |i| {
        const scene = scenes[i];
        const scene_name = try getName(scene.name, arena);

        std.log.debug("scene name: {s}", .{scene_name});

        scene_array[i].name = scene_name;

        const nodes = scene.nodes;
        const nodes_count = scene.nodes_count;

        try node_array.ensureTotalCapacity(nodes_count);

        for (0..nodes_count) |j| {
            const node = nodes[j];
            const node_name = try getName(node.*.name, arena);

            const nodePtr = node_array.addOneAssumeCapacity();
            nodePtr.name = node_name;

            setTransform(node, nodePtr);

            const mesh = node.*.mesh;
            const meshIndex = mesh - startMeshPtr;

            const mesh_name = try getName(mesh.*.name, arena);

            const primitives = mesh.*.primitives;
            const primitives_count = mesh.*.primitives_count;

            try primitive_array.ensureTotalCapacity(primitives_count);

            for (0..primitives_count) |l| {
                const primitive = &primitives[l];
                const primitive_name_mem = try arena.alloc(u8, mesh_name.len + 4);
                const primitive_name = try std.fmt.bufPrint(primitive_name_mem, "{s}_{d}", .{ mesh_name, l });

                try name_array.append(primitive_name);

                if (meshProcessed[meshIndex]) {
                    continue;
                }

                const primPtr = primitive_array.addOneAssumeCapacity();
                primPtr.name = primitive_name;

                const attributes = primitive.*.attributes;
                const attributes_count = primitive.*.attributes_count;

                const vertexCount = attributes[0].data.*.count;

                const vType = judgePrimitiveVertexType(&primitives[l]);
                std.log.debug("{s}", .{@tagName(vType)});

                primPtr.vertex = try allocVertex(vType, arena, @intCast(vertexCount));

                for (0..attributes_count) |o| {
                    const type_enum: cgltf_attribute_type = @enumFromInt(attributes[o].type);
                    switch (type_enum) {
                        .cgltf_attribute_type_position => {
                            for (0..attributes[o].data.*.count) |p| {
                                var pos: vertexStruct.vec3 = undefined;
                                _ = cgltf.cgltf_accessor_read_float(&data.*.accessors[o], p, &pos, 3);

                                setValue(
                                    primPtr.vertex,
                                    p,
                                    &pos,
                                    "position",
                                );
                            }
                        },
                        .cgltf_attribute_type_normal => {
                            for (0..attributes[o].data.*.count) |p| {
                                var pos: vec3 = undefined;
                                _ = cgltf.cgltf_accessor_read_float(&data.*.accessors[o], p, &pos, 3);

                                setValue(
                                    primPtr.vertex,
                                    p,
                                    &pos,
                                    "normal",
                                );
                            }
                        },
                        .cgltf_attribute_type_texcoord => {
                            for (0..attributes[o].data.*.count) |p| {
                                var pos: vec2 = undefined;
                                _ = cgltf.cgltf_accessor_read_float(&data.*.accessors[o], p, &pos, 2);

                                setValue(
                                    primPtr.vertex,
                                    p,
                                    &pos,
                                    "uv",
                                );
                            }
                        },
                        else => {
                            std.debug.panic("{s} not supported", .{@tagName(type_enum)});
                        },
                    }
                }

                primPtr.index = try arena.alloc(u32, primitive.*.indices.*.count);
                for (0..primitive.*.indices.*.count) |o| {
                    primPtr.index[o] = @intCast(cgltf.cgltf_accessor_read_index(primitive.*.indices, o));
                }
            }

            meshProcessed[meshIndex] = true;

            nodePtr.primitiveNames = try name_array.toOwnedSlice();
        }

        scene_array[i].nodes = try node_array.toOwnedSlice();
    }

    return .{
        .arenaAllocator = arenAllocator,
        .primitives = try primitive_array.toOwnedSlice(),
        .scenes = scene_array,
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

pub fn printVertex(vertex: vertexStruct.Vertex, indices: []u32) void {
    switch (vertex) {
        .f3p => |v| {
            for (indices) |i| {
                std.log.debug("({d}, {d}, {d})", .{
                    v[i].position[0],
                    v[i].position[1],
                    v[i].position[2],
                });
            }
        },
        .f3pf2u => |v| {
            for (indices) |i| {
                std.log.debug("({d}, {d}, {d}), ({d}, {d})", .{
                    v[i].position[0],
                    v[i].position[1],
                    v[i].position[2],
                    v[i].uv[0],
                    v[i].uv[1],
                });
            }
        },
        .f3pf3n => |v| {
            for (indices) |i| {
                std.log.debug("({d}, {d}, {d}), ({d}, {d}, {d})", .{
                    v[i].position[0],
                    v[i].position[1],
                    v[i].position[2],
                    v[i].normal[0],
                    v[i].normal[1],
                    v[i].normal[2],
                });
            }
        },
        .f3pf3nf2u => |v| {
            for (indices) |i| {
                std.log.debug("({d}, {d}, {d}), ({d}, {d}, {d}), ({d}, {d})", .{
                    v[i].position[0],
                    v[i].position[1],
                    v[i].position[2],
                    v[i].normal[0],
                    v[i].normal[1],
                    v[i].normal[2],
                    v[i].uv[0],
                    v[i].uv[1],
                });
            }
        },
        .none => {
            std.log.debug("unknow vertex type", .{});
        },
    }
}

pub const VertexPack = struct {
    vertices: *anyopaque,
    vertexCount: u32,
    vertexSize: u32,
};

pub fn unpackVertex(vertex: vertexStruct.Vertex) VertexPack {
    switch (vertex) {
        .none => {
            std.log.debug("unknow vertex type", .{});
            return .{
                .vertices = undefined,
                .vertexCount = 0,
                .vertexSize = 0,
            };
        },
        inline else => |v| {
            const info = @typeInfo(@TypeOf(v));
            return .{
                .vertices = v.ptr,
                .vertexCount = @intCast(v.len),
                .vertexSize = @sizeOf(info.pointer.child),
            };
        },
    }
}

pub fn packVertex(pack: VertexPack, vType: vertexStruct.VertexType) vertexStruct.Vertex {
    switch (vType) {
        .none => {
            std.log.debug("unknow vertex type", .{});
            return .none;
        },
        inline else => |tag| {
            const struct_name = "Vertex_" ++ @tagName(tag);
            const VertexType: type = @field(vertexStruct, struct_name);
            std.log.debug("{s} {d} - {d}", .{ @typeName(VertexType), @sizeOf(VertexType), pack.vertexSize });
            std.debug.assert(@sizeOf(VertexType) == pack.vertexSize);
            const slice = @as([*]VertexType, @ptrCast(@alignCast(pack.vertices)))[0..pack.vertexCount];
            return @unionInit(vertexStruct.Vertex, @tagName(tag), slice);
        },
    }
}

fn allocVertex(vType: vertexStruct.VertexType, allocator: std.mem.Allocator, vertexCount: u32) !vertexStruct.Vertex {
    // var vertex: vertexStruct.Vertex = undefined;
    switch (vType) {
        .none => {
            std.debug.panic("unknow vertex type", .{});
        },
        inline else => |tag| {
            const struct_name = "Vertex_" ++ @tagName(tag);
            const VertexType: type = @field(vertexStruct, struct_name);

            const slice = try allocator.alloc(VertexType, vertexCount);

            return @unionInit(vertexStruct.Vertex, @tagName(tag), slice);
        },
    }
}

fn setValue(vertex: vertexStruct.Vertex, index: usize, value: *anyopaque, comptime field_name: []const u8) void {
    switch (vertex) {
        .none => {},
        inline else => |v| {
            const ElementType = std.meta.Child(@TypeOf(v));

            const fields = @typeInfo(ElementType).@"struct".fields;

            inline for (fields) |f| {
                if (std.mem.eql(u8, f.name, field_name)) {
                    const T = f.type;
                    @field(v[index], f.name) = @as(*T, @ptrCast(@alignCast(value))).*;

                    return;
                }
            }

            std.debug.panic("Struct {s} has no field named \"{s}\"", .{ @tagName(vertex), field_name });
        },
    }
}
