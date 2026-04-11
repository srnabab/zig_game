pub const cgltf = @cImport(@cInclude("cgltf/cgltf.h"));

const std = @import("std");

const file = @import("fileSystem");

const enumFromC = @import("enumFromC");

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

pub fn loadGltfFile(fileID: i32, allocator: std.mem.Allocator) !void {
    var gltf = try file.getFile(fileID);
    defer gltf.close();

    const fileStat = try gltf.stat();
    const fileMem = try allocator.alloc(u8, fileStat.size);
    defer allocator.free(fileMem);
    _ = try gltf.readAll(fileMem);

    var options = cgltf.cgltf_options{};

    var data: [*c]cgltf.cgltf_data = null;
    try cgltf_parse(&options, fileMem.ptr, fileStat.size, &data);

    for (0..data.*.accessors_count) |i| {
        std.log.debug("component type {s}, type {s}, offset {d}, count {d}, stride {d}, size {d}", .{
            @tagName(@as(cgltf_compent_type, @enumFromInt(data.*.accessors[i].component_type))),
            @tagName(@as(cgltf_type, @enumFromInt(data.*.accessors[i].type))),
            data.*.accessors[i].offset,
            data.*.accessors[i].count,
            data.*.accessors[i].stride,
            data.*.accessors[i].buffer_view.*.size,
        });
    }

    _ = cgltf.cgltf_load_buffers(&options, data, null);

    for (0..data.*.accessors[0].count) |i| {
        var pos: [3]f32 = undefined;

        _ = cgltf.cgltf_accessor_read_float(&data.*.accessors[0], i, &pos, 3);
        std.log.debug("{d}, {d}, {d}", .{ pos[0], pos[1], pos[2] });
    }

    for (0..data.*.accessors[1].count) |i| {
        var pos: [3]f32 = undefined;

        _ = cgltf.cgltf_accessor_read_float(&data.*.accessors[1], i, &pos, 3);
        std.log.debug("{d}, {d}, {d}", .{ pos[0], pos[1], pos[2] });
    }

    for (0..data.*.accessors[2].count) |i| {
        var pos: [2]f32 = undefined;

        _ = cgltf.cgltf_accessor_read_float(&data.*.accessors[2], i, &pos, 2);
        std.log.debug("{d}, {d}", .{ pos[0], pos[1] });
    }

    for (0..data.*.accessors[2].count) |i| {
        const pos = cgltf.cgltf_accessor_read_index(&data.*.accessors[3], i);
        std.log.debug("{d}", .{pos});
    }

    // const ptr: [*]f32 = @ptrCast(@alignCast(data.*.accessors[0].buffer_view.*.data));
    // for (0..data.*.accessors[0].count) |j| {
    //     std.log.debug("{d}, {d}, {d}", .{
    //         ptr[j * 3 + 0],
    //         ptr[j * 3 + 1],
    //         ptr[j * 3 + 2],
    //     });
    // }

    defer cgltf.cgltf_free(data);
}
