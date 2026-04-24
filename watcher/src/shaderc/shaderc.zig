const std = @import("std");
const shaderc = @import("shaderc");

const shaderSuffixToShaderKind = a: {
    const maptype = std.StaticStringMap(shaderc.shaderc_shader_kind);
    const KV = struct {
        []const u8,
        shaderc.shaderc_shader_kind,
    };
    const list = [_]KV{
        .{ ".vert", shaderc.shaderc_vertex_shader },
        .{ ".frag", shaderc.shaderc_fragment_shader },
        .{ ".comp", shaderc.shaderc_compute_shader },
        .{ ".mesh", shaderc.shaderc_mesh_shader },
    };

    break :a maptype.initComptime(list);
};

pub const Compiler = struct {
    const Self = @This();

    compiler: shaderc.shaderc_compiler_t,
    options: shaderc.shaderc_compile_options_t,

    pub fn init(macroNames: ?[][]const u8, macroValues: ?[][]const u8, optimizationLevel: shaderc.shaderc_optimization_level) Self {
        const compiler = shaderc.shaderc_compiler_initialize();
        const options = shaderc.shaderc_compile_options_initialize();

        if (macroNames != null and macroValues != null) {
            for (macroNames.?, macroValues.?) |name, value| {
                shaderc.shaderc_compile_options_add_macro_definition(
                    options,
                    name.ptr,
                    name.len,
                    value.ptr,
                    value.len,
                );
            }
        }

        shaderc.shaderc_compile_options_set_optimization_level(options, optimizationLevel);

        return .{
            .compiler = compiler,
            .options = options,
        };
    }

    pub fn compileShader(
        self: Self,
        content: []u8,
        fileName: [:0]const u8,
        entryPoint: [:0]const u8,
        allocator: std.mem.Allocator,
    ) ![]u8 {
        const index = std.mem.find(u8, fileName, ".");

        var shaderKind: shaderc.shaderc_shader_kind = 0xFFFF;
        if (index) |i| {
            shaderKind = shaderSuffixToShaderKind.get(fileName[i..]) orelse return error.unknownShaderKind;
        } else {
            return error.unknownShaderKind;
        }

        const result = shaderc.shaderc_compile_into_spv(
            self.compiler,
            content.ptr,
            content.len,
            shaderKind,
            fileName.ptr,
            entryPoint.ptr,
            self.options,
        );
        defer shaderc.shaderc_result_release(result);

        const status = shaderc.shaderc_result_get_compilation_status(result);
        switch (status) {
            shaderc.shaderc_compilation_status_success => {
                const length = shaderc.shaderc_result_get_length(result);
                const bytes = shaderc.shaderc_result_get_bytes(result);

                const data = try allocator.alloc(u8, length);
                @memcpy(data, bytes[0..length]);

                std.log.debug("shader {s} compiled", .{fileName});

                return data;
            },
            else => {
                std.log.err("{s}", .{shaderc.shaderc_result_get_error_message(result)});
                return error.compilationFailed;
            },
        }
    }
};
