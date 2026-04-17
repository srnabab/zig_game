const __root = @This();
pub const __builtin = @import("std").zig.c_translation.builtins;
pub const __helpers = @import("std").zig.c_translation.helpers;
pub const ptrdiff_t = c_longlong;
pub const wchar_t = c_ushort;
pub const max_align_t = extern struct {
    __aro_max_align_ll: c_longlong = 0,
    __aro_max_align_ld: c_longdouble = 0,
};
pub const __builtin_va_list = [*c]u8;
pub const __gnuc_va_list = __builtin_va_list;
pub const va_list = __gnuc_va_list;
pub extern fn __mingw_get_crt_info() [*c]const u8;
pub const rsize_t = usize;
pub const wint_t = c_ushort;
pub const wctype_t = c_ushort;
pub const errno_t = c_int;
pub const __time32_t = c_long;
pub const __time64_t = c_longlong;
pub const time_t = __time64_t;
pub const struct_threadlocaleinfostruct = extern struct {
    _locale_pctype: [*c]const c_ushort = null,
    _locale_mb_cur_max: c_int = 0,
    _locale_lc_codepage: c_uint = 0,
};
pub const struct_threadmbcinfostruct = opaque {};
pub const pthreadlocinfo = [*c]struct_threadlocaleinfostruct;
pub const pthreadmbcinfo = ?*struct_threadmbcinfostruct;
pub const struct___lc_time_data = opaque {};
pub const struct_localeinfo_struct = extern struct {
    locinfo: pthreadlocinfo = null,
    mbcinfo: pthreadmbcinfo = null,
};
pub const _locale_tstruct = struct_localeinfo_struct;
pub const _locale_t = [*c]struct_localeinfo_struct;
pub const struct_tagLC_ID = extern struct {
    wLanguage: c_ushort = 0,
    wCountry: c_ushort = 0,
    wCodePage: c_ushort = 0,
};
pub const LC_ID = struct_tagLC_ID;
pub const LPLC_ID = [*c]struct_tagLC_ID;
pub const threadlocinfo = struct_threadlocaleinfostruct;
pub const int_least8_t = i8;
pub const uint_least8_t = u8;
pub const int_least16_t = c_short;
pub const uint_least16_t = c_ushort;
pub const int_least32_t = c_int;
pub const uint_least32_t = c_uint;
pub const int_least64_t = c_longlong;
pub const uint_least64_t = c_ulonglong;
pub const int_fast8_t = i8;
pub const uint_fast8_t = u8;
pub const int_fast16_t = c_short;
pub const uint_fast16_t = c_ushort;
pub const int_fast32_t = c_int;
pub const uint_fast32_t = c_uint;
pub const int_fast64_t = c_longlong;
pub const uint_fast64_t = c_ulonglong;
pub const intmax_t = c_longlong;
pub const uintmax_t = c_ulonglong;
pub const cgltf_size = usize;
pub const cgltf_ssize = c_longlong;
pub const cgltf_float = f32;
pub const cgltf_int = c_int;
pub const cgltf_uint = c_uint;
pub const cgltf_bool = c_int;
pub const cgltf_file_type_invalid: c_int = 0;
pub const cgltf_file_type_gltf: c_int = 1;
pub const cgltf_file_type_glb: c_int = 2;
pub const cgltf_file_type_max_enum: c_int = 3;
pub const enum_cgltf_file_type = c_uint;
pub const cgltf_file_type = enum_cgltf_file_type;
pub const cgltf_result_success: c_int = 0;
pub const cgltf_result_data_too_short: c_int = 1;
pub const cgltf_result_unknown_format: c_int = 2;
pub const cgltf_result_invalid_json: c_int = 3;
pub const cgltf_result_invalid_gltf: c_int = 4;
pub const cgltf_result_invalid_options: c_int = 5;
pub const cgltf_result_file_not_found: c_int = 6;
pub const cgltf_result_io_error: c_int = 7;
pub const cgltf_result_out_of_memory: c_int = 8;
pub const cgltf_result_legacy_gltf: c_int = 9;
pub const cgltf_result_max_enum: c_int = 10;
pub const enum_cgltf_result = c_uint;
pub const cgltf_result = enum_cgltf_result;
pub const struct_cgltf_memory_options = extern struct {
    alloc_func: ?*const fn (user: ?*anyopaque, size: cgltf_size) callconv(.c) ?*anyopaque = null,
    free_func: ?*const fn (user: ?*anyopaque, ptr: ?*anyopaque) callconv(.c) void = null,
    user_data: ?*anyopaque = null,
    pub const cgltf_default_file_read = __root.cgltf_default_file_read;
    pub const cgltf_default_file_release = __root.cgltf_default_file_release;
    pub const read = __root.cgltf_default_file_read;
    pub const release = __root.cgltf_default_file_release;
};
pub const cgltf_memory_options = struct_cgltf_memory_options;
pub const struct_cgltf_file_options = extern struct {
    read: ?*const fn (memory_options: [*c]const struct_cgltf_memory_options, file_options: [*c]const struct_cgltf_file_options, path: [*c]const u8, size: [*c]cgltf_size, data: [*c]?*anyopaque) callconv(.c) cgltf_result = null,
    release: ?*const fn (memory_options: [*c]const struct_cgltf_memory_options, file_options: [*c]const struct_cgltf_file_options, data: ?*anyopaque, size: cgltf_size) callconv(.c) void = null,
    user_data: ?*anyopaque = null,
};
pub const cgltf_file_options = struct_cgltf_file_options;
pub const struct_cgltf_options = extern struct {
    type: cgltf_file_type = @import("std").mem.zeroes(cgltf_file_type),
    json_token_count: cgltf_size = 0,
    memory: cgltf_memory_options = @import("std").mem.zeroes(cgltf_memory_options),
    file: cgltf_file_options = @import("std").mem.zeroes(cgltf_file_options),
    pub const cgltf_parse = __root.cgltf_parse;
    pub const cgltf_parse_file = __root.cgltf_parse_file;
    pub const cgltf_load_buffers = __root.cgltf_load_buffers;
    pub const cgltf_load_buffer_base64 = __root.cgltf_load_buffer_base64;
    pub const cgltf_calloc = __root.cgltf_calloc;
    pub const cgltf_parse_json = __root.cgltf_parse_json;
    pub const cgltf_load_buffer_file = __root.cgltf_load_buffer_file;
    pub const cgltf_parse_json_string = __root.cgltf_parse_json_string;
    pub const cgltf_parse_json_array = __root.cgltf_parse_json_array;
    pub const cgltf_parse_json_string_array = __root.cgltf_parse_json_string_array;
    pub const cgltf_parse_json_attribute_list = __root.cgltf_parse_json_attribute_list;
    pub const cgltf_parse_json_extras = __root.cgltf_parse_json_extras;
    pub const cgltf_parse_json_unprocessed_extension = __root.cgltf_parse_json_unprocessed_extension;
    pub const cgltf_parse_json_unprocessed_extensions = __root.cgltf_parse_json_unprocessed_extensions;
    pub const cgltf_parse_json_draco_mesh_compression = __root.cgltf_parse_json_draco_mesh_compression;
    pub const cgltf_parse_json_mesh_gpu_instancing = __root.cgltf_parse_json_mesh_gpu_instancing;
    pub const cgltf_parse_json_material_mapping_data = __root.cgltf_parse_json_material_mapping_data;
    pub const cgltf_parse_json_material_mappings = __root.cgltf_parse_json_material_mappings;
    pub const cgltf_parse_json_primitive = __root.cgltf_parse_json_primitive;
    pub const cgltf_parse_json_mesh = __root.cgltf_parse_json_mesh;
    pub const cgltf_parse_json_meshes = __root.cgltf_parse_json_meshes;
    pub const cgltf_parse_json_accessor = __root.cgltf_parse_json_accessor;
    pub const cgltf_parse_json_texture_view = __root.cgltf_parse_json_texture_view;
    pub const cgltf_parse_json_pbr_metallic_roughness = __root.cgltf_parse_json_pbr_metallic_roughness;
    pub const cgltf_parse_json_pbr_specular_glossiness = __root.cgltf_parse_json_pbr_specular_glossiness;
    pub const cgltf_parse_json_clearcoat = __root.cgltf_parse_json_clearcoat;
    pub const cgltf_parse_json_specular = __root.cgltf_parse_json_specular;
    pub const cgltf_parse_json_transmission = __root.cgltf_parse_json_transmission;
    pub const cgltf_parse_json_volume = __root.cgltf_parse_json_volume;
    pub const cgltf_parse_json_sheen = __root.cgltf_parse_json_sheen;
    pub const cgltf_parse_json_iridescence = __root.cgltf_parse_json_iridescence;
    pub const cgltf_parse_json_diffuse_transmission = __root.cgltf_parse_json_diffuse_transmission;
    pub const cgltf_parse_json_anisotropy = __root.cgltf_parse_json_anisotropy;
    pub const cgltf_parse_json_image = __root.cgltf_parse_json_image;
    pub const cgltf_parse_json_sampler = __root.cgltf_parse_json_sampler;
    pub const cgltf_parse_json_texture = __root.cgltf_parse_json_texture;
    pub const cgltf_parse_json_material = __root.cgltf_parse_json_material;
    pub const cgltf_parse_json_accessors = __root.cgltf_parse_json_accessors;
    pub const cgltf_parse_json_materials = __root.cgltf_parse_json_materials;
    pub const cgltf_parse_json_images = __root.cgltf_parse_json_images;
    pub const cgltf_parse_json_textures = __root.cgltf_parse_json_textures;
    pub const cgltf_parse_json_samplers = __root.cgltf_parse_json_samplers;
    pub const cgltf_parse_json_meshopt_compression = __root.cgltf_parse_json_meshopt_compression;
    pub const cgltf_parse_json_buffer_view = __root.cgltf_parse_json_buffer_view;
    pub const cgltf_parse_json_buffer_views = __root.cgltf_parse_json_buffer_views;
    pub const cgltf_parse_json_buffer = __root.cgltf_parse_json_buffer;
    pub const cgltf_parse_json_buffers = __root.cgltf_parse_json_buffers;
    pub const cgltf_parse_json_skin = __root.cgltf_parse_json_skin;
    pub const cgltf_parse_json_skins = __root.cgltf_parse_json_skins;
    pub const cgltf_parse_json_camera = __root.cgltf_parse_json_camera;
    pub const cgltf_parse_json_cameras = __root.cgltf_parse_json_cameras;
    pub const cgltf_parse_json_light = __root.cgltf_parse_json_light;
    pub const cgltf_parse_json_lights = __root.cgltf_parse_json_lights;
    pub const cgltf_parse_json_node = __root.cgltf_parse_json_node;
    pub const cgltf_parse_json_nodes = __root.cgltf_parse_json_nodes;
    pub const cgltf_parse_json_scene = __root.cgltf_parse_json_scene;
    pub const cgltf_parse_json_scenes = __root.cgltf_parse_json_scenes;
    pub const cgltf_parse_json_animation_sampler = __root.cgltf_parse_json_animation_sampler;
    pub const cgltf_parse_json_animation_channel = __root.cgltf_parse_json_animation_channel;
    pub const cgltf_parse_json_animation = __root.cgltf_parse_json_animation;
    pub const cgltf_parse_json_animations = __root.cgltf_parse_json_animations;
    pub const cgltf_parse_json_variant = __root.cgltf_parse_json_variant;
    pub const cgltf_parse_json_variants = __root.cgltf_parse_json_variants;
    pub const cgltf_parse_json_asset = __root.cgltf_parse_json_asset;
    pub const cgltf_parse_json_root = __root.cgltf_parse_json_root;
    pub const parse = __root.cgltf_parse;
    pub const buffers = __root.cgltf_load_buffers;
    pub const base64 = __root.cgltf_load_buffer_base64;
    pub const json = __root.cgltf_parse_json;
    pub const string = __root.cgltf_parse_json_string;
    pub const array = __root.cgltf_parse_json_array;
    pub const list = __root.cgltf_parse_json_attribute_list;
    pub const extras = __root.cgltf_parse_json_extras;
    pub const extension = __root.cgltf_parse_json_unprocessed_extension;
    pub const extensions = __root.cgltf_parse_json_unprocessed_extensions;
    pub const compression = __root.cgltf_parse_json_draco_mesh_compression;
    pub const instancing = __root.cgltf_parse_json_mesh_gpu_instancing;
    pub const data = __root.cgltf_parse_json_material_mapping_data;
    pub const mappings = __root.cgltf_parse_json_material_mappings;
    pub const primitive = __root.cgltf_parse_json_primitive;
    pub const mesh = __root.cgltf_parse_json_mesh;
    pub const meshes = __root.cgltf_parse_json_meshes;
    pub const accessor = __root.cgltf_parse_json_accessor;
    pub const view = __root.cgltf_parse_json_texture_view;
    pub const roughness = __root.cgltf_parse_json_pbr_metallic_roughness;
    pub const glossiness = __root.cgltf_parse_json_pbr_specular_glossiness;
    pub const clearcoat = __root.cgltf_parse_json_clearcoat;
    pub const specular = __root.cgltf_parse_json_specular;
    pub const transmission = __root.cgltf_parse_json_transmission;
    pub const volume = __root.cgltf_parse_json_volume;
    pub const sheen = __root.cgltf_parse_json_sheen;
    pub const iridescence = __root.cgltf_parse_json_iridescence;
    pub const anisotropy = __root.cgltf_parse_json_anisotropy;
    pub const image = __root.cgltf_parse_json_image;
    pub const sampler = __root.cgltf_parse_json_sampler;
    pub const texture = __root.cgltf_parse_json_texture;
    pub const material = __root.cgltf_parse_json_material;
    pub const accessors = __root.cgltf_parse_json_accessors;
    pub const materials = __root.cgltf_parse_json_materials;
    pub const images = __root.cgltf_parse_json_images;
    pub const textures = __root.cgltf_parse_json_textures;
    pub const samplers = __root.cgltf_parse_json_samplers;
    pub const views = __root.cgltf_parse_json_buffer_views;
    pub const buffer = __root.cgltf_parse_json_buffer;
    pub const skin = __root.cgltf_parse_json_skin;
    pub const skins = __root.cgltf_parse_json_skins;
    pub const camera = __root.cgltf_parse_json_camera;
    pub const cameras = __root.cgltf_parse_json_cameras;
    pub const light = __root.cgltf_parse_json_light;
    pub const lights = __root.cgltf_parse_json_lights;
    pub const node = __root.cgltf_parse_json_node;
    pub const nodes = __root.cgltf_parse_json_nodes;
    pub const scene = __root.cgltf_parse_json_scene;
    pub const scenes = __root.cgltf_parse_json_scenes;
    pub const channel = __root.cgltf_parse_json_animation_channel;
    pub const animation = __root.cgltf_parse_json_animation;
    pub const animations = __root.cgltf_parse_json_animations;
    pub const variant = __root.cgltf_parse_json_variant;
    pub const variants = __root.cgltf_parse_json_variants;
    pub const asset = __root.cgltf_parse_json_asset;
    pub const root = __root.cgltf_parse_json_root;
};
pub const cgltf_options = struct_cgltf_options;
pub const cgltf_buffer_view_type_invalid: c_int = 0;
pub const cgltf_buffer_view_type_indices: c_int = 1;
pub const cgltf_buffer_view_type_vertices: c_int = 2;
pub const cgltf_buffer_view_type_max_enum: c_int = 3;
pub const enum_cgltf_buffer_view_type = c_uint;
pub const cgltf_buffer_view_type = enum_cgltf_buffer_view_type;
pub const cgltf_attribute_type_invalid: c_int = 0;
pub const cgltf_attribute_type_position: c_int = 1;
pub const cgltf_attribute_type_normal: c_int = 2;
pub const cgltf_attribute_type_tangent: c_int = 3;
pub const cgltf_attribute_type_texcoord: c_int = 4;
pub const cgltf_attribute_type_color: c_int = 5;
pub const cgltf_attribute_type_joints: c_int = 6;
pub const cgltf_attribute_type_weights: c_int = 7;
pub const cgltf_attribute_type_custom: c_int = 8;
pub const cgltf_attribute_type_max_enum: c_int = 9;
pub const enum_cgltf_attribute_type = c_uint;
pub const cgltf_attribute_type = enum_cgltf_attribute_type;
pub const cgltf_component_type_invalid: c_int = 0;
pub const cgltf_component_type_r_8: c_int = 1;
pub const cgltf_component_type_r_8u: c_int = 2;
pub const cgltf_component_type_r_16: c_int = 3;
pub const cgltf_component_type_r_16u: c_int = 4;
pub const cgltf_component_type_r_32u: c_int = 5;
pub const cgltf_component_type_r_32f: c_int = 6;
pub const cgltf_component_type_max_enum: c_int = 7;
pub const enum_cgltf_component_type = c_uint;
pub const cgltf_component_type = enum_cgltf_component_type;
pub const cgltf_type_invalid: c_int = 0;
pub const cgltf_type_scalar: c_int = 1;
pub const cgltf_type_vec2: c_int = 2;
pub const cgltf_type_vec3: c_int = 3;
pub const cgltf_type_vec4: c_int = 4;
pub const cgltf_type_mat2: c_int = 5;
pub const cgltf_type_mat3: c_int = 6;
pub const cgltf_type_mat4: c_int = 7;
pub const cgltf_type_max_enum: c_int = 8;
pub const enum_cgltf_type = c_uint;
pub const cgltf_type = enum_cgltf_type;
pub const cgltf_primitive_type_invalid: c_int = 0;
pub const cgltf_primitive_type_points: c_int = 1;
pub const cgltf_primitive_type_lines: c_int = 2;
pub const cgltf_primitive_type_line_loop: c_int = 3;
pub const cgltf_primitive_type_line_strip: c_int = 4;
pub const cgltf_primitive_type_triangles: c_int = 5;
pub const cgltf_primitive_type_triangle_strip: c_int = 6;
pub const cgltf_primitive_type_triangle_fan: c_int = 7;
pub const cgltf_primitive_type_max_enum: c_int = 8;
pub const enum_cgltf_primitive_type = c_uint;
pub const cgltf_primitive_type = enum_cgltf_primitive_type;
pub const cgltf_alpha_mode_opaque: c_int = 0;
pub const cgltf_alpha_mode_mask: c_int = 1;
pub const cgltf_alpha_mode_blend: c_int = 2;
pub const cgltf_alpha_mode_max_enum: c_int = 3;
pub const enum_cgltf_alpha_mode = c_uint;
pub const cgltf_alpha_mode = enum_cgltf_alpha_mode;
pub const cgltf_animation_path_type_invalid: c_int = 0;
pub const cgltf_animation_path_type_translation: c_int = 1;
pub const cgltf_animation_path_type_rotation: c_int = 2;
pub const cgltf_animation_path_type_scale: c_int = 3;
pub const cgltf_animation_path_type_weights: c_int = 4;
pub const cgltf_animation_path_type_max_enum: c_int = 5;
pub const enum_cgltf_animation_path_type = c_uint;
pub const cgltf_animation_path_type = enum_cgltf_animation_path_type;
pub const cgltf_interpolation_type_linear: c_int = 0;
pub const cgltf_interpolation_type_step: c_int = 1;
pub const cgltf_interpolation_type_cubic_spline: c_int = 2;
pub const cgltf_interpolation_type_max_enum: c_int = 3;
pub const enum_cgltf_interpolation_type = c_uint;
pub const cgltf_interpolation_type = enum_cgltf_interpolation_type;
pub const cgltf_camera_type_invalid: c_int = 0;
pub const cgltf_camera_type_perspective: c_int = 1;
pub const cgltf_camera_type_orthographic: c_int = 2;
pub const cgltf_camera_type_max_enum: c_int = 3;
pub const enum_cgltf_camera_type = c_uint;
pub const cgltf_camera_type = enum_cgltf_camera_type;
pub const cgltf_light_type_invalid: c_int = 0;
pub const cgltf_light_type_directional: c_int = 1;
pub const cgltf_light_type_point: c_int = 2;
pub const cgltf_light_type_spot: c_int = 3;
pub const cgltf_light_type_max_enum: c_int = 4;
pub const enum_cgltf_light_type = c_uint;
pub const cgltf_light_type = enum_cgltf_light_type;
pub const cgltf_data_free_method_none: c_int = 0;
pub const cgltf_data_free_method_file_release: c_int = 1;
pub const cgltf_data_free_method_memory_free: c_int = 2;
pub const cgltf_data_free_method_max_enum: c_int = 3;
pub const enum_cgltf_data_free_method = c_uint;
pub const cgltf_data_free_method = enum_cgltf_data_free_method;
pub const struct_cgltf_extras = extern struct {
    start_offset: cgltf_size = 0,
    end_offset: cgltf_size = 0,
    data: [*c]u8 = null,
};
pub const cgltf_extras = struct_cgltf_extras;
pub const struct_cgltf_extension = extern struct {
    name: [*c]u8 = null,
    data: [*c]u8 = null,
};
pub const cgltf_extension = struct_cgltf_extension;
pub const struct_cgltf_buffer = extern struct {
    name: [*c]u8 = null,
    size: cgltf_size = 0,
    uri: [*c]u8 = null,
    data: ?*anyopaque = null,
    data_free_method: cgltf_data_free_method = @import("std").mem.zeroes(cgltf_data_free_method),
    extras: cgltf_extras = @import("std").mem.zeroes(cgltf_extras),
    extensions_count: cgltf_size = 0,
    extensions: [*c]cgltf_extension = null,
};
pub const cgltf_buffer = struct_cgltf_buffer;
pub const cgltf_meshopt_compression_mode_invalid: c_int = 0;
pub const cgltf_meshopt_compression_mode_attributes: c_int = 1;
pub const cgltf_meshopt_compression_mode_triangles: c_int = 2;
pub const cgltf_meshopt_compression_mode_indices: c_int = 3;
pub const cgltf_meshopt_compression_mode_max_enum: c_int = 4;
pub const enum_cgltf_meshopt_compression_mode = c_uint;
pub const cgltf_meshopt_compression_mode = enum_cgltf_meshopt_compression_mode;
pub const cgltf_meshopt_compression_filter_none: c_int = 0;
pub const cgltf_meshopt_compression_filter_octahedral: c_int = 1;
pub const cgltf_meshopt_compression_filter_quaternion: c_int = 2;
pub const cgltf_meshopt_compression_filter_exponential: c_int = 3;
pub const cgltf_meshopt_compression_filter_color: c_int = 4;
pub const cgltf_meshopt_compression_filter_max_enum: c_int = 5;
pub const enum_cgltf_meshopt_compression_filter = c_uint;
pub const cgltf_meshopt_compression_filter = enum_cgltf_meshopt_compression_filter;
pub const struct_cgltf_meshopt_compression = extern struct {
    buffer: [*c]cgltf_buffer = null,
    offset: cgltf_size = 0,
    size: cgltf_size = 0,
    stride: cgltf_size = 0,
    count: cgltf_size = 0,
    mode: cgltf_meshopt_compression_mode = @import("std").mem.zeroes(cgltf_meshopt_compression_mode),
    filter: cgltf_meshopt_compression_filter = @import("std").mem.zeroes(cgltf_meshopt_compression_filter),
    is_khr: cgltf_bool = 0,
};
pub const cgltf_meshopt_compression = struct_cgltf_meshopt_compression;
pub const struct_cgltf_buffer_view = extern struct {
    name: [*c]u8 = null,
    buffer: [*c]cgltf_buffer = null,
    offset: cgltf_size = 0,
    size: cgltf_size = 0,
    stride: cgltf_size = 0,
    type: cgltf_buffer_view_type = @import("std").mem.zeroes(cgltf_buffer_view_type),
    data: ?*anyopaque = null,
    has_meshopt_compression: cgltf_bool = 0,
    meshopt_compression: cgltf_meshopt_compression = @import("std").mem.zeroes(cgltf_meshopt_compression),
    extras: cgltf_extras = @import("std").mem.zeroes(cgltf_extras),
    extensions_count: cgltf_size = 0,
    extensions: [*c]cgltf_extension = null,
    pub const cgltf_buffer_view_data = __root.cgltf_buffer_view_data;
    pub const cgltf_calc_index_bound = __root.cgltf_calc_index_bound;
    pub const bound = __root.cgltf_calc_index_bound;
};
pub const cgltf_buffer_view = struct_cgltf_buffer_view;
pub const struct_cgltf_accessor_sparse = extern struct {
    count: cgltf_size = 0,
    indices_buffer_view: [*c]cgltf_buffer_view = null,
    indices_byte_offset: cgltf_size = 0,
    indices_component_type: cgltf_component_type = @import("std").mem.zeroes(cgltf_component_type),
    values_buffer_view: [*c]cgltf_buffer_view = null,
    values_byte_offset: cgltf_size = 0,
};
pub const cgltf_accessor_sparse = struct_cgltf_accessor_sparse;
pub const struct_cgltf_accessor = extern struct {
    name: [*c]u8 = null,
    component_type: cgltf_component_type = @import("std").mem.zeroes(cgltf_component_type),
    normalized: cgltf_bool = 0,
    type: cgltf_type = @import("std").mem.zeroes(cgltf_type),
    offset: cgltf_size = 0,
    count: cgltf_size = 0,
    stride: cgltf_size = 0,
    buffer_view: [*c]cgltf_buffer_view = null,
    has_min: cgltf_bool = 0,
    min: [16]cgltf_float = @import("std").mem.zeroes([16]cgltf_float),
    has_max: cgltf_bool = 0,
    max: [16]cgltf_float = @import("std").mem.zeroes([16]cgltf_float),
    is_sparse: cgltf_bool = 0,
    sparse: cgltf_accessor_sparse = @import("std").mem.zeroes(cgltf_accessor_sparse),
    extras: cgltf_extras = @import("std").mem.zeroes(cgltf_extras),
    extensions_count: cgltf_size = 0,
    extensions: [*c]cgltf_extension = null,
    pub const cgltf_accessor_read_float = __root.cgltf_accessor_read_float;
    pub const cgltf_accessor_read_uint = __root.cgltf_accessor_read_uint;
    pub const cgltf_accessor_read_index = __root.cgltf_accessor_read_index;
    pub const cgltf_accessor_unpack_floats = __root.cgltf_accessor_unpack_floats;
    pub const cgltf_accessor_unpack_indices = __root.cgltf_accessor_unpack_indices;
    pub const cgltf_find_sparse_index = __root.cgltf_find_sparse_index;
    pub const read_float = __root.cgltf_accessor_read_float;
    pub const read_uint = __root.cgltf_accessor_read_uint;
    pub const read_index = __root.cgltf_accessor_read_index;
    pub const unpack_floats = __root.cgltf_accessor_unpack_floats;
    pub const unpack_indices = __root.cgltf_accessor_unpack_indices;
    pub const index = __root.cgltf_find_sparse_index;
};
pub const cgltf_accessor = struct_cgltf_accessor;
pub const struct_cgltf_attribute = extern struct {
    name: [*c]u8 = null,
    type: cgltf_attribute_type = @import("std").mem.zeroes(cgltf_attribute_type),
    index: cgltf_int = 0,
    data: [*c]cgltf_accessor = null,
};
pub const cgltf_attribute = struct_cgltf_attribute;
pub const struct_cgltf_image = extern struct {
    name: [*c]u8 = null,
    uri: [*c]u8 = null,
    buffer_view: [*c]cgltf_buffer_view = null,
    mime_type: [*c]u8 = null,
    extras: cgltf_extras = @import("std").mem.zeroes(cgltf_extras),
    extensions_count: cgltf_size = 0,
    extensions: [*c]cgltf_extension = null,
};
pub const cgltf_image = struct_cgltf_image;
pub const cgltf_filter_type_undefined: c_int = 0;
pub const cgltf_filter_type_nearest: c_int = 9728;
pub const cgltf_filter_type_linear: c_int = 9729;
pub const cgltf_filter_type_nearest_mipmap_nearest: c_int = 9984;
pub const cgltf_filter_type_linear_mipmap_nearest: c_int = 9985;
pub const cgltf_filter_type_nearest_mipmap_linear: c_int = 9986;
pub const cgltf_filter_type_linear_mipmap_linear: c_int = 9987;
pub const enum_cgltf_filter_type = c_uint;
pub const cgltf_filter_type = enum_cgltf_filter_type;
pub const cgltf_wrap_mode_clamp_to_edge: c_int = 33071;
pub const cgltf_wrap_mode_mirrored_repeat: c_int = 33648;
pub const cgltf_wrap_mode_repeat: c_int = 10497;
pub const enum_cgltf_wrap_mode = c_uint;
pub const cgltf_wrap_mode = enum_cgltf_wrap_mode;
pub const struct_cgltf_sampler = extern struct {
    name: [*c]u8 = null,
    mag_filter: cgltf_filter_type = @import("std").mem.zeroes(cgltf_filter_type),
    min_filter: cgltf_filter_type = @import("std").mem.zeroes(cgltf_filter_type),
    wrap_s: cgltf_wrap_mode = @import("std").mem.zeroes(cgltf_wrap_mode),
    wrap_t: cgltf_wrap_mode = @import("std").mem.zeroes(cgltf_wrap_mode),
    extras: cgltf_extras = @import("std").mem.zeroes(cgltf_extras),
    extensions_count: cgltf_size = 0,
    extensions: [*c]cgltf_extension = null,
};
pub const cgltf_sampler = struct_cgltf_sampler;
pub const struct_cgltf_texture = extern struct {
    name: [*c]u8 = null,
    image: [*c]cgltf_image = null,
    sampler: [*c]cgltf_sampler = null,
    has_basisu: cgltf_bool = 0,
    basisu_image: [*c]cgltf_image = null,
    has_webp: cgltf_bool = 0,
    webp_image: [*c]cgltf_image = null,
    extras: cgltf_extras = @import("std").mem.zeroes(cgltf_extras),
    extensions_count: cgltf_size = 0,
    extensions: [*c]cgltf_extension = null,
};
pub const cgltf_texture = struct_cgltf_texture;
pub const struct_cgltf_texture_transform = extern struct {
    offset: [2]cgltf_float = @import("std").mem.zeroes([2]cgltf_float),
    rotation: cgltf_float = 0,
    scale: [2]cgltf_float = @import("std").mem.zeroes([2]cgltf_float),
    has_texcoord: cgltf_bool = 0,
    texcoord: cgltf_int = 0,
};
pub const cgltf_texture_transform = struct_cgltf_texture_transform;
pub const struct_cgltf_texture_view = extern struct {
    texture: [*c]cgltf_texture = null,
    texcoord: cgltf_int = 0,
    scale: cgltf_float = 0,
    has_transform: cgltf_bool = 0,
    transform: cgltf_texture_transform = @import("std").mem.zeroes(cgltf_texture_transform),
};
pub const cgltf_texture_view = struct_cgltf_texture_view;
pub const struct_cgltf_pbr_metallic_roughness = extern struct {
    base_color_texture: cgltf_texture_view = @import("std").mem.zeroes(cgltf_texture_view),
    metallic_roughness_texture: cgltf_texture_view = @import("std").mem.zeroes(cgltf_texture_view),
    base_color_factor: [4]cgltf_float = @import("std").mem.zeroes([4]cgltf_float),
    metallic_factor: cgltf_float = 0,
    roughness_factor: cgltf_float = 0,
};
pub const cgltf_pbr_metallic_roughness = struct_cgltf_pbr_metallic_roughness;
pub const struct_cgltf_pbr_specular_glossiness = extern struct {
    diffuse_texture: cgltf_texture_view = @import("std").mem.zeroes(cgltf_texture_view),
    specular_glossiness_texture: cgltf_texture_view = @import("std").mem.zeroes(cgltf_texture_view),
    diffuse_factor: [4]cgltf_float = @import("std").mem.zeroes([4]cgltf_float),
    specular_factor: [3]cgltf_float = @import("std").mem.zeroes([3]cgltf_float),
    glossiness_factor: cgltf_float = 0,
};
pub const cgltf_pbr_specular_glossiness = struct_cgltf_pbr_specular_glossiness;
pub const struct_cgltf_clearcoat = extern struct {
    clearcoat_texture: cgltf_texture_view = @import("std").mem.zeroes(cgltf_texture_view),
    clearcoat_roughness_texture: cgltf_texture_view = @import("std").mem.zeroes(cgltf_texture_view),
    clearcoat_normal_texture: cgltf_texture_view = @import("std").mem.zeroes(cgltf_texture_view),
    clearcoat_factor: cgltf_float = 0,
    clearcoat_roughness_factor: cgltf_float = 0,
};
pub const cgltf_clearcoat = struct_cgltf_clearcoat;
pub const struct_cgltf_transmission = extern struct {
    transmission_texture: cgltf_texture_view = @import("std").mem.zeroes(cgltf_texture_view),
    transmission_factor: cgltf_float = 0,
};
pub const cgltf_transmission = struct_cgltf_transmission;
pub const struct_cgltf_ior = extern struct {
    ior: cgltf_float = 0,
};
pub const cgltf_ior = struct_cgltf_ior;
pub const struct_cgltf_specular = extern struct {
    specular_texture: cgltf_texture_view = @import("std").mem.zeroes(cgltf_texture_view),
    specular_color_texture: cgltf_texture_view = @import("std").mem.zeroes(cgltf_texture_view),
    specular_color_factor: [3]cgltf_float = @import("std").mem.zeroes([3]cgltf_float),
    specular_factor: cgltf_float = 0,
};
pub const cgltf_specular = struct_cgltf_specular;
pub const struct_cgltf_volume = extern struct {
    thickness_texture: cgltf_texture_view = @import("std").mem.zeroes(cgltf_texture_view),
    thickness_factor: cgltf_float = 0,
    attenuation_color: [3]cgltf_float = @import("std").mem.zeroes([3]cgltf_float),
    attenuation_distance: cgltf_float = 0,
};
pub const cgltf_volume = struct_cgltf_volume;
pub const struct_cgltf_sheen = extern struct {
    sheen_color_texture: cgltf_texture_view = @import("std").mem.zeroes(cgltf_texture_view),
    sheen_color_factor: [3]cgltf_float = @import("std").mem.zeroes([3]cgltf_float),
    sheen_roughness_texture: cgltf_texture_view = @import("std").mem.zeroes(cgltf_texture_view),
    sheen_roughness_factor: cgltf_float = 0,
};
pub const cgltf_sheen = struct_cgltf_sheen;
pub const struct_cgltf_emissive_strength = extern struct {
    emissive_strength: cgltf_float = 0,
};
pub const cgltf_emissive_strength = struct_cgltf_emissive_strength;
pub const struct_cgltf_iridescence = extern struct {
    iridescence_factor: cgltf_float = 0,
    iridescence_texture: cgltf_texture_view = @import("std").mem.zeroes(cgltf_texture_view),
    iridescence_ior: cgltf_float = 0,
    iridescence_thickness_min: cgltf_float = 0,
    iridescence_thickness_max: cgltf_float = 0,
    iridescence_thickness_texture: cgltf_texture_view = @import("std").mem.zeroes(cgltf_texture_view),
};
pub const cgltf_iridescence = struct_cgltf_iridescence;
pub const struct_cgltf_diffuse_transmission = extern struct {
    diffuse_transmission_texture: cgltf_texture_view = @import("std").mem.zeroes(cgltf_texture_view),
    diffuse_transmission_factor: cgltf_float = 0,
    diffuse_transmission_color_factor: [3]cgltf_float = @import("std").mem.zeroes([3]cgltf_float),
    diffuse_transmission_color_texture: cgltf_texture_view = @import("std").mem.zeroes(cgltf_texture_view),
};
pub const cgltf_diffuse_transmission = struct_cgltf_diffuse_transmission;
pub const struct_cgltf_anisotropy = extern struct {
    anisotropy_strength: cgltf_float = 0,
    anisotropy_rotation: cgltf_float = 0,
    anisotropy_texture: cgltf_texture_view = @import("std").mem.zeroes(cgltf_texture_view),
};
pub const cgltf_anisotropy = struct_cgltf_anisotropy;
pub const struct_cgltf_dispersion = extern struct {
    dispersion: cgltf_float = 0,
};
pub const cgltf_dispersion = struct_cgltf_dispersion;
pub const struct_cgltf_material = extern struct {
    name: [*c]u8 = null,
    has_pbr_metallic_roughness: cgltf_bool = 0,
    has_pbr_specular_glossiness: cgltf_bool = 0,
    has_clearcoat: cgltf_bool = 0,
    has_transmission: cgltf_bool = 0,
    has_volume: cgltf_bool = 0,
    has_ior: cgltf_bool = 0,
    has_specular: cgltf_bool = 0,
    has_sheen: cgltf_bool = 0,
    has_emissive_strength: cgltf_bool = 0,
    has_iridescence: cgltf_bool = 0,
    has_diffuse_transmission: cgltf_bool = 0,
    has_anisotropy: cgltf_bool = 0,
    has_dispersion: cgltf_bool = 0,
    pbr_metallic_roughness: cgltf_pbr_metallic_roughness = @import("std").mem.zeroes(cgltf_pbr_metallic_roughness),
    pbr_specular_glossiness: cgltf_pbr_specular_glossiness = @import("std").mem.zeroes(cgltf_pbr_specular_glossiness),
    clearcoat: cgltf_clearcoat = @import("std").mem.zeroes(cgltf_clearcoat),
    ior: cgltf_ior = @import("std").mem.zeroes(cgltf_ior),
    specular: cgltf_specular = @import("std").mem.zeroes(cgltf_specular),
    sheen: cgltf_sheen = @import("std").mem.zeroes(cgltf_sheen),
    transmission: cgltf_transmission = @import("std").mem.zeroes(cgltf_transmission),
    volume: cgltf_volume = @import("std").mem.zeroes(cgltf_volume),
    emissive_strength: cgltf_emissive_strength = @import("std").mem.zeroes(cgltf_emissive_strength),
    iridescence: cgltf_iridescence = @import("std").mem.zeroes(cgltf_iridescence),
    diffuse_transmission: cgltf_diffuse_transmission = @import("std").mem.zeroes(cgltf_diffuse_transmission),
    anisotropy: cgltf_anisotropy = @import("std").mem.zeroes(cgltf_anisotropy),
    dispersion: cgltf_dispersion = @import("std").mem.zeroes(cgltf_dispersion),
    normal_texture: cgltf_texture_view = @import("std").mem.zeroes(cgltf_texture_view),
    occlusion_texture: cgltf_texture_view = @import("std").mem.zeroes(cgltf_texture_view),
    emissive_texture: cgltf_texture_view = @import("std").mem.zeroes(cgltf_texture_view),
    emissive_factor: [3]cgltf_float = @import("std").mem.zeroes([3]cgltf_float),
    alpha_mode: cgltf_alpha_mode = @import("std").mem.zeroes(cgltf_alpha_mode),
    alpha_cutoff: cgltf_float = 0,
    double_sided: cgltf_bool = 0,
    unlit: cgltf_bool = 0,
    extras: cgltf_extras = @import("std").mem.zeroes(cgltf_extras),
    extensions_count: cgltf_size = 0,
    extensions: [*c]cgltf_extension = null,
};
pub const cgltf_material = struct_cgltf_material;
pub const struct_cgltf_material_mapping = extern struct {
    variant: cgltf_size = 0,
    material: [*c]cgltf_material = null,
    extras: cgltf_extras = @import("std").mem.zeroes(cgltf_extras),
};
pub const cgltf_material_mapping = struct_cgltf_material_mapping;
pub const struct_cgltf_morph_target = extern struct {
    attributes: [*c]cgltf_attribute = null,
    attributes_count: cgltf_size = 0,
};
pub const cgltf_morph_target = struct_cgltf_morph_target;
pub const struct_cgltf_draco_mesh_compression = extern struct {
    buffer_view: [*c]cgltf_buffer_view = null,
    attributes: [*c]cgltf_attribute = null,
    attributes_count: cgltf_size = 0,
};
pub const cgltf_draco_mesh_compression = struct_cgltf_draco_mesh_compression;
pub const struct_cgltf_mesh_gpu_instancing = extern struct {
    attributes: [*c]cgltf_attribute = null,
    attributes_count: cgltf_size = 0,
};
pub const cgltf_mesh_gpu_instancing = struct_cgltf_mesh_gpu_instancing;
pub const struct_cgltf_primitive = extern struct {
    type: cgltf_primitive_type = @import("std").mem.zeroes(cgltf_primitive_type),
    indices: [*c]cgltf_accessor = null,
    material: [*c]cgltf_material = null,
    attributes: [*c]cgltf_attribute = null,
    attributes_count: cgltf_size = 0,
    targets: [*c]cgltf_morph_target = null,
    targets_count: cgltf_size = 0,
    extras: cgltf_extras = @import("std").mem.zeroes(cgltf_extras),
    has_draco_mesh_compression: cgltf_bool = 0,
    draco_mesh_compression: cgltf_draco_mesh_compression = @import("std").mem.zeroes(cgltf_draco_mesh_compression),
    mappings: [*c]cgltf_material_mapping = null,
    mappings_count: cgltf_size = 0,
    extensions_count: cgltf_size = 0,
    extensions: [*c]cgltf_extension = null,
    pub const cgltf_find_accessor = __root.cgltf_find_accessor;
    pub const accessor = __root.cgltf_find_accessor;
};
pub const cgltf_primitive = struct_cgltf_primitive;
pub const struct_cgltf_mesh = extern struct {
    name: [*c]u8 = null,
    primitives: [*c]cgltf_primitive = null,
    primitives_count: cgltf_size = 0,
    weights: [*c]cgltf_float = null,
    weights_count: cgltf_size = 0,
    target_names: [*c][*c]u8 = null,
    target_names_count: cgltf_size = 0,
    extras: cgltf_extras = @import("std").mem.zeroes(cgltf_extras),
    extensions_count: cgltf_size = 0,
    extensions: [*c]cgltf_extension = null,
};
pub const cgltf_mesh = struct_cgltf_mesh;
pub const cgltf_node = struct_cgltf_node;
pub const struct_cgltf_skin = extern struct {
    name: [*c]u8 = null,
    joints: [*c][*c]cgltf_node = null,
    joints_count: cgltf_size = 0,
    skeleton: [*c]cgltf_node = null,
    inverse_bind_matrices: [*c]cgltf_accessor = null,
    extras: cgltf_extras = @import("std").mem.zeroes(cgltf_extras),
    extensions_count: cgltf_size = 0,
    extensions: [*c]cgltf_extension = null,
};
pub const cgltf_skin = struct_cgltf_skin;
pub const struct_cgltf_camera_perspective = extern struct {
    has_aspect_ratio: cgltf_bool = 0,
    aspect_ratio: cgltf_float = 0,
    yfov: cgltf_float = 0,
    has_zfar: cgltf_bool = 0,
    zfar: cgltf_float = 0,
    znear: cgltf_float = 0,
    extras: cgltf_extras = @import("std").mem.zeroes(cgltf_extras),
};
pub const cgltf_camera_perspective = struct_cgltf_camera_perspective;
pub const struct_cgltf_camera_orthographic = extern struct {
    xmag: cgltf_float = 0,
    ymag: cgltf_float = 0,
    zfar: cgltf_float = 0,
    znear: cgltf_float = 0,
    extras: cgltf_extras = @import("std").mem.zeroes(cgltf_extras),
};
pub const cgltf_camera_orthographic = struct_cgltf_camera_orthographic;
const union_unnamed_1 = extern union {
    perspective: cgltf_camera_perspective,
    orthographic: cgltf_camera_orthographic,
};
pub const struct_cgltf_camera = extern struct {
    name: [*c]u8 = null,
    type: cgltf_camera_type = @import("std").mem.zeroes(cgltf_camera_type),
    data: union_unnamed_1 = @import("std").mem.zeroes(union_unnamed_1),
    extras: cgltf_extras = @import("std").mem.zeroes(cgltf_extras),
    extensions_count: cgltf_size = 0,
    extensions: [*c]cgltf_extension = null,
};
pub const cgltf_camera = struct_cgltf_camera;
pub const struct_cgltf_light = extern struct {
    name: [*c]u8 = null,
    color: [3]cgltf_float = @import("std").mem.zeroes([3]cgltf_float),
    intensity: cgltf_float = 0,
    type: cgltf_light_type = @import("std").mem.zeroes(cgltf_light_type),
    range: cgltf_float = 0,
    spot_inner_cone_angle: cgltf_float = 0,
    spot_outer_cone_angle: cgltf_float = 0,
    extras: cgltf_extras = @import("std").mem.zeroes(cgltf_extras),
};
pub const cgltf_light = struct_cgltf_light;
pub const struct_cgltf_node = extern struct {
    name: [*c]u8 = null,
    parent: [*c]cgltf_node = null,
    children: [*c][*c]cgltf_node = null,
    children_count: cgltf_size = 0,
    skin: [*c]cgltf_skin = null,
    mesh: [*c]cgltf_mesh = null,
    camera: [*c]cgltf_camera = null,
    light: [*c]cgltf_light = null,
    weights: [*c]cgltf_float = null,
    weights_count: cgltf_size = 0,
    has_translation: cgltf_bool = 0,
    has_rotation: cgltf_bool = 0,
    has_scale: cgltf_bool = 0,
    has_matrix: cgltf_bool = 0,
    translation: [3]cgltf_float = @import("std").mem.zeroes([3]cgltf_float),
    rotation: [4]cgltf_float = @import("std").mem.zeroes([4]cgltf_float),
    scale: [3]cgltf_float = @import("std").mem.zeroes([3]cgltf_float),
    matrix: [16]cgltf_float = @import("std").mem.zeroes([16]cgltf_float),
    extras: cgltf_extras = @import("std").mem.zeroes(cgltf_extras),
    has_mesh_gpu_instancing: cgltf_bool = 0,
    mesh_gpu_instancing: cgltf_mesh_gpu_instancing = @import("std").mem.zeroes(cgltf_mesh_gpu_instancing),
    extensions_count: cgltf_size = 0,
    extensions: [*c]cgltf_extension = null,
    pub const cgltf_node_transform_local = __root.cgltf_node_transform_local;
    pub const cgltf_node_transform_world = __root.cgltf_node_transform_world;
    pub const transform_local = __root.cgltf_node_transform_local;
    pub const transform_world = __root.cgltf_node_transform_world;
};
pub const struct_cgltf_scene = extern struct {
    name: [*c]u8 = null,
    nodes: [*c][*c]cgltf_node = null,
    nodes_count: cgltf_size = 0,
    extras: cgltf_extras = @import("std").mem.zeroes(cgltf_extras),
    extensions_count: cgltf_size = 0,
    extensions: [*c]cgltf_extension = null,
};
pub const cgltf_scene = struct_cgltf_scene;
pub const struct_cgltf_animation_sampler = extern struct {
    input: [*c]cgltf_accessor = null,
    output: [*c]cgltf_accessor = null,
    interpolation: cgltf_interpolation_type = @import("std").mem.zeroes(cgltf_interpolation_type),
    extras: cgltf_extras = @import("std").mem.zeroes(cgltf_extras),
    extensions_count: cgltf_size = 0,
    extensions: [*c]cgltf_extension = null,
};
pub const cgltf_animation_sampler = struct_cgltf_animation_sampler;
pub const struct_cgltf_animation_channel = extern struct {
    sampler: [*c]cgltf_animation_sampler = null,
    target_node: [*c]cgltf_node = null,
    target_path: cgltf_animation_path_type = @import("std").mem.zeroes(cgltf_animation_path_type),
    extras: cgltf_extras = @import("std").mem.zeroes(cgltf_extras),
    extensions_count: cgltf_size = 0,
    extensions: [*c]cgltf_extension = null,
};
pub const cgltf_animation_channel = struct_cgltf_animation_channel;
pub const struct_cgltf_animation = extern struct {
    name: [*c]u8 = null,
    samplers: [*c]cgltf_animation_sampler = null,
    samplers_count: cgltf_size = 0,
    channels: [*c]cgltf_animation_channel = null,
    channels_count: cgltf_size = 0,
    extras: cgltf_extras = @import("std").mem.zeroes(cgltf_extras),
    extensions_count: cgltf_size = 0,
    extensions: [*c]cgltf_extension = null,
    pub const cgltf_animation_sampler_index = __root.cgltf_animation_sampler_index;
    pub const cgltf_animation_channel_index = __root.cgltf_animation_channel_index;
    pub const sampler_index = __root.cgltf_animation_sampler_index;
    pub const channel_index = __root.cgltf_animation_channel_index;
};
pub const cgltf_animation = struct_cgltf_animation;
pub const struct_cgltf_material_variant = extern struct {
    name: [*c]u8 = null,
    extras: cgltf_extras = @import("std").mem.zeroes(cgltf_extras),
};
pub const cgltf_material_variant = struct_cgltf_material_variant;
pub const struct_cgltf_asset = extern struct {
    copyright: [*c]u8 = null,
    generator: [*c]u8 = null,
    version: [*c]u8 = null,
    min_version: [*c]u8 = null,
    extras: cgltf_extras = @import("std").mem.zeroes(cgltf_extras),
    extensions_count: cgltf_size = 0,
    extensions: [*c]cgltf_extension = null,
};
pub const cgltf_asset = struct_cgltf_asset;
pub const struct_cgltf_data = extern struct {
    file_type: cgltf_file_type = @import("std").mem.zeroes(cgltf_file_type),
    file_data: ?*anyopaque = null,
    file_size: cgltf_size = 0,
    asset: cgltf_asset = @import("std").mem.zeroes(cgltf_asset),
    meshes: [*c]cgltf_mesh = null,
    meshes_count: cgltf_size = 0,
    materials: [*c]cgltf_material = null,
    materials_count: cgltf_size = 0,
    accessors: [*c]cgltf_accessor = null,
    accessors_count: cgltf_size = 0,
    buffer_views: [*c]cgltf_buffer_view = null,
    buffer_views_count: cgltf_size = 0,
    buffers: [*c]cgltf_buffer = null,
    buffers_count: cgltf_size = 0,
    images: [*c]cgltf_image = null,
    images_count: cgltf_size = 0,
    textures: [*c]cgltf_texture = null,
    textures_count: cgltf_size = 0,
    samplers: [*c]cgltf_sampler = null,
    samplers_count: cgltf_size = 0,
    skins: [*c]cgltf_skin = null,
    skins_count: cgltf_size = 0,
    cameras: [*c]cgltf_camera = null,
    cameras_count: cgltf_size = 0,
    lights: [*c]cgltf_light = null,
    lights_count: cgltf_size = 0,
    nodes: [*c]cgltf_node = null,
    nodes_count: cgltf_size = 0,
    scenes: [*c]cgltf_scene = null,
    scenes_count: cgltf_size = 0,
    scene: [*c]cgltf_scene = null,
    animations: [*c]cgltf_animation = null,
    animations_count: cgltf_size = 0,
    variants: [*c]cgltf_material_variant = null,
    variants_count: cgltf_size = 0,
    extras: cgltf_extras = @import("std").mem.zeroes(cgltf_extras),
    data_extensions_count: cgltf_size = 0,
    data_extensions: [*c]cgltf_extension = null,
    extensions_used: [*c][*c]u8 = null,
    extensions_used_count: cgltf_size = 0,
    extensions_required: [*c][*c]u8 = null,
    extensions_required_count: cgltf_size = 0,
    json: [*c]const u8 = null,
    json_size: cgltf_size = 0,
    bin: ?*const anyopaque = null,
    bin_size: cgltf_size = 0,
    memory: cgltf_memory_options = @import("std").mem.zeroes(cgltf_memory_options),
    file: cgltf_file_options = @import("std").mem.zeroes(cgltf_file_options),
    pub const cgltf_validate = __root.cgltf_validate;
    pub const cgltf_free = __root.cgltf_free;
    pub const cgltf_copy_extras_json = __root.cgltf_copy_extras_json;
    pub const cgltf_mesh_index = __root.cgltf_mesh_index;
    pub const cgltf_material_index = __root.cgltf_material_index;
    pub const cgltf_accessor_index = __root.cgltf_accessor_index;
    pub const cgltf_buffer_view_index = __root.cgltf_buffer_view_index;
    pub const cgltf_buffer_index = __root.cgltf_buffer_index;
    pub const cgltf_image_index = __root.cgltf_image_index;
    pub const cgltf_texture_index = __root.cgltf_texture_index;
    pub const cgltf_sampler_index = __root.cgltf_sampler_index;
    pub const cgltf_skin_index = __root.cgltf_skin_index;
    pub const cgltf_camera_index = __root.cgltf_camera_index;
    pub const cgltf_light_index = __root.cgltf_light_index;
    pub const cgltf_node_index = __root.cgltf_node_index;
    pub const cgltf_scene_index = __root.cgltf_scene_index;
    pub const cgltf_animation_index = __root.cgltf_animation_index;
    pub const cgltf_free_extras = __root.cgltf_free_extras;
    pub const cgltf_free_extensions = __root.cgltf_free_extensions;
    pub const cgltf_fixup_pointers = __root.cgltf_fixup_pointers;
    pub const validate = __root.cgltf_validate;
    pub const index = __root.cgltf_mesh_index;
    pub const extensions = __root.cgltf_free_extensions;
    pub const pointers = __root.cgltf_fixup_pointers;
};
pub const cgltf_data = struct_cgltf_data;
pub export fn cgltf_parse(arg_options: [*c]const cgltf_options, arg_data: ?*const anyopaque, arg_size: cgltf_size, arg_out_data: [*c][*c]cgltf_data) cgltf_result {
    var options = arg_options;
    _ = &options;
    var data = arg_data;
    _ = &data;
    var size = arg_size;
    _ = &size;
    var out_data = arg_out_data;
    _ = &out_data;
    if (size < @as(cgltf_size, GlbHeaderSize)) {
        return cgltf_result_data_too_short;
    }
    if (@as(?*anyopaque, @ptrCast(@alignCast(@constCast(options)))) == @as(?*anyopaque, null)) {
        return cgltf_result_invalid_options;
    }
    var fixed_options: cgltf_options = options.*;
    _ = &fixed_options;
    if (@as(?*anyopaque, @ptrCast(@alignCast(@constCast(fixed_options.memory.alloc_func)))) == @as(?*anyopaque, null)) {
        fixed_options.memory.alloc_func = &cgltf_default_alloc;
    }
    if (@as(?*anyopaque, @ptrCast(@alignCast(@constCast(fixed_options.memory.free_func)))) == @as(?*anyopaque, null)) {
        fixed_options.memory.free_func = &cgltf_default_free;
    }
    var tmp: u32 = undefined;
    _ = &tmp;
    const extern_local_memcpy = struct {
        extern fn memcpy(noalias _Dst: ?*anyopaque, noalias _Src: ?*const anyopaque, _Size: usize) ?*anyopaque;
    };
    _ = &extern_local_memcpy;
    _ = memcpy(@ptrCast(@alignCast(&tmp)), data, 4);
    if (tmp != GlbMagic) {
        if (fixed_options.type == @as(cgltf_file_type, cgltf_file_type_invalid)) {
            fixed_options.type = cgltf_file_type_gltf;
        } else if (fixed_options.type == @as(cgltf_file_type, cgltf_file_type_glb)) {
            return cgltf_result_unknown_format;
        }
    }
    if (fixed_options.type == @as(cgltf_file_type, cgltf_file_type_gltf)) {
        var json_result: cgltf_result = cgltf_parse_json(&fixed_options, @ptrCast(@alignCast(data)), size, out_data);
        _ = &json_result;
        if (json_result != @as(cgltf_result, cgltf_result_success)) {
            return json_result;
        }
        out_data.*.*.file_type = cgltf_file_type_gltf;
        return cgltf_result_success;
    }
    var ptr: [*c]const u8 = @ptrCast(@alignCast(data));
    _ = &ptr;
    _ = extern_local_memcpy.memcpy(@ptrCast(@alignCast(&tmp)), @ptrCast(@alignCast(ptr + @as(usize, @bitCast(@as(isize, @intCast(@as(c_int, 4))))))), 4);
    var version: u32 = tmp;
    _ = &version;
    if (version != GlbVersion) {
        return @bitCast(if (version < GlbVersion) cgltf_result_legacy_gltf else cgltf_result_unknown_format);
    }
    _ = extern_local_memcpy.memcpy(@ptrCast(@alignCast(&tmp)), @ptrCast(@alignCast(ptr + @as(usize, @bitCast(@as(isize, @intCast(@as(c_int, 8))))))), 4);
    if (@as(cgltf_size, tmp) > size) {
        return cgltf_result_data_too_short;
    }
    var json_chunk: [*c]const u8 = ptr + @as(usize, @bitCast(@as(isize, @intCast(GlbHeaderSize))));
    _ = &json_chunk;
    if (@as(cgltf_size, @bitCast(@as(c_longlong, GlbHeaderSize + GlbChunkHeaderSize))) > size) {
        return cgltf_result_data_too_short;
    }
    var json_length: u32 = undefined;
    _ = &json_length;
    _ = extern_local_memcpy.memcpy(@ptrCast(@alignCast(&json_length)), @ptrCast(@alignCast(json_chunk)), 4);
    if (@as(cgltf_size, json_length) > ((size -% @as(cgltf_size, GlbHeaderSize)) -% @as(cgltf_size, GlbChunkHeaderSize))) {
        return cgltf_result_data_too_short;
    }
    _ = extern_local_memcpy.memcpy(@ptrCast(@alignCast(&tmp)), @ptrCast(@alignCast(json_chunk + @as(usize, @bitCast(@as(isize, @intCast(@as(c_int, 4))))))), 4);
    if (tmp != GlbMagicJsonChunk) {
        return cgltf_result_unknown_format;
    }
    json_chunk += @as(usize, @bitCast(@as(isize, @intCast(GlbChunkHeaderSize))));
    var bin: ?*const anyopaque = null;
    _ = &bin;
    var bin_size: cgltf_size = 0;
    _ = &bin_size;
    if (@as(cgltf_size, GlbChunkHeaderSize) <= (((size -% @as(cgltf_size, GlbHeaderSize)) -% @as(cgltf_size, GlbChunkHeaderSize)) -% @as(cgltf_size, json_length))) {
        var bin_chunk: [*c]const u8 = json_chunk + json_length;
        _ = &bin_chunk;
        var bin_length: u32 = undefined;
        _ = &bin_length;
        _ = extern_local_memcpy.memcpy(@ptrCast(@alignCast(&bin_length)), @ptrCast(@alignCast(bin_chunk)), 4);
        if (@as(cgltf_size, bin_length) > ((((size -% @as(cgltf_size, GlbHeaderSize)) -% @as(cgltf_size, GlbChunkHeaderSize)) -% @as(cgltf_size, json_length)) -% @as(cgltf_size, GlbChunkHeaderSize))) {
            return cgltf_result_data_too_short;
        }
        _ = extern_local_memcpy.memcpy(@ptrCast(@alignCast(&tmp)), @ptrCast(@alignCast(bin_chunk + @as(usize, @bitCast(@as(isize, @intCast(@as(c_int, 4))))))), 4);
        if (tmp != GlbMagicBinChunk) {
            return cgltf_result_unknown_format;
        }
        bin_chunk += @as(usize, @bitCast(@as(isize, @intCast(GlbChunkHeaderSize))));
        bin = @ptrCast(@alignCast(bin_chunk));
        bin_size = bin_length;
    }
    var json_result: cgltf_result = cgltf_parse_json(&fixed_options, json_chunk, json_length, out_data);
    _ = &json_result;
    if (json_result != @as(cgltf_result, cgltf_result_success)) {
        return json_result;
    }
    out_data.*.*.file_type = cgltf_file_type_glb;
    out_data.*.*.bin = bin;
    out_data.*.*.bin_size = bin_size;
    return cgltf_result_success;
}
pub export fn cgltf_parse_file(arg_options: [*c]const cgltf_options, arg_path: [*c]const u8, arg_out_data: [*c][*c]cgltf_data) cgltf_result {
    var options = arg_options;
    _ = &options;
    var path = arg_path;
    _ = &path;
    var out_data = arg_out_data;
    _ = &out_data;
    if (@as(?*anyopaque, @ptrCast(@alignCast(@constCast(options)))) == @as(?*anyopaque, null)) {
        return cgltf_result_invalid_options;
    }
    var file_read: ?*const fn ([*c]const struct_cgltf_memory_options, [*c]const struct_cgltf_file_options, [*c]const u8, [*c]cgltf_size, [*c]?*anyopaque) callconv(.c) cgltf_result = if (options.*.file.read != null) options.*.file.read else &cgltf_default_file_read;
    _ = &file_read;
    var file_release: ?*const fn ([*c]const struct_cgltf_memory_options, [*c]const struct_cgltf_file_options, data: ?*anyopaque, size: cgltf_size) callconv(.c) void = if (options.*.file.release != null) options.*.file.release else cgltf_default_file_release;
    _ = &file_release;
    var file_data: ?*anyopaque = null;
    _ = &file_data;
    var file_size: cgltf_size = 0;
    _ = &file_size;
    var result: cgltf_result = file_read.?(&options.*.memory, &options.*.file, path, &file_size, &file_data);
    _ = &result;
    if (result != @as(cgltf_result, cgltf_result_success)) {
        return result;
    }
    result = cgltf_parse(options, file_data, file_size, out_data);
    if (result != @as(cgltf_result, cgltf_result_success)) {
        file_release.?(&options.*.memory, &options.*.file, file_data, file_size);
        return result;
    }
    out_data.*.*.file_data = file_data;
    out_data.*.*.file_size = file_size;
    return cgltf_result_success;
}
pub export fn cgltf_load_buffers(arg_options: [*c]const cgltf_options, arg_data: [*c]cgltf_data, arg_gltf_path: [*c]const u8) cgltf_result {
    var options = arg_options;
    _ = &options;
    var data = arg_data;
    _ = &data;
    var gltf_path = arg_gltf_path;
    _ = &gltf_path;
    if (@as(?*anyopaque, @ptrCast(@alignCast(@constCast(options)))) == @as(?*anyopaque, null)) {
        return cgltf_result_invalid_options;
    }
    if ((((data.*.buffers_count != 0) and (@as(cgltf_size, @bitCast(@as(c_longlong, @intFromBool(data.*.buffers[@as(c_int, 0)].data == @as(?*anyopaque, null))))) != 0)) and (@as(?*anyopaque, @ptrCast(@alignCast(data.*.buffers[@as(c_int, 0)].uri))) == @as(?*anyopaque, null))) and (data.*.bin != null)) {
        if (data.*.bin_size < data.*.buffers[@as(c_int, 0)].size) {
            return cgltf_result_data_too_short;
        }
        data.*.buffers[@as(c_int, 0)].data = @ptrCast(@alignCast(@constCast(data.*.bin)));
        data.*.buffers[@as(c_int, 0)].data_free_method = cgltf_data_free_method_none;
    }
    {
        var i: cgltf_size = 0;
        _ = &i;
        while (i < data.*.buffers_count) : (i +%= 1) {
            if (data.*.buffers[@intCast(i)].data != null) {
                continue;
            }
            var uri: [*c]const u8 = data.*.buffers[@intCast(i)].uri;
            _ = &uri;
            if (@as(?*anyopaque, @ptrCast(@alignCast(@constCast(uri)))) == @as(?*anyopaque, null)) {
                continue;
            }
            const extern_local_strncmp = struct {
                extern fn strncmp(_Str1: [*c]const u8, _Str2: [*c]const u8, _MaxCount: usize) c_int;
            };
            const extern_local_strstr = struct {
                extern fn strstr(_Str: [*c]const u8, _SubStr: [*c]const u8) [*c]u8;
            };
            if (strncmp(uri, "data:", 5) == @as(c_int, 0)) {
                const extern_local_strchr = struct {
                    extern fn strchr(_Str: [*c]const u8, _Val: c_int) [*c]u8;
                };
                _ = &extern_local_strchr;
                var comma: [*c]const u8 = strchr(uri, ',');
                _ = &comma;
                const extern_local_strncmp = struct {
                    extern fn strncmp(_Str1: [*c]const u8, _Str2: [*c]const u8, _MaxCount: usize) c_int;
                };
                if (((comma != null) and (@divExact(@as(c_longlong, @bitCast(@intFromPtr(comma) -% @intFromPtr(uri))), @sizeOf(u8)) >= @as(c_longlong, 7))) and (strncmp(comma - @as(usize, @bitCast(@as(isize, @intCast(@as(c_int, 7))))), ";base64", 7) == @as(c_int, 0))) {
                    var res: cgltf_result = cgltf_load_buffer_base64(options, data.*.buffers[@intCast(i)].size, comma + @as(usize, @bitCast(@as(isize, @intCast(@as(c_int, 1))))), &data.*.buffers[@intCast(i)].data);
                    _ = &res;
                    data.*.buffers[@intCast(i)].data_free_method = cgltf_data_free_method_memory_free;
                    if (res != @as(cgltf_result, cgltf_result_success)) {
                        return res;
                    }
                } else {
                    return cgltf_result_unknown_format;
                }
            } else if ((@as(?*anyopaque, @ptrCast(@alignCast(strstr(uri, "://")))) == @as(?*anyopaque, null)) and (gltf_path != null)) {
                var res: cgltf_result = cgltf_load_buffer_file(options, data.*.buffers[@intCast(i)].size, uri, gltf_path, &data.*.buffers[@intCast(i)].data);
                _ = &res;
                data.*.buffers[@intCast(i)].data_free_method = cgltf_data_free_method_file_release;
                if (res != @as(cgltf_result, cgltf_result_success)) {
                    return res;
                }
            } else {
                return cgltf_result_unknown_format;
            }
        }
    }
    return cgltf_result_success;
}
pub export fn cgltf_load_buffer_base64(arg_options: [*c]const cgltf_options, arg_size: cgltf_size, arg_base64: [*c]const u8, arg_out_data: [*c]?*anyopaque) cgltf_result {
    var options = arg_options;
    _ = &options;
    var size = arg_size;
    _ = &size;
    var base64 = arg_base64;
    _ = &base64;
    var out_data = arg_out_data;
    _ = &out_data;
    var memory_alloc: ?*const fn (?*anyopaque, cgltf_size) callconv(.c) ?*anyopaque = if (options.*.memory.alloc_func != null) options.*.memory.alloc_func else &cgltf_default_alloc;
    _ = &memory_alloc;
    var memory_free: ?*const fn (?*anyopaque, ?*anyopaque) callconv(.c) void = if (options.*.memory.free_func != null) options.*.memory.free_func else &cgltf_default_free;
    _ = &memory_free;
    var data: [*c]u8 = @ptrCast(@alignCast(memory_alloc.?(options.*.memory.user_data, size)));
    _ = &data;
    if (!(data != null)) {
        return cgltf_result_out_of_memory;
    }
    var buffer: c_uint = 0;
    _ = &buffer;
    var buffer_bits: c_uint = 0;
    _ = &buffer_bits;
    {
        var i: cgltf_size = 0;
        _ = &i;
        while (i < size) : (i +%= 1) {
            while (buffer_bits < @as(c_uint, 8)) {
                var ch: u8 = (blk: {
                    const ref = &base64;
                    const tmp = ref.*;
                    ref.* += 1;
                    break :blk tmp;
                }).*;
                _ = &ch;
                var index: c_int = if (@as(c_uint, @bitCast(@as(c_int, @as(c_int, ch) - @as(c_int, 'A')))) < @as(c_uint, 26)) @as(c_int, ch) - @as(c_int, 'A') else if (@as(c_uint, @bitCast(@as(c_int, @as(c_int, ch) - @as(c_int, 'a')))) < @as(c_uint, 26)) (@as(c_int, ch) - @as(c_int, 'a')) + @as(c_int, 26) else if (@as(c_uint, @bitCast(@as(c_int, @as(c_int, ch) - @as(c_int, '0')))) < @as(c_uint, 10)) (@as(c_int, ch) - @as(c_int, '0')) + @as(c_int, 52) else if (@as(c_int, ch) == @as(c_int, '+')) @as(c_int, 62) else if (@as(c_int, ch) == @as(c_int, '/')) @as(c_int, 63) else -@as(c_int, 1);
                _ = &index;
                if (index < @as(c_int, 0)) {
                    memory_free.?(options.*.memory.user_data, @ptrCast(@alignCast(data)));
                    return cgltf_result_io_error;
                }
                buffer = (buffer << @intCast(@as(c_uint, 6))) | @as(c_uint, @bitCast(@as(c_int, index)));
                buffer_bits +%= 6;
            }
            data[@intCast(i)] = @truncate(buffer >> @intCast(buffer_bits -% @as(c_uint, 8)));
            buffer_bits -%= 8;
        }
    }
    out_data.* = @ptrCast(@alignCast(data));
    return cgltf_result_success;
}
pub export fn cgltf_decode_string(arg_string: [*c]u8) cgltf_size {
    var string = arg_string;
    _ = &string;
    const extern_local_strcspn = struct {
        extern fn strcspn(_Str: [*c]const u8, _Control: [*c]const u8) usize;
    };
    _ = &extern_local_strcspn;
    var read: [*c]u8 = string + strcspn(string, "\\");
    _ = &read;
    if (@as(c_int, read.*) == @as(c_int, 0)) {
        return @bitCast(@as(c_longlong, @divExact(@as(c_longlong, @bitCast(@intFromPtr(read) -% @intFromPtr(string))), @sizeOf(u8))));
    }
    var write: [*c]u8 = string;
    _ = &write;
    var last: [*c]u8 = string;
    _ = &last;
    while (true) {
        var written: cgltf_size = @bitCast(@as(c_longlong, @divExact(@as(c_longlong, @bitCast(@intFromPtr(read) -% @intFromPtr(last))), @sizeOf(u8))));
        _ = &written;
        const extern_local_memmove = struct {
            extern fn memmove(_Dst: ?*anyopaque, _Src: ?*const anyopaque, _Size: usize) ?*anyopaque;
        };
        _ = &extern_local_memmove;
        _ = memmove(@ptrCast(@alignCast(write)), @ptrCast(@alignCast(last)), written);
        write += written;
        if (@as(c_int, (blk: {
            const ref = &read;
            const tmp = ref.*;
            ref.* += 1;
            break :blk tmp;
        }).*) == @as(c_int, 0)) {
            break;
        }
        while (true) {
            switch (@as(c_int, (blk: {
                const ref = &read;
                const tmp = ref.*;
                ref.* += 1;
                break :blk tmp;
            }).*)) {
                @as(c_int, '"') => {
                    (blk: {
                        const ref = &write;
                        const tmp = ref.*;
                        ref.* += 1;
                        break :blk tmp;
                    }).* = '"';
                    break;
                },
                @as(c_int, '/') => {
                    (blk: {
                        const ref = &write;
                        const tmp = ref.*;
                        ref.* += 1;
                        break :blk tmp;
                    }).* = '/';
                    break;
                },
                @as(c_int, '\\') => {
                    (blk: {
                        const ref = &write;
                        const tmp = ref.*;
                        ref.* += 1;
                        break :blk tmp;
                    }).* = '\\';
                    break;
                },
                @as(c_int, 'b') => {
                    (blk: {
                        const ref = &write;
                        const tmp = ref.*;
                        ref.* += 1;
                        break :blk tmp;
                    }).* = '\x08';
                    break;
                },
                @as(c_int, 'f') => {
                    (blk: {
                        const ref = &write;
                        const tmp = ref.*;
                        ref.* += 1;
                        break :blk tmp;
                    }).* = '\x0c';
                    break;
                },
                @as(c_int, 'r') => {
                    (blk: {
                        const ref = &write;
                        const tmp = ref.*;
                        ref.* += 1;
                        break :blk tmp;
                    }).* = '\r';
                    break;
                },
                @as(c_int, 'n') => {
                    (blk: {
                        const ref = &write;
                        const tmp = ref.*;
                        ref.* += 1;
                        break :blk tmp;
                    }).* = '\n';
                    break;
                },
                @as(c_int, 't') => {
                    (blk: {
                        const ref = &write;
                        const tmp = ref.*;
                        ref.* += 1;
                        break :blk tmp;
                    }).* = '\t';
                    break;
                },
                @as(c_int, 'u') => {
                    {
                        var character: c_int = 0;
                        _ = &character;
                        {
                            var i: cgltf_size = 0;
                            _ = &i;
                            while (i < @as(cgltf_size, 4)) : (i +%= 1) {
                                character = (character << @intCast(@as(c_int, 4))) + cgltf_unhex((blk: {
                                    const ref = &read;
                                    const tmp = ref.*;
                                    ref.* += 1;
                                    break :blk tmp;
                                }).*);
                            }
                        }
                        if (character <= @as(c_int, 127)) {
                            (blk: {
                                const ref = &write;
                                const tmp = ref.*;
                                ref.* += 1;
                                break :blk tmp;
                            }).* = @bitCast(@as(i8, @truncate(character & @as(c_int, 255))));
                        } else if (character <= @as(c_int, 2047)) {
                            (blk: {
                                const ref = &write;
                                const tmp = ref.*;
                                ref.* += 1;
                                break :blk tmp;
                            }).* = @bitCast(@as(i8, @truncate(@as(c_int, 192) | ((character >> @intCast(@as(c_int, 6))) & @as(c_int, 255)))));
                            (blk: {
                                const ref = &write;
                                const tmp = ref.*;
                                ref.* += 1;
                                break :blk tmp;
                            }).* = @bitCast(@as(i8, @truncate(@as(c_int, 128) | (character & @as(c_int, 63)))));
                        } else {
                            (blk: {
                                const ref = &write;
                                const tmp = ref.*;
                                ref.* += 1;
                                break :blk tmp;
                            }).* = @bitCast(@as(i8, @truncate(@as(c_int, 224) | ((character >> @intCast(@as(c_int, 12))) & @as(c_int, 255)))));
                            (blk: {
                                const ref = &write;
                                const tmp = ref.*;
                                ref.* += 1;
                                break :blk tmp;
                            }).* = @bitCast(@as(i8, @truncate(@as(c_int, 128) | ((character >> @intCast(@as(c_int, 6))) & @as(c_int, 63)))));
                            (blk: {
                                const ref = &write;
                                const tmp = ref.*;
                                ref.* += 1;
                                break :blk tmp;
                            }).* = @bitCast(@as(i8, @truncate(@as(c_int, 128) | (character & @as(c_int, 63)))));
                        }
                        break;
                    }
                },
                else => {
                    break;
                },
            }
            break;
        }
        last = read;
        read += extern_local_strcspn.strcspn(read, "\\");
    }
    write.* = 0;
    return @bitCast(@as(c_longlong, @divExact(@as(c_longlong, @bitCast(@intFromPtr(write) -% @intFromPtr(string))), @sizeOf(u8))));
}
pub export fn cgltf_decode_uri(arg_uri: [*c]u8) cgltf_size {
    var uri = arg_uri;
    _ = &uri;
    var write: [*c]u8 = uri;
    _ = &write;
    var i: [*c]u8 = uri;
    _ = &i;
    while (@as(c_int, i.*) != 0) {
        if (@as(c_int, i.*) == @as(c_int, '%')) {
            var ch1: c_int = cgltf_unhex(i[@as(c_int, 1)]);
            _ = &ch1;
            if (ch1 >= @as(c_int, 0)) {
                var ch2: c_int = cgltf_unhex(i[@as(c_int, 2)]);
                _ = &ch2;
                if (ch2 >= @as(c_int, 0)) {
                    (blk: {
                        const ref = &write;
                        const tmp = ref.*;
                        ref.* += 1;
                        break :blk tmp;
                    }).* = @bitCast(@as(i8, @truncate((ch1 * @as(c_int, 16)) + ch2)));
                    i += @as(usize, @bitCast(@as(isize, @intCast(3))));
                    continue;
                }
            }
        }
        (blk: {
            const ref = &write;
            const tmp = ref.*;
            ref.* += 1;
            break :blk tmp;
        }).* = (blk: {
            const ref = &i;
            const tmp = ref.*;
            ref.* += 1;
            break :blk tmp;
        }).*;
    }
    write.* = 0;
    return @bitCast(@as(c_longlong, @divExact(@as(c_longlong, @bitCast(@intFromPtr(write) -% @intFromPtr(uri))), @sizeOf(u8))));
}
pub export fn cgltf_validate(arg_data: [*c]cgltf_data) cgltf_result {
    var data = arg_data;
    _ = &data;
    {
        var i: cgltf_size = 0;
        _ = &i;
        while (i < data.*.accessors_count) : (i +%= 1) {
            var accessor: [*c]cgltf_accessor = &data.*.accessors[@intCast(i)];
            _ = &accessor;
            if (data.*.accessors[@intCast(i)].component_type == @as(cgltf_component_type, cgltf_component_type_invalid)) return cgltf_result_invalid_gltf;
            if (data.*.accessors[@intCast(i)].type == @as(cgltf_type, cgltf_type_invalid)) return cgltf_result_invalid_gltf;
            var element_size: cgltf_size = cgltf_calc_size(accessor.*.type, accessor.*.component_type);
            _ = &element_size;
            if (accessor.*.buffer_view != null) {
                var req_size: cgltf_size = (accessor.*.offset +% (accessor.*.stride *% (accessor.*.count -% @as(cgltf_size, 1)))) +% element_size;
                _ = &req_size;
                if (accessor.*.buffer_view.*.size < req_size) return cgltf_result_data_too_short;
            }
            if (accessor.*.is_sparse != 0) {
                var sparse: [*c]cgltf_accessor_sparse = &accessor.*.sparse;
                _ = &sparse;
                var indices_component_size: cgltf_size = cgltf_component_size(sparse.*.indices_component_type);
                _ = &indices_component_size;
                var indices_req_size: cgltf_size = sparse.*.indices_byte_offset +% (indices_component_size *% sparse.*.count);
                _ = &indices_req_size;
                var values_req_size: cgltf_size = sparse.*.values_byte_offset +% (element_size *% sparse.*.count);
                _ = &values_req_size;
                if ((sparse.*.indices_buffer_view.*.size < indices_req_size) or (sparse.*.values_buffer_view.*.size < values_req_size)) return cgltf_result_data_too_short;
                if (((sparse.*.indices_component_type != @as(cgltf_component_type, cgltf_component_type_r_8u)) and (sparse.*.indices_component_type != @as(cgltf_component_type, cgltf_component_type_r_16u))) and (sparse.*.indices_component_type != @as(cgltf_component_type, cgltf_component_type_r_32u))) return cgltf_result_invalid_gltf;
                if (sparse.*.indices_buffer_view.*.buffer.*.data != null) {
                    var index_bound: cgltf_size = cgltf_calc_index_bound(sparse.*.indices_buffer_view, sparse.*.indices_byte_offset, sparse.*.indices_component_type, sparse.*.count);
                    _ = &index_bound;
                    if (index_bound >= accessor.*.count) return cgltf_result_data_too_short;
                }
            }
        }
    }
    {
        var i: cgltf_size = 0;
        _ = &i;
        while (i < data.*.buffer_views_count) : (i +%= 1) {
            var req_size: cgltf_size = data.*.buffer_views[@intCast(i)].offset +% data.*.buffer_views[@intCast(i)].size;
            _ = &req_size;
            if ((data.*.buffer_views[@intCast(i)].buffer != null) and (data.*.buffer_views[@intCast(i)].buffer.*.size < req_size)) return cgltf_result_data_too_short;
            if (data.*.buffer_views[@intCast(i)].has_meshopt_compression != 0) {
                var mc: [*c]cgltf_meshopt_compression = &data.*.buffer_views[@intCast(i)].meshopt_compression;
                _ = &mc;
                if ((@as(?*anyopaque, @ptrCast(@alignCast(mc.*.buffer))) == @as(?*anyopaque, null)) or (mc.*.buffer.*.size < (mc.*.offset +% mc.*.size))) return cgltf_result_data_too_short;
                if ((data.*.buffer_views[@intCast(i)].stride != 0) and (@as(cgltf_size, @bitCast(@as(c_longlong, @intFromBool(mc.*.stride != data.*.buffer_views[@intCast(i)].stride)))) != 0)) return cgltf_result_invalid_gltf;
                if (data.*.buffer_views[@intCast(i)].size != (mc.*.stride *% mc.*.count)) return cgltf_result_invalid_gltf;
                if (mc.*.mode == @as(cgltf_meshopt_compression_mode, cgltf_meshopt_compression_mode_invalid)) return cgltf_result_invalid_gltf;
                if ((mc.*.mode == @as(cgltf_meshopt_compression_mode, cgltf_meshopt_compression_mode_attributes)) and !(((mc.*.stride % @as(cgltf_size, 4)) == @as(cgltf_size, 0)) and (mc.*.stride <= @as(cgltf_size, 256)))) return cgltf_result_invalid_gltf;
                if ((mc.*.mode == @as(cgltf_meshopt_compression_mode, cgltf_meshopt_compression_mode_triangles)) and ((mc.*.count % @as(cgltf_size, 3)) != @as(cgltf_size, 0))) return cgltf_result_invalid_gltf;
                if ((((mc.*.mode == @as(cgltf_meshopt_compression_mode, cgltf_meshopt_compression_mode_triangles)) or (mc.*.mode == @as(cgltf_meshopt_compression_mode, cgltf_meshopt_compression_mode_indices))) and (mc.*.stride != @as(cgltf_size, 2))) and (mc.*.stride != @as(cgltf_size, 4))) return cgltf_result_invalid_gltf;
                if (((mc.*.mode == @as(cgltf_meshopt_compression_mode, cgltf_meshopt_compression_mode_triangles)) or (mc.*.mode == @as(cgltf_meshopt_compression_mode, cgltf_meshopt_compression_mode_indices))) and (mc.*.filter != @as(cgltf_meshopt_compression_filter, cgltf_meshopt_compression_filter_none))) return cgltf_result_invalid_gltf;
                if (((mc.*.filter == @as(cgltf_meshopt_compression_filter, cgltf_meshopt_compression_filter_octahedral)) and (mc.*.stride != @as(cgltf_size, 4))) and (mc.*.stride != @as(cgltf_size, 8))) return cgltf_result_invalid_gltf;
                if ((mc.*.filter == @as(cgltf_meshopt_compression_filter, cgltf_meshopt_compression_filter_quaternion)) and (mc.*.stride != @as(cgltf_size, 8))) return cgltf_result_invalid_gltf;
                if (((mc.*.filter == @as(cgltf_meshopt_compression_filter, cgltf_meshopt_compression_filter_color)) and (mc.*.stride != @as(cgltf_size, 4))) and (mc.*.stride != @as(cgltf_size, 8))) return cgltf_result_invalid_gltf;
            }
        }
    }
    {
        var i: cgltf_size = 0;
        _ = &i;
        while (i < data.*.meshes_count) : (i +%= 1) {
            if (data.*.meshes[@intCast(i)].weights != null) {
                if ((data.*.meshes[@intCast(i)].primitives_count != 0) and (@as(cgltf_size, @bitCast(@as(c_longlong, @intFromBool(data.*.meshes[@intCast(i)].primitives[@as(c_int, 0)].targets_count != data.*.meshes[@intCast(i)].weights_count)))) != 0)) return cgltf_result_invalid_gltf;
            }
            if (data.*.meshes[@intCast(i)].target_names != null) {
                if ((data.*.meshes[@intCast(i)].primitives_count != 0) and (@as(cgltf_size, @bitCast(@as(c_longlong, @intFromBool(data.*.meshes[@intCast(i)].primitives[@as(c_int, 0)].targets_count != data.*.meshes[@intCast(i)].target_names_count)))) != 0)) return cgltf_result_invalid_gltf;
            }
            {
                var j: cgltf_size = 0;
                _ = &j;
                while (j < data.*.meshes[@intCast(i)].primitives_count) : (j +%= 1) {
                    if (data.*.meshes[@intCast(i)].primitives[@intCast(j)].type == @as(cgltf_primitive_type, cgltf_primitive_type_invalid)) return cgltf_result_invalid_gltf;
                    if (data.*.meshes[@intCast(i)].primitives[@intCast(j)].targets_count != data.*.meshes[@intCast(i)].primitives[@as(c_int, 0)].targets_count) return cgltf_result_invalid_gltf;
                    if (data.*.meshes[@intCast(i)].primitives[@intCast(j)].attributes_count == @as(cgltf_size, 0)) return cgltf_result_invalid_gltf;
                    var first: [*c]cgltf_accessor = data.*.meshes[@intCast(i)].primitives[@intCast(j)].attributes[@as(c_int, 0)].data;
                    _ = &first;
                    if (first.*.count == @as(cgltf_size, 0)) return cgltf_result_invalid_gltf;
                    {
                        var k: cgltf_size = 0;
                        _ = &k;
                        while (k < data.*.meshes[@intCast(i)].primitives[@intCast(j)].attributes_count) : (k +%= 1) {
                            if (data.*.meshes[@intCast(i)].primitives[@intCast(j)].attributes[@intCast(k)].data.*.count != first.*.count) return cgltf_result_invalid_gltf;
                        }
                    }
                    {
                        var k: cgltf_size = 0;
                        _ = &k;
                        while (k < data.*.meshes[@intCast(i)].primitives[@intCast(j)].targets_count) : (k +%= 1) {
                            {
                                var m: cgltf_size = 0;
                                _ = &m;
                                while (m < data.*.meshes[@intCast(i)].primitives[@intCast(j)].targets[@intCast(k)].attributes_count) : (m +%= 1) {
                                    if (data.*.meshes[@intCast(i)].primitives[@intCast(j)].targets[@intCast(k)].attributes[@intCast(m)].data.*.count != first.*.count) return cgltf_result_invalid_gltf;
                                }
                            }
                        }
                    }
                    var indices: [*c]cgltf_accessor = data.*.meshes[@intCast(i)].primitives[@intCast(j)].indices;
                    _ = &indices;
                    if ((((indices != null) and (indices.*.component_type != @as(cgltf_component_type, cgltf_component_type_r_8u))) and (indices.*.component_type != @as(cgltf_component_type, cgltf_component_type_r_16u))) and (indices.*.component_type != @as(cgltf_component_type, cgltf_component_type_r_32u))) return cgltf_result_invalid_gltf;
                    if ((indices != null) and (indices.*.type != @as(cgltf_type, cgltf_type_scalar))) return cgltf_result_invalid_gltf;
                    if ((indices != null) and (indices.*.stride != cgltf_component_size(indices.*.component_type))) return cgltf_result_invalid_gltf;
                    if (((indices != null) and (indices.*.buffer_view != null)) and (indices.*.buffer_view.*.buffer.*.data != null)) {
                        var index_bound: cgltf_size = cgltf_calc_index_bound(indices.*.buffer_view, indices.*.offset, indices.*.component_type, indices.*.count);
                        _ = &index_bound;
                        if (index_bound >= first.*.count) return cgltf_result_data_too_short;
                    }
                    {
                        var k: cgltf_size = 0;
                        _ = &k;
                        while (k < data.*.meshes[@intCast(i)].primitives[@intCast(j)].mappings_count) : (k +%= 1) {
                            if (data.*.meshes[@intCast(i)].primitives[@intCast(j)].mappings[@intCast(k)].variant >= data.*.variants_count) return cgltf_result_invalid_gltf;
                        }
                    }
                }
            }
        }
    }
    {
        var i: cgltf_size = 0;
        _ = &i;
        while (i < data.*.nodes_count) : (i +%= 1) {
            if ((data.*.nodes[@intCast(i)].weights != null) and (data.*.nodes[@intCast(i)].mesh != null)) {
                if ((data.*.nodes[@intCast(i)].mesh.*.primitives_count != 0) and (@as(cgltf_size, @bitCast(@as(c_longlong, @intFromBool(data.*.nodes[@intCast(i)].mesh.*.primitives[@as(c_int, 0)].targets_count != data.*.nodes[@intCast(i)].weights_count)))) != 0)) return cgltf_result_invalid_gltf;
            }
            if (data.*.nodes[@intCast(i)].has_mesh_gpu_instancing != 0) {
                if (@as(?*anyopaque, @ptrCast(@alignCast(data.*.nodes[@intCast(i)].mesh))) == @as(?*anyopaque, null)) return cgltf_result_invalid_gltf;
                if (data.*.nodes[@intCast(i)].mesh_gpu_instancing.attributes_count == @as(cgltf_size, 0)) return cgltf_result_invalid_gltf;
                var first: [*c]cgltf_accessor = data.*.nodes[@intCast(i)].mesh_gpu_instancing.attributes[@as(c_int, 0)].data;
                _ = &first;
                {
                    var k: cgltf_size = 0;
                    _ = &k;
                    while (k < data.*.nodes[@intCast(i)].mesh_gpu_instancing.attributes_count) : (k +%= 1) {
                        if (data.*.nodes[@intCast(i)].mesh_gpu_instancing.attributes[@intCast(k)].data.*.count != first.*.count) return cgltf_result_invalid_gltf;
                    }
                }
            }
        }
    }
    {
        var i: cgltf_size = 0;
        _ = &i;
        while (i < data.*.nodes_count) : (i +%= 1) {
            var p1: [*c]cgltf_node = data.*.nodes[@intCast(i)].parent;
            _ = &p1;
            var p2: [*c]cgltf_node = @ptrCast(@alignCast(if (p1 != null) @as(?*anyopaque, @ptrCast(@alignCast(p1.*.parent))) else @as(?*anyopaque, null)));
            _ = &p2;
            while ((p1 != null) and (p2 != null)) {
                if (p1 == p2) return cgltf_result_invalid_gltf;
                p1 = p1.*.parent;
                p2 = @ptrCast(@alignCast(if (p2.*.parent != null) @as(?*anyopaque, @ptrCast(@alignCast(p2.*.parent.*.parent))) else @as(?*anyopaque, null)));
            }
        }
    }
    {
        var i: cgltf_size = 0;
        _ = &i;
        while (i < data.*.scenes_count) : (i +%= 1) {
            {
                var j: cgltf_size = 0;
                _ = &j;
                while (j < data.*.scenes[@intCast(i)].nodes_count) : (j +%= 1) {
                    if (data.*.scenes[@intCast(i)].nodes[@intCast(j)].*.parent != null) return cgltf_result_invalid_gltf;
                }
            }
        }
    }
    {
        var i: cgltf_size = 0;
        _ = &i;
        while (i < data.*.animations_count) : (i +%= 1) {
            {
                var j: cgltf_size = 0;
                _ = &j;
                while (j < data.*.animations[@intCast(i)].channels_count) : (j +%= 1) {
                    var channel: [*c]cgltf_animation_channel = &data.*.animations[@intCast(i)].channels[@intCast(j)];
                    _ = &channel;
                    if (!(channel.*.target_node != null)) {
                        continue;
                    }
                    var components: cgltf_size = 1;
                    _ = &components;
                    if (channel.*.target_path == @as(cgltf_animation_path_type, cgltf_animation_path_type_weights)) {
                        if (!(channel.*.target_node.*.mesh != null) or !(channel.*.target_node.*.mesh.*.primitives_count != 0)) return cgltf_result_invalid_gltf;
                        components = channel.*.target_node.*.mesh.*.primitives[@as(c_int, 0)].targets_count;
                    }
                    var values: cgltf_size = @bitCast(@as(c_longlong, if (channel.*.sampler.*.interpolation == @as(cgltf_interpolation_type, cgltf_interpolation_type_cubic_spline)) @as(c_int, 3) else @as(c_int, 1)));
                    _ = &values;
                    if (((channel.*.sampler.*.input.*.count *% components) *% values) != channel.*.sampler.*.output.*.count) return cgltf_result_invalid_gltf;
                }
            }
        }
    }
    {
        var i: cgltf_size = 0;
        _ = &i;
        while (i < data.*.variants_count) : (i +%= 1) {
            if (!(data.*.variants[@intCast(i)].name != null)) return cgltf_result_invalid_gltf;
        }
    }
    return cgltf_result_success;
}
pub export fn cgltf_free(arg_data: [*c]cgltf_data) void {
    var data = arg_data;
    _ = &data;
    if (!(data != null)) {
        return;
    }
    var file_release: ?*const fn ([*c]const struct_cgltf_memory_options, [*c]const struct_cgltf_file_options, data: ?*anyopaque, size: cgltf_size) callconv(.c) void = if (data.*.file.release != null) data.*.file.release else cgltf_default_file_release;
    _ = &file_release;
    data.*.memory.free_func.?(data.*.memory.user_data, @ptrCast(@alignCast(data.*.asset.copyright)));
    data.*.memory.free_func.?(data.*.memory.user_data, @ptrCast(@alignCast(data.*.asset.generator)));
    data.*.memory.free_func.?(data.*.memory.user_data, @ptrCast(@alignCast(data.*.asset.version)));
    data.*.memory.free_func.?(data.*.memory.user_data, @ptrCast(@alignCast(data.*.asset.min_version)));
    cgltf_free_extensions(data, data.*.asset.extensions, data.*.asset.extensions_count);
    cgltf_free_extras(data, &data.*.asset.extras);
    {
        var i: cgltf_size = 0;
        _ = &i;
        while (i < data.*.accessors_count) : (i +%= 1) {
            data.*.memory.free_func.?(data.*.memory.user_data, @ptrCast(@alignCast(data.*.accessors[@intCast(i)].name)));
            cgltf_free_extensions(data, data.*.accessors[@intCast(i)].extensions, data.*.accessors[@intCast(i)].extensions_count);
            cgltf_free_extras(data, &data.*.accessors[@intCast(i)].extras);
        }
    }
    data.*.memory.free_func.?(data.*.memory.user_data, @ptrCast(@alignCast(data.*.accessors)));
    {
        var i: cgltf_size = 0;
        _ = &i;
        while (i < data.*.buffer_views_count) : (i +%= 1) {
            data.*.memory.free_func.?(data.*.memory.user_data, @ptrCast(@alignCast(data.*.buffer_views[@intCast(i)].name)));
            data.*.memory.free_func.?(data.*.memory.user_data, data.*.buffer_views[@intCast(i)].data);
            cgltf_free_extensions(data, data.*.buffer_views[@intCast(i)].extensions, data.*.buffer_views[@intCast(i)].extensions_count);
            cgltf_free_extras(data, &data.*.buffer_views[@intCast(i)].extras);
        }
    }
    data.*.memory.free_func.?(data.*.memory.user_data, @ptrCast(@alignCast(data.*.buffer_views)));
    {
        var i: cgltf_size = 0;
        _ = &i;
        while (i < data.*.buffers_count) : (i +%= 1) {
            data.*.memory.free_func.?(data.*.memory.user_data, @ptrCast(@alignCast(data.*.buffers[@intCast(i)].name)));
            if (data.*.buffers[@intCast(i)].data_free_method == @as(cgltf_data_free_method, cgltf_data_free_method_file_release)) {
                file_release.?(&data.*.memory, &data.*.file, data.*.buffers[@intCast(i)].data, data.*.buffers[@intCast(i)].size);
            } else if (data.*.buffers[@intCast(i)].data_free_method == @as(cgltf_data_free_method, cgltf_data_free_method_memory_free)) {
                data.*.memory.free_func.?(data.*.memory.user_data, data.*.buffers[@intCast(i)].data);
            }
            data.*.memory.free_func.?(data.*.memory.user_data, @ptrCast(@alignCast(data.*.buffers[@intCast(i)].uri)));
            cgltf_free_extensions(data, data.*.buffers[@intCast(i)].extensions, data.*.buffers[@intCast(i)].extensions_count);
            cgltf_free_extras(data, &data.*.buffers[@intCast(i)].extras);
        }
    }
    data.*.memory.free_func.?(data.*.memory.user_data, @ptrCast(@alignCast(data.*.buffers)));
    {
        var i: cgltf_size = 0;
        _ = &i;
        while (i < data.*.meshes_count) : (i +%= 1) {
            data.*.memory.free_func.?(data.*.memory.user_data, @ptrCast(@alignCast(data.*.meshes[@intCast(i)].name)));
            {
                var j: cgltf_size = 0;
                _ = &j;
                while (j < data.*.meshes[@intCast(i)].primitives_count) : (j +%= 1) {
                    {
                        var k: cgltf_size = 0;
                        _ = &k;
                        while (k < data.*.meshes[@intCast(i)].primitives[@intCast(j)].attributes_count) : (k +%= 1) {
                            data.*.memory.free_func.?(data.*.memory.user_data, @ptrCast(@alignCast(data.*.meshes[@intCast(i)].primitives[@intCast(j)].attributes[@intCast(k)].name)));
                        }
                    }
                    data.*.memory.free_func.?(data.*.memory.user_data, @ptrCast(@alignCast(data.*.meshes[@intCast(i)].primitives[@intCast(j)].attributes)));
                    {
                        var k: cgltf_size = 0;
                        _ = &k;
                        while (k < data.*.meshes[@intCast(i)].primitives[@intCast(j)].targets_count) : (k +%= 1) {
                            {
                                var m: cgltf_size = 0;
                                _ = &m;
                                while (m < data.*.meshes[@intCast(i)].primitives[@intCast(j)].targets[@intCast(k)].attributes_count) : (m +%= 1) {
                                    data.*.memory.free_func.?(data.*.memory.user_data, @ptrCast(@alignCast(data.*.meshes[@intCast(i)].primitives[@intCast(j)].targets[@intCast(k)].attributes[@intCast(m)].name)));
                                }
                            }
                            data.*.memory.free_func.?(data.*.memory.user_data, @ptrCast(@alignCast(data.*.meshes[@intCast(i)].primitives[@intCast(j)].targets[@intCast(k)].attributes)));
                        }
                    }
                    data.*.memory.free_func.?(data.*.memory.user_data, @ptrCast(@alignCast(data.*.meshes[@intCast(i)].primitives[@intCast(j)].targets)));
                    if (data.*.meshes[@intCast(i)].primitives[@intCast(j)].has_draco_mesh_compression != 0) {
                        {
                            var k: cgltf_size = 0;
                            _ = &k;
                            while (k < data.*.meshes[@intCast(i)].primitives[@intCast(j)].draco_mesh_compression.attributes_count) : (k +%= 1) {
                                data.*.memory.free_func.?(data.*.memory.user_data, @ptrCast(@alignCast(data.*.meshes[@intCast(i)].primitives[@intCast(j)].draco_mesh_compression.attributes[@intCast(k)].name)));
                            }
                        }
                        data.*.memory.free_func.?(data.*.memory.user_data, @ptrCast(@alignCast(data.*.meshes[@intCast(i)].primitives[@intCast(j)].draco_mesh_compression.attributes)));
                    }
                    {
                        var k: cgltf_size = 0;
                        _ = &k;
                        while (k < data.*.meshes[@intCast(i)].primitives[@intCast(j)].mappings_count) : (k +%= 1) {
                            cgltf_free_extras(data, &data.*.meshes[@intCast(i)].primitives[@intCast(j)].mappings[@intCast(k)].extras);
                        }
                    }
                    data.*.memory.free_func.?(data.*.memory.user_data, @ptrCast(@alignCast(data.*.meshes[@intCast(i)].primitives[@intCast(j)].mappings)));
                    cgltf_free_extensions(data, data.*.meshes[@intCast(i)].primitives[@intCast(j)].extensions, data.*.meshes[@intCast(i)].primitives[@intCast(j)].extensions_count);
                    cgltf_free_extras(data, &data.*.meshes[@intCast(i)].primitives[@intCast(j)].extras);
                }
            }
            data.*.memory.free_func.?(data.*.memory.user_data, @ptrCast(@alignCast(data.*.meshes[@intCast(i)].primitives)));
            data.*.memory.free_func.?(data.*.memory.user_data, @ptrCast(@alignCast(data.*.meshes[@intCast(i)].weights)));
            {
                var j: cgltf_size = 0;
                _ = &j;
                while (j < data.*.meshes[@intCast(i)].target_names_count) : (j +%= 1) {
                    data.*.memory.free_func.?(data.*.memory.user_data, @ptrCast(@alignCast(data.*.meshes[@intCast(i)].target_names[@intCast(j)])));
                }
            }
            cgltf_free_extensions(data, data.*.meshes[@intCast(i)].extensions, data.*.meshes[@intCast(i)].extensions_count);
            cgltf_free_extras(data, &data.*.meshes[@intCast(i)].extras);
            data.*.memory.free_func.?(data.*.memory.user_data, @ptrCast(@alignCast(data.*.meshes[@intCast(i)].target_names)));
        }
    }
    data.*.memory.free_func.?(data.*.memory.user_data, @ptrCast(@alignCast(data.*.meshes)));
    {
        var i: cgltf_size = 0;
        _ = &i;
        while (i < data.*.materials_count) : (i +%= 1) {
            data.*.memory.free_func.?(data.*.memory.user_data, @ptrCast(@alignCast(data.*.materials[@intCast(i)].name)));
            cgltf_free_extensions(data, data.*.materials[@intCast(i)].extensions, data.*.materials[@intCast(i)].extensions_count);
            cgltf_free_extras(data, &data.*.materials[@intCast(i)].extras);
        }
    }
    data.*.memory.free_func.?(data.*.memory.user_data, @ptrCast(@alignCast(data.*.materials)));
    {
        var i: cgltf_size = 0;
        _ = &i;
        while (i < data.*.images_count) : (i +%= 1) {
            data.*.memory.free_func.?(data.*.memory.user_data, @ptrCast(@alignCast(data.*.images[@intCast(i)].name)));
            data.*.memory.free_func.?(data.*.memory.user_data, @ptrCast(@alignCast(data.*.images[@intCast(i)].uri)));
            data.*.memory.free_func.?(data.*.memory.user_data, @ptrCast(@alignCast(data.*.images[@intCast(i)].mime_type)));
            cgltf_free_extensions(data, data.*.images[@intCast(i)].extensions, data.*.images[@intCast(i)].extensions_count);
            cgltf_free_extras(data, &data.*.images[@intCast(i)].extras);
        }
    }
    data.*.memory.free_func.?(data.*.memory.user_data, @ptrCast(@alignCast(data.*.images)));
    {
        var i: cgltf_size = 0;
        _ = &i;
        while (i < data.*.textures_count) : (i +%= 1) {
            data.*.memory.free_func.?(data.*.memory.user_data, @ptrCast(@alignCast(data.*.textures[@intCast(i)].name)));
            cgltf_free_extensions(data, data.*.textures[@intCast(i)].extensions, data.*.textures[@intCast(i)].extensions_count);
            cgltf_free_extras(data, &data.*.textures[@intCast(i)].extras);
        }
    }
    data.*.memory.free_func.?(data.*.memory.user_data, @ptrCast(@alignCast(data.*.textures)));
    {
        var i: cgltf_size = 0;
        _ = &i;
        while (i < data.*.samplers_count) : (i +%= 1) {
            data.*.memory.free_func.?(data.*.memory.user_data, @ptrCast(@alignCast(data.*.samplers[@intCast(i)].name)));
            cgltf_free_extensions(data, data.*.samplers[@intCast(i)].extensions, data.*.samplers[@intCast(i)].extensions_count);
            cgltf_free_extras(data, &data.*.samplers[@intCast(i)].extras);
        }
    }
    data.*.memory.free_func.?(data.*.memory.user_data, @ptrCast(@alignCast(data.*.samplers)));
    {
        var i: cgltf_size = 0;
        _ = &i;
        while (i < data.*.skins_count) : (i +%= 1) {
            data.*.memory.free_func.?(data.*.memory.user_data, @ptrCast(@alignCast(data.*.skins[@intCast(i)].name)));
            data.*.memory.free_func.?(data.*.memory.user_data, @ptrCast(@alignCast(data.*.skins[@intCast(i)].joints)));
            cgltf_free_extensions(data, data.*.skins[@intCast(i)].extensions, data.*.skins[@intCast(i)].extensions_count);
            cgltf_free_extras(data, &data.*.skins[@intCast(i)].extras);
        }
    }
    data.*.memory.free_func.?(data.*.memory.user_data, @ptrCast(@alignCast(data.*.skins)));
    {
        var i: cgltf_size = 0;
        _ = &i;
        while (i < data.*.cameras_count) : (i +%= 1) {
            data.*.memory.free_func.?(data.*.memory.user_data, @ptrCast(@alignCast(data.*.cameras[@intCast(i)].name)));
            if (data.*.cameras[@intCast(i)].type == @as(cgltf_camera_type, cgltf_camera_type_perspective)) {
                cgltf_free_extras(data, &data.*.cameras[@intCast(i)].data.perspective.extras);
            } else if (data.*.cameras[@intCast(i)].type == @as(cgltf_camera_type, cgltf_camera_type_orthographic)) {
                cgltf_free_extras(data, &data.*.cameras[@intCast(i)].data.orthographic.extras);
            }
            cgltf_free_extensions(data, data.*.cameras[@intCast(i)].extensions, data.*.cameras[@intCast(i)].extensions_count);
            cgltf_free_extras(data, &data.*.cameras[@intCast(i)].extras);
        }
    }
    data.*.memory.free_func.?(data.*.memory.user_data, @ptrCast(@alignCast(data.*.cameras)));
    {
        var i: cgltf_size = 0;
        _ = &i;
        while (i < data.*.lights_count) : (i +%= 1) {
            data.*.memory.free_func.?(data.*.memory.user_data, @ptrCast(@alignCast(data.*.lights[@intCast(i)].name)));
            cgltf_free_extras(data, &data.*.lights[@intCast(i)].extras);
        }
    }
    data.*.memory.free_func.?(data.*.memory.user_data, @ptrCast(@alignCast(data.*.lights)));
    {
        var i: cgltf_size = 0;
        _ = &i;
        while (i < data.*.nodes_count) : (i +%= 1) {
            data.*.memory.free_func.?(data.*.memory.user_data, @ptrCast(@alignCast(data.*.nodes[@intCast(i)].name)));
            data.*.memory.free_func.?(data.*.memory.user_data, @ptrCast(@alignCast(data.*.nodes[@intCast(i)].children)));
            data.*.memory.free_func.?(data.*.memory.user_data, @ptrCast(@alignCast(data.*.nodes[@intCast(i)].weights)));
            if (data.*.nodes[@intCast(i)].has_mesh_gpu_instancing != 0) {
                {
                    var j: cgltf_size = 0;
                    _ = &j;
                    while (j < data.*.nodes[@intCast(i)].mesh_gpu_instancing.attributes_count) : (j +%= 1) {
                        data.*.memory.free_func.?(data.*.memory.user_data, @ptrCast(@alignCast(data.*.nodes[@intCast(i)].mesh_gpu_instancing.attributes[@intCast(j)].name)));
                    }
                }
                data.*.memory.free_func.?(data.*.memory.user_data, @ptrCast(@alignCast(data.*.nodes[@intCast(i)].mesh_gpu_instancing.attributes)));
            }
            cgltf_free_extensions(data, data.*.nodes[@intCast(i)].extensions, data.*.nodes[@intCast(i)].extensions_count);
            cgltf_free_extras(data, &data.*.nodes[@intCast(i)].extras);
        }
    }
    data.*.memory.free_func.?(data.*.memory.user_data, @ptrCast(@alignCast(data.*.nodes)));
    {
        var i: cgltf_size = 0;
        _ = &i;
        while (i < data.*.scenes_count) : (i +%= 1) {
            data.*.memory.free_func.?(data.*.memory.user_data, @ptrCast(@alignCast(data.*.scenes[@intCast(i)].name)));
            data.*.memory.free_func.?(data.*.memory.user_data, @ptrCast(@alignCast(data.*.scenes[@intCast(i)].nodes)));
            cgltf_free_extensions(data, data.*.scenes[@intCast(i)].extensions, data.*.scenes[@intCast(i)].extensions_count);
            cgltf_free_extras(data, &data.*.scenes[@intCast(i)].extras);
        }
    }
    data.*.memory.free_func.?(data.*.memory.user_data, @ptrCast(@alignCast(data.*.scenes)));
    {
        var i: cgltf_size = 0;
        _ = &i;
        while (i < data.*.animations_count) : (i +%= 1) {
            data.*.memory.free_func.?(data.*.memory.user_data, @ptrCast(@alignCast(data.*.animations[@intCast(i)].name)));
            {
                var j: cgltf_size = 0;
                _ = &j;
                while (j < data.*.animations[@intCast(i)].samplers_count) : (j +%= 1) {
                    cgltf_free_extensions(data, data.*.animations[@intCast(i)].samplers[@intCast(j)].extensions, data.*.animations[@intCast(i)].samplers[@intCast(j)].extensions_count);
                    cgltf_free_extras(data, &data.*.animations[@intCast(i)].samplers[@intCast(j)].extras);
                }
            }
            data.*.memory.free_func.?(data.*.memory.user_data, @ptrCast(@alignCast(data.*.animations[@intCast(i)].samplers)));
            {
                var j: cgltf_size = 0;
                _ = &j;
                while (j < data.*.animations[@intCast(i)].channels_count) : (j +%= 1) {
                    cgltf_free_extensions(data, data.*.animations[@intCast(i)].channels[@intCast(j)].extensions, data.*.animations[@intCast(i)].channels[@intCast(j)].extensions_count);
                    cgltf_free_extras(data, &data.*.animations[@intCast(i)].channels[@intCast(j)].extras);
                }
            }
            data.*.memory.free_func.?(data.*.memory.user_data, @ptrCast(@alignCast(data.*.animations[@intCast(i)].channels)));
            cgltf_free_extensions(data, data.*.animations[@intCast(i)].extensions, data.*.animations[@intCast(i)].extensions_count);
            cgltf_free_extras(data, &data.*.animations[@intCast(i)].extras);
        }
    }
    data.*.memory.free_func.?(data.*.memory.user_data, @ptrCast(@alignCast(data.*.animations)));
    {
        var i: cgltf_size = 0;
        _ = &i;
        while (i < data.*.variants_count) : (i +%= 1) {
            data.*.memory.free_func.?(data.*.memory.user_data, @ptrCast(@alignCast(data.*.variants[@intCast(i)].name)));
            cgltf_free_extras(data, &data.*.variants[@intCast(i)].extras);
        }
    }
    data.*.memory.free_func.?(data.*.memory.user_data, @ptrCast(@alignCast(data.*.variants)));
    cgltf_free_extensions(data, data.*.data_extensions, data.*.data_extensions_count);
    cgltf_free_extras(data, &data.*.extras);
    {
        var i: cgltf_size = 0;
        _ = &i;
        while (i < data.*.extensions_used_count) : (i +%= 1) {
            data.*.memory.free_func.?(data.*.memory.user_data, @ptrCast(@alignCast(data.*.extensions_used[@intCast(i)])));
        }
    }
    data.*.memory.free_func.?(data.*.memory.user_data, @ptrCast(@alignCast(data.*.extensions_used)));
    {
        var i: cgltf_size = 0;
        _ = &i;
        while (i < data.*.extensions_required_count) : (i +%= 1) {
            data.*.memory.free_func.?(data.*.memory.user_data, @ptrCast(@alignCast(data.*.extensions_required[@intCast(i)])));
        }
    }
    data.*.memory.free_func.?(data.*.memory.user_data, @ptrCast(@alignCast(data.*.extensions_required)));
    file_release.?(&data.*.memory, &data.*.file, data.*.file_data, data.*.file_size);
    data.*.memory.free_func.?(data.*.memory.user_data, @ptrCast(@alignCast(data)));
}
pub export fn cgltf_node_transform_local(arg_node: [*c]const cgltf_node, arg_out_matrix: [*c]cgltf_float) void {
    var node = arg_node;
    _ = &node;
    var out_matrix = arg_out_matrix;
    _ = &out_matrix;
    var lm: [*c]cgltf_float = out_matrix;
    _ = &lm;
    if (node.*.has_matrix != 0) {
        const extern_local_memcpy = struct {
            extern fn memcpy(noalias _Dst: ?*anyopaque, noalias _Src: ?*const anyopaque, _Size: usize) ?*anyopaque;
        };
        _ = &extern_local_memcpy;
        _ = memcpy(@ptrCast(@alignCast(lm)), @ptrCast(@alignCast(@as([*c]cgltf_float, @ptrCast(@alignCast(&node.*.matrix))))), @sizeOf(f32) *% @as(c_ulonglong, 16));
    } else {
        var tx: f32 = node.*.translation[@as(c_int, 0)];
        _ = &tx;
        var ty: f32 = node.*.translation[@as(c_int, 1)];
        _ = &ty;
        var tz: f32 = node.*.translation[@as(c_int, 2)];
        _ = &tz;
        var qx: f32 = node.*.rotation[@as(c_int, 0)];
        _ = &qx;
        var qy: f32 = node.*.rotation[@as(c_int, 1)];
        _ = &qy;
        var qz: f32 = node.*.rotation[@as(c_int, 2)];
        _ = &qz;
        var qw: f32 = node.*.rotation[@as(c_int, 3)];
        _ = &qw;
        var sx: f32 = node.*.scale[@as(c_int, 0)];
        _ = &sx;
        var sy: f32 = node.*.scale[@as(c_int, 1)];
        _ = &sy;
        var sz: f32 = node.*.scale[@as(c_int, 2)];
        _ = &sz;
        lm[@as(c_int, 0)] = ((@as(f32, @floatFromInt(@as(c_int, 1))) - ((@as(f32, @floatFromInt(@as(c_int, 2))) * qy) * qy)) - ((@as(f32, @floatFromInt(@as(c_int, 2))) * qz) * qz)) * sx;
        lm[@as(c_int, 1)] = (((@as(f32, @floatFromInt(@as(c_int, 2))) * qx) * qy) + ((@as(f32, @floatFromInt(@as(c_int, 2))) * qz) * qw)) * sx;
        lm[@as(c_int, 2)] = (((@as(f32, @floatFromInt(@as(c_int, 2))) * qx) * qz) - ((@as(f32, @floatFromInt(@as(c_int, 2))) * qy) * qw)) * sx;
        lm[@as(c_int, 3)] = 0.0;
        lm[@as(c_int, 4)] = (((@as(f32, @floatFromInt(@as(c_int, 2))) * qx) * qy) - ((@as(f32, @floatFromInt(@as(c_int, 2))) * qz) * qw)) * sy;
        lm[@as(c_int, 5)] = ((@as(f32, @floatFromInt(@as(c_int, 1))) - ((@as(f32, @floatFromInt(@as(c_int, 2))) * qx) * qx)) - ((@as(f32, @floatFromInt(@as(c_int, 2))) * qz) * qz)) * sy;
        lm[@as(c_int, 6)] = (((@as(f32, @floatFromInt(@as(c_int, 2))) * qy) * qz) + ((@as(f32, @floatFromInt(@as(c_int, 2))) * qx) * qw)) * sy;
        lm[@as(c_int, 7)] = 0.0;
        lm[@as(c_int, 8)] = (((@as(f32, @floatFromInt(@as(c_int, 2))) * qx) * qz) + ((@as(f32, @floatFromInt(@as(c_int, 2))) * qy) * qw)) * sz;
        lm[@as(c_int, 9)] = (((@as(f32, @floatFromInt(@as(c_int, 2))) * qy) * qz) - ((@as(f32, @floatFromInt(@as(c_int, 2))) * qx) * qw)) * sz;
        lm[@as(c_int, 10)] = ((@as(f32, @floatFromInt(@as(c_int, 1))) - ((@as(f32, @floatFromInt(@as(c_int, 2))) * qx) * qx)) - ((@as(f32, @floatFromInt(@as(c_int, 2))) * qy) * qy)) * sz;
        lm[@as(c_int, 11)] = 0.0;
        lm[@as(c_int, 12)] = tx;
        lm[@as(c_int, 13)] = ty;
        lm[@as(c_int, 14)] = tz;
        lm[@as(c_int, 15)] = 1.0;
    }
}
pub export fn cgltf_node_transform_world(arg_node: [*c]const cgltf_node, arg_out_matrix: [*c]cgltf_float) void {
    var node = arg_node;
    _ = &node;
    var out_matrix = arg_out_matrix;
    _ = &out_matrix;
    var lm: [*c]cgltf_float = out_matrix;
    _ = &lm;
    cgltf_node_transform_local(node, lm);
    var parent: [*c]const cgltf_node = node.*.parent;
    _ = &parent;
    while (parent != null) {
        var pm: [16]f32 = undefined;
        _ = &pm;
        cgltf_node_transform_local(parent, @ptrCast(@alignCast(&pm)));
        {
            var i: c_int = 0;
            _ = &i;
            while (i < @as(c_int, 4)) : (i += 1) {
                var l0: f32 = lm[@bitCast(@as(isize, @intCast((i * @as(c_int, 4)) + @as(c_int, 0))))];
                _ = &l0;
                var l1: f32 = lm[@bitCast(@as(isize, @intCast((i * @as(c_int, 4)) + @as(c_int, 1))))];
                _ = &l1;
                var l2: f32 = lm[@bitCast(@as(isize, @intCast((i * @as(c_int, 4)) + @as(c_int, 2))))];
                _ = &l2;
                var r0: f32 = ((l0 * pm[@as(c_int, 0)]) + (l1 * pm[@as(c_int, 4)])) + (l2 * pm[@as(c_int, 8)]);
                _ = &r0;
                var r1: f32 = ((l0 * pm[@as(c_int, 1)]) + (l1 * pm[@as(c_int, 5)])) + (l2 * pm[@as(c_int, 9)]);
                _ = &r1;
                var r2: f32 = ((l0 * pm[@as(c_int, 2)]) + (l1 * pm[@as(c_int, 6)])) + (l2 * pm[@as(c_int, 10)]);
                _ = &r2;
                lm[@bitCast(@as(isize, @intCast((i * @as(c_int, 4)) + @as(c_int, 0))))] = r0;
                lm[@bitCast(@as(isize, @intCast((i * @as(c_int, 4)) + @as(c_int, 1))))] = r1;
                lm[@bitCast(@as(isize, @intCast((i * @as(c_int, 4)) + @as(c_int, 2))))] = r2;
            }
        }
        lm[@as(c_int, 12)] += pm[@as(c_int, 12)];
        lm[@as(c_int, 13)] += pm[@as(c_int, 13)];
        lm[@as(c_int, 14)] += pm[@as(c_int, 14)];
        parent = parent.*.parent;
    }
}
pub export fn cgltf_buffer_view_data(arg_view: [*c]const cgltf_buffer_view) [*c]const u8 {
    var view = arg_view;
    _ = &view;
    if (view.*.data != null) return @ptrCast(@alignCast(view.*.data));
    if (!(view.*.buffer.*.data != null)) return null;
    var result: [*c]const u8 = @ptrCast(@alignCast(view.*.buffer.*.data));
    _ = &result;
    result += view.*.offset;
    return result;
}
pub export fn cgltf_find_accessor(arg_prim: [*c]const cgltf_primitive, arg_type: cgltf_attribute_type, arg_index: cgltf_int) [*c]const cgltf_accessor {
    var prim = arg_prim;
    _ = &prim;
    var @"type" = arg_type;
    _ = &@"type";
    var index = arg_index;
    _ = &index;
    {
        var i: cgltf_size = 0;
        _ = &i;
        while (i < prim.*.attributes_count) : (i +%= 1) {
            var attr: [*c]const cgltf_attribute = &prim.*.attributes[@intCast(i)];
            _ = &attr;
            if ((attr.*.type == @"type") and (attr.*.index == index)) return attr.*.data;
        }
    }
    return null;
}
pub export fn cgltf_accessor_read_float(arg_accessor: [*c]const cgltf_accessor, arg_index: cgltf_size, arg_out: [*c]cgltf_float, arg_element_size: cgltf_size) cgltf_bool {
    var accessor = arg_accessor;
    _ = &accessor;
    var index = arg_index;
    _ = &index;
    var out = arg_out;
    _ = &out;
    var element_size = arg_element_size;
    _ = &element_size;
    if (accessor.*.is_sparse != 0) {
        var element: [*c]const u8 = cgltf_find_sparse_index(accessor, index);
        _ = &element;
        if (element != null) return cgltf_element_read_float(element, accessor.*.type, accessor.*.component_type, accessor.*.normalized, out, element_size);
    }
    if (@as(?*anyopaque, @ptrCast(@alignCast(accessor.*.buffer_view))) == @as(?*anyopaque, null)) {
        const extern_local_memset = struct {
            extern fn memset(_Dst: ?*anyopaque, _Val: c_int, _Size: usize) ?*anyopaque;
        };
        _ = &extern_local_memset;
        _ = memset(@ptrCast(@alignCast(out)), 0, element_size *% @sizeOf(cgltf_float));
        return 1;
    }
    var element: [*c]const u8 = cgltf_buffer_view_data(accessor.*.buffer_view);
    _ = &element;
    if (@as(?*anyopaque, @ptrCast(@alignCast(@constCast(element)))) == @as(?*anyopaque, null)) {
        return 0;
    }
    element += accessor.*.offset +% (accessor.*.stride *% index);
    return cgltf_element_read_float(element, accessor.*.type, accessor.*.component_type, accessor.*.normalized, out, element_size);
}
pub export fn cgltf_accessor_read_uint(arg_accessor: [*c]const cgltf_accessor, arg_index: cgltf_size, arg_out: [*c]cgltf_uint, arg_element_size: cgltf_size) cgltf_bool {
    var accessor = arg_accessor;
    _ = &accessor;
    var index = arg_index;
    _ = &index;
    var out = arg_out;
    _ = &out;
    var element_size = arg_element_size;
    _ = &element_size;
    if (accessor.*.is_sparse != 0) {
        var element: [*c]const u8 = cgltf_find_sparse_index(accessor, index);
        _ = &element;
        if (element != null) return cgltf_element_read_uint(element, accessor.*.type, accessor.*.component_type, out, element_size);
    }
    if (@as(?*anyopaque, @ptrCast(@alignCast(accessor.*.buffer_view))) == @as(?*anyopaque, null)) {
        const extern_local_memset = struct {
            extern fn memset(_Dst: ?*anyopaque, _Val: c_int, _Size: usize) ?*anyopaque;
        };
        _ = &extern_local_memset;
        _ = memset(@ptrCast(@alignCast(out)), 0, element_size *% @sizeOf(cgltf_uint));
        return 1;
    }
    var element: [*c]const u8 = cgltf_buffer_view_data(accessor.*.buffer_view);
    _ = &element;
    if (@as(?*anyopaque, @ptrCast(@alignCast(@constCast(element)))) == @as(?*anyopaque, null)) {
        return 0;
    }
    element += accessor.*.offset +% (accessor.*.stride *% index);
    return cgltf_element_read_uint(element, accessor.*.type, accessor.*.component_type, out, element_size);
}
pub export fn cgltf_accessor_read_index(arg_accessor: [*c]const cgltf_accessor, arg_index: cgltf_size) cgltf_size {
    var accessor = arg_accessor;
    _ = &accessor;
    var index = arg_index;
    _ = &index;
    if (accessor.*.is_sparse != 0) {
        var element: [*c]const u8 = cgltf_find_sparse_index(accessor, index);
        _ = &element;
        if (element != null) return cgltf_component_read_index(@ptrCast(@alignCast(element)), accessor.*.component_type);
    }
    if (@as(?*anyopaque, @ptrCast(@alignCast(accessor.*.buffer_view))) == @as(?*anyopaque, null)) {
        return 0;
    }
    var element: [*c]const u8 = cgltf_buffer_view_data(accessor.*.buffer_view);
    _ = &element;
    if (@as(?*anyopaque, @ptrCast(@alignCast(@constCast(element)))) == @as(?*anyopaque, null)) {
        return 0;
    }
    element += accessor.*.offset +% (accessor.*.stride *% index);
    return cgltf_component_read_index(@ptrCast(@alignCast(element)), accessor.*.component_type);
}
pub export fn cgltf_num_components(arg_type: cgltf_type) cgltf_size {
    var @"type" = arg_type;
    _ = &@"type";
    while (true) {
        switch (@"type") {
            @as(cgltf_type, cgltf_type_vec2) => {
                return 2;
            },
            @as(cgltf_type, cgltf_type_vec3) => {
                return 3;
            },
            @as(cgltf_type, cgltf_type_vec4) => {
                return 4;
            },
            @as(cgltf_type, cgltf_type_mat2) => {
                return 4;
            },
            @as(cgltf_type, cgltf_type_mat3) => {
                return 9;
            },
            @as(cgltf_type, cgltf_type_mat4) => {
                return 16;
            },
            else => {
                return 1;
            },
        }
        break;
    }
    return undefined;
}
pub export fn cgltf_component_size(arg_component_type: cgltf_component_type) cgltf_size {
    var component_type = arg_component_type;
    _ = &component_type;
    while (true) {
        switch (component_type) {
            @as(cgltf_component_type, cgltf_component_type_r_8), @as(cgltf_component_type, cgltf_component_type_r_8u) => {
                return 1;
            },
            @as(cgltf_component_type, cgltf_component_type_r_16), @as(cgltf_component_type, cgltf_component_type_r_16u) => {
                return 2;
            },
            @as(cgltf_component_type, cgltf_component_type_r_32u), @as(cgltf_component_type, cgltf_component_type_r_32f) => {
                return 4;
            },
            else => {
                return 0;
            },
        }
        break;
    }
    return undefined;
}
pub export fn cgltf_calc_size(arg_type: cgltf_type, arg_component_type: cgltf_component_type) cgltf_size {
    var @"type" = arg_type;
    _ = &@"type";
    var component_type = arg_component_type;
    _ = &component_type;
    var component_size: cgltf_size = cgltf_component_size(component_type);
    _ = &component_size;
    if ((@"type" == @as(cgltf_type, cgltf_type_mat2)) and (component_size == @as(cgltf_size, 1))) {
        return @as(cgltf_size, 8) *% component_size;
    } else if ((@"type" == @as(cgltf_type, cgltf_type_mat3)) and ((component_size == @as(cgltf_size, 1)) or (component_size == @as(cgltf_size, 2)))) {
        return @as(cgltf_size, 12) *% component_size;
    }
    return component_size *% cgltf_num_components(@"type");
}
pub export fn cgltf_accessor_unpack_floats(arg_accessor: [*c]const cgltf_accessor, arg_out: [*c]cgltf_float, arg_float_count: cgltf_size) cgltf_size {
    var accessor = arg_accessor;
    _ = &accessor;
    var out = arg_out;
    _ = &out;
    var float_count = arg_float_count;
    _ = &float_count;
    var floats_per_element: cgltf_size = cgltf_num_components(accessor.*.type);
    _ = &floats_per_element;
    var available_floats: cgltf_size = accessor.*.count *% floats_per_element;
    _ = &available_floats;
    if (@as(?*anyopaque, @ptrCast(@alignCast(out))) == @as(?*anyopaque, null)) {
        return available_floats;
    }
    float_count = if (available_floats < float_count) available_floats else float_count;
    var element_count: cgltf_size = float_count / floats_per_element;
    _ = &element_count;
    if (@as(?*anyopaque, @ptrCast(@alignCast(accessor.*.buffer_view))) == @as(?*anyopaque, null)) {
        const extern_local_memset = struct {
            extern fn memset(_Dst: ?*anyopaque, _Val: c_int, _Size: usize) ?*anyopaque;
        };
        _ = &extern_local_memset;
        _ = memset(@ptrCast(@alignCast(out)), 0, (element_count *% floats_per_element) *% @sizeOf(cgltf_float));
    } else {
        var element: [*c]const u8 = cgltf_buffer_view_data(accessor.*.buffer_view);
        _ = &element;
        if (@as(?*anyopaque, @ptrCast(@alignCast(@constCast(element)))) == @as(?*anyopaque, null)) {
            return 0;
        }
        element += accessor.*.offset;
        if ((accessor.*.component_type == @as(cgltf_component_type, cgltf_component_type_r_32f)) and (accessor.*.stride == (floats_per_element *% @sizeOf(cgltf_float)))) {
            const extern_local_memcpy = struct {
                extern fn memcpy(noalias _Dst: ?*anyopaque, noalias _Src: ?*const anyopaque, _Size: usize) ?*anyopaque;
            };
            _ = &extern_local_memcpy;
            _ = memcpy(@ptrCast(@alignCast(out)), @ptrCast(@alignCast(element)), (element_count *% floats_per_element) *% @sizeOf(cgltf_float));
        } else {
            var dest: [*c]cgltf_float = out;
            _ = &dest;
            {
                var index: cgltf_size = 0;
                _ = &index;
                index +%= 1;
                dest += floats_per_element;
                while (index < element_count) : (element += accessor.*.stride) {
                    if (!(cgltf_element_read_float(element, accessor.*.type, accessor.*.component_type, accessor.*.normalized, dest, floats_per_element) != 0)) {
                        return 0;
                    }
                }
            }
        }
    }
    if (accessor.*.is_sparse != 0) {
        var sparse: [*c]const cgltf_accessor_sparse = &accessor.*.sparse;
        _ = &sparse;
        var index_data: [*c]const u8 = cgltf_buffer_view_data(sparse.*.indices_buffer_view);
        _ = &index_data;
        var reader_head: [*c]const u8 = cgltf_buffer_view_data(sparse.*.values_buffer_view);
        _ = &reader_head;
        if ((@as(?*anyopaque, @ptrCast(@alignCast(@constCast(index_data)))) == @as(?*anyopaque, null)) or (@as(?*anyopaque, @ptrCast(@alignCast(@constCast(reader_head)))) == @as(?*anyopaque, null))) {
            return 0;
        }
        index_data += sparse.*.indices_byte_offset;
        reader_head += sparse.*.values_byte_offset;
        var index_stride: cgltf_size = cgltf_component_size(sparse.*.indices_component_type);
        _ = &index_stride;
        {
            var reader_index: cgltf_size = 0;
            _ = &reader_index;
            reader_index +%= 1;
            index_data += index_stride;
            while (reader_index < sparse.*.count) : (reader_head += accessor.*.stride) {
                var writer_index: usize = cgltf_component_read_index(@ptrCast(@alignCast(index_data)), sparse.*.indices_component_type);
                _ = &writer_index;
                var writer_head: [*c]f32 = out + (writer_index *% floats_per_element);
                _ = &writer_head;
                if (!(cgltf_element_read_float(reader_head, accessor.*.type, accessor.*.component_type, accessor.*.normalized, writer_head, floats_per_element) != 0)) {
                    return 0;
                }
            }
        }
    }
    return element_count *% floats_per_element;
}
pub export fn cgltf_accessor_unpack_indices(arg_accessor: [*c]const cgltf_accessor, arg_out: ?*anyopaque, arg_out_component_size: cgltf_size, arg_index_count: cgltf_size) cgltf_size {
    var accessor = arg_accessor;
    _ = &accessor;
    var out = arg_out;
    _ = &out;
    var out_component_size = arg_out_component_size;
    _ = &out_component_size;
    var index_count = arg_index_count;
    _ = &index_count;
    if (out == @as(?*anyopaque, null)) {
        return accessor.*.count;
    }
    var numbers_per_element: cgltf_size = cgltf_num_components(accessor.*.type);
    _ = &numbers_per_element;
    var available_numbers: cgltf_size = accessor.*.count *% numbers_per_element;
    _ = &available_numbers;
    index_count = if (available_numbers < index_count) available_numbers else index_count;
    var index_component_size: cgltf_size = cgltf_component_size(accessor.*.component_type);
    _ = &index_component_size;
    if (accessor.*.is_sparse != 0) {
        return 0;
    }
    if (@as(?*anyopaque, @ptrCast(@alignCast(accessor.*.buffer_view))) == @as(?*anyopaque, null)) {
        return 0;
    }
    if (index_component_size > out_component_size) {
        return 0;
    }
    var element: [*c]const u8 = cgltf_buffer_view_data(accessor.*.buffer_view);
    _ = &element;
    if (@as(?*anyopaque, @ptrCast(@alignCast(@constCast(element)))) == @as(?*anyopaque, null)) {
        return 0;
    }
    element += accessor.*.offset;
    if ((index_component_size == out_component_size) and (accessor.*.stride == (out_component_size *% numbers_per_element))) {
        const extern_local_memcpy = struct {
            extern fn memcpy(noalias _Dst: ?*anyopaque, noalias _Src: ?*const anyopaque, _Size: usize) ?*anyopaque;
        };
        _ = &extern_local_memcpy;
        _ = memcpy(out, @ptrCast(@alignCast(element)), index_count *% index_component_size);
        return index_count;
    }
    while (true) {
        switch (out_component_size) {
            @as(cgltf_size, 1) => {
                {
                    var index: cgltf_size = 0;
                    _ = &index;
                    index +%= 1;
                    while (index < index_count) : (element += accessor.*.stride) {
                        @as([*c]u8, @ptrCast(@alignCast(out)))[@intCast(index)] = @truncate(cgltf_component_read_index(@ptrCast(@alignCast(element)), accessor.*.component_type));
                    }
                }
                break;
            },
            @as(cgltf_size, 2) => {
                {
                    var index: cgltf_size = 0;
                    _ = &index;
                    index +%= 1;
                    while (index < index_count) : (element += accessor.*.stride) {
                        @as([*c]u16, @ptrCast(@alignCast(out)))[@intCast(index)] = @truncate(cgltf_component_read_index(@ptrCast(@alignCast(element)), accessor.*.component_type));
                    }
                }
                break;
            },
            @as(cgltf_size, 4) => {
                {
                    var index: cgltf_size = 0;
                    _ = &index;
                    index +%= 1;
                    while (index < index_count) : (element += accessor.*.stride) {
                        @as([*c]u32, @ptrCast(@alignCast(out)))[@intCast(index)] = @truncate(cgltf_component_read_index(@ptrCast(@alignCast(element)), accessor.*.component_type));
                    }
                }
                break;
            },
            else => {
                return 0;
            },
        }
        break;
    }
    return index_count;
}
pub export fn cgltf_copy_extras_json(arg_data: [*c]const cgltf_data, arg_extras: [*c]const cgltf_extras, arg_dest: [*c]u8, arg_dest_size: [*c]cgltf_size) cgltf_result {
    var data = arg_data;
    _ = &data;
    var extras = arg_extras;
    _ = &extras;
    var dest = arg_dest;
    _ = &dest;
    var dest_size = arg_dest_size;
    _ = &dest_size;
    var json_size: cgltf_size = extras.*.end_offset -% extras.*.start_offset;
    _ = &json_size;
    if (!(dest != null)) {
        if (dest_size != null) {
            dest_size.* = json_size +% @as(cgltf_size, 1);
            return cgltf_result_success;
        }
        return cgltf_result_invalid_options;
    }
    if ((dest_size.* +% @as(cgltf_size, 1)) < json_size) {
        const extern_local_strncpy = struct {
            extern fn strncpy(noalias _Dest: [*c]u8, noalias _Source: [*c]const u8, _Count: usize) [*c]u8;
        };
        _ = &extern_local_strncpy;
        _ = strncpy(dest, data.*.json + extras.*.start_offset, dest_size.* -% @as(cgltf_size, 1));
        dest[@intCast(dest_size.* -% @as(cgltf_size, 1))] = 0;
    } else {
        const extern_local_strncpy = struct {
            extern fn strncpy(noalias _Dest: [*c]u8, noalias _Source: [*c]const u8, _Count: usize) [*c]u8;
        };
        _ = &extern_local_strncpy;
        _ = strncpy(dest, data.*.json + extras.*.start_offset, json_size);
        dest[@intCast(json_size)] = 0;
    }
    return cgltf_result_success;
}
pub export fn cgltf_mesh_index(arg_data: [*c]const cgltf_data, arg_object: [*c]const cgltf_mesh) cgltf_size {
    var data = arg_data;
    _ = &data;
    var object = arg_object;
    _ = &object;
    _ = !!((object != null) and (@as(cgltf_size, @bitCast(@as(c_longlong, @divExact(@as(c_longlong, @bitCast(@intFromPtr(object) -% @intFromPtr(data.*.meshes))), @sizeOf(cgltf_mesh))))) < data.*.meshes_count)) or ((blk: {
        const extern_local__assert = struct {
            extern fn _assert(_Message: [*c]const u8, _File: [*c]const u8, _Line: c_uint) noreturn;
        };
        _ = &extern_local__assert;
        _assert("object && (cgltf_size)(object - data->meshes) < data->meshes_count", ".\\include\\cgltf\\cgltf.h", 2584);
        break :blk 0;
    }) != 0);
    return @bitCast(@as(c_longlong, @divExact(@as(c_longlong, @bitCast(@intFromPtr(object) -% @intFromPtr(data.*.meshes))), @sizeOf(cgltf_mesh))));
}
pub export fn cgltf_material_index(arg_data: [*c]const cgltf_data, arg_object: [*c]const cgltf_material) cgltf_size {
    var data = arg_data;
    _ = &data;
    var object = arg_object;
    _ = &object;
    _ = !!((object != null) and (@as(cgltf_size, @bitCast(@as(c_longlong, @divExact(@as(c_longlong, @bitCast(@intFromPtr(object) -% @intFromPtr(data.*.materials))), @sizeOf(cgltf_material))))) < data.*.materials_count)) or ((blk: {
        const extern_local__assert = struct {
            extern fn _assert(_Message: [*c]const u8, _File: [*c]const u8, _Line: c_uint) noreturn;
        };
        _ = &extern_local__assert;
        _assert("object && (cgltf_size)(object - data->materials) < data->materials_count", ".\\include\\cgltf\\cgltf.h", 2590);
        break :blk 0;
    }) != 0);
    return @bitCast(@as(c_longlong, @divExact(@as(c_longlong, @bitCast(@intFromPtr(object) -% @intFromPtr(data.*.materials))), @sizeOf(cgltf_material))));
}
pub export fn cgltf_accessor_index(arg_data: [*c]const cgltf_data, arg_object: [*c]const cgltf_accessor) cgltf_size {
    var data = arg_data;
    _ = &data;
    var object = arg_object;
    _ = &object;
    _ = !!((object != null) and (@as(cgltf_size, @bitCast(@as(c_longlong, @divExact(@as(c_longlong, @bitCast(@intFromPtr(object) -% @intFromPtr(data.*.accessors))), @sizeOf(cgltf_accessor))))) < data.*.accessors_count)) or ((blk: {
        const extern_local__assert = struct {
            extern fn _assert(_Message: [*c]const u8, _File: [*c]const u8, _Line: c_uint) noreturn;
        };
        _ = &extern_local__assert;
        _assert("object && (cgltf_size)(object - data->accessors) < data->accessors_count", ".\\include\\cgltf\\cgltf.h", 2596);
        break :blk 0;
    }) != 0);
    return @bitCast(@as(c_longlong, @divExact(@as(c_longlong, @bitCast(@intFromPtr(object) -% @intFromPtr(data.*.accessors))), @sizeOf(cgltf_accessor))));
}
pub export fn cgltf_buffer_view_index(arg_data: [*c]const cgltf_data, arg_object: [*c]const cgltf_buffer_view) cgltf_size {
    var data = arg_data;
    _ = &data;
    var object = arg_object;
    _ = &object;
    _ = !!((object != null) and (@as(cgltf_size, @bitCast(@as(c_longlong, @divExact(@as(c_longlong, @bitCast(@intFromPtr(object) -% @intFromPtr(data.*.buffer_views))), @sizeOf(cgltf_buffer_view))))) < data.*.buffer_views_count)) or ((blk: {
        const extern_local__assert = struct {
            extern fn _assert(_Message: [*c]const u8, _File: [*c]const u8, _Line: c_uint) noreturn;
        };
        _ = &extern_local__assert;
        _assert("object && (cgltf_size)(object - data->buffer_views) < data->buffer_views_count", ".\\include\\cgltf\\cgltf.h", 2602);
        break :blk 0;
    }) != 0);
    return @bitCast(@as(c_longlong, @divExact(@as(c_longlong, @bitCast(@intFromPtr(object) -% @intFromPtr(data.*.buffer_views))), @sizeOf(cgltf_buffer_view))));
}
pub export fn cgltf_buffer_index(arg_data: [*c]const cgltf_data, arg_object: [*c]const cgltf_buffer) cgltf_size {
    var data = arg_data;
    _ = &data;
    var object = arg_object;
    _ = &object;
    _ = !!((object != null) and (@as(cgltf_size, @bitCast(@as(c_longlong, @divExact(@as(c_longlong, @bitCast(@intFromPtr(object) -% @intFromPtr(data.*.buffers))), @sizeOf(cgltf_buffer))))) < data.*.buffers_count)) or ((blk: {
        const extern_local__assert = struct {
            extern fn _assert(_Message: [*c]const u8, _File: [*c]const u8, _Line: c_uint) noreturn;
        };
        _ = &extern_local__assert;
        _assert("object && (cgltf_size)(object - data->buffers) < data->buffers_count", ".\\include\\cgltf\\cgltf.h", 2608);
        break :blk 0;
    }) != 0);
    return @bitCast(@as(c_longlong, @divExact(@as(c_longlong, @bitCast(@intFromPtr(object) -% @intFromPtr(data.*.buffers))), @sizeOf(cgltf_buffer))));
}
pub export fn cgltf_image_index(arg_data: [*c]const cgltf_data, arg_object: [*c]const cgltf_image) cgltf_size {
    var data = arg_data;
    _ = &data;
    var object = arg_object;
    _ = &object;
    _ = !!((object != null) and (@as(cgltf_size, @bitCast(@as(c_longlong, @divExact(@as(c_longlong, @bitCast(@intFromPtr(object) -% @intFromPtr(data.*.images))), @sizeOf(cgltf_image))))) < data.*.images_count)) or ((blk: {
        const extern_local__assert = struct {
            extern fn _assert(_Message: [*c]const u8, _File: [*c]const u8, _Line: c_uint) noreturn;
        };
        _ = &extern_local__assert;
        _assert("object && (cgltf_size)(object - data->images) < data->images_count", ".\\include\\cgltf\\cgltf.h", 2614);
        break :blk 0;
    }) != 0);
    return @bitCast(@as(c_longlong, @divExact(@as(c_longlong, @bitCast(@intFromPtr(object) -% @intFromPtr(data.*.images))), @sizeOf(cgltf_image))));
}
pub export fn cgltf_texture_index(arg_data: [*c]const cgltf_data, arg_object: [*c]const cgltf_texture) cgltf_size {
    var data = arg_data;
    _ = &data;
    var object = arg_object;
    _ = &object;
    _ = !!((object != null) and (@as(cgltf_size, @bitCast(@as(c_longlong, @divExact(@as(c_longlong, @bitCast(@intFromPtr(object) -% @intFromPtr(data.*.textures))), @sizeOf(cgltf_texture))))) < data.*.textures_count)) or ((blk: {
        const extern_local__assert = struct {
            extern fn _assert(_Message: [*c]const u8, _File: [*c]const u8, _Line: c_uint) noreturn;
        };
        _ = &extern_local__assert;
        _assert("object && (cgltf_size)(object - data->textures) < data->textures_count", ".\\include\\cgltf\\cgltf.h", 2620);
        break :blk 0;
    }) != 0);
    return @bitCast(@as(c_longlong, @divExact(@as(c_longlong, @bitCast(@intFromPtr(object) -% @intFromPtr(data.*.textures))), @sizeOf(cgltf_texture))));
}
pub export fn cgltf_sampler_index(arg_data: [*c]const cgltf_data, arg_object: [*c]const cgltf_sampler) cgltf_size {
    var data = arg_data;
    _ = &data;
    var object = arg_object;
    _ = &object;
    _ = !!((object != null) and (@as(cgltf_size, @bitCast(@as(c_longlong, @divExact(@as(c_longlong, @bitCast(@intFromPtr(object) -% @intFromPtr(data.*.samplers))), @sizeOf(cgltf_sampler))))) < data.*.samplers_count)) or ((blk: {
        const extern_local__assert = struct {
            extern fn _assert(_Message: [*c]const u8, _File: [*c]const u8, _Line: c_uint) noreturn;
        };
        _ = &extern_local__assert;
        _assert("object && (cgltf_size)(object - data->samplers) < data->samplers_count", ".\\include\\cgltf\\cgltf.h", 2626);
        break :blk 0;
    }) != 0);
    return @bitCast(@as(c_longlong, @divExact(@as(c_longlong, @bitCast(@intFromPtr(object) -% @intFromPtr(data.*.samplers))), @sizeOf(cgltf_sampler))));
}
pub export fn cgltf_skin_index(arg_data: [*c]const cgltf_data, arg_object: [*c]const cgltf_skin) cgltf_size {
    var data = arg_data;
    _ = &data;
    var object = arg_object;
    _ = &object;
    _ = !!((object != null) and (@as(cgltf_size, @bitCast(@as(c_longlong, @divExact(@as(c_longlong, @bitCast(@intFromPtr(object) -% @intFromPtr(data.*.skins))), @sizeOf(cgltf_skin))))) < data.*.skins_count)) or ((blk: {
        const extern_local__assert = struct {
            extern fn _assert(_Message: [*c]const u8, _File: [*c]const u8, _Line: c_uint) noreturn;
        };
        _ = &extern_local__assert;
        _assert("object && (cgltf_size)(object - data->skins) < data->skins_count", ".\\include\\cgltf\\cgltf.h", 2632);
        break :blk 0;
    }) != 0);
    return @bitCast(@as(c_longlong, @divExact(@as(c_longlong, @bitCast(@intFromPtr(object) -% @intFromPtr(data.*.skins))), @sizeOf(cgltf_skin))));
}
pub export fn cgltf_camera_index(arg_data: [*c]const cgltf_data, arg_object: [*c]const cgltf_camera) cgltf_size {
    var data = arg_data;
    _ = &data;
    var object = arg_object;
    _ = &object;
    _ = !!((object != null) and (@as(cgltf_size, @bitCast(@as(c_longlong, @divExact(@as(c_longlong, @bitCast(@intFromPtr(object) -% @intFromPtr(data.*.cameras))), @sizeOf(cgltf_camera))))) < data.*.cameras_count)) or ((blk: {
        const extern_local__assert = struct {
            extern fn _assert(_Message: [*c]const u8, _File: [*c]const u8, _Line: c_uint) noreturn;
        };
        _ = &extern_local__assert;
        _assert("object && (cgltf_size)(object - data->cameras) < data->cameras_count", ".\\include\\cgltf\\cgltf.h", 2638);
        break :blk 0;
    }) != 0);
    return @bitCast(@as(c_longlong, @divExact(@as(c_longlong, @bitCast(@intFromPtr(object) -% @intFromPtr(data.*.cameras))), @sizeOf(cgltf_camera))));
}
pub export fn cgltf_light_index(arg_data: [*c]const cgltf_data, arg_object: [*c]const cgltf_light) cgltf_size {
    var data = arg_data;
    _ = &data;
    var object = arg_object;
    _ = &object;
    _ = !!((object != null) and (@as(cgltf_size, @bitCast(@as(c_longlong, @divExact(@as(c_longlong, @bitCast(@intFromPtr(object) -% @intFromPtr(data.*.lights))), @sizeOf(cgltf_light))))) < data.*.lights_count)) or ((blk: {
        const extern_local__assert = struct {
            extern fn _assert(_Message: [*c]const u8, _File: [*c]const u8, _Line: c_uint) noreturn;
        };
        _ = &extern_local__assert;
        _assert("object && (cgltf_size)(object - data->lights) < data->lights_count", ".\\include\\cgltf\\cgltf.h", 2644);
        break :blk 0;
    }) != 0);
    return @bitCast(@as(c_longlong, @divExact(@as(c_longlong, @bitCast(@intFromPtr(object) -% @intFromPtr(data.*.lights))), @sizeOf(cgltf_light))));
}
pub export fn cgltf_node_index(arg_data: [*c]const cgltf_data, arg_object: [*c]const cgltf_node) cgltf_size {
    var data = arg_data;
    _ = &data;
    var object = arg_object;
    _ = &object;
    _ = !!((object != null) and (@as(cgltf_size, @bitCast(@as(c_longlong, @divExact(@as(c_longlong, @bitCast(@intFromPtr(object) -% @intFromPtr(data.*.nodes))), @sizeOf(cgltf_node))))) < data.*.nodes_count)) or ((blk: {
        const extern_local__assert = struct {
            extern fn _assert(_Message: [*c]const u8, _File: [*c]const u8, _Line: c_uint) noreturn;
        };
        _ = &extern_local__assert;
        _assert("object && (cgltf_size)(object - data->nodes) < data->nodes_count", ".\\include\\cgltf\\cgltf.h", 2650);
        break :blk 0;
    }) != 0);
    return @bitCast(@as(c_longlong, @divExact(@as(c_longlong, @bitCast(@intFromPtr(object) -% @intFromPtr(data.*.nodes))), @sizeOf(cgltf_node))));
}
pub export fn cgltf_scene_index(arg_data: [*c]const cgltf_data, arg_object: [*c]const cgltf_scene) cgltf_size {
    var data = arg_data;
    _ = &data;
    var object = arg_object;
    _ = &object;
    _ = !!((object != null) and (@as(cgltf_size, @bitCast(@as(c_longlong, @divExact(@as(c_longlong, @bitCast(@intFromPtr(object) -% @intFromPtr(data.*.scenes))), @sizeOf(cgltf_scene))))) < data.*.scenes_count)) or ((blk: {
        const extern_local__assert = struct {
            extern fn _assert(_Message: [*c]const u8, _File: [*c]const u8, _Line: c_uint) noreturn;
        };
        _ = &extern_local__assert;
        _assert("object && (cgltf_size)(object - data->scenes) < data->scenes_count", ".\\include\\cgltf\\cgltf.h", 2656);
        break :blk 0;
    }) != 0);
    return @bitCast(@as(c_longlong, @divExact(@as(c_longlong, @bitCast(@intFromPtr(object) -% @intFromPtr(data.*.scenes))), @sizeOf(cgltf_scene))));
}
pub export fn cgltf_animation_index(arg_data: [*c]const cgltf_data, arg_object: [*c]const cgltf_animation) cgltf_size {
    var data = arg_data;
    _ = &data;
    var object = arg_object;
    _ = &object;
    _ = !!((object != null) and (@as(cgltf_size, @bitCast(@as(c_longlong, @divExact(@as(c_longlong, @bitCast(@intFromPtr(object) -% @intFromPtr(data.*.animations))), @sizeOf(cgltf_animation))))) < data.*.animations_count)) or ((blk: {
        const extern_local__assert = struct {
            extern fn _assert(_Message: [*c]const u8, _File: [*c]const u8, _Line: c_uint) noreturn;
        };
        _ = &extern_local__assert;
        _assert("object && (cgltf_size)(object - data->animations) < data->animations_count", ".\\include\\cgltf\\cgltf.h", 2662);
        break :blk 0;
    }) != 0);
    return @bitCast(@as(c_longlong, @divExact(@as(c_longlong, @bitCast(@intFromPtr(object) -% @intFromPtr(data.*.animations))), @sizeOf(cgltf_animation))));
}
pub export fn cgltf_animation_sampler_index(arg_animation: [*c]const cgltf_animation, arg_object: [*c]const cgltf_animation_sampler) cgltf_size {
    var animation = arg_animation;
    _ = &animation;
    var object = arg_object;
    _ = &object;
    _ = !!((object != null) and (@as(cgltf_size, @bitCast(@as(c_longlong, @divExact(@as(c_longlong, @bitCast(@intFromPtr(object) -% @intFromPtr(animation.*.samplers))), @sizeOf(cgltf_animation_sampler))))) < animation.*.samplers_count)) or ((blk: {
        const extern_local__assert = struct {
            extern fn _assert(_Message: [*c]const u8, _File: [*c]const u8, _Line: c_uint) noreturn;
        };
        _ = &extern_local__assert;
        _assert("object && (cgltf_size)(object - animation->samplers) < animation->samplers_count", ".\\include\\cgltf\\cgltf.h", 2668);
        break :blk 0;
    }) != 0);
    return @bitCast(@as(c_longlong, @divExact(@as(c_longlong, @bitCast(@intFromPtr(object) -% @intFromPtr(animation.*.samplers))), @sizeOf(cgltf_animation_sampler))));
}
pub export fn cgltf_animation_channel_index(arg_animation: [*c]const cgltf_animation, arg_object: [*c]const cgltf_animation_channel) cgltf_size {
    var animation = arg_animation;
    _ = &animation;
    var object = arg_object;
    _ = &object;
    _ = !!((object != null) and (@as(cgltf_size, @bitCast(@as(c_longlong, @divExact(@as(c_longlong, @bitCast(@intFromPtr(object) -% @intFromPtr(animation.*.channels))), @sizeOf(cgltf_animation_channel))))) < animation.*.channels_count)) or ((blk: {
        const extern_local__assert = struct {
            extern fn _assert(_Message: [*c]const u8, _File: [*c]const u8, _Line: c_uint) noreturn;
        };
        _ = &extern_local__assert;
        _assert("object && (cgltf_size)(object - animation->channels) < animation->channels_count", ".\\include\\cgltf\\cgltf.h", 2674);
        break :blk 0;
    }) != 0);
    return @bitCast(@as(c_longlong, @divExact(@as(c_longlong, @bitCast(@intFromPtr(object) -% @intFromPtr(animation.*.channels))), @sizeOf(cgltf_animation_channel))));
}
pub extern fn _wassert(_Message: [*c]const wchar_t, _File: [*c]const wchar_t, _Line: c_uint) noreturn;
pub extern fn _assert(_Message: [*c]const u8, _File: [*c]const u8, _Line: c_uint) noreturn;
pub extern fn _memccpy(_Dst: ?*anyopaque, _Src: ?*const anyopaque, _Val: c_int, _MaxCount: usize) ?*anyopaque;
pub extern fn memchr(_Buf: ?*const anyopaque, _Val: c_int, _MaxCount: usize) ?*anyopaque;
pub extern fn _memicmp(_Buf1: ?*const anyopaque, _Buf2: ?*const anyopaque, _Size: usize) c_int;
pub extern fn _memicmp_l(_Buf1: ?*const anyopaque, _Buf2: ?*const anyopaque, _Size: usize, _Locale: _locale_t) c_int;
pub extern fn memcmp(_Buf1: ?*const anyopaque, _Buf2: ?*const anyopaque, _Size: usize) c_int;
pub extern fn memcpy(noalias _Dst: ?*anyopaque, noalias _Src: ?*const anyopaque, _Size: usize) ?*anyopaque;
pub extern fn memcpy_s(_dest: ?*anyopaque, _numberOfElements: usize, _src: ?*const anyopaque, _count: usize) errno_t;
pub extern fn mempcpy(_Dst: ?*anyopaque, _Src: ?*const anyopaque, _Size: usize) ?*anyopaque;
pub extern fn memset(_Dst: ?*anyopaque, _Val: c_int, _Size: usize) ?*anyopaque;
pub extern fn memccpy(_Dst: ?*anyopaque, _Src: ?*const anyopaque, _Val: c_int, _Size: usize) ?*anyopaque;
pub extern fn memicmp(_Buf1: ?*const anyopaque, _Buf2: ?*const anyopaque, _Size: usize) c_int;
pub extern fn _strset(_Str: [*c]u8, _Val: c_int) [*c]u8;
pub extern fn _strset_l(_Str: [*c]u8, _Val: c_int, _Locale: _locale_t) [*c]u8;
pub extern fn strcpy(noalias _Dest: [*c]u8, noalias _Source: [*c]const u8) [*c]u8;
pub extern fn strcat(noalias _Dest: [*c]u8, noalias _Source: [*c]const u8) [*c]u8;
pub extern fn strcmp(_Str1: [*c]const u8, _Str2: [*c]const u8) c_int;
pub extern fn strlen(_Str: [*c]const u8) usize;
pub extern fn strnlen(_Str: [*c]const u8, _MaxCount: usize) usize;
pub extern fn memmove(_Dst: ?*anyopaque, _Src: ?*const anyopaque, _Size: usize) ?*anyopaque;
pub extern fn _strdup(_Src: [*c]const u8) [*c]u8;
pub extern fn strchr(_Str: [*c]const u8, _Val: c_int) [*c]u8;
pub extern fn _stricmp(_Str1: [*c]const u8, _Str2: [*c]const u8) c_int;
pub extern fn _strcmpi(_Str1: [*c]const u8, _Str2: [*c]const u8) c_int;
pub extern fn _stricmp_l(_Str1: [*c]const u8, _Str2: [*c]const u8, _Locale: _locale_t) c_int;
pub extern fn strcoll(_Str1: [*c]const u8, _Str2: [*c]const u8) c_int;
pub extern fn _strcoll_l(_Str1: [*c]const u8, _Str2: [*c]const u8, _Locale: _locale_t) c_int;
pub extern fn _stricoll(_Str1: [*c]const u8, _Str2: [*c]const u8) c_int;
pub extern fn _stricoll_l(_Str1: [*c]const u8, _Str2: [*c]const u8, _Locale: _locale_t) c_int;
pub extern fn _strncoll(_Str1: [*c]const u8, _Str2: [*c]const u8, _MaxCount: usize) c_int;
pub extern fn _strncoll_l(_Str1: [*c]const u8, _Str2: [*c]const u8, _MaxCount: usize, _Locale: _locale_t) c_int;
pub extern fn _strnicoll(_Str1: [*c]const u8, _Str2: [*c]const u8, _MaxCount: usize) c_int;
pub extern fn _strnicoll_l(_Str1: [*c]const u8, _Str2: [*c]const u8, _MaxCount: usize, _Locale: _locale_t) c_int;
pub extern fn strcspn(_Str: [*c]const u8, _Control: [*c]const u8) usize;
pub extern fn _strerror(_ErrMsg: [*c]const u8) [*c]u8;
pub extern fn strerror(c_int) [*c]u8;
pub extern fn _strlwr(_String: [*c]u8) [*c]u8;
pub extern fn strlwr_l(_String: [*c]u8, _Locale: _locale_t) [*c]u8;
pub extern fn strncat(noalias _Dest: [*c]u8, noalias _Source: [*c]const u8, _Count: usize) [*c]u8;
pub extern fn strncmp(_Str1: [*c]const u8, _Str2: [*c]const u8, _MaxCount: usize) c_int;
pub extern fn _strnicmp(_Str1: [*c]const u8, _Str2: [*c]const u8, _MaxCount: usize) c_int;
pub extern fn _strnicmp_l(_Str1: [*c]const u8, _Str2: [*c]const u8, _MaxCount: usize, _Locale: _locale_t) c_int;
pub extern fn strncpy(noalias _Dest: [*c]u8, noalias _Source: [*c]const u8, _Count: usize) [*c]u8;
pub extern fn _strnset(_Str: [*c]u8, _Val: c_int, _MaxCount: usize) [*c]u8;
pub extern fn _strnset_l(str: [*c]u8, c: c_int, count: usize, _Locale: _locale_t) [*c]u8;
pub extern fn strpbrk(_Str: [*c]const u8, _Control: [*c]const u8) [*c]u8;
pub extern fn strrchr(_Str: [*c]const u8, _Ch: c_int) [*c]u8;
pub extern fn _strrev(_Str: [*c]u8) [*c]u8;
pub extern fn strspn(_Str: [*c]const u8, _Control: [*c]const u8) usize;
pub extern fn strstr(_Str: [*c]const u8, _SubStr: [*c]const u8) [*c]u8;
pub extern fn strtok(noalias _Str: [*c]u8, noalias _Delim: [*c]const u8) [*c]u8;
pub extern fn strtok_r(noalias _Str: [*c]u8, noalias _Delim: [*c]const u8, noalias __last: [*c][*c]u8) [*c]u8;
pub extern fn _strupr(_String: [*c]u8) [*c]u8;
pub extern fn _strupr_l(_String: [*c]u8, _Locale: _locale_t) [*c]u8;
pub extern fn strxfrm(noalias _Dst: [*c]u8, noalias _Src: [*c]const u8, _MaxCount: usize) usize;
pub extern fn _strxfrm_l(noalias _Dst: [*c]u8, noalias _Src: [*c]const u8, _MaxCount: usize, _Locale: _locale_t) usize;
pub extern fn strdup(_Src: [*c]const u8) [*c]u8;
pub extern fn strcmpi(_Str1: [*c]const u8, _Str2: [*c]const u8) c_int;
pub extern fn stricmp(_Str1: [*c]const u8, _Str2: [*c]const u8) c_int;
pub extern fn strlwr(_Str: [*c]u8) [*c]u8;
pub extern fn strnicmp(_Str1: [*c]const u8, _Str: [*c]const u8, _MaxCount: usize) c_int;
pub fn strncasecmp(arg___sz1: [*c]const u8, arg___sz2: [*c]const u8, arg___sizeMaxCompare: usize) callconv(.c) c_int {
    var __sz1 = arg___sz1;
    _ = &__sz1;
    var __sz2 = arg___sz2;
    _ = &__sz2;
    var __sizeMaxCompare = arg___sizeMaxCompare;
    _ = &__sizeMaxCompare;
    return _strnicmp(__sz1, __sz2, __sizeMaxCompare);
}
pub fn strcasecmp(arg___sz1: [*c]const u8, arg___sz2: [*c]const u8) callconv(.c) c_int {
    var __sz1 = arg___sz1;
    _ = &__sz1;
    var __sz2 = arg___sz2;
    _ = &__sz2;
    return _stricmp(__sz1, __sz2);
}
pub extern fn strnset(_Str: [*c]u8, _Val: c_int, _MaxCount: usize) [*c]u8;
pub extern fn strrev(_Str: [*c]u8) [*c]u8;
pub extern fn strset(_Str: [*c]u8, _Val: c_int) [*c]u8;
pub extern fn strupr(_Str: [*c]u8) [*c]u8;
pub extern fn _wcsdup(_Str: [*c]const wchar_t) [*c]wchar_t;
pub extern fn wcscat(noalias _Dest: [*c]wchar_t, noalias _Source: [*c]const wchar_t) [*c]wchar_t;
pub extern fn wcschr(_Str: [*c]const wchar_t, _Ch: wchar_t) [*c]wchar_t;
pub extern fn wcscmp(_Str1: [*c]const wchar_t, _Str2: [*c]const wchar_t) c_int;
pub extern fn wcscpy(noalias _Dest: [*c]wchar_t, noalias _Source: [*c]const wchar_t) [*c]wchar_t;
pub extern fn wcscspn(_Str: [*c]const wchar_t, _Control: [*c]const wchar_t) usize;
pub extern fn wcslen(_Str: [*c]const wchar_t) usize;
pub extern fn wcsnlen(_Src: [*c]const wchar_t, _MaxCount: usize) usize;
pub extern fn wcsncat(noalias _Dest: [*c]wchar_t, noalias _Source: [*c]const wchar_t, _Count: usize) [*c]wchar_t;
pub extern fn wcsncmp(_Str1: [*c]const wchar_t, _Str2: [*c]const wchar_t, _MaxCount: usize) c_int;
pub extern fn wcsncpy(noalias _Dest: [*c]wchar_t, noalias _Source: [*c]const wchar_t, _Count: usize) [*c]wchar_t;
pub extern fn _wcsncpy_l(noalias _Dest: [*c]wchar_t, noalias _Source: [*c]const wchar_t, _Count: usize, _Locale: _locale_t) [*c]wchar_t;
pub extern fn wcspbrk(_Str: [*c]const wchar_t, _Control: [*c]const wchar_t) [*c]wchar_t;
pub extern fn wcsrchr(_Str: [*c]const wchar_t, _Ch: wchar_t) [*c]wchar_t;
pub extern fn wcsspn(_Str: [*c]const wchar_t, _Control: [*c]const wchar_t) usize;
pub extern fn wcsstr(_Str: [*c]const wchar_t, _SubStr: [*c]const wchar_t) [*c]wchar_t;
pub extern fn wcstok(noalias _Str: [*c]wchar_t, noalias _Delim: [*c]const wchar_t, noalias _Ptr: [*c][*c]wchar_t) [*c]wchar_t;
pub extern fn _wcstok(noalias _Str: [*c]wchar_t, noalias _Delim: [*c]const wchar_t) [*c]wchar_t;
pub extern fn _wcserror(_ErrNum: c_int) [*c]wchar_t;
pub extern fn __wcserror(_Str: [*c]const wchar_t) [*c]wchar_t;
pub extern fn _wcsicmp(_Str1: [*c]const wchar_t, _Str2: [*c]const wchar_t) c_int;
pub extern fn _wcsicmp_l(_Str1: [*c]const wchar_t, _Str2: [*c]const wchar_t, _Locale: _locale_t) c_int;
pub extern fn _wcsnicmp(_Str1: [*c]const wchar_t, _Str2: [*c]const wchar_t, _MaxCount: usize) c_int;
pub extern fn _wcsnicmp_l(_Str1: [*c]const wchar_t, _Str2: [*c]const wchar_t, _MaxCount: usize, _Locale: _locale_t) c_int;
pub extern fn _wcsnset(_Str: [*c]wchar_t, _Val: wchar_t, _MaxCount: usize) [*c]wchar_t;
pub extern fn _wcsrev(_Str: [*c]wchar_t) [*c]wchar_t;
pub extern fn _wcsset(_Str: [*c]wchar_t, _Val: wchar_t) [*c]wchar_t;
pub extern fn _wcslwr(_String: [*c]wchar_t) [*c]wchar_t;
pub extern fn _wcslwr_l(_String: [*c]wchar_t, _Locale: _locale_t) [*c]wchar_t;
pub extern fn _wcsupr(_String: [*c]wchar_t) [*c]wchar_t;
pub extern fn _wcsupr_l(_String: [*c]wchar_t, _Locale: _locale_t) [*c]wchar_t;
pub extern fn wcsxfrm(noalias _Dst: [*c]wchar_t, noalias _Src: [*c]const wchar_t, _MaxCount: usize) usize;
pub extern fn _wcsxfrm_l(noalias _Dst: [*c]wchar_t, noalias _Src: [*c]const wchar_t, _MaxCount: usize, _Locale: _locale_t) usize;
pub extern fn wcscoll(_Str1: [*c]const wchar_t, _Str2: [*c]const wchar_t) c_int;
pub extern fn _wcscoll_l(_Str1: [*c]const wchar_t, _Str2: [*c]const wchar_t, _Locale: _locale_t) c_int;
pub extern fn _wcsicoll(_Str1: [*c]const wchar_t, _Str2: [*c]const wchar_t) c_int;
pub extern fn _wcsicoll_l(_Str1: [*c]const wchar_t, _Str2: [*c]const wchar_t, _Locale: _locale_t) c_int;
pub extern fn _wcsncoll(_Str1: [*c]const wchar_t, _Str2: [*c]const wchar_t, _MaxCount: usize) c_int;
pub extern fn _wcsncoll_l(_Str1: [*c]const wchar_t, _Str2: [*c]const wchar_t, _MaxCount: usize, _Locale: _locale_t) c_int;
pub extern fn _wcsnicoll(_Str1: [*c]const wchar_t, _Str2: [*c]const wchar_t, _MaxCount: usize) c_int;
pub extern fn _wcsnicoll_l(_Str1: [*c]const wchar_t, _Str2: [*c]const wchar_t, _MaxCount: usize, _Locale: _locale_t) c_int;
pub extern fn wcsdup(_Str: [*c]const wchar_t) [*c]wchar_t;
pub extern fn wcsicmp(_Str1: [*c]const wchar_t, _Str2: [*c]const wchar_t) c_int;
pub extern fn wcsnicmp(_Str1: [*c]const wchar_t, _Str2: [*c]const wchar_t, _MaxCount: usize) c_int;
pub extern fn wcsnset(_Str: [*c]wchar_t, _Val: wchar_t, _MaxCount: usize) [*c]wchar_t;
pub extern fn wcsrev(_Str: [*c]wchar_t) [*c]wchar_t;
pub extern fn wcsset(_Str: [*c]wchar_t, _Val: wchar_t) [*c]wchar_t;
pub extern fn wcslwr(_Str: [*c]wchar_t) [*c]wchar_t;
pub extern fn wcsupr(_Str: [*c]wchar_t) [*c]wchar_t;
pub extern fn wcsicoll(_Str1: [*c]const wchar_t, _Str2: [*c]const wchar_t) c_int;
pub extern fn _strset_s(_Dst: [*c]u8, _DstSize: usize, _Value: c_int) errno_t;
pub extern fn _strerror_s(_Buf: [*c]u8, _SizeInBytes: usize, _ErrMsg: [*c]const u8) errno_t;
pub extern fn strerror_s(_Buf: [*c]u8, _SizeInBytes: usize, _ErrNum: c_int) errno_t;
pub extern fn _strlwr_s(_Str: [*c]u8, _Size: usize) errno_t;
pub extern fn _strlwr_s_l(_Str: [*c]u8, _Size: usize, _Locale: _locale_t) errno_t;
pub extern fn _strnset_s(_Str: [*c]u8, _Size: usize, _Val: c_int, _MaxCount: usize) errno_t;
pub extern fn _strupr_s(_Str: [*c]u8, _Size: usize) errno_t;
pub extern fn _strupr_s_l(_Str: [*c]u8, _Size: usize, _Locale: _locale_t) errno_t;
pub extern fn strncat_s(_Dst: [*c]u8, _DstSizeInChars: usize, _Src: [*c]const u8, _MaxCount: usize) errno_t;
pub extern fn _strncat_s_l(_Dst: [*c]u8, _DstSizeInChars: usize, _Src: [*c]const u8, _MaxCount: usize, _Locale: _locale_t) errno_t;
pub extern fn strcpy_s(_Dst: [*c]u8, _SizeInBytes: rsize_t, _Src: [*c]const u8) errno_t;
pub extern fn strncpy_s(_Dst: [*c]u8, _DstSizeInChars: usize, _Src: [*c]const u8, _MaxCount: usize) errno_t;
pub extern fn _strncpy_s_l(_Dst: [*c]u8, _DstSizeInChars: usize, _Src: [*c]const u8, _MaxCount: usize, _Locale: _locale_t) errno_t;
pub extern fn strtok_s(_Str: [*c]u8, _Delim: [*c]const u8, _Context: [*c][*c]u8) [*c]u8;
pub extern fn _strtok_s_l(_Str: [*c]u8, _Delim: [*c]const u8, _Context: [*c][*c]u8, _Locale: _locale_t) [*c]u8;
pub extern fn strcat_s(_Dst: [*c]u8, _SizeInBytes: rsize_t, _Src: [*c]const u8) errno_t;
pub inline fn strnlen_s(arg__src: [*c]const u8, arg__count: usize) usize {
    var _src = arg__src;
    _ = &_src;
    var _count = arg__count;
    _ = &_count;
    return if (_src != null) strnlen(_src, _count) else @as(usize, 0);
}
pub extern fn memmove_s(_dest: ?*anyopaque, _numberOfElements: usize, _src: ?*const anyopaque, _count: usize) errno_t;
pub extern fn wcstok_s(_Str: [*c]wchar_t, _Delim: [*c]const wchar_t, _Context: [*c][*c]wchar_t) [*c]wchar_t;
pub extern fn _wcserror_s(_Buf: [*c]wchar_t, _SizeInWords: usize, _ErrNum: c_int) errno_t;
pub extern fn __wcserror_s(_Buffer: [*c]wchar_t, _SizeInWords: usize, _ErrMsg: [*c]const wchar_t) errno_t;
pub extern fn _wcsnset_s(_Dst: [*c]wchar_t, _DstSizeInWords: usize, _Val: wchar_t, _MaxCount: usize) errno_t;
pub extern fn _wcsset_s(_Str: [*c]wchar_t, _SizeInWords: usize, _Val: wchar_t) errno_t;
pub extern fn _wcslwr_s(_Str: [*c]wchar_t, _SizeInWords: usize) errno_t;
pub extern fn _wcslwr_s_l(_Str: [*c]wchar_t, _SizeInWords: usize, _Locale: _locale_t) errno_t;
pub extern fn _wcsupr_s(_Str: [*c]wchar_t, _Size: usize) errno_t;
pub extern fn _wcsupr_s_l(_Str: [*c]wchar_t, _Size: usize, _Locale: _locale_t) errno_t;
pub extern fn wcscpy_s(_Dst: [*c]wchar_t, _SizeInWords: rsize_t, _Src: [*c]const wchar_t) errno_t;
pub extern fn wcscat_s(_Dst: [*c]wchar_t, _SizeInWords: rsize_t, _Src: [*c]const wchar_t) errno_t;
pub extern fn wcsncat_s(_Dst: [*c]wchar_t, _DstSizeInChars: usize, _Src: [*c]const wchar_t, _MaxCount: usize) errno_t;
pub extern fn _wcsncat_s_l(_Dst: [*c]wchar_t, _DstSizeInChars: usize, _Src: [*c]const wchar_t, _MaxCount: usize, _Locale: _locale_t) errno_t;
pub extern fn wcsncpy_s(_Dst: [*c]wchar_t, _DstSizeInChars: usize, _Src: [*c]const wchar_t, _MaxCount: usize) errno_t;
pub extern fn _wcsncpy_s_l(_Dst: [*c]wchar_t, _DstSizeInChars: usize, _Src: [*c]const wchar_t, _MaxCount: usize, _Locale: _locale_t) errno_t;
pub extern fn _wcstok_s_l(_Str: [*c]wchar_t, _Delim: [*c]const wchar_t, _Context: [*c][*c]wchar_t, _Locale: _locale_t) [*c]wchar_t;
pub extern fn _wcsset_s_l(_Str: [*c]wchar_t, _SizeInChars: usize, _Val: wchar_t, _Locale: _locale_t) errno_t;
pub extern fn _wcsnset_s_l(_Str: [*c]wchar_t, _SizeInChars: usize, _Val: wchar_t, _Count: usize, _Locale: _locale_t) errno_t;
pub inline fn wcsnlen_s(arg__src: [*c]const wchar_t, arg__count: usize) usize {
    var _src = arg__src;
    _ = &_src;
    var _count = arg__count;
    _ = &_count;
    return if (_src != null) wcsnlen(_src, _count) else @as(usize, 0);
}
pub extern fn __local_stdio_printf_options() [*c]c_ulonglong;
pub extern fn __local_stdio_scanf_options() [*c]c_ulonglong;
pub const struct__iobuf = extern struct {
    _Placeholder: ?*anyopaque = null,
    pub const __mingw_fscanf = __root.__mingw_fscanf;
    pub const __mingw_vfscanf = __root.__mingw_vfscanf;
    pub const __mingw_fprintf = __root.__mingw_fprintf;
    pub const __mingw_vfprintf = __root.__mingw_vfprintf;
    pub const __ms_fscanf = __root.__ms_fscanf;
    pub const __ms_vfscanf = __root.__ms_vfscanf;
    pub const __ms_fprintf = __root.__ms_fprintf;
    pub const __ms_vfprintf = __root.__ms_vfprintf;
    pub const fprintf = __root.fprintf;
    pub const vfprintf = __root.vfprintf;
    pub const fscanf = __root.fscanf;
    pub const vfscanf = __root.vfscanf;
    pub const _filbuf = __root._filbuf;
    pub const clearerr = __root.clearerr;
    pub const fclose = __root.fclose;
    pub const feof = __root.feof;
    pub const ferror = __root.ferror;
    pub const fflush = __root.fflush;
    pub const fgetc = __root.fgetc;
    pub const fgetpos = __root.fgetpos;
    pub const fgetpos64 = __root.fgetpos64;
    pub const _fileno = __root._fileno;
    pub const fsetpos = __root.fsetpos;
    pub const fsetpos64 = __root.fsetpos64;
    pub const fseek = __root.fseek;
    pub const ftell = __root.ftell;
    pub const _fseeki64 = __root._fseeki64;
    pub const _ftelli64 = __root._ftelli64;
    pub const fseeko = __root.fseeko;
    pub const fseeko64 = __root.fseeko64;
    pub const ftello = __root.ftello;
    pub const ftello64 = __root.ftello64;
    pub const getc = __root.getc;
    pub const _getw = __root._getw;
    pub const _pclose = __root._pclose;
    pub const rewind = __root.rewind;
    pub const setbuf = __root.setbuf;
    pub const setvbuf = __root.setvbuf;
    pub const __mingw_fwscanf = __root.__mingw_fwscanf;
    pub const __mingw_vfwscanf = __root.__mingw_vfwscanf;
    pub const __mingw_fwprintf = __root.__mingw_fwprintf;
    pub const __mingw_vfwprintf = __root.__mingw_vfwprintf;
    pub const __ms_fwscanf = __root.__ms_fwscanf;
    pub const __ms_vfwscanf = __root.__ms_vfwscanf;
    pub const __ms_fwprintf = __root.__ms_fwprintf;
    pub const __ms_vfwprintf = __root.__ms_vfwprintf;
    pub const fwscanf = __root.fwscanf;
    pub const vfwscanf = __root.vfwscanf;
    pub const fwprintf = __root.fwprintf;
    pub const vfwprintf = __root.vfwprintf;
    pub const fgetwc = __root.fgetwc;
    pub const getwc = __root.getwc;
    pub const _fgetwc_nolock = __root._fgetwc_nolock;
    pub const _fgetc_nolock = __root._fgetc_nolock;
    pub const _getc_nolock = __root._getc_nolock;
    pub const _lock_file = __root._lock_file;
    pub const _unlock_file = __root._unlock_file;
    pub const _fclose_nolock = __root._fclose_nolock;
    pub const _fflush_nolock = __root._fflush_nolock;
    pub const _fseek_nolock = __root._fseek_nolock;
    pub const _ftell_nolock = __root._ftell_nolock;
    pub const _fseeki64_nolock = __root._fseeki64_nolock;
    pub const _ftelli64_nolock = __root._ftelli64_nolock;
    pub const fileno = __root.fileno;
    pub const getw = __root.getw;
    pub const clearerr_s = __root.clearerr_s;
    pub const _vfscanf_s_l = __root._vfscanf_s_l;
    pub const vfscanf_s = __root.vfscanf_s;
    pub const _fscanf_s_l = __root._fscanf_s_l;
    pub const fscanf_s = __root.fscanf_s;
    pub const _vfscanf_l = __root._vfscanf_l;
    pub const _fscanf_l = __root._fscanf_l;
    pub const _vfprintf_s_l = __root._vfprintf_s_l;
    pub const vfprintf_s = __root.vfprintf_s;
    pub const _fprintf_s_l = __root._fprintf_s_l;
    pub const fprintf_s = __root.fprintf_s;
    pub const _vfprintf_p_l = __root._vfprintf_p_l;
    pub const _vfprintf_p = __root._vfprintf_p;
    pub const _fprintf_p_l = __root._fprintf_p_l;
    pub const _fprintf_p = __root._fprintf_p;
    pub const _vfprintf_l = __root._vfprintf_l;
    pub const _fprintf_l = __root._fprintf_l;
    pub const _vfwscanf_s_l = __root._vfwscanf_s_l;
    pub const vfwscanf_s = __root.vfwscanf_s;
    pub const _fwscanf_s_l = __root._fwscanf_s_l;
    pub const fwscanf_s = __root.fwscanf_s;
    pub const _vfwprintf_s_l = __root._vfwprintf_s_l;
    pub const vfwprintf_s = __root.vfwprintf_s;
    pub const _fwprintf_s_l = __root._fwprintf_s_l;
    pub const fwprintf_s = __root.fwprintf_s;
    pub const filbuf = __root._filbuf;
    pub const fseeki64 = __root._fseeki64;
    pub const ftelli64 = __root._ftelli64;
    pub const nolock = __root._fgetwc_nolock;
    pub const file = __root._lock_file;
    pub const s = __root.clearerr_s;
    pub const l = __root._vfscanf_s_l;
    pub const p = __root._vfprintf_p;
};
pub const FILE = struct__iobuf;
pub const _off_t = c_long;
pub const off32_t = c_long;
pub const _off64_t = c_longlong;
pub const off64_t = c_longlong;
pub const off_t = off32_t;
pub extern fn __acrt_iob_func(index: c_uint) [*c]FILE;
pub extern fn __iob_func() [*c]FILE;
pub const fpos_t = c_longlong;
pub extern fn __mingw_sscanf(noalias _Src: [*c]const u8, noalias _Format: [*c]const u8, ...) c_int;
pub extern fn __mingw_vsscanf(noalias _Str: [*c]const u8, noalias Format: [*c]const u8, argp: va_list) c_int;
pub extern fn __mingw_scanf(noalias _Format: [*c]const u8, ...) c_int;
pub extern fn __mingw_vscanf(noalias Format: [*c]const u8, argp: va_list) c_int;
pub extern fn __mingw_fscanf(noalias _File: [*c]FILE, noalias _Format: [*c]const u8, ...) c_int;
pub extern fn __mingw_vfscanf(noalias fp: [*c]FILE, noalias Format: [*c]const u8, argp: va_list) c_int;
pub extern fn __mingw_vsnprintf(noalias _DstBuf: [*c]u8, _MaxCount: usize, noalias _Format: [*c]const u8, _ArgList: va_list) c_int;
pub extern fn __mingw_snprintf(noalias s: [*c]u8, n: usize, noalias format: [*c]const u8, ...) c_int;
pub extern fn __mingw_printf(noalias [*c]const u8, ...) c_int;
pub extern fn __mingw_vprintf(noalias [*c]const u8, va_list) c_int;
pub extern fn __mingw_fprintf(noalias [*c]FILE, noalias [*c]const u8, ...) c_int;
pub extern fn __mingw_vfprintf(noalias [*c]FILE, noalias [*c]const u8, va_list) c_int;
pub extern fn __mingw_sprintf(noalias [*c]u8, noalias [*c]const u8, ...) c_int;
pub extern fn __mingw_vsprintf(noalias [*c]u8, noalias [*c]const u8, va_list) c_int;
pub extern fn __mingw_asprintf(noalias [*c][*c]u8, noalias [*c]const u8, ...) c_int;
pub extern fn __mingw_vasprintf(noalias [*c][*c]u8, noalias [*c]const u8, va_list) c_int;
pub extern fn __ms_sscanf(noalias _Src: [*c]const u8, noalias _Format: [*c]const u8, ...) c_int;
pub extern fn __ms_vsscanf(noalias _Str: [*c]const u8, noalias _Format: [*c]const u8, argp: va_list) c_int;
pub extern fn __ms_scanf(noalias _Format: [*c]const u8, ...) c_int;
pub extern fn __ms_vscanf(noalias _Format: [*c]const u8, argp: va_list) c_int;
pub extern fn __ms_fscanf(noalias _File: [*c]FILE, noalias _Format: [*c]const u8, ...) c_int;
pub extern fn __ms_vfscanf(noalias _File: [*c]FILE, noalias _Format: [*c]const u8, argp: va_list) c_int;
pub extern fn __ms_printf(noalias [*c]const u8, ...) c_int;
pub extern fn __ms_vprintf(noalias [*c]const u8, va_list) c_int;
pub extern fn __ms_fprintf(noalias [*c]FILE, noalias [*c]const u8, ...) c_int;
pub extern fn __ms_vfprintf(noalias [*c]FILE, noalias [*c]const u8, va_list) c_int;
pub extern fn __ms_sprintf(noalias [*c]u8, noalias [*c]const u8, ...) c_int;
pub extern fn __ms_vsprintf(noalias [*c]u8, noalias [*c]const u8, va_list) c_int;
pub extern fn __ms_snprintf(noalias [*c]u8, usize, noalias [*c]const u8, ...) c_int;
pub extern fn __ms_vsnprintf(noalias [*c]u8, usize, noalias [*c]const u8, va_list) c_int;
pub extern fn __stdio_common_vsprintf(options: c_ulonglong, str: [*c]u8, len: usize, format: [*c]const u8, locale: _locale_t, valist: va_list) c_int;
pub extern fn __stdio_common_vfprintf(options: c_ulonglong, file: [*c]FILE, format: [*c]const u8, locale: _locale_t, valist: va_list) c_int;
pub extern fn __stdio_common_vsscanf(options: c_ulonglong, input: [*c]const u8, length: usize, format: [*c]const u8, locale: _locale_t, valist: va_list) c_int;
pub extern fn __stdio_common_vfscanf(options: c_ulonglong, file: [*c]FILE, format: [*c]const u8, locale: _locale_t, valist: va_list) c_int;
pub extern fn fprintf(noalias _File: [*c]FILE, noalias _Format: [*c]const u8, ...) c_int;
pub extern fn printf(noalias _Format: [*c]const u8, ...) c_int;
pub extern fn sprintf(noalias _Dest: [*c]u8, noalias _Format: [*c]const u8, ...) c_int;
pub extern fn vfprintf(noalias _File: [*c]FILE, noalias _Format: [*c]const u8, _ArgList: va_list) c_int;
pub extern fn vprintf(noalias _Format: [*c]const u8, _ArgList: va_list) c_int;
pub extern fn vsprintf(noalias _Dest: [*c]u8, noalias _Format: [*c]const u8, _Args: va_list) c_int;
pub extern fn fscanf(noalias _File: [*c]FILE, noalias _Format: [*c]const u8, ...) c_int;
pub extern fn scanf(noalias _Format: [*c]const u8, ...) c_int;
pub extern fn sscanf(noalias _Src: [*c]const u8, noalias _Format: [*c]const u8, ...) c_int;
pub extern fn vfscanf(__stream: [*c]FILE, __format: [*c]const u8, __local_argv: __builtin_va_list) c_int;
pub extern fn vsscanf(noalias __source: [*c]const u8, noalias __format: [*c]const u8, __local_argv: __builtin_va_list) c_int;
pub extern fn vscanf(__format: [*c]const u8, __local_argv: __builtin_va_list) c_int;
pub extern fn _filbuf(_File: [*c]FILE) c_int;
pub extern fn _flsbuf(_Ch: c_int, _File: [*c]FILE) c_int;
pub extern fn _fsopen(_Filename: [*c]const u8, _Mode: [*c]const u8, _ShFlag: c_int) [*c]FILE;
pub extern fn clearerr(_File: [*c]FILE) void;
pub extern fn fclose(_File: [*c]FILE) c_int;
pub extern fn _fcloseall() c_int;
pub extern fn _fdopen(_FileHandle: c_int, _Mode: [*c]const u8) [*c]FILE;
pub extern fn feof(_File: [*c]FILE) c_int;
pub extern fn ferror(_File: [*c]FILE) c_int;
pub extern fn fflush(_File: [*c]FILE) c_int;
pub extern fn fgetc(_File: [*c]FILE) c_int;
pub extern fn _fgetchar() c_int;
pub extern fn fgetpos(noalias _File: [*c]FILE, noalias _Pos: [*c]fpos_t) c_int;
pub extern fn fgetpos64(noalias _File: [*c]FILE, noalias _Pos: [*c]fpos_t) c_int;
pub extern fn fgets(noalias _Buf: [*c]u8, _MaxCount: c_int, noalias _File: [*c]FILE) [*c]u8;
pub extern fn _fileno(_File: [*c]FILE) c_int;
pub extern fn _tempnam(_DirName: [*c]const u8, _FilePrefix: [*c]const u8) [*c]u8;
pub extern fn _flushall() c_int;
pub extern fn fopen(noalias _Filename: [*c]const u8, noalias _Mode: [*c]const u8) [*c]FILE;
pub extern fn fopen64(noalias filename: [*c]const u8, noalias mode: [*c]const u8) [*c]FILE;
pub extern fn fputc(_Ch: c_int, _File: [*c]FILE) c_int;
pub extern fn _fputchar(_Ch: c_int) c_int;
pub extern fn fputs(noalias _Str: [*c]const u8, noalias _File: [*c]FILE) c_int;
pub extern fn fread(noalias _DstBuf: ?*anyopaque, _ElementSize: usize, _Count: usize, noalias _File: [*c]FILE) usize;
pub extern fn freopen(noalias _Filename: [*c]const u8, noalias _Mode: [*c]const u8, noalias _File: [*c]FILE) [*c]FILE;
pub extern fn fsetpos(_File: [*c]FILE, _Pos: [*c]const fpos_t) c_int;
pub extern fn fsetpos64(_File: [*c]FILE, _Pos: [*c]const fpos_t) c_int;
pub extern fn fseek(_File: [*c]FILE, _Offset: c_long, _Origin: c_int) c_int;
pub extern fn ftell(_File: [*c]FILE) c_long;
pub extern fn _fseeki64(_File: [*c]FILE, _Offset: c_longlong, _Origin: c_int) c_int;
pub extern fn _ftelli64(_File: [*c]FILE) c_longlong;
pub fn fseeko(arg__File: [*c]FILE, arg__Offset: _off_t, arg__Origin: c_int) callconv(.c) c_int {
    var _File = arg__File;
    _ = &_File;
    var _Offset = arg__Offset;
    _ = &_Offset;
    var _Origin = arg__Origin;
    _ = &_Origin;
    return fseek(_File, _Offset, _Origin);
}
pub fn fseeko64(arg__File: [*c]FILE, arg__Offset: _off64_t, arg__Origin: c_int) callconv(.c) c_int {
    var _File = arg__File;
    _ = &_File;
    var _Offset = arg__Offset;
    _ = &_Offset;
    var _Origin = arg__Origin;
    _ = &_Origin;
    return _fseeki64(_File, _Offset, _Origin);
}
pub fn ftello(arg__File: [*c]FILE) callconv(.c) _off_t {
    var _File = arg__File;
    _ = &_File;
    return ftell(_File);
}
pub fn ftello64(arg__File: [*c]FILE) callconv(.c) _off64_t {
    var _File = arg__File;
    _ = &_File;
    return _ftelli64(_File);
}
pub extern fn fwrite(noalias _Str: ?*const anyopaque, _Size: usize, _Count: usize, noalias _File: [*c]FILE) usize;
pub extern fn getc(_File: [*c]FILE) c_int;
pub extern fn getchar() c_int;
pub extern fn _getmaxstdio() c_int;
pub extern fn gets(_Buffer: [*c]u8) [*c]u8;
pub extern fn _getw(_File: [*c]FILE) c_int;
pub extern fn perror(_ErrMsg: [*c]const u8) void;
pub extern fn _pclose(_File: [*c]FILE) c_int;
pub extern fn _popen(_Command: [*c]const u8, _Mode: [*c]const u8) [*c]FILE;
pub extern fn putc(_Ch: c_int, _File: [*c]FILE) c_int;
pub extern fn putchar(_Ch: c_int) c_int;
pub extern fn puts(_Str: [*c]const u8) c_int;
pub extern fn _putw(_Word: c_int, _File: [*c]FILE) c_int;
pub extern fn remove(_Filename: [*c]const u8) c_int;
pub extern fn rename(_OldFilename: [*c]const u8, _NewFilename: [*c]const u8) c_int;
pub extern fn _unlink(_Filename: [*c]const u8) c_int;
pub extern fn unlink(_Filename: [*c]const u8) c_int;
pub extern fn rewind(_File: [*c]FILE) void;
pub extern fn _rmtmp() c_int;
pub extern fn setbuf(noalias _File: [*c]FILE, noalias _Buffer: [*c]u8) void;
pub extern fn _setmaxstdio(_Max: c_int) c_int;
pub extern fn _set_output_format(_Format: c_uint) c_uint;
pub extern fn _get_output_format() c_uint;
pub extern fn setvbuf(noalias _File: [*c]FILE, noalias _Buf: [*c]u8, _Mode: c_int, _Size: usize) c_int;
pub extern fn _scprintf(noalias _Format: [*c]const u8, ...) c_int;
pub extern fn _snscanf(noalias _Src: [*c]const u8, _MaxCount: usize, noalias _Format: [*c]const u8, ...) c_int;
pub extern fn _vscprintf(noalias _Format: [*c]const u8, _ArgList: va_list) c_int;
pub extern fn tmpfile() [*c]FILE;
pub extern fn tmpnam(_Buffer: [*c]u8) [*c]u8;
pub extern fn ungetc(_Ch: c_int, _File: [*c]FILE) c_int;
pub extern fn _vsnprintf(noalias _Dest: [*c]u8, _Count: usize, noalias _Format: [*c]const u8, _Args: va_list) c_int;
pub extern fn _snprintf(noalias _Dest: [*c]u8, _Count: usize, noalias _Format: [*c]const u8, ...) c_int;
pub extern fn vsnprintf(noalias __stream: [*c]u8, __n: usize, noalias __format: [*c]const u8, __local_argv: va_list) c_int;
pub extern fn snprintf(noalias __stream: [*c]u8, __n: usize, noalias __format: [*c]const u8, ...) c_int;
pub extern fn _set_printf_count_output(_Value: c_int) c_int;
pub extern fn _get_printf_count_output() c_int;
pub extern fn __mingw_swscanf(noalias _Src: [*c]const wchar_t, noalias _Format: [*c]const wchar_t, ...) c_int;
pub extern fn __mingw_vswscanf(noalias _Str: [*c]const wchar_t, noalias Format: [*c]const wchar_t, argp: va_list) c_int;
pub extern fn __mingw_wscanf(noalias _Format: [*c]const wchar_t, ...) c_int;
pub extern fn __mingw_vwscanf(noalias Format: [*c]const wchar_t, argp: va_list) c_int;
pub extern fn __mingw_fwscanf(noalias _File: [*c]FILE, noalias _Format: [*c]const wchar_t, ...) c_int;
pub extern fn __mingw_vfwscanf(noalias fp: [*c]FILE, noalias Format: [*c]const wchar_t, argp: va_list) c_int;
pub extern fn __mingw_fwprintf(noalias _File: [*c]FILE, noalias _Format: [*c]const wchar_t, ...) c_int;
pub extern fn __mingw_wprintf(noalias _Format: [*c]const wchar_t, ...) c_int;
pub extern fn __mingw_vfwprintf(noalias _File: [*c]FILE, noalias _Format: [*c]const wchar_t, _ArgList: va_list) c_int;
pub extern fn __mingw_vwprintf(noalias _Format: [*c]const wchar_t, _ArgList: va_list) c_int;
pub extern fn __mingw_snwprintf(noalias s: [*c]wchar_t, n: usize, noalias format: [*c]const wchar_t, ...) c_int;
pub extern fn __mingw_vsnwprintf(noalias [*c]wchar_t, usize, noalias [*c]const wchar_t, va_list) c_int;
pub extern fn __mingw_swprintf(noalias [*c]wchar_t, usize, noalias [*c]const wchar_t, ...) c_int;
pub extern fn __mingw_vswprintf(noalias [*c]wchar_t, usize, noalias [*c]const wchar_t, va_list) c_int;
pub extern fn __ms_swscanf(noalias _Src: [*c]const wchar_t, noalias _Format: [*c]const wchar_t, ...) c_int;
pub extern fn __ms_vswscanf(noalias _Src: [*c]const wchar_t, noalias _Format: [*c]const wchar_t, va_list) c_int;
pub extern fn __ms_wscanf(noalias _Format: [*c]const wchar_t, ...) c_int;
pub extern fn __ms_vwscanf(noalias _Format: [*c]const wchar_t, va_list) c_int;
pub extern fn __ms_fwscanf(noalias _File: [*c]FILE, noalias _Format: [*c]const wchar_t, ...) c_int;
pub extern fn __ms_vfwscanf(noalias _File: [*c]FILE, noalias _Format: [*c]const wchar_t, va_list) c_int;
pub extern fn __ms_fwprintf(noalias _File: [*c]FILE, noalias _Format: [*c]const wchar_t, ...) c_int;
pub extern fn __ms_wprintf(noalias _Format: [*c]const wchar_t, ...) c_int;
pub extern fn __ms_vfwprintf(noalias _File: [*c]FILE, noalias _Format: [*c]const wchar_t, _ArgList: va_list) c_int;
pub extern fn __ms_vwprintf(noalias _Format: [*c]const wchar_t, _ArgList: va_list) c_int;
pub extern fn __ms_swprintf(noalias [*c]wchar_t, usize, noalias [*c]const wchar_t, ...) c_int;
pub extern fn __ms_vswprintf(noalias [*c]wchar_t, usize, noalias [*c]const wchar_t, va_list) c_int;
pub extern fn __ms_snwprintf(noalias [*c]wchar_t, usize, noalias [*c]const wchar_t, ...) c_int;
pub extern fn __ms_vsnwprintf(noalias [*c]wchar_t, usize, noalias [*c]const wchar_t, va_list) c_int;
pub extern fn __stdio_common_vswprintf(options: c_ulonglong, str: [*c]wchar_t, len: usize, format: [*c]const wchar_t, locale: _locale_t, valist: va_list) c_int;
pub extern fn __stdio_common_vfwprintf(options: c_ulonglong, file: [*c]FILE, format: [*c]const wchar_t, locale: _locale_t, valist: va_list) c_int;
pub extern fn __stdio_common_vswscanf(options: c_ulonglong, input: [*c]const wchar_t, length: usize, format: [*c]const wchar_t, locale: _locale_t, valist: va_list) c_int;
pub extern fn __stdio_common_vfwscanf(options: c_ulonglong, file: [*c]FILE, format: [*c]const wchar_t, locale: _locale_t, valist: va_list) c_int;
pub extern fn fwscanf(noalias _File: [*c]FILE, noalias _Format: [*c]const wchar_t, ...) c_int;
pub extern fn swscanf(noalias _Src: [*c]const wchar_t, noalias _Format: [*c]const wchar_t, ...) c_int;
pub extern fn wscanf(noalias _Format: [*c]const wchar_t, ...) c_int;
pub extern fn vfwscanf(__stream: [*c]FILE, __format: [*c]const wchar_t, __local_argv: va_list) c_int;
pub extern fn vswscanf(noalias __source: [*c]const wchar_t, noalias __format: [*c]const wchar_t, __local_argv: va_list) c_int;
pub extern fn vwscanf(__format: [*c]const wchar_t, __local_argv: va_list) c_int;
pub extern fn fwprintf(noalias _File: [*c]FILE, noalias _Format: [*c]const wchar_t, ...) c_int;
pub extern fn wprintf(noalias _Format: [*c]const wchar_t, ...) c_int;
pub extern fn vfwprintf(noalias _File: [*c]FILE, noalias _Format: [*c]const wchar_t, _ArgList: va_list) c_int;
pub extern fn vwprintf(noalias _Format: [*c]const wchar_t, _ArgList: va_list) c_int;
pub extern fn _wfsopen(_Filename: [*c]const wchar_t, _Mode: [*c]const wchar_t, _ShFlag: c_int) [*c]FILE;
pub extern fn fgetwc(_File: [*c]FILE) wint_t;
pub extern fn _fgetwchar() wint_t;
pub extern fn fputwc(_Ch: wchar_t, _File: [*c]FILE) wint_t;
pub extern fn _fputwchar(_Ch: wchar_t) wint_t;
pub extern fn getwc(_File: [*c]FILE) wint_t;
pub extern fn getwchar() wint_t;
pub extern fn putwc(_Ch: wchar_t, _File: [*c]FILE) wint_t;
pub extern fn putwchar(_Ch: wchar_t) wint_t;
pub extern fn ungetwc(_Ch: wint_t, _File: [*c]FILE) wint_t;
pub extern fn fgetws(noalias _Dst: [*c]wchar_t, _SizeInWords: c_int, noalias _File: [*c]FILE) [*c]wchar_t;
pub extern fn fputws(noalias _Str: [*c]const wchar_t, noalias _File: [*c]FILE) c_int;
pub extern fn _getws(_String: [*c]wchar_t) [*c]wchar_t;
pub extern fn _putws(_Str: [*c]const wchar_t) c_int; // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\stdio.h:1169:15: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _scwprintf(noalias _Format: [*c]const wchar_t, ...) c_int;
pub extern fn _snwprintf(noalias _Dest: [*c]wchar_t, _Count: usize, noalias _Format: [*c]const wchar_t, ...) c_int;
pub extern fn _vsnwprintf(noalias _Dest: [*c]wchar_t, _Count: usize, noalias _Format: [*c]const wchar_t, _Args: va_list) c_int;
pub extern fn swprintf(noalias _Dest: [*c]wchar_t, _Count: usize, noalias _Format: [*c]const wchar_t, ...) c_int;
pub extern fn vswprintf(noalias _Dest: [*c]wchar_t, _Count: usize, noalias _Format: [*c]const wchar_t, _Args: va_list) c_int;
pub extern fn snwprintf(noalias s: [*c]wchar_t, n: usize, noalias format: [*c]const wchar_t, ...) c_int;
pub extern fn vsnwprintf(noalias s: [*c]wchar_t, n: usize, noalias format: [*c]const wchar_t, arg: va_list) c_int; // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\stdio.h:1190:15: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _swprintf(noalias _Dest: [*c]wchar_t, noalias _Format: [*c]const wchar_t, ...) c_int;
pub fn _vswprintf(noalias arg__Dest: [*c]wchar_t, noalias arg__Format: [*c]const wchar_t, arg__Args: va_list) callconv(.c) c_int {
    var _Dest = arg__Dest;
    _ = &_Dest;
    var _Format = arg__Format;
    _ = &_Format;
    var _Args = arg__Args;
    _ = &_Args;
    return __stdio_common_vswprintf(__local_stdio_printf_options().*, _Dest, @bitCast(@as(c_longlong, -@as(c_int, 1))), _Format, null, _Args);
}
pub fn _vscwprintf(noalias arg__Format: [*c]const wchar_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _Format = arg__Format;
    _ = &_Format;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    var _Result: c_int = __stdio_common_vswprintf(__local_stdio_printf_options().* | _CRT_INTERNAL_PRINTF_STANDARD_SNPRINTF_BEHAVIOR, null, 0, _Format, null, _ArgList);
    _ = &_Result;
    return if (_Result < @as(c_int, 0)) -@as(c_int, 1) else _Result;
}
pub extern fn _wtempnam(_Directory: [*c]const wchar_t, _FilePrefix: [*c]const wchar_t) [*c]wchar_t;
pub extern fn _snwscanf(noalias _Src: [*c]const wchar_t, _MaxCount: usize, noalias _Format: [*c]const wchar_t, ...) c_int;
pub extern fn _wfdopen(_FileHandle: c_int, _Mode: [*c]const wchar_t) [*c]FILE;
pub extern fn _wfopen(noalias _Filename: [*c]const wchar_t, noalias _Mode: [*c]const wchar_t) [*c]FILE;
pub extern fn _wfreopen(noalias _Filename: [*c]const wchar_t, noalias _Mode: [*c]const wchar_t, noalias _OldFile: [*c]FILE) [*c]FILE;
pub extern fn _wperror(_ErrMsg: [*c]const wchar_t) void;
pub extern fn _wpopen(_Command: [*c]const wchar_t, _Mode: [*c]const wchar_t) [*c]FILE;
pub extern fn _wremove(_Filename: [*c]const wchar_t) c_int;
pub extern fn _wtmpnam(_Buffer: [*c]wchar_t) [*c]wchar_t;
pub extern fn _fgetwc_nolock(_File: [*c]FILE) wint_t;
pub extern fn _fputwc_nolock(_Ch: wchar_t, _File: [*c]FILE) wint_t;
pub extern fn _ungetwc_nolock(_Ch: wint_t, _File: [*c]FILE) wint_t;
pub extern fn _fgetc_nolock(_File: [*c]FILE) c_int;
pub extern fn _fputc_nolock(_Char: c_int, _File: [*c]FILE) c_int;
pub extern fn _getc_nolock(_File: [*c]FILE) c_int;
pub extern fn _putc_nolock(_Char: c_int, _File: [*c]FILE) c_int;
pub extern fn _lock_file(_File: [*c]FILE) void;
pub extern fn _unlock_file(_File: [*c]FILE) void;
pub extern fn _fclose_nolock(_File: [*c]FILE) c_int;
pub extern fn _fflush_nolock(_File: [*c]FILE) c_int;
pub extern fn _fread_nolock(noalias _DstBuf: ?*anyopaque, _ElementSize: usize, _Count: usize, noalias _File: [*c]FILE) usize;
pub extern fn _fseek_nolock(_File: [*c]FILE, _Offset: c_long, _Origin: c_int) c_int;
pub extern fn _ftell_nolock(_File: [*c]FILE) c_long;
pub extern fn _fseeki64_nolock(_File: [*c]FILE, _Offset: c_longlong, _Origin: c_int) c_int;
pub extern fn _ftelli64_nolock(_File: [*c]FILE) c_longlong;
pub extern fn _fwrite_nolock(noalias _DstBuf: ?*const anyopaque, _Size: usize, _Count: usize, noalias _File: [*c]FILE) usize;
pub extern fn _ungetc_nolock(_Ch: c_int, _File: [*c]FILE) c_int;
pub extern fn tempnam(_Directory: [*c]const u8, _FilePrefix: [*c]const u8) [*c]u8;
pub extern fn fcloseall() c_int;
pub extern fn fdopen(_FileHandle: c_int, _Format: [*c]const u8) [*c]FILE;
pub extern fn fgetchar() c_int;
pub extern fn fileno(_File: [*c]FILE) c_int;
pub extern fn flushall() c_int;
pub extern fn fputchar(_Ch: c_int) c_int;
pub extern fn getw(_File: [*c]FILE) c_int;
pub extern fn putw(_Ch: c_int, _File: [*c]FILE) c_int;
pub extern fn rmtmp() c_int;
pub extern fn __mingw_str_wide_utf8(wptr: [*c]const wchar_t, mbptr: [*c][*c]u8, buflen: [*c]usize) c_int;
pub extern fn __mingw_str_utf8_wide(mbptr: [*c]const u8, wptr: [*c][*c]wchar_t, buflen: [*c]usize) c_int;
pub extern fn __mingw_str_free(ptr: ?*anyopaque) void;
pub extern fn _wspawnl(_Mode: c_int, _Filename: [*c]const wchar_t, _ArgList: [*c]const wchar_t, ...) isize;
pub extern fn _wspawnle(_Mode: c_int, _Filename: [*c]const wchar_t, _ArgList: [*c]const wchar_t, ...) isize;
pub extern fn _wspawnlp(_Mode: c_int, _Filename: [*c]const wchar_t, _ArgList: [*c]const wchar_t, ...) isize;
pub extern fn _wspawnlpe(_Mode: c_int, _Filename: [*c]const wchar_t, _ArgList: [*c]const wchar_t, ...) isize;
pub extern fn _wspawnv(_Mode: c_int, _Filename: [*c]const wchar_t, _ArgList: [*c]const [*c]const wchar_t) isize;
pub extern fn _wspawnve(_Mode: c_int, _Filename: [*c]const wchar_t, _ArgList: [*c]const [*c]const wchar_t, _Env: [*c]const [*c]const wchar_t) isize;
pub extern fn _wspawnvp(_Mode: c_int, _Filename: [*c]const wchar_t, _ArgList: [*c]const [*c]const wchar_t) isize;
pub extern fn _wspawnvpe(_Mode: c_int, _Filename: [*c]const wchar_t, _ArgList: [*c]const [*c]const wchar_t, _Env: [*c]const [*c]const wchar_t) isize;
pub extern fn _spawnv(_Mode: c_int, _Filename: [*c]const u8, _ArgList: [*c]const [*c]const u8) isize;
pub extern fn _spawnve(_Mode: c_int, _Filename: [*c]const u8, _ArgList: [*c]const [*c]const u8, _Env: [*c]const [*c]const u8) isize;
pub extern fn _spawnvp(_Mode: c_int, _Filename: [*c]const u8, _ArgList: [*c]const [*c]const u8) isize;
pub extern fn _spawnvpe(_Mode: c_int, _Filename: [*c]const u8, _ArgList: [*c]const [*c]const u8, _Env: [*c]const [*c]const u8) isize;
pub extern fn clearerr_s(_File: [*c]FILE) errno_t;
pub extern fn fread_s(_DstBuf: ?*anyopaque, _DstSize: usize, _ElementSize: usize, _Count: usize, _File: [*c]FILE) usize;
pub extern fn __stdio_common_vsprintf_s(_Options: c_ulonglong, _Str: [*c]u8, _Len: usize, _Format: [*c]const u8, _Locale: _locale_t, _ArgList: va_list) c_int;
pub extern fn __stdio_common_vsprintf_p(_Options: c_ulonglong, _Str: [*c]u8, _Len: usize, _Format: [*c]const u8, _Locale: _locale_t, _ArgList: va_list) c_int;
pub extern fn __stdio_common_vsnprintf_s(_Options: c_ulonglong, _Str: [*c]u8, _Len: usize, _MaxCount: usize, _Format: [*c]const u8, _Locale: _locale_t, _ArgList: va_list) c_int;
pub extern fn __stdio_common_vfprintf_s(_Options: c_ulonglong, _File: [*c]FILE, _Format: [*c]const u8, _Locale: _locale_t, _ArgList: va_list) c_int;
pub extern fn __stdio_common_vfprintf_p(_Options: c_ulonglong, _File: [*c]FILE, _Format: [*c]const u8, _Locale: _locale_t, _ArgList: va_list) c_int;
pub fn _vfscanf_s_l(arg__File: [*c]FILE, arg__Format: [*c]const u8, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _File = arg__File;
    _ = &_File;
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return __stdio_common_vfscanf(_CRT_INTERNAL_SCANF_SECURECRT, _File, _Format, _Locale, _ArgList);
}
pub fn vfscanf_s(arg__File: [*c]FILE, arg__Format: [*c]const u8, arg__ArgList: va_list) callconv(.c) c_int {
    var _File = arg__File;
    _ = &_File;
    var _Format = arg__Format;
    _ = &_Format;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vfscanf_s_l(_File, _Format, null, _ArgList);
}
pub fn _vscanf_s_l(arg__Format: [*c]const u8, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vfscanf_s_l(__acrt_iob_func(0), _Format, _Locale, _ArgList);
}
pub fn vscanf_s(arg__Format: [*c]const u8, arg__ArgList: va_list) callconv(.c) c_int {
    var _Format = arg__Format;
    _ = &_Format;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vfscanf_s_l(__acrt_iob_func(0), _Format, null, _ArgList);
} // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\sec_api/stdio_s.h:60:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _fscanf_s_l(_File: [*c]FILE, _Format: [*c]const u8, _Locale: _locale_t, ...) c_int; // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\sec_api/stdio_s.h:70:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn fscanf_s(_File: [*c]FILE, _Format: [*c]const u8, ...) c_int; // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\sec_api/stdio_s.h:80:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _scanf_s_l(_Format: [*c]const u8, _Locale: _locale_t, ...) c_int; // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\sec_api/stdio_s.h:90:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn scanf_s(_Format: [*c]const u8, ...) c_int;
pub fn _vfscanf_l(arg__File: [*c]FILE, arg__Format: [*c]const u8, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _File = arg__File;
    _ = &_File;
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return __stdio_common_vfscanf(0, _File, _Format, _Locale, _ArgList);
}
pub fn _vscanf_l(arg__Format: [*c]const u8, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vfscanf_l(__acrt_iob_func(0), _Format, _Locale, _ArgList);
} // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\sec_api/stdio_s.h:110:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _fscanf_l(_File: [*c]FILE, _Format: [*c]const u8, _Locale: _locale_t, ...) c_int; // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\sec_api/stdio_s.h:119:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _scanf_l(_Format: [*c]const u8, _Locale: _locale_t, ...) c_int;
pub fn _vsscanf_s_l(arg__Src: [*c]const u8, arg__Format: [*c]const u8, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _Src = arg__Src;
    _ = &_Src;
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return __stdio_common_vsscanf(_CRT_INTERNAL_SCANF_SECURECRT, _Src, @bitCast(@as(c_longlong, -@as(c_int, 1))), _Format, _Locale, _ArgList);
}
pub fn vsscanf_s(arg__Src: [*c]const u8, arg__Format: [*c]const u8, arg__ArgList: va_list) callconv(.c) c_int {
    var _Src = arg__Src;
    _ = &_Src;
    var _Format = arg__Format;
    _ = &_Format;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vsscanf_s_l(_Src, _Format, null, _ArgList);
} // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\sec_api/stdio_s.h:137:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _sscanf_s_l(_Src: [*c]const u8, _Format: [*c]const u8, _Locale: _locale_t, ...) c_int; // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\sec_api/stdio_s.h:146:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn sscanf_s(_Src: [*c]const u8, _Format: [*c]const u8, ...) c_int;
pub fn _vsscanf_l(arg__Src: [*c]const u8, arg__Format: [*c]const u8, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _Src = arg__Src;
    _ = &_Src;
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return __stdio_common_vsscanf(0, _Src, @bitCast(@as(c_longlong, -@as(c_int, 1))), _Format, _Locale, _ArgList);
} // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\sec_api/stdio_s.h:160:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _sscanf_l(_Src: [*c]const u8, _Format: [*c]const u8, _Locale: _locale_t, ...) c_int; // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\sec_api/stdio_s.h:171:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _snscanf_s_l(_Src: [*c]const u8, _MaxCount: usize, _Format: [*c]const u8, _Locale: _locale_t, ...) c_int; // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\sec_api/stdio_s.h:180:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _snscanf_s(_Src: [*c]const u8, _MaxCount: usize, _Format: [*c]const u8, ...) c_int; // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\sec_api/stdio_s.h:191:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _snscanf_l(_Src: [*c]const u8, _MaxCount: usize, _Format: [*c]const u8, _Locale: _locale_t, ...) c_int;
pub fn _vfprintf_s_l(arg__File: [*c]FILE, arg__Format: [*c]const u8, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _File = arg__File;
    _ = &_File;
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return __stdio_common_vfprintf_s(__local_stdio_printf_options().*, _File, _Format, _Locale, _ArgList);
}
pub fn vfprintf_s(arg__File: [*c]FILE, arg__Format: [*c]const u8, arg__ArgList: va_list) callconv(.c) c_int {
    var _File = arg__File;
    _ = &_File;
    var _Format = arg__Format;
    _ = &_Format;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vfprintf_s_l(_File, _Format, null, _ArgList);
}
pub fn _vprintf_s_l(arg__Format: [*c]const u8, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vfprintf_s_l(__acrt_iob_func(1), _Format, _Locale, _ArgList);
}
pub fn vprintf_s(arg__Format: [*c]const u8, arg__ArgList: va_list) callconv(.c) c_int {
    var _Format = arg__Format;
    _ = &_Format;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vfprintf_s_l(__acrt_iob_func(1), _Format, null, _ArgList);
} // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\sec_api/stdio_s.h:218:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _fprintf_s_l(_File: [*c]FILE, _Format: [*c]const u8, _Locale: _locale_t, ...) c_int; // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\sec_api/stdio_s.h:227:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _printf_s_l(_Format: [*c]const u8, _Locale: _locale_t, ...) c_int; // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\sec_api/stdio_s.h:236:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn fprintf_s(_File: [*c]FILE, _Format: [*c]const u8, ...) c_int; // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\sec_api/stdio_s.h:245:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn printf_s(_Format: [*c]const u8, ...) c_int;
pub fn _vsnprintf_c_l(arg__DstBuf: [*c]u8, arg__MaxCount: usize, arg__Format: [*c]const u8, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _DstBuf = arg__DstBuf;
    _ = &_DstBuf;
    var _MaxCount = arg__MaxCount;
    _ = &_MaxCount;
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return __stdio_common_vsprintf(__local_stdio_printf_options().*, _DstBuf, _MaxCount, _Format, _Locale, _ArgList);
}
pub fn _vsnprintf_c(arg__DstBuf: [*c]u8, arg__MaxCount: usize, arg__Format: [*c]const u8, arg__ArgList: va_list) callconv(.c) c_int {
    var _DstBuf = arg__DstBuf;
    _ = &_DstBuf;
    var _MaxCount = arg__MaxCount;
    _ = &_MaxCount;
    var _Format = arg__Format;
    _ = &_Format;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vsnprintf_c_l(_DstBuf, _MaxCount, _Format, null, _ArgList);
} // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\sec_api/stdio_s.h:263:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _snprintf_c_l(_DstBuf: [*c]u8, _MaxCount: usize, _Format: [*c]const u8, _Locale: _locale_t, ...) c_int; // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\sec_api/stdio_s.h:272:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _snprintf_c(_DstBuf: [*c]u8, _MaxCount: usize, _Format: [*c]const u8, ...) c_int;
pub fn _vsnprintf_s_l(arg__DstBuf: [*c]u8, arg__DstSize: usize, arg__MaxCount: usize, arg__Format: [*c]const u8, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _DstBuf = arg__DstBuf;
    _ = &_DstBuf;
    var _DstSize = arg__DstSize;
    _ = &_DstSize;
    var _MaxCount = arg__MaxCount;
    _ = &_MaxCount;
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return __stdio_common_vsnprintf_s(__local_stdio_printf_options().*, _DstBuf, _DstSize, _MaxCount, _Format, _Locale, _ArgList);
}
pub fn vsnprintf_s(arg__DstBuf: [*c]u8, arg__DstSize: usize, arg__MaxCount: usize, arg__Format: [*c]const u8, arg__ArgList: va_list) callconv(.c) c_int {
    var _DstBuf = arg__DstBuf;
    _ = &_DstBuf;
    var _DstSize = arg__DstSize;
    _ = &_DstSize;
    var _MaxCount = arg__MaxCount;
    _ = &_MaxCount;
    var _Format = arg__Format;
    _ = &_Format;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vsnprintf_s_l(_DstBuf, _DstSize, _MaxCount, _Format, null, _ArgList);
}
pub fn _vsnprintf_s(arg__DstBuf: [*c]u8, arg__DstSize: usize, arg__MaxCount: usize, arg__Format: [*c]const u8, arg__ArgList: va_list) callconv(.c) c_int {
    var _DstBuf = arg__DstBuf;
    _ = &_DstBuf;
    var _DstSize = arg__DstSize;
    _ = &_DstSize;
    var _MaxCount = arg__MaxCount;
    _ = &_MaxCount;
    var _Format = arg__Format;
    _ = &_Format;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vsnprintf_s_l(_DstBuf, _DstSize, _MaxCount, _Format, null, _ArgList);
} // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\sec_api/stdio_s.h:294:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _snprintf_s_l(_DstBuf: [*c]u8, _DstSize: usize, _MaxCount: usize, _Format: [*c]const u8, _Locale: _locale_t, ...) c_int; // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\sec_api/stdio_s.h:303:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _snprintf_s(_DstBuf: [*c]u8, _DstSize: usize, _MaxCount: usize, _Format: [*c]const u8, ...) c_int;
pub fn _vsprintf_s_l(arg__DstBuf: [*c]u8, arg__DstSize: usize, arg__Format: [*c]const u8, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _DstBuf = arg__DstBuf;
    _ = &_DstBuf;
    var _DstSize = arg__DstSize;
    _ = &_DstSize;
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return __stdio_common_vsprintf_s(__local_stdio_printf_options().*, _DstBuf, _DstSize, _Format, _Locale, _ArgList);
}
pub fn vsprintf_s(arg__DstBuf: [*c]u8, arg__Size: usize, arg__Format: [*c]const u8, arg__ArgList: va_list) callconv(.c) c_int {
    var _DstBuf = arg__DstBuf;
    _ = &_DstBuf;
    var _Size = arg__Size;
    _ = &_Size;
    var _Format = arg__Format;
    _ = &_Format;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vsprintf_s_l(_DstBuf, _Size, _Format, null, _ArgList);
} // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\sec_api/stdio_s.h:321:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _sprintf_s_l(_DstBuf: [*c]u8, _DstSize: usize, _Format: [*c]const u8, _Locale: _locale_t, ...) c_int; // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\sec_api/stdio_s.h:330:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn sprintf_s(_DstBuf: [*c]u8, _DstSize: usize, _Format: [*c]const u8, ...) c_int;
pub fn _vfprintf_p_l(arg__File: [*c]FILE, arg__Format: [*c]const u8, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _File = arg__File;
    _ = &_File;
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return __stdio_common_vfprintf_p(__local_stdio_printf_options().*, _File, _Format, _Locale, _ArgList);
}
pub fn _vfprintf_p(arg__File: [*c]FILE, arg__Format: [*c]const u8, arg__ArgList: va_list) callconv(.c) c_int {
    var _File = arg__File;
    _ = &_File;
    var _Format = arg__Format;
    _ = &_Format;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vfprintf_p_l(_File, _Format, null, _ArgList);
}
pub fn _vprintf_p_l(arg__Format: [*c]const u8, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vfprintf_p_l(__acrt_iob_func(1), _Format, _Locale, _ArgList);
}
pub fn _vprintf_p(arg__Format: [*c]const u8, arg__ArgList: va_list) callconv(.c) c_int {
    var _Format = arg__Format;
    _ = &_Format;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vfprintf_p_l(__acrt_iob_func(1), _Format, null, _ArgList);
} // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\sec_api/stdio_s.h:356:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _fprintf_p_l(_File: [*c]FILE, _Format: [*c]const u8, _Locale: _locale_t, ...) c_int; // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\sec_api/stdio_s.h:365:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _fprintf_p(_File: [*c]FILE, _Format: [*c]const u8, ...) c_int; // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\sec_api/stdio_s.h:374:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _printf_p_l(_Format: [*c]const u8, _Locale: _locale_t, ...) c_int; // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\sec_api/stdio_s.h:383:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _printf_p(_Format: [*c]const u8, ...) c_int;
pub fn _vsprintf_p_l(arg__DstBuf: [*c]u8, arg__MaxCount: usize, arg__Format: [*c]const u8, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _DstBuf = arg__DstBuf;
    _ = &_DstBuf;
    var _MaxCount = arg__MaxCount;
    _ = &_MaxCount;
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return __stdio_common_vsprintf_p(__local_stdio_printf_options().*, _DstBuf, _MaxCount, _Format, _Locale, _ArgList);
}
pub fn _vsprintf_p(arg__Dst: [*c]u8, arg__MaxCount: usize, arg__Format: [*c]const u8, arg__ArgList: va_list) callconv(.c) c_int {
    var _Dst = arg__Dst;
    _ = &_Dst;
    var _MaxCount = arg__MaxCount;
    _ = &_MaxCount;
    var _Format = arg__Format;
    _ = &_Format;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vsprintf_p_l(_Dst, _MaxCount, _Format, null, _ArgList);
} // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\sec_api/stdio_s.h:401:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _sprintf_p_l(_DstBuf: [*c]u8, _MaxCount: usize, _Format: [*c]const u8, _Locale: _locale_t, ...) c_int; // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\sec_api/stdio_s.h:410:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _sprintf_p(_Dst: [*c]u8, _MaxCount: usize, _Format: [*c]const u8, ...) c_int;
pub fn _vscprintf_p_l(arg__Format: [*c]const u8, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return __stdio_common_vsprintf_p(_CRT_INTERNAL_PRINTF_STANDARD_SNPRINTF_BEHAVIOR, null, 0, _Format, _Locale, _ArgList);
}
pub fn _vscprintf_p(arg__Format: [*c]const u8, arg__ArgList: va_list) callconv(.c) c_int {
    var _Format = arg__Format;
    _ = &_Format;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vscprintf_p_l(_Format, null, _ArgList);
} // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\sec_api/stdio_s.h:428:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _scprintf_p_l(_Format: [*c]const u8, _Locale: _locale_t, ...) c_int; // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\sec_api/stdio_s.h:437:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _scprintf_p(_Format: [*c]const u8, ...) c_int;
pub fn _vfprintf_l(arg__File: [*c]FILE, arg__Format: [*c]const u8, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _File = arg__File;
    _ = &_File;
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return __stdio_common_vfprintf(__local_stdio_printf_options().*, _File, _Format, _Locale, _ArgList);
}
pub fn _vprintf_l(arg__Format: [*c]const u8, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vfprintf_l(__acrt_iob_func(1), _Format, _Locale, _ArgList);
} // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\sec_api/stdio_s.h:455:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _fprintf_l(_File: [*c]FILE, _Format: [*c]const u8, _Locale: _locale_t, ...) c_int; // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\sec_api/stdio_s.h:464:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _printf_l(_Format: [*c]const u8, _Locale: _locale_t, ...) c_int;
pub fn _vsnprintf_l(arg__DstBuf: [*c]u8, arg__MaxCount: usize, arg__Format: [*c]const u8, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _DstBuf = arg__DstBuf;
    _ = &_DstBuf;
    var _MaxCount = arg__MaxCount;
    _ = &_MaxCount;
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return __stdio_common_vsprintf(_CRT_INTERNAL_PRINTF_LEGACY_VSPRINTF_NULL_TERMINATION, _DstBuf, _MaxCount, _Format, _Locale, _ArgList);
} // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\sec_api/stdio_s.h:478:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _snprintf_l(_DstBuf: [*c]u8, _MaxCount: usize, _Format: [*c]const u8, _Locale: _locale_t, ...) c_int;
pub fn _vsprintf_l(arg__DstBuf: [*c]u8, arg__Format: [*c]const u8, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _DstBuf = arg__DstBuf;
    _ = &_DstBuf;
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vsnprintf_l(_DstBuf, @bitCast(@as(c_longlong, -@as(c_int, 1))), _Format, _Locale, _ArgList);
} // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\sec_api/stdio_s.h:491:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _sprintf_l(_DstBuf: [*c]u8, _Format: [*c]const u8, _Locale: _locale_t, ...) c_int;
pub fn _vscprintf_l(arg__Format: [*c]const u8, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return __stdio_common_vsprintf(_CRT_INTERNAL_PRINTF_STANDARD_SNPRINTF_BEHAVIOR, null, 0, _Format, _Locale, _ArgList);
} // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\sec_api/stdio_s.h:505:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _scprintf_l(_Format: [*c]const u8, _Locale: _locale_t, ...) c_int;
pub extern fn fopen_s(_File: [*c][*c]FILE, _Filename: [*c]const u8, _Mode: [*c]const u8) errno_t;
pub extern fn freopen_s(_File: [*c][*c]FILE, _Filename: [*c]const u8, _Mode: [*c]const u8, _Stream: [*c]FILE) errno_t;
pub extern fn gets_s([*c]u8, rsize_t) [*c]u8;
pub extern fn tmpfile_s(_File: [*c][*c]FILE) errno_t;
pub extern fn tmpnam_s([*c]u8, rsize_t) errno_t;
pub extern fn _getws_s(_Str: [*c]wchar_t, _SizeInWords: usize) [*c]wchar_t;
pub extern fn __stdio_common_vswprintf_s(_Options: c_ulonglong, _Str: [*c]wchar_t, _Len: usize, _Format: [*c]const wchar_t, _Locale: _locale_t, _ArgList: va_list) c_int;
pub extern fn __stdio_common_vsnwprintf_s(_Options: c_ulonglong, _Str: [*c]wchar_t, _Len: usize, _MaxCount: usize, _Format: [*c]const wchar_t, _Locale: _locale_t, _ArgList: va_list) c_int;
pub extern fn __stdio_common_vfwprintf_s(_Options: c_ulonglong, _File: [*c]FILE, _Format: [*c]const wchar_t, _Locale: _locale_t, _ArgList: va_list) c_int;
pub fn _vfwscanf_s_l(arg__File: [*c]FILE, arg__Format: [*c]const wchar_t, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _File = arg__File;
    _ = &_File;
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return __stdio_common_vfwscanf(__local_stdio_scanf_options().* | _CRT_INTERNAL_SCANF_SECURECRT, _File, _Format, _Locale, _ArgList);
}
pub fn vfwscanf_s(arg__File: [*c]FILE, arg__Format: [*c]const wchar_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _File = arg__File;
    _ = &_File;
    var _Format = arg__Format;
    _ = &_Format;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vfwscanf_s_l(_File, _Format, null, _ArgList);
}
pub fn _vwscanf_s_l(arg__Format: [*c]const wchar_t, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vfwscanf_s_l(__acrt_iob_func(0), _Format, _Locale, _ArgList);
}
pub fn vwscanf_s(arg__Format: [*c]const wchar_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _Format = arg__Format;
    _ = &_Format;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vfwscanf_s_l(__acrt_iob_func(0), _Format, null, _ArgList);
} // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\sec_api/stdio_s.h:631:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _fwscanf_s_l(_File: [*c]FILE, _Format: [*c]const wchar_t, _Locale: _locale_t, ...) c_int; // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\sec_api/stdio_s.h:641:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn fwscanf_s(_File: [*c]FILE, _Format: [*c]const wchar_t, ...) c_int; // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\sec_api/stdio_s.h:651:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _wscanf_s_l(_Format: [*c]const wchar_t, _Locale: _locale_t, ...) c_int; // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\sec_api/stdio_s.h:661:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn wscanf_s(_Format: [*c]const wchar_t, ...) c_int;
pub fn _vswscanf_s_l(arg__Src: [*c]const wchar_t, arg__Format: [*c]const wchar_t, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _Src = arg__Src;
    _ = &_Src;
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return __stdio_common_vswscanf(__local_stdio_scanf_options().* | _CRT_INTERNAL_SCANF_SECURECRT, _Src, @bitCast(@as(c_longlong, -@as(c_int, 1))), _Format, _Locale, _ArgList);
}
pub fn vswscanf_s(arg__Src: [*c]const wchar_t, arg__Format: [*c]const wchar_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _Src = arg__Src;
    _ = &_Src;
    var _Format = arg__Format;
    _ = &_Format;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vswscanf_s_l(_Src, _Format, null, _ArgList);
} // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\sec_api/stdio_s.h:681:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _swscanf_s_l(_Src: [*c]const wchar_t, _Format: [*c]const wchar_t, _Locale: _locale_t, ...) c_int; // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\sec_api/stdio_s.h:690:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn swscanf_s(_Src: [*c]const wchar_t, _Format: [*c]const wchar_t, ...) c_int;
pub fn _vsnwscanf_s_l(arg__Src: [*c]const wchar_t, arg__MaxCount: usize, arg__Format: [*c]const wchar_t, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _Src = arg__Src;
    _ = &_Src;
    var _MaxCount = arg__MaxCount;
    _ = &_MaxCount;
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return __stdio_common_vswscanf(__local_stdio_scanf_options().* | _CRT_INTERNAL_SCANF_SECURECRT, _Src, _MaxCount, _Format, _Locale, _ArgList);
} // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\sec_api/stdio_s.h:704:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _snwscanf_s_l(_Src: [*c]const wchar_t, _MaxCount: usize, _Format: [*c]const wchar_t, _Locale: _locale_t, ...) c_int; // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\sec_api/stdio_s.h:713:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _snwscanf_s(_Src: [*c]const wchar_t, _MaxCount: usize, _Format: [*c]const wchar_t, ...) c_int;
pub fn _vfwprintf_s_l(arg__File: [*c]FILE, arg__Format: [*c]const wchar_t, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _File = arg__File;
    _ = &_File;
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return __stdio_common_vfwprintf_s(__local_stdio_printf_options().*, _File, _Format, _Locale, _ArgList);
}
pub fn _vwprintf_s_l(arg__Format: [*c]const wchar_t, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vfwprintf_s_l(__acrt_iob_func(1), _Format, _Locale, _ArgList);
}
pub fn vfwprintf_s(arg__File: [*c]FILE, arg__Format: [*c]const wchar_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _File = arg__File;
    _ = &_File;
    var _Format = arg__Format;
    _ = &_Format;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vfwprintf_s_l(_File, _Format, null, _ArgList);
}
pub fn vwprintf_s(arg__Format: [*c]const wchar_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _Format = arg__Format;
    _ = &_Format;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vfwprintf_s_l(__acrt_iob_func(1), _Format, null, _ArgList);
} // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\sec_api/stdio_s.h:739:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _fwprintf_s_l(_File: [*c]FILE, _Format: [*c]const wchar_t, _Locale: _locale_t, ...) c_int; // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\sec_api/stdio_s.h:748:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _wprintf_s_l(_Format: [*c]const wchar_t, _Locale: _locale_t, ...) c_int; // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\sec_api/stdio_s.h:757:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn fwprintf_s(_File: [*c]FILE, _Format: [*c]const wchar_t, ...) c_int; // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\sec_api/stdio_s.h:766:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn wprintf_s(_Format: [*c]const wchar_t, ...) c_int;
pub fn _vswprintf_s_l(arg__DstBuf: [*c]wchar_t, arg__DstSize: usize, arg__Format: [*c]const wchar_t, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _DstBuf = arg__DstBuf;
    _ = &_DstBuf;
    var _DstSize = arg__DstSize;
    _ = &_DstSize;
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return __stdio_common_vswprintf_s(__local_stdio_printf_options().*, _DstBuf, _DstSize, _Format, _Locale, _ArgList);
}
pub fn vswprintf_s(arg__DstBuf: [*c]wchar_t, arg__DstSize: usize, arg__Format: [*c]const wchar_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _DstBuf = arg__DstBuf;
    _ = &_DstBuf;
    var _DstSize = arg__DstSize;
    _ = &_DstSize;
    var _Format = arg__Format;
    _ = &_Format;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vswprintf_s_l(_DstBuf, _DstSize, _Format, null, _ArgList);
} // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\sec_api/stdio_s.h:784:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _swprintf_s_l(_DstBuf: [*c]wchar_t, _DstSize: usize, _Format: [*c]const wchar_t, _Locale: _locale_t, ...) c_int; // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\sec_api/stdio_s.h:793:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn swprintf_s(_DstBuf: [*c]wchar_t, _DstSize: usize, _Format: [*c]const wchar_t, ...) c_int;
pub fn _vsnwprintf_s_l(arg__DstBuf: [*c]wchar_t, arg__DstSize: usize, arg__MaxCount: usize, arg__Format: [*c]const wchar_t, arg__Locale: _locale_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _DstBuf = arg__DstBuf;
    _ = &_DstBuf;
    var _DstSize = arg__DstSize;
    _ = &_DstSize;
    var _MaxCount = arg__MaxCount;
    _ = &_MaxCount;
    var _Format = arg__Format;
    _ = &_Format;
    var _Locale = arg__Locale;
    _ = &_Locale;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return __stdio_common_vsnwprintf_s(__local_stdio_printf_options().*, _DstBuf, _DstSize, _MaxCount, _Format, _Locale, _ArgList);
}
pub fn _vsnwprintf_s(arg__DstBuf: [*c]wchar_t, arg__DstSize: usize, arg__MaxCount: usize, arg__Format: [*c]const wchar_t, arg__ArgList: va_list) callconv(.c) c_int {
    var _DstBuf = arg__DstBuf;
    _ = &_DstBuf;
    var _DstSize = arg__DstSize;
    _ = &_DstSize;
    var _MaxCount = arg__MaxCount;
    _ = &_MaxCount;
    var _Format = arg__Format;
    _ = &_Format;
    var _ArgList = arg__ArgList;
    _ = &_ArgList;
    return _vsnwprintf_s_l(_DstBuf, _DstSize, _MaxCount, _Format, null, _ArgList);
} // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\sec_api/stdio_s.h:811:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _snwprintf_s_l(_DstBuf: [*c]wchar_t, _DstSize: usize, _MaxCount: usize, _Format: [*c]const wchar_t, _Locale: _locale_t, ...) c_int; // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\sec_api/stdio_s.h:820:27: warning: TODO unable to translate variadic function, demoted to extern
pub extern fn _snwprintf_s(_DstBuf: [*c]wchar_t, _DstSize: usize, _MaxCount: usize, _Format: [*c]const wchar_t, ...) c_int;
pub extern fn _wfopen_s(_File: [*c][*c]FILE, _Filename: [*c]const wchar_t, _Mode: [*c]const wchar_t) errno_t;
pub extern fn _wfreopen_s(_File: [*c][*c]FILE, _Filename: [*c]const wchar_t, _Mode: [*c]const wchar_t, _OldFile: [*c]FILE) errno_t;
pub extern fn _wtmpnam_s(_DstBuf: [*c]wchar_t, _SizeInWords: usize) errno_t;
pub extern fn _fread_nolock_s(_DstBuf: ?*anyopaque, _DstSize: usize, _ElementSize: usize, _Count: usize, _File: [*c]FILE) usize;
pub extern fn _wdupenv_s(_Buffer: [*c][*c]wchar_t, _BufferSizeInWords: [*c]usize, _VarName: [*c]const wchar_t) errno_t;
pub extern fn _itow_s(_Val: c_int, _DstBuf: [*c]wchar_t, _SizeInWords: usize, _Radix: c_int) errno_t;
pub extern fn _ltow_s(_Val: c_long, _DstBuf: [*c]wchar_t, _SizeInWords: usize, _Radix: c_int) errno_t;
pub extern fn _ultow_s(_Val: c_ulong, _DstBuf: [*c]wchar_t, _SizeInWords: usize, _Radix: c_int) errno_t;
pub extern fn _wgetenv_s(_ReturnSize: [*c]usize, _DstBuf: [*c]wchar_t, _DstSizeInWords: usize, _VarName: [*c]const wchar_t) errno_t;
pub extern fn _i64tow_s(_Val: c_longlong, _DstBuf: [*c]wchar_t, _SizeInWords: usize, _Radix: c_int) errno_t;
pub extern fn _ui64tow_s(_Val: c_ulonglong, _DstBuf: [*c]wchar_t, _SizeInWords: usize, _Radix: c_int) errno_t;
pub extern fn _wmakepath_s(_PathResult: [*c]wchar_t, _SizeInWords: usize, _Drive: [*c]const wchar_t, _Dir: [*c]const wchar_t, _Filename: [*c]const wchar_t, _Ext: [*c]const wchar_t) errno_t;
pub extern fn _wputenv_s(_Name: [*c]const wchar_t, _Value: [*c]const wchar_t) errno_t;
pub extern fn _wsearchenv_s(_Filename: [*c]const wchar_t, _EnvVar: [*c]const wchar_t, _ResultPath: [*c]wchar_t, _SizeInWords: usize) errno_t;
pub extern fn _wsplitpath_s(_FullPath: [*c]const wchar_t, _Drive: [*c]wchar_t, _DriveSizeInWords: usize, _Dir: [*c]wchar_t, _DirSizeInWords: usize, _Filename: [*c]wchar_t, _FilenameSizeInWords: usize, _Ext: [*c]wchar_t, _ExtSizeInWords: usize) errno_t;
pub const _onexit_t = ?*const fn () callconv(.c) c_int;
pub const struct__div_t = extern struct {
    quot: c_int = 0,
    rem: c_int = 0,
};
pub const div_t = struct__div_t;
pub const struct__ldiv_t = extern struct {
    quot: c_long = 0,
    rem: c_long = 0,
};
pub const ldiv_t = struct__ldiv_t;
pub const _LDOUBLE = extern struct {
    ld: [10]u8 = @import("std").mem.zeroes([10]u8),
    pub const _atoldbl = __root._atoldbl;
    pub const _atoldbl_l = __root._atoldbl_l;
    pub const atoldbl = __root._atoldbl;
    pub const l = __root._atoldbl_l;
};
pub const _CRT_DOUBLE = extern struct {
    x: f64 = 0,
    pub const _atodbl = __root._atodbl;
    pub const _atodbl_l = __root._atodbl_l;
    pub const atodbl = __root._atodbl;
    pub const l = __root._atodbl_l;
};
pub const _CRT_FLOAT = extern struct {
    f: f32 = 0,
    pub const _atoflt = __root._atoflt;
    pub const _atoflt_l = __root._atoflt_l;
    pub const atoflt = __root._atoflt;
    pub const l = __root._atoflt_l;
};
pub const _LONGDOUBLE = extern struct {
    x: c_longdouble = 0,
};
pub const _LDBL12 = extern struct {
    ld12: [12]u8 = @import("std").mem.zeroes([12]u8),
};
pub extern fn ___mb_cur_max_func() c_int;
pub const _purecall_handler = ?*const fn () callconv(.c) void;
pub extern fn _set_purecall_handler(_Handler: _purecall_handler) _purecall_handler;
pub extern fn _get_purecall_handler() _purecall_handler;
pub const _invalid_parameter_handler = ?*const fn ([*c]const wchar_t, [*c]const wchar_t, [*c]const wchar_t, c_uint, usize) callconv(.c) void;
pub extern fn _set_invalid_parameter_handler(_Handler: _invalid_parameter_handler) _invalid_parameter_handler;
pub extern fn _get_invalid_parameter_handler() _invalid_parameter_handler;
pub extern fn _errno() [*c]c_int;
pub extern fn _set_errno(_Value: c_int) errno_t;
pub extern fn _get_errno(_Value: [*c]c_int) errno_t;
pub extern fn __doserrno() [*c]c_ulong;
pub extern fn _set_doserrno(_Value: c_ulong) errno_t;
pub extern fn _get_doserrno(_Value: [*c]c_ulong) errno_t;
pub extern fn __sys_errlist() [*c][*c]u8;
pub extern fn __sys_nerr() [*c]c_int;
pub extern fn __p___argv() [*c][*c][*c]u8;
pub extern fn __p__fmode() [*c]c_int;
pub extern fn __p___argc() [*c]c_int;
pub extern fn __p___wargv() [*c][*c][*c]wchar_t;
pub extern fn __p__pgmptr() [*c][*c]u8;
pub extern fn __p__wpgmptr() [*c][*c]wchar_t;
pub extern fn _get_pgmptr(_Value: [*c][*c]u8) errno_t;
pub extern fn _get_wpgmptr(_Value: [*c][*c]wchar_t) errno_t;
pub extern fn _set_fmode(_Mode: c_int) errno_t;
pub extern fn _get_fmode(_PMode: [*c]c_int) errno_t;
pub extern fn __p__environ() [*c][*c][*c]u8;
pub extern fn __p__wenviron() [*c][*c][*c]wchar_t;
pub extern fn __p__osplatform() [*c]c_uint;
pub extern fn __p__osver() [*c]c_uint;
pub extern fn __p__winver() [*c]c_uint;
pub extern fn __p__winmajor() [*c]c_uint;
pub extern fn __p__winminor() [*c]c_uint;
pub extern fn _get_osplatform(_Value: [*c]c_uint) errno_t;
pub extern fn _get_osver(_Value: [*c]c_uint) errno_t;
pub extern fn _get_winver(_Value: [*c]c_uint) errno_t;
pub extern fn _get_winmajor(_Value: [*c]c_uint) errno_t;
pub extern fn _get_winminor(_Value: [*c]c_uint) errno_t;
pub extern fn exit(_Code: c_int) noreturn;
pub extern fn _exit(_Code: c_int) noreturn;
pub extern fn quick_exit(_Code: c_int) noreturn;
pub fn _Exit(arg_status: c_int) callconv(.c) noreturn {
    var status = arg_status;
    _ = &status;
    _exit(status);
}
pub extern fn abort() noreturn;
pub extern fn _set_abort_behavior(_Flags: c_uint, _Mask: c_uint) c_uint;
pub extern fn abs(_X: c_int) c_int;
pub extern fn labs(_X: c_long) c_long;
pub inline fn _abs64(arg_x: c_longlong) c_longlong {
    var x = arg_x;
    _ = &x;
    return __builtin.llabs(x);
}
pub extern fn atexit(?*const fn () callconv(.c) void) c_int;
pub extern fn at_quick_exit(?*const fn () callconv(.c) void) c_int;
pub extern fn atof(_String: [*c]const u8) f64;
pub extern fn _atof_l(_String: [*c]const u8, _Locale: _locale_t) f64;
pub extern fn atoi(_Str: [*c]const u8) c_int;
pub extern fn _atoi_l(_Str: [*c]const u8, _Locale: _locale_t) c_int;
pub extern fn atol(_Str: [*c]const u8) c_long;
pub extern fn _atol_l(_Str: [*c]const u8, _Locale: _locale_t) c_long;
pub extern fn bsearch(_Key: ?*const anyopaque, _Base: ?*const anyopaque, _NumOfElements: usize, _SizeOfElements: usize, _PtFuncCompare: ?*const fn (?*const anyopaque, ?*const anyopaque) callconv(.c) c_int) ?*anyopaque;
pub extern fn qsort(_Base: ?*anyopaque, _NumOfElements: usize, _SizeOfElements: usize, _PtFuncCompare: ?*const fn (?*const anyopaque, ?*const anyopaque) callconv(.c) c_int) void;
pub extern fn _byteswap_ushort(_Short: c_ushort) c_ushort;
pub extern fn _byteswap_ulong(_Long: c_ulong) c_ulong;
pub extern fn _byteswap_uint64(_Int64: c_ulonglong) c_ulonglong;
pub extern fn div(_Numerator: c_int, _Denominator: c_int) div_t;
pub extern fn getenv(_VarName: [*c]const u8) [*c]u8;
pub extern fn _itoa(_Value: c_int, _Dest: [*c]u8, _Radix: c_int) [*c]u8;
pub extern fn _i64toa(_Val: c_longlong, _DstBuf: [*c]u8, _Radix: c_int) [*c]u8;
pub extern fn _ui64toa(_Val: c_ulonglong, _DstBuf: [*c]u8, _Radix: c_int) [*c]u8;
pub extern fn _atoi64(_String: [*c]const u8) c_longlong;
pub extern fn _atoi64_l(_String: [*c]const u8, _Locale: _locale_t) c_longlong;
pub extern fn _strtoi64(_String: [*c]const u8, _EndPtr: [*c][*c]u8, _Radix: c_int) c_longlong;
pub extern fn _strtoi64_l(_String: [*c]const u8, _EndPtr: [*c][*c]u8, _Radix: c_int, _Locale: _locale_t) c_longlong;
pub extern fn _strtoui64(_String: [*c]const u8, _EndPtr: [*c][*c]u8, _Radix: c_int) c_ulonglong;
pub extern fn _strtoui64_l(_String: [*c]const u8, _EndPtr: [*c][*c]u8, _Radix: c_int, _Locale: _locale_t) c_ulonglong;
pub extern fn ldiv(_Numerator: c_long, _Denominator: c_long) ldiv_t;
pub extern fn _ltoa(_Value: c_long, _Dest: [*c]u8, _Radix: c_int) [*c]u8;
pub extern fn mblen(_Ch: [*c]const u8, _MaxCount: usize) c_int;
pub extern fn _mblen_l(_Ch: [*c]const u8, _MaxCount: usize, _Locale: _locale_t) c_int;
pub extern fn _mbstrlen(_Str: [*c]const u8) usize;
pub extern fn _mbstrlen_l(_Str: [*c]const u8, _Locale: _locale_t) usize;
pub extern fn _mbstrnlen(_Str: [*c]const u8, _MaxCount: usize) usize;
pub extern fn _mbstrnlen_l(_Str: [*c]const u8, _MaxCount: usize, _Locale: _locale_t) usize;
pub extern fn mbtowc(noalias _DstCh: [*c]wchar_t, noalias _SrcCh: [*c]const u8, _SrcSizeInBytes: usize) c_int;
pub extern fn _mbtowc_l(noalias _DstCh: [*c]wchar_t, noalias _SrcCh: [*c]const u8, _SrcSizeInBytes: usize, _Locale: _locale_t) c_int;
pub extern fn mbstowcs(noalias _Dest: [*c]wchar_t, noalias _Source: [*c]const u8, _MaxCount: usize) usize;
pub extern fn _mbstowcs_l(noalias _Dest: [*c]wchar_t, noalias _Source: [*c]const u8, _MaxCount: usize, _Locale: _locale_t) usize;
pub extern fn mkstemp(template_name: [*c]u8) c_int;
pub extern fn rand() c_int;
pub extern fn _set_error_mode(_Mode: c_int) c_int;
pub extern fn srand(_Seed: c_uint) void;
pub extern fn strtod(noalias _Str: [*c]const u8, noalias _EndPtr: [*c][*c]u8) f64;
pub extern fn strtof(noalias nptr: [*c]const u8, noalias endptr: [*c][*c]u8) f32;
pub extern fn strtold(noalias [*c]const u8, noalias [*c][*c]u8) c_longdouble;
pub extern fn __strtod(noalias [*c]const u8, noalias [*c][*c]u8) f64;
pub extern fn __mingw_strtof(noalias [*c]const u8, noalias [*c][*c]u8) f32;
pub extern fn __mingw_strtod(noalias [*c]const u8, noalias [*c][*c]u8) f64;
pub extern fn __mingw_strtold(noalias [*c]const u8, noalias [*c][*c]u8) c_longdouble;
pub extern fn _strtof_l(noalias _Str: [*c]const u8, noalias _EndPtr: [*c][*c]u8, _Locale: _locale_t) f32;
pub extern fn _strtod_l(noalias _Str: [*c]const u8, noalias _EndPtr: [*c][*c]u8, _Locale: _locale_t) f64;
pub extern fn strtol(noalias _Str: [*c]const u8, noalias _EndPtr: [*c][*c]u8, _Radix: c_int) c_long;
pub extern fn _strtol_l(noalias _Str: [*c]const u8, noalias _EndPtr: [*c][*c]u8, _Radix: c_int, _Locale: _locale_t) c_long;
pub extern fn strtoul(noalias _Str: [*c]const u8, noalias _EndPtr: [*c][*c]u8, _Radix: c_int) c_ulong;
pub extern fn _strtoul_l(noalias _Str: [*c]const u8, noalias _EndPtr: [*c][*c]u8, _Radix: c_int, _Locale: _locale_t) c_ulong;
pub extern fn system(_Command: [*c]const u8) c_int;
pub extern fn _ultoa(_Value: c_ulong, _Dest: [*c]u8, _Radix: c_int) [*c]u8;
pub extern fn wctomb(_MbCh: [*c]u8, _WCh: wchar_t) c_int;
pub extern fn _wctomb_l(_MbCh: [*c]u8, _WCh: wchar_t, _Locale: _locale_t) c_int;
pub extern fn wcstombs(noalias _Dest: [*c]u8, noalias _Source: [*c]const wchar_t, _MaxCount: usize) usize;
pub extern fn _wcstombs_l(noalias _Dest: [*c]u8, noalias _Source: [*c]const wchar_t, _MaxCount: usize, _Locale: _locale_t) usize;
pub extern fn calloc(_NumOfElements: usize, _SizeOfElements: usize) ?*anyopaque;
pub extern fn free(_Memory: ?*anyopaque) void;
pub extern fn malloc(_Size: usize) ?*anyopaque;
pub extern fn realloc(_Memory: ?*anyopaque, _NewSize: usize) ?*anyopaque;
pub extern fn _aligned_free(_Memory: ?*anyopaque) void;
pub extern fn _aligned_malloc(_Size: usize, _Alignment: usize) ?*anyopaque;
pub extern fn _aligned_offset_malloc(_Size: usize, _Alignment: usize, _Offset: usize) ?*anyopaque;
pub extern fn _aligned_realloc(_Memory: ?*anyopaque, _Size: usize, _Alignment: usize) ?*anyopaque;
pub extern fn _aligned_offset_realloc(_Memory: ?*anyopaque, _Size: usize, _Alignment: usize, _Offset: usize) ?*anyopaque;
pub extern fn _recalloc(_Memory: ?*anyopaque, _Count: usize, _Size: usize) ?*anyopaque;
pub extern fn _aligned_recalloc(_Memory: ?*anyopaque, _Count: usize, _Size: usize, _Alignment: usize) ?*anyopaque;
pub extern fn _aligned_offset_recalloc(_Memory: ?*anyopaque, _Count: usize, _Size: usize, _Alignment: usize, _Offset: usize) ?*anyopaque;
pub extern fn _aligned_msize(_Memory: ?*anyopaque, _Alignment: usize, _Offset: usize) usize;
pub extern fn _itow(_Value: c_int, _Dest: [*c]wchar_t, _Radix: c_int) [*c]wchar_t;
pub extern fn _ltow(_Value: c_long, _Dest: [*c]wchar_t, _Radix: c_int) [*c]wchar_t;
pub extern fn _ultow(_Value: c_ulong, _Dest: [*c]wchar_t, _Radix: c_int) [*c]wchar_t;
pub extern fn __mingw_wcstod(noalias _Str: [*c]const wchar_t, noalias _EndPtr: [*c][*c]wchar_t) f64;
pub extern fn __mingw_wcstof(noalias nptr: [*c]const wchar_t, noalias endptr: [*c][*c]wchar_t) f32;
pub extern fn __mingw_wcstold(noalias [*c]const wchar_t, noalias [*c][*c]wchar_t) c_longdouble;
pub extern fn wcstod(noalias _Str: [*c]const wchar_t, noalias _EndPtr: [*c][*c]wchar_t) f64;
pub extern fn wcstof(noalias nptr: [*c]const wchar_t, noalias endptr: [*c][*c]wchar_t) f32;
pub extern fn wcstold(noalias [*c]const wchar_t, noalias [*c][*c]wchar_t) c_longdouble;
pub extern fn _wcstod_l(noalias _Str: [*c]const wchar_t, noalias _EndPtr: [*c][*c]wchar_t, _Locale: _locale_t) f64;
pub extern fn _wcstof_l(noalias _Str: [*c]const wchar_t, noalias _EndPtr: [*c][*c]wchar_t, _Locale: _locale_t) f32;
pub extern fn wcstol(noalias _Str: [*c]const wchar_t, noalias _EndPtr: [*c][*c]wchar_t, _Radix: c_int) c_long;
pub extern fn _wcstol_l(noalias _Str: [*c]const wchar_t, noalias _EndPtr: [*c][*c]wchar_t, _Radix: c_int, _Locale: _locale_t) c_long;
pub extern fn wcstoul(noalias _Str: [*c]const wchar_t, noalias _EndPtr: [*c][*c]wchar_t, _Radix: c_int) c_ulong;
pub extern fn _wcstoul_l(noalias _Str: [*c]const wchar_t, noalias _EndPtr: [*c][*c]wchar_t, _Radix: c_int, _Locale: _locale_t) c_ulong;
pub extern fn _wgetenv(_VarName: [*c]const wchar_t) [*c]wchar_t;
pub extern fn _wsystem(_Command: [*c]const wchar_t) c_int;
pub extern fn _wtof(_Str: [*c]const wchar_t) f64;
pub extern fn _wtof_l(_Str: [*c]const wchar_t, _Locale: _locale_t) f64;
pub extern fn _wtoi(_Str: [*c]const wchar_t) c_int;
pub extern fn _wtoi_l(_Str: [*c]const wchar_t, _Locale: _locale_t) c_int;
pub extern fn _wtol(_Str: [*c]const wchar_t) c_long;
pub extern fn _wtol_l(_Str: [*c]const wchar_t, _Locale: _locale_t) c_long;
pub extern fn _i64tow(_Val: c_longlong, _DstBuf: [*c]wchar_t, _Radix: c_int) [*c]wchar_t;
pub extern fn _ui64tow(_Val: c_ulonglong, _DstBuf: [*c]wchar_t, _Radix: c_int) [*c]wchar_t;
pub extern fn _wtoi64(_Str: [*c]const wchar_t) c_longlong;
pub extern fn _wtoi64_l(_Str: [*c]const wchar_t, _Locale: _locale_t) c_longlong;
pub extern fn _wcstoi64(_Str: [*c]const wchar_t, _EndPtr: [*c][*c]wchar_t, _Radix: c_int) c_longlong;
pub extern fn _wcstoi64_l(_Str: [*c]const wchar_t, _EndPtr: [*c][*c]wchar_t, _Radix: c_int, _Locale: _locale_t) c_longlong;
pub extern fn _wcstoui64(_Str: [*c]const wchar_t, _EndPtr: [*c][*c]wchar_t, _Radix: c_int) c_ulonglong;
pub extern fn _wcstoui64_l(_Str: [*c]const wchar_t, _EndPtr: [*c][*c]wchar_t, _Radix: c_int, _Locale: _locale_t) c_ulonglong;
pub extern fn _putenv(_EnvString: [*c]const u8) c_int;
pub extern fn _wputenv(_EnvString: [*c]const wchar_t) c_int;
pub extern fn _fullpath(_FullPath: [*c]u8, _Path: [*c]const u8, _SizeInBytes: usize) [*c]u8;
pub extern fn _ecvt(_Val: f64, _NumOfDigits: c_int, _PtDec: [*c]c_int, _PtSign: [*c]c_int) [*c]u8;
pub extern fn _fcvt(_Val: f64, _NumOfDec: c_int, _PtDec: [*c]c_int, _PtSign: [*c]c_int) [*c]u8;
pub extern fn _gcvt(_Val: f64, _NumOfDigits: c_int, _DstBuf: [*c]u8) [*c]u8;
pub extern fn _atodbl(_Result: [*c]_CRT_DOUBLE, _Str: [*c]u8) c_int;
pub extern fn _atoldbl(_Result: [*c]_LDOUBLE, _Str: [*c]u8) c_int;
pub extern fn _atoflt(_Result: [*c]_CRT_FLOAT, _Str: [*c]u8) c_int;
pub extern fn _atodbl_l(_Result: [*c]_CRT_DOUBLE, _Str: [*c]u8, _Locale: _locale_t) c_int;
pub extern fn _atoldbl_l(_Result: [*c]_LDOUBLE, _Str: [*c]u8, _Locale: _locale_t) c_int;
pub extern fn _atoflt_l(_Result: [*c]_CRT_FLOAT, _Str: [*c]u8, _Locale: _locale_t) c_int;
pub extern fn _lrotl(c_ulong, c_int) c_ulong;
pub extern fn _lrotr(c_ulong, c_int) c_ulong;
pub extern fn _makepath(_Path: [*c]u8, _Drive: [*c]const u8, _Dir: [*c]const u8, _Filename: [*c]const u8, _Ext: [*c]const u8) void;
pub extern fn _onexit(_Func: _onexit_t) _onexit_t;
pub extern fn _rotl64(_Val: c_ulonglong, _Shift: c_int) c_ulonglong;
pub extern fn _rotr64(Value: c_ulonglong, Shift: c_int) c_ulonglong;
pub extern fn _rotr(_Val: c_uint, _Shift: c_int) c_uint;
pub extern fn _rotl(_Val: c_uint, _Shift: c_int) c_uint;
pub extern fn _searchenv(_Filename: [*c]const u8, _EnvVar: [*c]const u8, _ResultPath: [*c]u8) void;
pub extern fn _splitpath(_FullPath: [*c]const u8, _Drive: [*c]u8, _Dir: [*c]u8, _Filename: [*c]u8, _Ext: [*c]u8) void;
pub extern fn _swab(_Buf1: [*c]u8, _Buf2: [*c]u8, _SizeInBytes: c_int) void;
pub extern fn _wfullpath(_FullPath: [*c]wchar_t, _Path: [*c]const wchar_t, _SizeInWords: usize) [*c]wchar_t;
pub extern fn _wmakepath(_ResultPath: [*c]wchar_t, _Drive: [*c]const wchar_t, _Dir: [*c]const wchar_t, _Filename: [*c]const wchar_t, _Ext: [*c]const wchar_t) void;
pub extern fn _wsearchenv(_Filename: [*c]const wchar_t, _EnvVar: [*c]const wchar_t, _ResultPath: [*c]wchar_t) void;
pub extern fn _wsplitpath(_FullPath: [*c]const wchar_t, _Drive: [*c]wchar_t, _Dir: [*c]wchar_t, _Filename: [*c]wchar_t, _Ext: [*c]wchar_t) void;
pub extern fn _beep(_Frequency: c_uint, _Duration: c_uint) void;
pub extern fn _seterrormode(_Mode: c_int) void;
pub extern fn _sleep(_Duration: c_ulong) void;
pub extern fn ecvt(_Val: f64, _NumOfDigits: c_int, _PtDec: [*c]c_int, _PtSign: [*c]c_int) [*c]u8;
pub extern fn fcvt(_Val: f64, _NumOfDec: c_int, _PtDec: [*c]c_int, _PtSign: [*c]c_int) [*c]u8;
pub extern fn gcvt(_Val: f64, _NumOfDigits: c_int, _DstBuf: [*c]u8) [*c]u8;
pub extern fn itoa(_Val: c_int, _DstBuf: [*c]u8, _Radix: c_int) [*c]u8;
pub extern fn ltoa(_Val: c_long, _DstBuf: [*c]u8, _Radix: c_int) [*c]u8;
pub extern fn putenv(_EnvString: [*c]const u8) c_int;
pub extern fn swab(_Buf1: [*c]u8, _Buf2: [*c]u8, _SizeInBytes: c_int) void;
pub extern fn ultoa(_Val: c_ulong, _Dstbuf: [*c]u8, _Radix: c_int) [*c]u8;
pub extern fn onexit(_Func: _onexit_t) _onexit_t;
pub const lldiv_t = extern struct {
    quot: c_longlong = 0,
    rem: c_longlong = 0,
};
pub extern fn lldiv(c_longlong, c_longlong) lldiv_t;
pub fn llabs(arg__j: c_longlong) callconv(.c) c_longlong {
    var _j = arg__j;
    _ = &_j;
    return if (_j >= @as(c_longlong, 0)) _j else -_j;
}
pub extern fn strtoll(noalias [*c]const u8, noalias [*c][*c]u8, c_int) c_longlong;
pub extern fn strtoull(noalias [*c]const u8, noalias [*c][*c]u8, c_int) c_ulonglong;
pub extern fn atoll([*c]const u8) c_longlong;
pub fn wtoll(arg__w: [*c]const wchar_t) callconv(.c) c_longlong {
    var _w = arg__w;
    _ = &_w;
    return _wtoi64(_w);
}
pub fn lltoa(arg__n: c_longlong, arg__c: [*c]u8, arg__i: c_int) callconv(.c) [*c]u8 {
    var _n = arg__n;
    _ = &_n;
    var _c = arg__c;
    _ = &_c;
    var _i = arg__i;
    _ = &_i;
    return _i64toa(_n, _c, _i);
}
pub fn ulltoa(arg__n: c_ulonglong, arg__c: [*c]u8, arg__i: c_int) callconv(.c) [*c]u8 {
    var _n = arg__n;
    _ = &_n;
    var _c = arg__c;
    _ = &_c;
    var _i = arg__i;
    _ = &_i;
    return _ui64toa(_n, _c, _i);
}
pub fn lltow(arg__n: c_longlong, arg__w: [*c]wchar_t, arg__i: c_int) callconv(.c) [*c]wchar_t {
    var _n = arg__n;
    _ = &_n;
    var _w = arg__w;
    _ = &_w;
    var _i = arg__i;
    _ = &_i;
    return _i64tow(_n, _w, _i);
}
pub fn ulltow(arg__n: c_ulonglong, arg__w: [*c]wchar_t, arg__i: c_int) callconv(.c) [*c]wchar_t {
    var _n = arg__n;
    _ = &_n;
    var _w = arg__w;
    _ = &_w;
    var _i = arg__i;
    _ = &_i;
    return _ui64tow(_n, _w, _i);
}
pub extern fn _dupenv_s(_PBuffer: [*c][*c]u8, _PBufferSizeInBytes: [*c]usize, _VarName: [*c]const u8) errno_t;
pub extern fn bsearch_s(_Key: ?*const anyopaque, _Base: ?*const anyopaque, _NumOfElements: rsize_t, _SizeOfElements: rsize_t, _PtFuncCompare: ?*const fn (?*anyopaque, ?*const anyopaque, ?*const anyopaque) callconv(.c) c_int, _Context: ?*anyopaque) ?*anyopaque;
pub extern fn getenv_s(_ReturnSize: [*c]usize, _DstBuf: [*c]u8, _DstSize: rsize_t, _VarName: [*c]const u8) errno_t;
pub extern fn _itoa_s(_Value: c_int, _DstBuf: [*c]u8, _Size: usize, _Radix: c_int) errno_t;
pub extern fn _i64toa_s(_Val: c_longlong, _DstBuf: [*c]u8, _Size: usize, _Radix: c_int) errno_t;
pub extern fn _ui64toa_s(_Val: c_ulonglong, _DstBuf: [*c]u8, _Size: usize, _Radix: c_int) errno_t;
pub extern fn _ltoa_s(_Val: c_long, _DstBuf: [*c]u8, _Size: usize, _Radix: c_int) errno_t;
pub extern fn mbstowcs_s(_PtNumOfCharConverted: [*c]usize, _DstBuf: [*c]wchar_t, _SizeInWords: usize, _SrcBuf: [*c]const u8, _MaxCount: usize) errno_t;
pub extern fn _mbstowcs_s_l(_PtNumOfCharConverted: [*c]usize, _DstBuf: [*c]wchar_t, _SizeInWords: usize, _SrcBuf: [*c]const u8, _MaxCount: usize, _Locale: _locale_t) errno_t;
pub extern fn _ultoa_s(_Val: c_ulong, _DstBuf: [*c]u8, _Size: usize, _Radix: c_int) errno_t;
pub extern fn wctomb_s(_SizeConverted: [*c]c_int, _MbCh: [*c]u8, _SizeInBytes: rsize_t, _WCh: wchar_t) errno_t;
pub extern fn _wctomb_s_l(_SizeConverted: [*c]c_int, _MbCh: [*c]u8, _SizeInBytes: usize, _WCh: wchar_t, _Locale: _locale_t) errno_t;
pub extern fn wcstombs_s(_PtNumOfCharConverted: [*c]usize, _Dst: [*c]u8, _DstSizeInBytes: usize, _Src: [*c]const wchar_t, _MaxCountInBytes: usize) errno_t;
pub extern fn _wcstombs_s_l(_PtNumOfCharConverted: [*c]usize, _Dst: [*c]u8, _DstSizeInBytes: usize, _Src: [*c]const wchar_t, _MaxCountInBytes: usize, _Locale: _locale_t) errno_t;
pub extern fn _ecvt_s(_DstBuf: [*c]u8, _Size: usize, _Val: f64, _NumOfDights: c_int, _PtDec: [*c]c_int, _PtSign: [*c]c_int) errno_t;
pub extern fn _fcvt_s(_DstBuf: [*c]u8, _Size: usize, _Val: f64, _NumOfDec: c_int, _PtDec: [*c]c_int, _PtSign: [*c]c_int) errno_t;
pub extern fn _gcvt_s(_DstBuf: [*c]u8, _Size: usize, _Val: f64, _NumOfDigits: c_int) errno_t;
pub extern fn _makepath_s(_PathResult: [*c]u8, _Size: usize, _Drive: [*c]const u8, _Dir: [*c]const u8, _Filename: [*c]const u8, _Ext: [*c]const u8) errno_t;
pub extern fn _putenv_s(_Name: [*c]const u8, _Value: [*c]const u8) errno_t;
pub extern fn _searchenv_s(_Filename: [*c]const u8, _EnvVar: [*c]const u8, _ResultPath: [*c]u8, _SizeInBytes: usize) errno_t;
pub extern fn _splitpath_s(_FullPath: [*c]const u8, _Drive: [*c]u8, _DriveSize: usize, _Dir: [*c]u8, _DirSize: usize, _Filename: [*c]u8, _FilenameSize: usize, _Ext: [*c]u8, _ExtSize: usize) errno_t;
pub extern fn qsort_s(_Base: ?*anyopaque, _NumOfElements: usize, _SizeOfElements: usize, _PtFuncCompare: ?*const fn (?*anyopaque, ?*const anyopaque, ?*const anyopaque) callconv(.c) c_int, _Context: ?*anyopaque) void;
pub const struct__heapinfo = extern struct {
    _pentry: [*c]c_int = null,
    _size: usize = 0,
    _useflag: c_int = 0,
    pub const _heapwalk = __root._heapwalk;
    pub const heapwalk = __root._heapwalk;
};
pub const _HEAPINFO = struct__heapinfo;
pub extern fn __p__amblksiz() [*c]c_uint;
pub extern fn __mingw_aligned_malloc(_Size: usize, _Alignment: usize) ?*anyopaque;
pub extern fn __mingw_aligned_free(_Memory: ?*anyopaque) void;
pub extern fn __mingw_aligned_offset_realloc(_Memory: ?*anyopaque, _Size: usize, _Alignment: usize, _Offset: usize) ?*anyopaque;
pub extern fn __mingw_aligned_offset_malloc(usize, usize, usize) ?*anyopaque;
pub extern fn __mingw_aligned_realloc(_Memory: ?*anyopaque, _Size: usize, _Offset: usize) ?*anyopaque;
pub extern fn __mingw_aligned_msize(memblock: ?*anyopaque, alignment: usize, offset: usize) usize;
pub inline fn _mm_malloc(arg___size: usize, arg___align: usize) ?*anyopaque {
    var __size = arg___size;
    _ = &__size;
    var __align = arg___align;
    _ = &__align;
    if (__align == @as(usize, 1)) {
        return malloc(__size);
    }
    if (!((__align & (__align -% @as(usize, 1))) != 0) and (__align < @sizeOf(?*anyopaque))) {
        __align = @sizeOf(?*anyopaque);
    }
    var __mallocedMemory: ?*anyopaque = undefined;
    _ = &__mallocedMemory;
    __mallocedMemory = __mingw_aligned_malloc(__size, __align);
    return __mallocedMemory;
}
pub inline fn _mm_free(arg___p: ?*anyopaque) void {
    var __p = arg___p;
    _ = &__p;
    __mingw_aligned_free(__p);
}
pub extern fn _resetstkoflw() c_int;
pub extern fn _set_malloc_crt_max_wait(_NewValue: c_ulong) c_ulong;
pub extern fn _expand(_Memory: ?*anyopaque, _NewSize: usize) ?*anyopaque;
pub extern fn _msize(_Memory: ?*anyopaque) usize;
pub extern fn _get_sbh_threshold() usize;
pub extern fn _set_sbh_threshold(_NewValue: usize) c_int;
pub extern fn _set_amblksiz(_Value: usize) errno_t;
pub extern fn _get_amblksiz(_Value: [*c]usize) errno_t;
pub extern fn _heapadd(_Memory: ?*anyopaque, _Size: usize) c_int;
pub extern fn _heapchk() c_int;
pub extern fn _heapmin() c_int;
pub extern fn _heapset(_Fill: c_uint) c_int;
pub extern fn _heapwalk(_EntryInfo: [*c]_HEAPINFO) c_int;
pub extern fn _heapused(_Used: [*c]usize, _Commit: [*c]usize) usize;
pub extern fn _get_heap_handle() isize;
pub fn _MarkAllocaS(arg__Ptr: ?*anyopaque, arg__Marker: c_uint) callconv(.c) ?*anyopaque {
    var _Ptr = arg__Ptr;
    _ = &_Ptr;
    var _Marker = arg__Marker;
    _ = &_Marker;
    if (_Ptr != null) {
        @as([*c]c_uint, @ptrCast(@alignCast(_Ptr))).* = _Marker;
        _Ptr = @ptrCast(@alignCast(@as([*c]u8, @ptrCast(@alignCast(_Ptr))) + @as(usize, @bitCast(@as(isize, @intCast(_ALLOCA_S_MARKER_SIZE))))));
    }
    return _Ptr;
}
pub fn _freea(arg__Memory: ?*anyopaque) callconv(.c) void {
    var _Memory = arg__Memory;
    _ = &_Memory;
    var _Marker: c_uint = undefined;
    _ = &_Marker;
    if (_Memory != null) {
        _Memory = @ptrCast(@alignCast(@as([*c]u8, @ptrCast(@alignCast(_Memory))) - @as(usize, @bitCast(@as(isize, @intCast(_ALLOCA_S_MARKER_SIZE))))));
        _Marker = @as([*c]c_uint, @ptrCast(@alignCast(_Memory))).*;
        if (_Marker == @as(c_uint, _ALLOCA_S_HEAP_MARKER)) {
            free(_Memory);
        }
    }
}
pub const JSMN_UNDEFINED: c_int = 0;
pub const JSMN_OBJECT: c_int = 1;
pub const JSMN_ARRAY: c_int = 2;
pub const JSMN_STRING: c_int = 3;
pub const JSMN_PRIMITIVE: c_int = 4;
pub const jsmntype_t = c_uint;
pub const JSMN_ERROR_NOMEM: c_int = -1;
pub const JSMN_ERROR_INVAL: c_int = -2;
pub const JSMN_ERROR_PART: c_int = -3;
pub const enum_jsmnerr = c_int;
pub const jsmntok_t = extern struct {
    type: jsmntype_t = @import("std").mem.zeroes(jsmntype_t),
    start: ptrdiff_t = 0,
    end: ptrdiff_t = 0,
    size: c_int = 0,
    parent: c_int = 0,
    pub const cgltf_json_strcmp = __root.cgltf_json_strcmp;
    pub const cgltf_json_to_int = __root.cgltf_json_to_int;
    pub const cgltf_json_to_size = __root.cgltf_json_to_size;
    pub const cgltf_json_to_float = __root.cgltf_json_to_float;
    pub const cgltf_json_to_bool = __root.cgltf_json_to_bool;
    pub const cgltf_skip_json = __root.cgltf_skip_json;
    pub const cgltf_parse_json_float_array = __root.cgltf_parse_json_float_array;
    pub const cgltf_json_to_primitive_type = __root.cgltf_json_to_primitive_type;
    pub const cgltf_json_to_component_type = __root.cgltf_json_to_component_type;
    pub const cgltf_parse_json_accessor_sparse = __root.cgltf_parse_json_accessor_sparse;
    pub const cgltf_parse_json_texture_transform = __root.cgltf_parse_json_texture_transform;
    pub const cgltf_parse_json_ior = __root.cgltf_parse_json_ior;
    pub const cgltf_parse_json_emissive_strength = __root.cgltf_parse_json_emissive_strength;
    pub const cgltf_parse_json_dispersion = __root.cgltf_parse_json_dispersion;
    pub const jsmn_fill_token = __root.jsmn_fill_token;
    pub const int = __root.cgltf_json_to_int;
    pub const float = __root.cgltf_json_to_float;
    pub const @"bool" = __root.cgltf_json_to_bool;
    pub const json = __root.cgltf_skip_json;
    pub const array = __root.cgltf_parse_json_float_array;
    pub const sparse = __root.cgltf_parse_json_accessor_sparse;
    pub const transform = __root.cgltf_parse_json_texture_transform;
    pub const ior = __root.cgltf_parse_json_ior;
    pub const strength = __root.cgltf_parse_json_emissive_strength;
    pub const dispersion = __root.cgltf_parse_json_dispersion;
    pub const token = __root.jsmn_fill_token;
};
pub const jsmn_parser = extern struct {
    pos: usize = 0,
    toknext: c_uint = 0,
    toksuper: c_int = 0,
    pub const jsmn_init = __root.jsmn_init;
    pub const jsmn_parse = __root.jsmn_parse;
    pub const jsmn_alloc_token = __root.jsmn_alloc_token;
    pub const jsmn_parse_string = __root.jsmn_parse_string;
    pub const init = __root.jsmn_init;
    pub const parse = __root.jsmn_parse;
    pub const token = __root.jsmn_alloc_token;
    pub const string = __root.jsmn_parse_string;
};
pub fn jsmn_init(arg_parser: [*c]jsmn_parser) callconv(.c) void {
    var parser = arg_parser;
    _ = &parser;
    parser.*.pos = 0;
    parser.*.toknext = 0;
    parser.*.toksuper = -@as(c_int, 1);
}
pub fn jsmn_parse(arg_parser: [*c]jsmn_parser, arg_js: [*c]const u8, arg_len: usize, arg_tokens: [*c]jsmntok_t, arg_num_tokens: usize) callconv(.c) c_int {
    var parser = arg_parser;
    _ = &parser;
    var js = arg_js;
    _ = &js;
    var len = arg_len;
    _ = &len;
    var tokens = arg_tokens;
    _ = &tokens;
    var num_tokens = arg_num_tokens;
    _ = &num_tokens;
    var r: c_int = undefined;
    _ = &r;
    var i: c_int = undefined;
    _ = &i;
    var token: [*c]jsmntok_t = undefined;
    _ = &token;
    var count: c_int = @bitCast(@as(c_uint, @truncate(parser.*.toknext)));
    _ = &count;
    while ((parser.*.pos < len) and (@as(c_int, js[@intCast(parser.*.pos)]) != @as(c_int, '\x00'))) : (parser.*.pos +%= 1) {
        var c: u8 = undefined;
        _ = &c;
        var @"type": jsmntype_t = undefined;
        _ = &@"type";
        c = js[@intCast(parser.*.pos)];
        while (true) {
            switch (@as(c_int, c)) {
                @as(c_int, '{'), @as(c_int, '[') => {
                    count += 1;
                    if (@as(?*anyopaque, @ptrCast(@alignCast(tokens))) == @as(?*anyopaque, null)) {
                        break;
                    }
                    token = jsmn_alloc_token(parser, tokens, num_tokens);
                    if (@as(?*anyopaque, @ptrCast(@alignCast(token))) == @as(?*anyopaque, null)) return JSMN_ERROR_NOMEM;
                    if (parser.*.toksuper != -@as(c_int, 1)) {
                        tokens[@bitCast(@as(isize, @intCast(parser.*.toksuper)))].size += 1;
                        token.*.parent = parser.*.toksuper;
                    }
                    token.*.type = @bitCast(if (@as(c_int, c) == @as(c_int, '{')) JSMN_OBJECT else JSMN_ARRAY);
                    token.*.start = @bitCast(@as(c_ulonglong, @truncate(parser.*.pos)));
                    parser.*.toksuper = @bitCast(@as(c_uint, @truncate(parser.*.toknext -% @as(c_uint, 1))));
                    break;
                },
                @as(c_int, '}'), @as(c_int, ']') => {
                    if (@as(?*anyopaque, @ptrCast(@alignCast(tokens))) == @as(?*anyopaque, null)) break;
                    @"type" = @bitCast(if (@as(c_int, c) == @as(c_int, '}')) JSMN_OBJECT else JSMN_ARRAY);
                    if (parser.*.toknext < @as(c_uint, 1)) {
                        return JSMN_ERROR_INVAL;
                    }
                    token = &tokens[parser.*.toknext -% @as(c_uint, 1)];
                    while (true) {
                        if ((token.*.start != @as(ptrdiff_t, -@as(c_int, 1))) and (token.*.end == @as(ptrdiff_t, -@as(c_int, 1)))) {
                            if (token.*.type != @"type") {
                                return JSMN_ERROR_INVAL;
                            }
                            token.*.end = @bitCast(@as(c_ulonglong, @truncate(parser.*.pos +% @as(usize, 1))));
                            parser.*.toksuper = token.*.parent;
                            break;
                        }
                        if (token.*.parent == -@as(c_int, 1)) {
                            if ((token.*.type != @"type") or (parser.*.toksuper == -@as(c_int, 1))) {
                                return JSMN_ERROR_INVAL;
                            }
                            break;
                        }
                        token = &tokens[@bitCast(@as(isize, @intCast(token.*.parent)))];
                    }
                    break;
                },
                @as(c_int, '"') => {
                    r = jsmn_parse_string(parser, js, len, tokens, num_tokens);
                    if (r < @as(c_int, 0)) return r;
                    count += 1;
                    if ((parser.*.toksuper != -@as(c_int, 1)) and (@as(?*anyopaque, @ptrCast(@alignCast(tokens))) != @as(?*anyopaque, null))) {
                        tokens[@bitCast(@as(isize, @intCast(parser.*.toksuper)))].size += 1;
                    }
                    break;
                },
                @as(c_int, '\t'), @as(c_int, '\r'), @as(c_int, '\n'), @as(c_int, ' ') => {
                    break;
                },
                @as(c_int, ':') => {
                    parser.*.toksuper = @bitCast(@as(c_uint, @truncate(parser.*.toknext -% @as(c_uint, 1))));
                    break;
                },
                @as(c_int, ',') => {
                    if ((((@as(?*anyopaque, @ptrCast(@alignCast(tokens))) != @as(?*anyopaque, null)) and (parser.*.toksuper != -@as(c_int, 1))) and (tokens[@bitCast(@as(isize, @intCast(parser.*.toksuper)))].type != @as(jsmntype_t, JSMN_ARRAY))) and (tokens[@bitCast(@as(isize, @intCast(parser.*.toksuper)))].type != @as(jsmntype_t, JSMN_OBJECT))) {
                        parser.*.toksuper = tokens[@bitCast(@as(isize, @intCast(parser.*.toksuper)))].parent;
                    }
                    break;
                },
                @as(c_int, '-'), @as(c_int, '0'), @as(c_int, '1'), @as(c_int, '2'), @as(c_int, '3'), @as(c_int, '4'), @as(c_int, '5'), @as(c_int, '6'), @as(c_int, '7'), @as(c_int, '8'), @as(c_int, '9'), @as(c_int, 't'), @as(c_int, 'f'), @as(c_int, 'n') => {
                    if ((@as(?*anyopaque, @ptrCast(@alignCast(tokens))) != @as(?*anyopaque, null)) and (parser.*.toksuper != -@as(c_int, 1))) {
                        var t: [*c]jsmntok_t = &tokens[@bitCast(@as(isize, @intCast(parser.*.toksuper)))];
                        _ = &t;
                        if ((t.*.type == @as(jsmntype_t, JSMN_OBJECT)) or ((t.*.type == @as(jsmntype_t, JSMN_STRING)) and (t.*.size != @as(c_int, 0)))) {
                            return JSMN_ERROR_INVAL;
                        }
                    }
                    r = jsmn_parse_primitive(parser, js, len, tokens, num_tokens);
                    if (r < @as(c_int, 0)) return r;
                    count += 1;
                    if ((parser.*.toksuper != -@as(c_int, 1)) and (@as(?*anyopaque, @ptrCast(@alignCast(tokens))) != @as(?*anyopaque, null))) {
                        tokens[@bitCast(@as(isize, @intCast(parser.*.toksuper)))].size += 1;
                    }
                    break;
                },
                else => {
                    return JSMN_ERROR_INVAL;
                },
            }
            break;
        }
    }
    if (@as(?*anyopaque, @ptrCast(@alignCast(tokens))) != @as(?*anyopaque, null)) {
        {
            i = @bitCast(@as(c_uint, @truncate(parser.*.toknext -% @as(c_uint, 1))));
            while (i >= @as(c_int, 0)) : (i -= 1) {
                if ((tokens[@bitCast(@as(isize, @intCast(i)))].start != @as(ptrdiff_t, -@as(c_int, 1))) and (tokens[@bitCast(@as(isize, @intCast(i)))].end == @as(ptrdiff_t, -@as(c_int, 1)))) {
                    return JSMN_ERROR_PART;
                }
            }
        }
    }
    return count;
}
pub const GlbVersion: u32 = 2;
pub const GlbMagic: u32 = 1179937895;
pub const GlbMagicJsonChunk: u32 = 1313821514;
pub const GlbMagicBinChunk: u32 = 5130562;
pub fn cgltf_default_alloc(arg_user: ?*anyopaque, arg_size: cgltf_size) callconv(.c) ?*anyopaque {
    var user = arg_user;
    _ = &user;
    var size = arg_size;
    _ = &size;
    _ = &user;
    return malloc(size);
}
pub fn cgltf_default_free(arg_user: ?*anyopaque, arg_ptr: ?*anyopaque) callconv(.c) void {
    var user = arg_user;
    _ = &user;
    var ptr = arg_ptr;
    _ = &ptr;
    _ = &user;
    free(ptr);
}
pub fn cgltf_calloc(arg_options: [*c]cgltf_options, arg_element_size: usize, arg_count: cgltf_size) callconv(.c) ?*anyopaque {
    var options = arg_options;
    _ = &options;
    var element_size = arg_element_size;
    _ = &element_size;
    var count = arg_count;
    _ = &count;
    if ((UINT64_MAX / element_size) < count) {
        return null;
    }
    var result: ?*anyopaque = options.*.memory.alloc_func.?(options.*.memory.user_data, element_size *% count);
    _ = &result;
    if (!(result != null)) {
        return null;
    }
    _ = memset(result, 0, element_size *% count);
    return result;
}
pub fn cgltf_default_file_read(arg_memory_options: [*c]const struct_cgltf_memory_options, arg_file_options: [*c]const struct_cgltf_file_options, arg_path: [*c]const u8, arg_size: [*c]cgltf_size, arg_data: [*c]?*anyopaque) callconv(.c) cgltf_result {
    var memory_options = arg_memory_options;
    _ = &memory_options;
    var file_options = arg_file_options;
    _ = &file_options;
    var path = arg_path;
    _ = &path;
    var size = arg_size;
    _ = &size;
    var data = arg_data;
    _ = &data;
    _ = &file_options;
    var memory_alloc: ?*const fn (?*anyopaque, cgltf_size) callconv(.c) ?*anyopaque = if (memory_options.*.alloc_func != null) memory_options.*.alloc_func else &cgltf_default_alloc;
    _ = &memory_alloc;
    var memory_free: ?*const fn (?*anyopaque, ?*anyopaque) callconv(.c) void = if (memory_options.*.free_func != null) memory_options.*.free_func else &cgltf_default_free;
    _ = &memory_free;
    var file: [*c]FILE = fopen(path, "rb");
    _ = &file;
    if (!(file != null)) {
        return cgltf_result_file_not_found;
    }
    var file_size: cgltf_size = if (size != null) size.* else @as(cgltf_size, 0);
    _ = &file_size;
    if (file_size == @as(cgltf_size, 0)) {
        _ = fseek(file, 0, SEEK_END);
        var length: c_long = ftell(file);
        _ = &length;
        if (length < @as(c_long, 0)) {
            _ = fclose(file);
            return cgltf_result_io_error;
        }
        _ = fseek(file, 0, SEEK_SET);
        file_size = @bitCast(@as(c_longlong, length));
    }
    var file_data: [*c]u8 = @ptrCast(@alignCast(memory_alloc.?(memory_options.*.user_data, file_size)));
    _ = &file_data;
    if (!(file_data != null)) {
        _ = fclose(file);
        return cgltf_result_out_of_memory;
    }
    var read_size: cgltf_size = fread(@ptrCast(@alignCast(file_data)), 1, file_size, file);
    _ = &read_size;
    _ = fclose(file);
    if (read_size != file_size) {
        memory_free.?(memory_options.*.user_data, @ptrCast(@alignCast(file_data)));
        return cgltf_result_io_error;
    }
    if (size != null) {
        size.* = file_size;
    }
    if (data != null) {
        data.* = @ptrCast(@alignCast(file_data));
    }
    return cgltf_result_success;
}
pub fn cgltf_default_file_release(arg_memory_options: [*c]const struct_cgltf_memory_options, arg_file_options: [*c]const struct_cgltf_file_options, arg_data: ?*anyopaque, arg_size: cgltf_size) callconv(.c) void {
    var memory_options = arg_memory_options;
    _ = &memory_options;
    var file_options = arg_file_options;
    _ = &file_options;
    var data = arg_data;
    _ = &data;
    var size = arg_size;
    _ = &size;
    _ = &file_options;
    _ = &size;
    var memfree: ?*const fn (?*anyopaque, ?*anyopaque) callconv(.c) void = if (memory_options.*.free_func != null) memory_options.*.free_func else &cgltf_default_free;
    _ = &memfree;
    memfree.?(memory_options.*.user_data, data);
}
pub export fn cgltf_parse_json(arg_options: [*c]cgltf_options, arg_json_chunk: [*c]const u8, arg_size: cgltf_size, arg_out_data: [*c][*c]cgltf_data) cgltf_result {
    var options = arg_options;
    _ = &options;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var size = arg_size;
    _ = &size;
    var out_data = arg_out_data;
    _ = &out_data;
    var parser: jsmn_parser = jsmn_parser{
        .pos = 0,
        .toknext = 0,
        .toksuper = 0,
    };
    _ = &parser;
    if (options.*.json_token_count == @as(cgltf_size, 0)) {
        var token_count: c_int = jsmn_parse(&parser, @ptrCast(@alignCast(json_chunk)), size, null, 0);
        _ = &token_count;
        if (token_count <= @as(c_int, 0)) {
            return cgltf_result_invalid_json;
        }
        options.*.json_token_count = @bitCast(@as(c_longlong, token_count));
    }
    var tokens: [*c]jsmntok_t = @ptrCast(@alignCast(options.*.memory.alloc_func.?(options.*.memory.user_data, @sizeOf(jsmntok_t) *% (options.*.json_token_count +% @as(cgltf_size, 1)))));
    _ = &tokens;
    if (!(tokens != null)) {
        return cgltf_result_out_of_memory;
    }
    jsmn_init(&parser);
    var token_count: c_int = jsmn_parse(&parser, @ptrCast(@alignCast(json_chunk)), size, tokens, options.*.json_token_count);
    _ = &token_count;
    if (token_count <= @as(c_int, 0)) {
        options.*.memory.free_func.?(options.*.memory.user_data, @ptrCast(@alignCast(tokens)));
        return cgltf_result_invalid_json;
    }
    tokens[@bitCast(@as(isize, @intCast(token_count)))].type = JSMN_UNDEFINED;
    var data: [*c]cgltf_data = @ptrCast(@alignCast(options.*.memory.alloc_func.?(options.*.memory.user_data, @sizeOf(cgltf_data))));
    _ = &data;
    if (!(data != null)) {
        options.*.memory.free_func.?(options.*.memory.user_data, @ptrCast(@alignCast(tokens)));
        return cgltf_result_out_of_memory;
    }
    _ = memset(@ptrCast(@alignCast(data)), 0, @sizeOf(cgltf_data));
    data.*.memory = options.*.memory;
    data.*.file = options.*.file;
    var i: c_int = cgltf_parse_json_root(options, tokens, 0, json_chunk, data);
    _ = &i;
    options.*.memory.free_func.?(options.*.memory.user_data, @ptrCast(@alignCast(tokens)));
    if (i < @as(c_int, 0)) {
        cgltf_free(data);
        while (true) {
            switch (i) {
                -@as(c_int, 2) => {
                    return cgltf_result_out_of_memory;
                },
                -@as(c_int, 3) => {
                    return cgltf_result_legacy_gltf;
                },
                else => {
                    return cgltf_result_invalid_gltf;
                },
            }
            break;
        }
    }
    if (cgltf_fixup_pointers(data) < @as(c_int, 0)) {
        cgltf_free(data);
        return cgltf_result_invalid_gltf;
    }
    data.*.json = @ptrCast(@alignCast(json_chunk));
    data.*.json_size = size;
    out_data.* = data;
    return cgltf_result_success;
}
pub fn cgltf_combine_paths(arg_path: [*c]u8, arg_base: [*c]const u8, arg_uri: [*c]const u8) callconv(.c) void {
    var path = arg_path;
    _ = &path;
    var base = arg_base;
    _ = &base;
    var uri = arg_uri;
    _ = &uri;
    var s0: [*c]const u8 = strrchr(base, '/');
    _ = &s0;
    var s1: [*c]const u8 = strrchr(base, '\\');
    _ = &s1;
    var slash: [*c]const u8 = if (s0 != null) if ((s1 != null) and (s1 > s0)) s1 else s0 else s1;
    _ = &slash;
    if (slash != null) {
        var prefix: usize = @bitCast(@as(c_longlong, @divExact(@as(c_longlong, @bitCast(@intFromPtr(slash) -% @intFromPtr(base))), @sizeOf(u8)) + @as(c_longlong, 1)));
        _ = &prefix;
        _ = strncpy(path, base, prefix);
        _ = strcpy(path + prefix, uri);
    } else {
        _ = strcpy(path, uri);
    }
}
pub fn cgltf_load_buffer_file(arg_options: [*c]const cgltf_options, arg_size: cgltf_size, arg_uri: [*c]const u8, arg_gltf_path: [*c]const u8, arg_out_data: [*c]?*anyopaque) callconv(.c) cgltf_result {
    var options = arg_options;
    _ = &options;
    var size = arg_size;
    _ = &size;
    var uri = arg_uri;
    _ = &uri;
    var gltf_path = arg_gltf_path;
    _ = &gltf_path;
    var out_data = arg_out_data;
    _ = &out_data;
    var memory_alloc: ?*const fn (?*anyopaque, cgltf_size) callconv(.c) ?*anyopaque = if (options.*.memory.alloc_func != null) options.*.memory.alloc_func else &cgltf_default_alloc;
    _ = &memory_alloc;
    var memory_free: ?*const fn (?*anyopaque, ?*anyopaque) callconv(.c) void = if (options.*.memory.free_func != null) options.*.memory.free_func else &cgltf_default_free;
    _ = &memory_free;
    var file_read: ?*const fn ([*c]const struct_cgltf_memory_options, [*c]const struct_cgltf_file_options, [*c]const u8, [*c]cgltf_size, [*c]?*anyopaque) callconv(.c) cgltf_result = if (options.*.file.read != null) options.*.file.read else &cgltf_default_file_read;
    _ = &file_read;
    var path: [*c]u8 = @ptrCast(@alignCast(memory_alloc.?(options.*.memory.user_data, (strlen(uri) +% strlen(gltf_path)) +% @as(usize, 1))));
    _ = &path;
    if (!(path != null)) {
        return cgltf_result_out_of_memory;
    }
    cgltf_combine_paths(path, gltf_path, uri);
    _ = cgltf_decode_uri((path + strlen(path)) - strlen(uri));
    var file_data: ?*anyopaque = null;
    _ = &file_data;
    var result: cgltf_result = file_read.?(&options.*.memory, &options.*.file, path, &size, &file_data);
    _ = &result;
    memory_free.?(options.*.memory.user_data, @ptrCast(@alignCast(path)));
    out_data.* = if (result == @as(cgltf_result, cgltf_result_success)) file_data else @as(?*anyopaque, null);
    return result;
}
pub fn cgltf_unhex(arg_ch: u8) callconv(.c) c_int {
    var ch = arg_ch;
    _ = &ch;
    return if (@as(c_uint, @bitCast(@as(c_int, @as(c_int, ch) - @as(c_int, '0')))) < @as(c_uint, 10)) @as(c_int, ch) - @as(c_int, '0') else if (@as(c_uint, @bitCast(@as(c_int, @as(c_int, ch) - @as(c_int, 'A')))) < @as(c_uint, 6)) (@as(c_int, ch) - @as(c_int, 'A')) + @as(c_int, 10) else if (@as(c_uint, @bitCast(@as(c_int, @as(c_int, ch) - @as(c_int, 'a')))) < @as(c_uint, 6)) (@as(c_int, ch) - @as(c_int, 'a')) + @as(c_int, 10) else -@as(c_int, 1);
}
pub fn cgltf_calc_index_bound(arg_buffer_view: [*c]cgltf_buffer_view, arg_offset: cgltf_size, arg_component_type: cgltf_component_type, arg_count: cgltf_size) callconv(.c) cgltf_size {
    var buffer_view = arg_buffer_view;
    _ = &buffer_view;
    var offset = arg_offset;
    _ = &offset;
    var component_type = arg_component_type;
    _ = &component_type;
    var count = arg_count;
    _ = &count;
    var data: [*c]u8 = (@as([*c]u8, @ptrCast(@alignCast(buffer_view.*.buffer.*.data))) + offset) + buffer_view.*.offset;
    _ = &data;
    var bound: cgltf_size = 0;
    _ = &bound;
    while (true) {
        switch (component_type) {
            @as(cgltf_component_type, cgltf_component_type_r_8u) => {
                {
                    var i: usize = 0;
                    _ = &i;
                    while (i < count) : (i +%= 1) {
                        var v: cgltf_size = @as([*c]u8, @ptrCast(@alignCast(data)))[@intCast(i)];
                        _ = &v;
                        bound = if (bound > v) bound else v;
                    }
                }
                break;
            },
            @as(cgltf_component_type, cgltf_component_type_r_16u) => {
                {
                    var i: usize = 0;
                    _ = &i;
                    while (i < count) : (i +%= 1) {
                        var v: cgltf_size = @as([*c]c_ushort, @ptrCast(@alignCast(data)))[@intCast(i)];
                        _ = &v;
                        bound = if (bound > v) bound else v;
                    }
                }
                break;
            },
            @as(cgltf_component_type, cgltf_component_type_r_32u) => {
                {
                    var i: usize = 0;
                    _ = &i;
                    while (i < count) : (i +%= 1) {
                        var v: cgltf_size = @as([*c]c_uint, @ptrCast(@alignCast(data)))[@intCast(i)];
                        _ = &v;
                        bound = if (bound > v) bound else v;
                    }
                }
                break;
            },
            else => {
                {}
            },
        }
        break;
    }
    return bound;
}
pub fn cgltf_free_extras(arg_data: [*c]cgltf_data, arg_extras: [*c]cgltf_extras) callconv(.c) void {
    var data = arg_data;
    _ = &data;
    var extras = arg_extras;
    _ = &extras;
    data.*.memory.free_func.?(data.*.memory.user_data, @ptrCast(@alignCast(extras.*.data)));
}
pub fn cgltf_free_extensions(arg_data: [*c]cgltf_data, arg_extensions: [*c]cgltf_extension, arg_extensions_count: cgltf_size) callconv(.c) void {
    var data = arg_data;
    _ = &data;
    var extensions = arg_extensions;
    _ = &extensions;
    var extensions_count = arg_extensions_count;
    _ = &extensions_count;
    {
        var i: cgltf_size = 0;
        _ = &i;
        while (i < extensions_count) : (i +%= 1) {
            data.*.memory.free_func.?(data.*.memory.user_data, @ptrCast(@alignCast(extensions[@intCast(i)].name)));
            data.*.memory.free_func.?(data.*.memory.user_data, @ptrCast(@alignCast(extensions[@intCast(i)].data)));
        }
    }
    data.*.memory.free_func.?(data.*.memory.user_data, @ptrCast(@alignCast(extensions)));
}
pub fn cgltf_component_read_integer(arg_in: ?*const anyopaque, arg_component_type: cgltf_component_type) callconv(.c) cgltf_ssize {
    var in = arg_in;
    _ = &in;
    var component_type = arg_component_type;
    _ = &component_type;
    while (true) {
        switch (component_type) {
            @as(cgltf_component_type, cgltf_component_type_r_16) => {
                return @as([*c]const i16, @ptrCast(@alignCast(in))).*;
            },
            @as(cgltf_component_type, cgltf_component_type_r_16u) => {
                return @as([*c]const u16, @ptrCast(@alignCast(in))).*;
            },
            @as(cgltf_component_type, cgltf_component_type_r_32u) => {
                return @as([*c]const u32, @ptrCast(@alignCast(in))).*;
            },
            @as(cgltf_component_type, cgltf_component_type_r_8) => {
                return @as([*c]const i8, @ptrCast(@alignCast(in))).*;
            },
            @as(cgltf_component_type, cgltf_component_type_r_8u) => {
                return @as([*c]const u8, @ptrCast(@alignCast(in))).*;
            },
            else => {
                return 0;
            },
        }
        break;
    }
    return undefined;
}
pub fn cgltf_component_read_index(arg_in: ?*const anyopaque, arg_component_type: cgltf_component_type) callconv(.c) cgltf_size {
    var in = arg_in;
    _ = &in;
    var component_type = arg_component_type;
    _ = &component_type;
    while (true) {
        switch (component_type) {
            @as(cgltf_component_type, cgltf_component_type_r_16u) => {
                return @as([*c]const u16, @ptrCast(@alignCast(in))).*;
            },
            @as(cgltf_component_type, cgltf_component_type_r_32u) => {
                return @as([*c]const u32, @ptrCast(@alignCast(in))).*;
            },
            @as(cgltf_component_type, cgltf_component_type_r_8u) => {
                return @as([*c]const u8, @ptrCast(@alignCast(in))).*;
            },
            else => {
                return 0;
            },
        }
        break;
    }
    return undefined;
}
pub fn cgltf_component_read_float(arg_in: ?*const anyopaque, arg_component_type: cgltf_component_type, arg_normalized: cgltf_bool) callconv(.c) cgltf_float {
    var in = arg_in;
    _ = &in;
    var component_type = arg_component_type;
    _ = &component_type;
    var normalized = arg_normalized;
    _ = &normalized;
    if (component_type == @as(cgltf_component_type, cgltf_component_type_r_32f)) {
        return @as([*c]const f32, @ptrCast(@alignCast(in))).*;
    }
    if (normalized != 0) {
        while (true) {
            switch (component_type) {
                @as(cgltf_component_type, cgltf_component_type_r_16) => {
                    return @as(cgltf_float, @floatFromInt(@as(c_int, @as([*c]const i16, @ptrCast(@alignCast(in))).*))) / @as(cgltf_float, @floatFromInt(@as(c_int, 32767)));
                },
                @as(cgltf_component_type, cgltf_component_type_r_16u) => {
                    return @as(cgltf_float, @floatFromInt(@as(c_int, @as([*c]const u16, @ptrCast(@alignCast(in))).*))) / @as(cgltf_float, @floatFromInt(@as(c_int, 65535)));
                },
                @as(cgltf_component_type, cgltf_component_type_r_8) => {
                    return @as(cgltf_float, @floatFromInt(@as(c_int, @as([*c]const i8, @ptrCast(@alignCast(in))).*))) / @as(cgltf_float, @floatFromInt(@as(c_int, 127)));
                },
                @as(cgltf_component_type, cgltf_component_type_r_8u) => {
                    return @as(cgltf_float, @floatFromInt(@as(c_int, @as([*c]const u8, @ptrCast(@alignCast(in))).*))) / @as(cgltf_float, @floatFromInt(@as(c_int, 255)));
                },
                else => {
                    return @floatFromInt(@as(c_int, 0));
                },
            }
            break;
        }
    }
    return @floatFromInt(cgltf_component_read_integer(in, component_type));
}
pub fn cgltf_element_read_float(arg_element: [*c]const u8, arg_type: cgltf_type, arg_component_type: cgltf_component_type, arg_normalized: cgltf_bool, arg_out: [*c]cgltf_float, arg_element_size: cgltf_size) callconv(.c) cgltf_bool {
    var element = arg_element;
    _ = &element;
    var @"type" = arg_type;
    _ = &@"type";
    var component_type = arg_component_type;
    _ = &component_type;
    var normalized = arg_normalized;
    _ = &normalized;
    var out = arg_out;
    _ = &out;
    var element_size = arg_element_size;
    _ = &element_size;
    var num_components: cgltf_size = cgltf_num_components(@"type");
    _ = &num_components;
    if (element_size < num_components) {
        return 0;
    }
    var component_size: cgltf_size = cgltf_component_size(component_type);
    _ = &component_size;
    if ((@"type" == @as(cgltf_type, cgltf_type_mat2)) and (component_size == @as(cgltf_size, 1))) {
        out[@as(c_int, 0)] = cgltf_component_read_float(@ptrCast(@alignCast(element)), component_type, normalized);
        out[@as(c_int, 1)] = cgltf_component_read_float(@ptrCast(@alignCast(element + @as(usize, @bitCast(@as(isize, @intCast(@as(c_int, 1))))))), component_type, normalized);
        out[@as(c_int, 2)] = cgltf_component_read_float(@ptrCast(@alignCast(element + @as(usize, @bitCast(@as(isize, @intCast(@as(c_int, 4))))))), component_type, normalized);
        out[@as(c_int, 3)] = cgltf_component_read_float(@ptrCast(@alignCast(element + @as(usize, @bitCast(@as(isize, @intCast(@as(c_int, 5))))))), component_type, normalized);
        return 1;
    }
    if ((@"type" == @as(cgltf_type, cgltf_type_mat3)) and (component_size == @as(cgltf_size, 1))) {
        out[@as(c_int, 0)] = cgltf_component_read_float(@ptrCast(@alignCast(element)), component_type, normalized);
        out[@as(c_int, 1)] = cgltf_component_read_float(@ptrCast(@alignCast(element + @as(usize, @bitCast(@as(isize, @intCast(@as(c_int, 1))))))), component_type, normalized);
        out[@as(c_int, 2)] = cgltf_component_read_float(@ptrCast(@alignCast(element + @as(usize, @bitCast(@as(isize, @intCast(@as(c_int, 2))))))), component_type, normalized);
        out[@as(c_int, 3)] = cgltf_component_read_float(@ptrCast(@alignCast(element + @as(usize, @bitCast(@as(isize, @intCast(@as(c_int, 4))))))), component_type, normalized);
        out[@as(c_int, 4)] = cgltf_component_read_float(@ptrCast(@alignCast(element + @as(usize, @bitCast(@as(isize, @intCast(@as(c_int, 5))))))), component_type, normalized);
        out[@as(c_int, 5)] = cgltf_component_read_float(@ptrCast(@alignCast(element + @as(usize, @bitCast(@as(isize, @intCast(@as(c_int, 6))))))), component_type, normalized);
        out[@as(c_int, 6)] = cgltf_component_read_float(@ptrCast(@alignCast(element + @as(usize, @bitCast(@as(isize, @intCast(@as(c_int, 8))))))), component_type, normalized);
        out[@as(c_int, 7)] = cgltf_component_read_float(@ptrCast(@alignCast(element + @as(usize, @bitCast(@as(isize, @intCast(@as(c_int, 9))))))), component_type, normalized);
        out[@as(c_int, 8)] = cgltf_component_read_float(@ptrCast(@alignCast(element + @as(usize, @bitCast(@as(isize, @intCast(@as(c_int, 10))))))), component_type, normalized);
        return 1;
    }
    if ((@"type" == @as(cgltf_type, cgltf_type_mat3)) and (component_size == @as(cgltf_size, 2))) {
        out[@as(c_int, 0)] = cgltf_component_read_float(@ptrCast(@alignCast(element)), component_type, normalized);
        out[@as(c_int, 1)] = cgltf_component_read_float(@ptrCast(@alignCast(element + @as(usize, @bitCast(@as(isize, @intCast(@as(c_int, 2))))))), component_type, normalized);
        out[@as(c_int, 2)] = cgltf_component_read_float(@ptrCast(@alignCast(element + @as(usize, @bitCast(@as(isize, @intCast(@as(c_int, 4))))))), component_type, normalized);
        out[@as(c_int, 3)] = cgltf_component_read_float(@ptrCast(@alignCast(element + @as(usize, @bitCast(@as(isize, @intCast(@as(c_int, 8))))))), component_type, normalized);
        out[@as(c_int, 4)] = cgltf_component_read_float(@ptrCast(@alignCast(element + @as(usize, @bitCast(@as(isize, @intCast(@as(c_int, 10))))))), component_type, normalized);
        out[@as(c_int, 5)] = cgltf_component_read_float(@ptrCast(@alignCast(element + @as(usize, @bitCast(@as(isize, @intCast(@as(c_int, 12))))))), component_type, normalized);
        out[@as(c_int, 6)] = cgltf_component_read_float(@ptrCast(@alignCast(element + @as(usize, @bitCast(@as(isize, @intCast(@as(c_int, 16))))))), component_type, normalized);
        out[@as(c_int, 7)] = cgltf_component_read_float(@ptrCast(@alignCast(element + @as(usize, @bitCast(@as(isize, @intCast(@as(c_int, 18))))))), component_type, normalized);
        out[@as(c_int, 8)] = cgltf_component_read_float(@ptrCast(@alignCast(element + @as(usize, @bitCast(@as(isize, @intCast(@as(c_int, 20))))))), component_type, normalized);
        return 1;
    }
    {
        var i: cgltf_size = 0;
        _ = &i;
        while (i < num_components) : (i +%= 1) {
            out[@intCast(i)] = cgltf_component_read_float(@ptrCast(@alignCast(element + (component_size *% i))), component_type, normalized);
        }
    }
    return 1;
}
pub fn cgltf_find_sparse_index(arg_accessor: [*c]const cgltf_accessor, arg_needle: cgltf_size) callconv(.c) [*c]const u8 {
    var accessor = arg_accessor;
    _ = &accessor;
    var needle = arg_needle;
    _ = &needle;
    var sparse: [*c]const cgltf_accessor_sparse = &accessor.*.sparse;
    _ = &sparse;
    var index_data: [*c]const u8 = cgltf_buffer_view_data(sparse.*.indices_buffer_view);
    _ = &index_data;
    var value_data: [*c]const u8 = cgltf_buffer_view_data(sparse.*.values_buffer_view);
    _ = &value_data;
    if ((@as(?*anyopaque, @ptrCast(@alignCast(@constCast(index_data)))) == @as(?*anyopaque, null)) or (@as(?*anyopaque, @ptrCast(@alignCast(@constCast(value_data)))) == @as(?*anyopaque, null))) return null;
    index_data += sparse.*.indices_byte_offset;
    value_data += sparse.*.values_byte_offset;
    var index_stride: cgltf_size = cgltf_component_size(sparse.*.indices_component_type);
    _ = &index_stride;
    var offset: cgltf_size = 0;
    _ = &offset;
    var length: cgltf_size = sparse.*.count;
    _ = &length;
    while (length != 0) {
        var rem: cgltf_size = length % @as(cgltf_size, 2);
        _ = &rem;
        length /= 2;
        var index: cgltf_size = cgltf_component_read_index(@ptrCast(@alignCast(index_data + ((offset +% length) *% index_stride))), sparse.*.indices_component_type);
        _ = &index;
        offset +%= if (index < needle) length +% rem else @as(cgltf_size, 0);
    }
    if (offset == sparse.*.count) return null;
    var index: cgltf_size = cgltf_component_read_index(@ptrCast(@alignCast(index_data + (offset *% index_stride))), sparse.*.indices_component_type);
    _ = &index;
    return @ptrCast(@alignCast(if (index == needle) @as(?*const anyopaque, @ptrCast(@alignCast(value_data + (offset *% accessor.*.stride)))) else @as(?*const anyopaque, @ptrCast(@alignCast(@as(?*anyopaque, null))))));
}
pub fn cgltf_component_read_uint(arg_in: ?*const anyopaque, arg_component_type: cgltf_component_type) callconv(.c) cgltf_uint {
    var in = arg_in;
    _ = &in;
    var component_type = arg_component_type;
    _ = &component_type;
    while (true) {
        switch (component_type) {
            @as(cgltf_component_type, cgltf_component_type_r_8) => {
                return @bitCast(@as(c_int, @as([*c]const i8, @ptrCast(@alignCast(in))).*));
            },
            @as(cgltf_component_type, cgltf_component_type_r_8u) => {
                return @as([*c]const u8, @ptrCast(@alignCast(in))).*;
            },
            @as(cgltf_component_type, cgltf_component_type_r_16) => {
                return @bitCast(@as(c_int, @as([*c]const i16, @ptrCast(@alignCast(in))).*));
            },
            @as(cgltf_component_type, cgltf_component_type_r_16u) => {
                return @as([*c]const u16, @ptrCast(@alignCast(in))).*;
            },
            @as(cgltf_component_type, cgltf_component_type_r_32u) => {
                return @as([*c]const u32, @ptrCast(@alignCast(in))).*;
            },
            else => {
                return 0;
            },
        }
        break;
    }
    return undefined;
}
pub fn cgltf_element_read_uint(arg_element: [*c]const u8, arg_type: cgltf_type, arg_component_type: cgltf_component_type, arg_out: [*c]cgltf_uint, arg_element_size: cgltf_size) callconv(.c) cgltf_bool {
    var element = arg_element;
    _ = &element;
    var @"type" = arg_type;
    _ = &@"type";
    var component_type = arg_component_type;
    _ = &component_type;
    var out = arg_out;
    _ = &out;
    var element_size = arg_element_size;
    _ = &element_size;
    var num_components: cgltf_size = cgltf_num_components(@"type");
    _ = &num_components;
    if (element_size < num_components) {
        return 0;
    }
    if (((@"type" == @as(cgltf_type, cgltf_type_mat2)) or (@"type" == @as(cgltf_type, cgltf_type_mat3))) or (@"type" == @as(cgltf_type, cgltf_type_mat4))) {
        return 0;
    }
    var component_size: cgltf_size = cgltf_component_size(component_type);
    _ = &component_size;
    {
        var i: cgltf_size = 0;
        _ = &i;
        while (i < num_components) : (i +%= 1) {
            out[@intCast(i)] = cgltf_component_read_uint(@ptrCast(@alignCast(element + (component_size *% i))), component_type);
        }
    }
    return 1;
}
pub fn cgltf_json_strcmp(arg_tok: [*c]const jsmntok_t, arg_json_chunk: [*c]const u8, arg_str: [*c]const u8) callconv(.c) c_int {
    var tok = arg_tok;
    _ = &tok;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var str = arg_str;
    _ = &str;
    if (tok.*.type != @as(jsmntype_t, @bitCast(JSMN_STRING))) {
        return -@as(c_int, 1);
    }
    const str_len: usize = strlen(str);
    _ = &str_len;
    const name_length: usize = @bitCast(@as(c_longlong, tok.*.end - tok.*.start));
    _ = &name_length;
    return if (str_len == name_length) strncmp(@as([*c]const u8, @ptrCast(@alignCast(json_chunk))) + @as(usize, @bitCast(@as(isize, @intCast(tok.*.start)))), str, str_len) else @as(c_int, 128);
}
pub fn cgltf_json_to_int(arg_tok: [*c]const jsmntok_t, arg_json_chunk: [*c]const u8) callconv(.c) c_int {
    var tok = arg_tok;
    _ = &tok;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    if (tok.*.type != @as(jsmntype_t, @bitCast(JSMN_PRIMITIVE))) {
        return -@as(c_int, 1);
    }
    var tmp: [128]u8 = undefined;
    _ = &tmp;
    var size: c_int = if (@as(usize, @bitCast(@as(c_longlong, tok.*.end - tok.*.start))) < @sizeOf(@TypeOf(tmp))) @as(c_int, @truncate(tok.*.end - tok.*.start)) else @as(c_int, @bitCast(@as(c_uint, @truncate(@sizeOf(@TypeOf(tmp)) -% @as(c_ulonglong, 1)))));
    _ = &size;
    _ = strncpy(@ptrCast(@alignCast(&tmp)), @as([*c]const u8, @ptrCast(@alignCast(json_chunk))) + @as(usize, @bitCast(@as(isize, @intCast(tok.*.start)))), @bitCast(@as(c_longlong, size)));
    tmp[@bitCast(@as(isize, @intCast(size)))] = 0;
    return atoi(@ptrCast(@alignCast(&tmp)));
}
pub fn cgltf_json_to_size(arg_tok: [*c]const jsmntok_t, arg_json_chunk: [*c]const u8) callconv(.c) cgltf_size {
    var tok = arg_tok;
    _ = &tok;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    if (tok.*.type != @as(jsmntype_t, @bitCast(JSMN_PRIMITIVE))) {
        return 0;
    }
    var tmp: [128]u8 = undefined;
    _ = &tmp;
    var size: c_int = if (@as(usize, @bitCast(@as(c_longlong, tok.*.end - tok.*.start))) < @sizeOf(@TypeOf(tmp))) @as(c_int, @truncate(tok.*.end - tok.*.start)) else @as(c_int, @bitCast(@as(c_uint, @truncate(@sizeOf(@TypeOf(tmp)) -% @as(c_ulonglong, 1)))));
    _ = &size;
    _ = strncpy(@ptrCast(@alignCast(&tmp)), @as([*c]const u8, @ptrCast(@alignCast(json_chunk))) + @as(usize, @bitCast(@as(isize, @intCast(tok.*.start)))), @bitCast(@as(c_longlong, size)));
    tmp[@bitCast(@as(isize, @intCast(size)))] = 0;
    var res: c_longlong = atoll(@ptrCast(@alignCast(&tmp)));
    _ = &res;
    return if (res < @as(c_longlong, 0)) @as(cgltf_size, 0) else @as(cgltf_size, @bitCast(@as(c_longlong, res)));
}
pub fn cgltf_json_to_float(arg_tok: [*c]const jsmntok_t, arg_json_chunk: [*c]const u8) callconv(.c) cgltf_float {
    var tok = arg_tok;
    _ = &tok;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    if (tok.*.type != @as(jsmntype_t, @bitCast(JSMN_PRIMITIVE))) {
        return @floatFromInt(-@as(c_int, 1));
    }
    var tmp: [128]u8 = undefined;
    _ = &tmp;
    var size: c_int = if (@as(usize, @bitCast(@as(c_longlong, tok.*.end - tok.*.start))) < @sizeOf(@TypeOf(tmp))) @as(c_int, @truncate(tok.*.end - tok.*.start)) else @as(c_int, @bitCast(@as(c_uint, @truncate(@sizeOf(@TypeOf(tmp)) -% @as(c_ulonglong, 1)))));
    _ = &size;
    _ = strncpy(@ptrCast(@alignCast(&tmp)), @as([*c]const u8, @ptrCast(@alignCast(json_chunk))) + @as(usize, @bitCast(@as(isize, @intCast(tok.*.start)))), @bitCast(@as(c_longlong, size)));
    tmp[@bitCast(@as(isize, @intCast(size)))] = 0;
    return @floatCast(atof(@ptrCast(@alignCast(&tmp))));
}
pub fn cgltf_json_to_bool(arg_tok: [*c]const jsmntok_t, arg_json_chunk: [*c]const u8) callconv(.c) cgltf_bool {
    var tok = arg_tok;
    _ = &tok;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var size: c_int = @truncate(tok.*.end - tok.*.start);
    _ = &size;
    return @intFromBool((size == @as(c_int, 4)) and (memcmp(@ptrCast(@alignCast(json_chunk + @as(usize, @bitCast(@as(isize, @intCast(tok.*.start)))))), @ptrCast(@alignCast(@constCast("true"))), 4) == @as(c_int, 0)));
}
pub fn cgltf_skip_json(arg_tokens: [*c]const jsmntok_t, arg_i: c_int) callconv(.c) c_int {
    var tokens = arg_tokens;
    _ = &tokens;
    var i = arg_i;
    _ = &i;
    var end: c_int = i + @as(c_int, 1);
    _ = &end;
    while (i < end) {
        while (true) {
            switch (tokens[@bitCast(@as(isize, @intCast(i)))].type) {
                @as(jsmntype_t, JSMN_OBJECT) => {
                    end += tokens[@bitCast(@as(isize, @intCast(i)))].size * @as(c_int, 2);
                    break;
                },
                @as(jsmntype_t, JSMN_ARRAY) => {
                    end += tokens[@bitCast(@as(isize, @intCast(i)))].size;
                    break;
                },
                @as(jsmntype_t, JSMN_PRIMITIVE), @as(jsmntype_t, JSMN_STRING) => {
                    break;
                },
                else => {
                    return -@as(c_int, 1);
                },
            }
            break;
        }
        i += 1;
    }
    return i;
}
pub fn cgltf_fill_float_array(arg_out_array: [*c]f32, arg_size: c_int, arg_value: f32) callconv(.c) void {
    var out_array = arg_out_array;
    _ = &out_array;
    var size = arg_size;
    _ = &size;
    var value = arg_value;
    _ = &value;
    {
        var j: c_int = 0;
        _ = &j;
        while (j < size) : (j += 1) {
            out_array[@bitCast(@as(isize, @intCast(j)))] = value;
        }
    }
}
pub fn cgltf_parse_json_float_array(arg_tokens: [*c]const jsmntok_t, arg_i: c_int, arg_json_chunk: [*c]const u8, arg_out_array: [*c]f32, arg_size: c_int) callconv(.c) c_int {
    var tokens = arg_tokens;
    _ = &tokens;
    var i = arg_i;
    _ = &i;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var out_array = arg_out_array;
    _ = &out_array;
    var size = arg_size;
    _ = &size;
    if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_ARRAY))) {
        return -@as(c_int, 1);
    }
    if (tokens[@bitCast(@as(isize, @intCast(i)))].size != size) {
        return -@as(c_int, 1);
    }
    i += 1;
    {
        var j: c_int = 0;
        _ = &j;
        while (j < size) : (j += 1) {
            if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_PRIMITIVE))) {
                return -@as(c_int, 1);
            }
            out_array[@bitCast(@as(isize, @intCast(j)))] = cgltf_json_to_float(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk);
            i += 1;
        }
    }
    return i;
}
pub fn cgltf_parse_json_string(arg_options: [*c]cgltf_options, arg_tokens: [*c]const jsmntok_t, arg_i: c_int, arg_json_chunk: [*c]const u8, arg_out_string: [*c][*c]u8) callconv(.c) c_int {
    var options = arg_options;
    _ = &options;
    var tokens = arg_tokens;
    _ = &tokens;
    var i = arg_i;
    _ = &i;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var out_string = arg_out_string;
    _ = &out_string;
    if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_STRING))) {
        return -@as(c_int, 1);
    }
    if (out_string.* != null) {
        return -@as(c_int, 1);
    }
    var size: c_int = @truncate(tokens[@bitCast(@as(isize, @intCast(i)))].end - tokens[@bitCast(@as(isize, @intCast(i)))].start);
    _ = &size;
    var result: [*c]u8 = @ptrCast(@alignCast(options.*.memory.alloc_func.?(options.*.memory.user_data, @bitCast(@as(c_longlong, size + @as(c_int, 1))))));
    _ = &result;
    if (!(result != null)) {
        return -@as(c_int, 2);
    }
    _ = strncpy(result, @as([*c]const u8, @ptrCast(@alignCast(json_chunk))) + @as(usize, @bitCast(@as(isize, @intCast(tokens[@bitCast(@as(isize, @intCast(i)))].start)))), @bitCast(@as(c_longlong, size)));
    result[@bitCast(@as(isize, @intCast(size)))] = 0;
    out_string.* = result;
    return i + @as(c_int, 1);
}
pub fn cgltf_parse_json_array(arg_options: [*c]cgltf_options, arg_tokens: [*c]const jsmntok_t, arg_i: c_int, arg_json_chunk: [*c]const u8, arg_element_size: usize, arg_out_array: [*c]?*anyopaque, arg_out_size: [*c]cgltf_size) callconv(.c) c_int {
    var options = arg_options;
    _ = &options;
    var tokens = arg_tokens;
    _ = &tokens;
    var i = arg_i;
    _ = &i;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var element_size = arg_element_size;
    _ = &element_size;
    var out_array = arg_out_array;
    _ = &out_array;
    var out_size = arg_out_size;
    _ = &out_size;
    _ = &json_chunk;
    if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, JSMN_ARRAY)) {
        return if (tokens[@bitCast(@as(isize, @intCast(i)))].type == @as(jsmntype_t, JSMN_OBJECT)) -@as(c_int, 3) else -@as(c_int, 1);
    }
    if (out_array.* != null) {
        return -@as(c_int, 1);
    }
    var size: c_int = tokens[@bitCast(@as(isize, @intCast(i)))].size;
    _ = &size;
    var result: ?*anyopaque = cgltf_calloc(options, element_size, @bitCast(@as(c_longlong, size)));
    _ = &result;
    if (!(result != null)) {
        return -@as(c_int, 2);
    }
    out_array.* = result;
    out_size.* = @bitCast(@as(c_longlong, size));
    return i + @as(c_int, 1);
}
pub fn cgltf_parse_json_string_array(arg_options: [*c]cgltf_options, arg_tokens: [*c]const jsmntok_t, arg_i: c_int, arg_json_chunk: [*c]const u8, arg_out_array: [*c][*c][*c]u8, arg_out_size: [*c]cgltf_size) callconv(.c) c_int {
    var options = arg_options;
    _ = &options;
    var tokens = arg_tokens;
    _ = &tokens;
    var i = arg_i;
    _ = &i;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var out_array = arg_out_array;
    _ = &out_array;
    var out_size = arg_out_size;
    _ = &out_size;
    if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_ARRAY))) {
        return -@as(c_int, 1);
    }
    i = cgltf_parse_json_array(options, tokens, i, json_chunk, @sizeOf([*c]u8), @ptrCast(@alignCast(out_array)), out_size);
    if (i < @as(c_int, 0)) {
        return i;
    }
    {
        var j: cgltf_size = 0;
        _ = &j;
        while (j < out_size.*) : (j +%= 1) {
            i = cgltf_parse_json_string(options, tokens, i, json_chunk, j + out_array.*);
            if (i < @as(c_int, 0)) {
                return i;
            }
        }
    }
    return i;
}
pub fn cgltf_parse_attribute_type(arg_name: [*c]const u8, arg_out_type: [*c]cgltf_attribute_type, arg_out_index: [*c]c_int) callconv(.c) void {
    var name = arg_name;
    _ = &name;
    var out_type = arg_out_type;
    _ = &out_type;
    var out_index = arg_out_index;
    _ = &out_index;
    if (@as(c_int, name.*) == @as(c_int, '_')) {
        out_type.* = cgltf_attribute_type_custom;
        return;
    }
    var us: [*c]const u8 = strchr(name, '_');
    _ = &us;
    var len: usize = if (us != null) @as(usize, @bitCast(@as(c_longlong, @divExact(@as(c_longlong, @bitCast(@intFromPtr(us) -% @intFromPtr(name))), @sizeOf(u8))))) else strlen(name);
    _ = &len;
    if ((len == @as(usize, 8)) and (strncmp(name, "POSITION", 8) == @as(c_int, 0))) {
        out_type.* = cgltf_attribute_type_position;
    } else if ((len == @as(usize, 6)) and (strncmp(name, "NORMAL", 6) == @as(c_int, 0))) {
        out_type.* = cgltf_attribute_type_normal;
    } else if ((len == @as(usize, 7)) and (strncmp(name, "TANGENT", 7) == @as(c_int, 0))) {
        out_type.* = cgltf_attribute_type_tangent;
    } else if ((len == @as(usize, 8)) and (strncmp(name, "TEXCOORD", 8) == @as(c_int, 0))) {
        out_type.* = cgltf_attribute_type_texcoord;
    } else if ((len == @as(usize, 5)) and (strncmp(name, "COLOR", 5) == @as(c_int, 0))) {
        out_type.* = cgltf_attribute_type_color;
    } else if ((len == @as(usize, 6)) and (strncmp(name, "JOINTS", 6) == @as(c_int, 0))) {
        out_type.* = cgltf_attribute_type_joints;
    } else if ((len == @as(usize, 7)) and (strncmp(name, "WEIGHTS", 7) == @as(c_int, 0))) {
        out_type.* = cgltf_attribute_type_weights;
    } else {
        out_type.* = cgltf_attribute_type_invalid;
    }
    if ((us != null) and (out_type.* != @as(cgltf_attribute_type, cgltf_attribute_type_invalid))) {
        out_index.* = atoi(us + @as(usize, @bitCast(@as(isize, @intCast(@as(c_int, 1))))));
        if (out_index.* < @as(c_int, 0)) {
            out_type.* = cgltf_attribute_type_invalid;
            out_index.* = 0;
        }
    }
}
pub fn cgltf_parse_json_attribute_list(arg_options: [*c]cgltf_options, arg_tokens: [*c]const jsmntok_t, arg_i: c_int, arg_json_chunk: [*c]const u8, arg_out_attributes: [*c][*c]cgltf_attribute, arg_out_attributes_count: [*c]cgltf_size) callconv(.c) c_int {
    var options = arg_options;
    _ = &options;
    var tokens = arg_tokens;
    _ = &tokens;
    var i = arg_i;
    _ = &i;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var out_attributes = arg_out_attributes;
    _ = &out_attributes;
    var out_attributes_count = arg_out_attributes_count;
    _ = &out_attributes_count;
    if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_OBJECT))) {
        return -@as(c_int, 1);
    }
    if (out_attributes.* != null) {
        return -@as(c_int, 1);
    }
    out_attributes_count.* = @bitCast(@as(c_longlong, tokens[@bitCast(@as(isize, @intCast(i)))].size));
    out_attributes.* = @ptrCast(@alignCast(cgltf_calloc(options, @sizeOf(cgltf_attribute), out_attributes_count.*)));
    i += 1;
    if (!(out_attributes.* != null)) {
        return -@as(c_int, 2);
    }
    {
        var j: cgltf_size = 0;
        _ = &j;
        while (j < out_attributes_count.*) : (j +%= 1) {
            if ((tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, JSMN_STRING)) or (tokens[@bitCast(@as(isize, @intCast(i)))].size == @as(c_int, 0))) {
                return -@as(c_int, 1);
            }
            i = cgltf_parse_json_string(options, tokens, i, json_chunk, &out_attributes.*[@intCast(j)].name);
            if (i < @as(c_int, 0)) {
                return -@as(c_int, 1);
            }
            cgltf_parse_attribute_type(out_attributes.*[@intCast(j)].name, &out_attributes.*[@intCast(j)].type, &out_attributes.*[@intCast(j)].index);
            out_attributes.*[@intCast(j)].data = @ptrFromInt(@as(cgltf_size, @bitCast(@as(c_longlong, cgltf_json_to_int(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk)))) +% @as(cgltf_size, 1));
            i += 1;
        }
    }
    return i;
}
pub fn cgltf_parse_json_extras(arg_options: [*c]cgltf_options, arg_tokens: [*c]const jsmntok_t, arg_i: c_int, arg_json_chunk: [*c]const u8, arg_out_extras: [*c]cgltf_extras) callconv(.c) c_int {
    var options = arg_options;
    _ = &options;
    var tokens = arg_tokens;
    _ = &tokens;
    var i = arg_i;
    _ = &i;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var out_extras = arg_out_extras;
    _ = &out_extras;
    if (out_extras.*.data != null) {
        return -@as(c_int, 1);
    }
    out_extras.*.start_offset = @bitCast(@as(c_longlong, tokens[@bitCast(@as(isize, @intCast(i)))].start));
    out_extras.*.end_offset = @bitCast(@as(c_longlong, tokens[@bitCast(@as(isize, @intCast(i)))].end));
    var start: usize = @bitCast(@as(c_longlong, tokens[@bitCast(@as(isize, @intCast(i)))].start));
    _ = &start;
    var size: usize = @as(usize, @bitCast(@as(c_longlong, tokens[@bitCast(@as(isize, @intCast(i)))].end))) -% start;
    _ = &size;
    out_extras.*.data = @ptrCast(@alignCast(options.*.memory.alloc_func.?(options.*.memory.user_data, size +% @as(usize, 1))));
    if (!(out_extras.*.data != null)) {
        return -@as(c_int, 2);
    }
    _ = strncpy(out_extras.*.data, @as([*c]const u8, @ptrCast(@alignCast(json_chunk))) + start, size);
    out_extras.*.data[@intCast(size)] = '\x00';
    i = cgltf_skip_json(tokens, i);
    return i;
}
pub fn cgltf_parse_json_unprocessed_extension(arg_options: [*c]cgltf_options, arg_tokens: [*c]const jsmntok_t, arg_i: c_int, arg_json_chunk: [*c]const u8, arg_out_extension: [*c]cgltf_extension) callconv(.c) c_int {
    var options = arg_options;
    _ = &options;
    var tokens = arg_tokens;
    _ = &tokens;
    var i = arg_i;
    _ = &i;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var out_extension = arg_out_extension;
    _ = &out_extension;
    if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_STRING))) {
        return -@as(c_int, 1);
    }
    if (tokens[@bitCast(@as(isize, @intCast(i + @as(c_int, 1))))].type != @as(jsmntype_t, @bitCast(JSMN_OBJECT))) {
        return -@as(c_int, 1);
    }
    if (out_extension.*.name != null) {
        return -@as(c_int, 1);
    }
    var name_length: cgltf_size = @bitCast(@as(c_longlong, tokens[@bitCast(@as(isize, @intCast(i)))].end - tokens[@bitCast(@as(isize, @intCast(i)))].start));
    _ = &name_length;
    out_extension.*.name = @ptrCast(@alignCast(options.*.memory.alloc_func.?(options.*.memory.user_data, name_length +% @as(cgltf_size, 1))));
    if (!(out_extension.*.name != null)) {
        return -@as(c_int, 2);
    }
    _ = strncpy(out_extension.*.name, @as([*c]const u8, @ptrCast(@alignCast(json_chunk))) + @as(usize, @bitCast(@as(isize, @intCast(tokens[@bitCast(@as(isize, @intCast(i)))].start)))), name_length);
    out_extension.*.name[@intCast(name_length)] = 0;
    i += 1;
    var start: usize = @bitCast(@as(c_longlong, tokens[@bitCast(@as(isize, @intCast(i)))].start));
    _ = &start;
    var size: usize = @as(usize, @bitCast(@as(c_longlong, tokens[@bitCast(@as(isize, @intCast(i)))].end))) -% start;
    _ = &size;
    out_extension.*.data = @ptrCast(@alignCast(options.*.memory.alloc_func.?(options.*.memory.user_data, size +% @as(usize, 1))));
    if (!(out_extension.*.data != null)) {
        return -@as(c_int, 2);
    }
    _ = strncpy(out_extension.*.data, @as([*c]const u8, @ptrCast(@alignCast(json_chunk))) + start, size);
    out_extension.*.data[@intCast(size)] = '\x00';
    i = cgltf_skip_json(tokens, i);
    return i;
}
pub fn cgltf_parse_json_unprocessed_extensions(arg_options: [*c]cgltf_options, arg_tokens: [*c]const jsmntok_t, arg_i: c_int, arg_json_chunk: [*c]const u8, arg_out_extensions_count: [*c]cgltf_size, arg_out_extensions: [*c][*c]cgltf_extension) callconv(.c) c_int {
    var options = arg_options;
    _ = &options;
    var tokens = arg_tokens;
    _ = &tokens;
    var i = arg_i;
    _ = &i;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var out_extensions_count = arg_out_extensions_count;
    _ = &out_extensions_count;
    var out_extensions = arg_out_extensions;
    _ = &out_extensions;
    i += 1;
    if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_OBJECT))) {
        return -@as(c_int, 1);
    }
    if (out_extensions.* != null) {
        return -@as(c_int, 1);
    }
    var extensions_size: c_int = tokens[@bitCast(@as(isize, @intCast(i)))].size;
    _ = &extensions_size;
    out_extensions_count.* = 0;
    out_extensions.* = @ptrCast(@alignCast(cgltf_calloc(options, @sizeOf(cgltf_extension), @bitCast(@as(c_longlong, extensions_size)))));
    if (!(out_extensions.* != null)) {
        return -@as(c_int, 2);
    }
    i += 1;
    {
        var j: c_int = 0;
        _ = &j;
        while (j < extensions_size) : (j += 1) {
            if ((tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, JSMN_STRING)) or (tokens[@bitCast(@as(isize, @intCast(i)))].size == @as(c_int, 0))) {
                return -@as(c_int, 1);
            }
            var extension_index: cgltf_size = blk: {
                const ref = &out_extensions_count.*;
                const tmp = ref.*;
                ref.* +%= 1;
                break :blk tmp;
            };
            _ = &extension_index;
            var extension: [*c]cgltf_extension = &out_extensions.*[@intCast(extension_index)];
            _ = &extension;
            i = cgltf_parse_json_unprocessed_extension(options, tokens, i, json_chunk, extension);
            if (i < @as(c_int, 0)) {
                return i;
            }
        }
    }
    return i;
}
pub fn cgltf_parse_json_draco_mesh_compression(arg_options: [*c]cgltf_options, arg_tokens: [*c]const jsmntok_t, arg_i: c_int, arg_json_chunk: [*c]const u8, arg_out_draco_mesh_compression: [*c]cgltf_draco_mesh_compression) callconv(.c) c_int {
    var options = arg_options;
    _ = &options;
    var tokens = arg_tokens;
    _ = &tokens;
    var i = arg_i;
    _ = &i;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var out_draco_mesh_compression = arg_out_draco_mesh_compression;
    _ = &out_draco_mesh_compression;
    if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_OBJECT))) {
        return -@as(c_int, 1);
    }
    var size: c_int = tokens[@bitCast(@as(isize, @intCast(i)))].size;
    _ = &size;
    i += 1;
    {
        var j: c_int = 0;
        _ = &j;
        while (j < size) : (j += 1) {
            if ((tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, JSMN_STRING)) or (tokens[@bitCast(@as(isize, @intCast(i)))].size == @as(c_int, 0))) {
                return -@as(c_int, 1);
            }
            if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "attributes") == @as(c_int, 0)) {
                i = cgltf_parse_json_attribute_list(options, tokens, i + @as(c_int, 1), json_chunk, &out_draco_mesh_compression.*.attributes, &out_draco_mesh_compression.*.attributes_count);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "bufferView") == @as(c_int, 0)) {
                i += 1;
                out_draco_mesh_compression.*.buffer_view = @ptrFromInt(@as(cgltf_size, @bitCast(@as(c_longlong, cgltf_json_to_int(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk)))) +% @as(cgltf_size, 1));
                i += 1;
            } else {
                i = cgltf_skip_json(tokens, i + @as(c_int, 1));
            }
            if (i < @as(c_int, 0)) {
                return i;
            }
        }
    }
    return i;
}
pub fn cgltf_parse_json_mesh_gpu_instancing(arg_options: [*c]cgltf_options, arg_tokens: [*c]const jsmntok_t, arg_i: c_int, arg_json_chunk: [*c]const u8, arg_out_mesh_gpu_instancing: [*c]cgltf_mesh_gpu_instancing) callconv(.c) c_int {
    var options = arg_options;
    _ = &options;
    var tokens = arg_tokens;
    _ = &tokens;
    var i = arg_i;
    _ = &i;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var out_mesh_gpu_instancing = arg_out_mesh_gpu_instancing;
    _ = &out_mesh_gpu_instancing;
    if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_OBJECT))) {
        return -@as(c_int, 1);
    }
    var size: c_int = tokens[@bitCast(@as(isize, @intCast(i)))].size;
    _ = &size;
    i += 1;
    {
        var j: c_int = 0;
        _ = &j;
        while (j < size) : (j += 1) {
            if ((tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, JSMN_STRING)) or (tokens[@bitCast(@as(isize, @intCast(i)))].size == @as(c_int, 0))) {
                return -@as(c_int, 1);
            }
            if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "attributes") == @as(c_int, 0)) {
                i = cgltf_parse_json_attribute_list(options, tokens, i + @as(c_int, 1), json_chunk, &out_mesh_gpu_instancing.*.attributes, &out_mesh_gpu_instancing.*.attributes_count);
            } else {
                i = cgltf_skip_json(tokens, i + @as(c_int, 1));
            }
            if (i < @as(c_int, 0)) {
                return i;
            }
        }
    }
    return i;
}
pub fn cgltf_parse_json_material_mapping_data(arg_options: [*c]cgltf_options, arg_tokens: [*c]const jsmntok_t, arg_i: c_int, arg_json_chunk: [*c]const u8, arg_out_mappings: [*c]cgltf_material_mapping, arg_offset: [*c]cgltf_size) callconv(.c) c_int {
    var options = arg_options;
    _ = &options;
    var tokens = arg_tokens;
    _ = &tokens;
    var i = arg_i;
    _ = &i;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var out_mappings = arg_out_mappings;
    _ = &out_mappings;
    var offset = arg_offset;
    _ = &offset;
    _ = &options;
    if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_ARRAY))) {
        return -@as(c_int, 1);
    }
    var size: c_int = tokens[@bitCast(@as(isize, @intCast(i)))].size;
    _ = &size;
    i += 1;
    {
        var j: c_int = 0;
        _ = &j;
        while (j < size) : (j += 1) {
            if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_OBJECT))) {
                return -@as(c_int, 1);
            }
            var obj_size: c_int = tokens[@bitCast(@as(isize, @intCast(i)))].size;
            _ = &obj_size;
            i += 1;
            var material: c_int = -@as(c_int, 1);
            _ = &material;
            var variants_tok: c_int = -@as(c_int, 1);
            _ = &variants_tok;
            var extras_tok: c_int = -@as(c_int, 1);
            _ = &extras_tok;
            {
                var k: c_int = 0;
                _ = &k;
                while (k < obj_size) : (k += 1) {
                    if ((tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, JSMN_STRING)) or (tokens[@bitCast(@as(isize, @intCast(i)))].size == @as(c_int, 0))) {
                        return -@as(c_int, 1);
                    }
                    if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "material") == @as(c_int, 0)) {
                        i += 1;
                        material = cgltf_json_to_int(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk);
                        i += 1;
                    } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "variants") == @as(c_int, 0)) {
                        variants_tok = i + @as(c_int, 1);
                        if (tokens[@bitCast(@as(isize, @intCast(variants_tok)))].type != @as(jsmntype_t, @bitCast(JSMN_ARRAY))) {
                            return -@as(c_int, 1);
                        }
                        i = cgltf_skip_json(tokens, i + @as(c_int, 1));
                    } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "extras") == @as(c_int, 0)) {
                        extras_tok = i + @as(c_int, 1);
                        i = cgltf_skip_json(tokens, extras_tok);
                    } else {
                        i = cgltf_skip_json(tokens, i + @as(c_int, 1));
                    }
                    if (i < @as(c_int, 0)) {
                        return i;
                    }
                }
            }
            if ((material < @as(c_int, 0)) or (variants_tok < @as(c_int, 0))) {
                return -@as(c_int, 1);
            }
            if (out_mappings != null) {
                {
                    var k: c_int = 0;
                    _ = &k;
                    while (k < tokens[@bitCast(@as(isize, @intCast(variants_tok)))].size) : (k += 1) {
                        var variant: c_int = cgltf_json_to_int(&tokens[@bitCast(@as(isize, @intCast((variants_tok + @as(c_int, 1)) + k)))], json_chunk);
                        _ = &variant;
                        if (variant < @as(c_int, 0)) return variant;
                        out_mappings[@intCast(offset.*)].material = @ptrFromInt(@as(cgltf_size, @bitCast(@as(c_longlong, material))) +% @as(cgltf_size, 1));
                        out_mappings[@intCast(offset.*)].variant = @bitCast(@as(c_longlong, variant));
                        if (extras_tok >= @as(c_int, 0)) {
                            var e: c_int = cgltf_parse_json_extras(options, tokens, extras_tok, json_chunk, &out_mappings[@intCast(offset.*)].extras);
                            _ = &e;
                            if (e < @as(c_int, 0)) return e;
                        }
                        offset.* +%= 1;
                    }
                }
            } else {
                offset.* +%= @bitCast(@as(c_longlong, tokens[@bitCast(@as(isize, @intCast(variants_tok)))].size));
            }
        }
    }
    return i;
}
pub fn cgltf_parse_json_material_mappings(arg_options: [*c]cgltf_options, arg_tokens: [*c]const jsmntok_t, arg_i: c_int, arg_json_chunk: [*c]const u8, arg_out_prim: [*c]cgltf_primitive) callconv(.c) c_int {
    var options = arg_options;
    _ = &options;
    var tokens = arg_tokens;
    _ = &tokens;
    var i = arg_i;
    _ = &i;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var out_prim = arg_out_prim;
    _ = &out_prim;
    if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_OBJECT))) {
        return -@as(c_int, 1);
    }
    var size: c_int = tokens[@bitCast(@as(isize, @intCast(i)))].size;
    _ = &size;
    i += 1;
    {
        var j: c_int = 0;
        _ = &j;
        while (j < size) : (j += 1) {
            if ((tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, JSMN_STRING)) or (tokens[@bitCast(@as(isize, @intCast(i)))].size == @as(c_int, 0))) {
                return -@as(c_int, 1);
            }
            if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "mappings") == @as(c_int, 0)) {
                if (out_prim.*.mappings != null) {
                    return -@as(c_int, 1);
                }
                var mappings_offset: cgltf_size = 0;
                _ = &mappings_offset;
                var k: c_int = cgltf_parse_json_material_mapping_data(options, tokens, i + @as(c_int, 1), json_chunk, null, &mappings_offset);
                _ = &k;
                if (k < @as(c_int, 0)) {
                    return k;
                }
                out_prim.*.mappings_count = mappings_offset;
                out_prim.*.mappings = @ptrCast(@alignCast(cgltf_calloc(options, @sizeOf(cgltf_material_mapping), out_prim.*.mappings_count)));
                mappings_offset = 0;
                i = cgltf_parse_json_material_mapping_data(options, tokens, i + @as(c_int, 1), json_chunk, out_prim.*.mappings, &mappings_offset);
            } else {
                i = cgltf_skip_json(tokens, i + @as(c_int, 1));
            }
            if (i < @as(c_int, 0)) {
                return i;
            }
        }
    }
    return i;
}
pub fn cgltf_json_to_primitive_type(arg_tok: [*c]const jsmntok_t, arg_json_chunk: [*c]const u8) callconv(.c) cgltf_primitive_type {
    var tok = arg_tok;
    _ = &tok;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var @"type": c_int = cgltf_json_to_int(tok, json_chunk);
    _ = &@"type";
    while (true) {
        switch (@"type") {
            @as(c_int, 0) => {
                return cgltf_primitive_type_points;
            },
            @as(c_int, 1) => {
                return cgltf_primitive_type_lines;
            },
            @as(c_int, 2) => {
                return cgltf_primitive_type_line_loop;
            },
            @as(c_int, 3) => {
                return cgltf_primitive_type_line_strip;
            },
            @as(c_int, 4) => {
                return cgltf_primitive_type_triangles;
            },
            @as(c_int, 5) => {
                return cgltf_primitive_type_triangle_strip;
            },
            @as(c_int, 6) => {
                return cgltf_primitive_type_triangle_fan;
            },
            else => {
                return cgltf_primitive_type_invalid;
            },
        }
        break;
    }
    return undefined;
}
pub fn cgltf_parse_json_primitive(arg_options: [*c]cgltf_options, arg_tokens: [*c]const jsmntok_t, arg_i: c_int, arg_json_chunk: [*c]const u8, arg_out_prim: [*c]cgltf_primitive) callconv(.c) c_int {
    var options = arg_options;
    _ = &options;
    var tokens = arg_tokens;
    _ = &tokens;
    var i = arg_i;
    _ = &i;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var out_prim = arg_out_prim;
    _ = &out_prim;
    if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_OBJECT))) {
        return -@as(c_int, 1);
    }
    out_prim.*.type = cgltf_primitive_type_triangles;
    var size: c_int = tokens[@bitCast(@as(isize, @intCast(i)))].size;
    _ = &size;
    i += 1;
    {
        var j: c_int = 0;
        _ = &j;
        while (j < size) : (j += 1) {
            if ((tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, JSMN_STRING)) or (tokens[@bitCast(@as(isize, @intCast(i)))].size == @as(c_int, 0))) {
                return -@as(c_int, 1);
            }
            if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "mode") == @as(c_int, 0)) {
                i += 1;
                out_prim.*.type = cgltf_json_to_primitive_type(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk);
                i += 1;
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "indices") == @as(c_int, 0)) {
                i += 1;
                out_prim.*.indices = @ptrFromInt(@as(cgltf_size, @bitCast(@as(c_longlong, cgltf_json_to_int(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk)))) +% @as(cgltf_size, 1));
                i += 1;
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "material") == @as(c_int, 0)) {
                i += 1;
                out_prim.*.material = @ptrFromInt(@as(cgltf_size, @bitCast(@as(c_longlong, cgltf_json_to_int(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk)))) +% @as(cgltf_size, 1));
                i += 1;
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "attributes") == @as(c_int, 0)) {
                i = cgltf_parse_json_attribute_list(options, tokens, i + @as(c_int, 1), json_chunk, &out_prim.*.attributes, &out_prim.*.attributes_count);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "targets") == @as(c_int, 0)) {
                i = cgltf_parse_json_array(options, tokens, i + @as(c_int, 1), json_chunk, @sizeOf(cgltf_morph_target), @ptrCast(@alignCast(&out_prim.*.targets)), &out_prim.*.targets_count);
                if (i < @as(c_int, 0)) {
                    return i;
                }
                {
                    var k: cgltf_size = 0;
                    _ = &k;
                    while (k < out_prim.*.targets_count) : (k +%= 1) {
                        i = cgltf_parse_json_attribute_list(options, tokens, i, json_chunk, &out_prim.*.targets[@intCast(k)].attributes, &out_prim.*.targets[@intCast(k)].attributes_count);
                        if (i < @as(c_int, 0)) {
                            return i;
                        }
                    }
                }
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "extras") == @as(c_int, 0)) {
                i = cgltf_parse_json_extras(options, tokens, i + @as(c_int, 1), json_chunk, &out_prim.*.extras);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "extensions") == @as(c_int, 0)) {
                i += 1;
                if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_OBJECT))) {
                    return -@as(c_int, 1);
                }
                if (out_prim.*.extensions != null) {
                    return -@as(c_int, 1);
                }
                var extensions_size: c_int = tokens[@bitCast(@as(isize, @intCast(i)))].size;
                _ = &extensions_size;
                out_prim.*.extensions_count = 0;
                out_prim.*.extensions = @ptrCast(@alignCast(cgltf_calloc(options, @sizeOf(cgltf_extension), @bitCast(@as(c_longlong, extensions_size)))));
                if (!(out_prim.*.extensions != null)) {
                    return -@as(c_int, 2);
                }
                i += 1;
                {
                    var k: c_int = 0;
                    _ = &k;
                    while (k < extensions_size) : (k += 1) {
                        if ((tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, JSMN_STRING)) or (tokens[@bitCast(@as(isize, @intCast(i)))].size == @as(c_int, 0))) {
                            return -@as(c_int, 1);
                        }
                        if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "KHR_draco_mesh_compression") == @as(c_int, 0)) {
                            out_prim.*.has_draco_mesh_compression = 1;
                            i = cgltf_parse_json_draco_mesh_compression(options, tokens, i + @as(c_int, 1), json_chunk, &out_prim.*.draco_mesh_compression);
                        } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "KHR_materials_variants") == @as(c_int, 0)) {
                            i = cgltf_parse_json_material_mappings(options, tokens, i + @as(c_int, 1), json_chunk, out_prim);
                        } else {
                            i = cgltf_parse_json_unprocessed_extension(options, tokens, i, json_chunk, &out_prim.*.extensions[
                                @intCast(blk: {
                                    const ref = &out_prim.*.extensions_count;
                                    const tmp = ref.*;
                                    ref.* +%= 1;
                                    break :blk tmp;
                                })
                            ]);
                        }
                        if (i < @as(c_int, 0)) {
                            return i;
                        }
                    }
                }
            } else {
                i = cgltf_skip_json(tokens, i + @as(c_int, 1));
            }
            if (i < @as(c_int, 0)) {
                return i;
            }
        }
    }
    return i;
}
pub fn cgltf_parse_json_mesh(arg_options: [*c]cgltf_options, arg_tokens: [*c]const jsmntok_t, arg_i: c_int, arg_json_chunk: [*c]const u8, arg_out_mesh: [*c]cgltf_mesh) callconv(.c) c_int {
    var options = arg_options;
    _ = &options;
    var tokens = arg_tokens;
    _ = &tokens;
    var i = arg_i;
    _ = &i;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var out_mesh = arg_out_mesh;
    _ = &out_mesh;
    if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_OBJECT))) {
        return -@as(c_int, 1);
    }
    var size: c_int = tokens[@bitCast(@as(isize, @intCast(i)))].size;
    _ = &size;
    i += 1;
    {
        var j: c_int = 0;
        _ = &j;
        while (j < size) : (j += 1) {
            if ((tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, JSMN_STRING)) or (tokens[@bitCast(@as(isize, @intCast(i)))].size == @as(c_int, 0))) {
                return -@as(c_int, 1);
            }
            if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "name") == @as(c_int, 0)) {
                i = cgltf_parse_json_string(options, tokens, i + @as(c_int, 1), json_chunk, &out_mesh.*.name);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "primitives") == @as(c_int, 0)) {
                i = cgltf_parse_json_array(options, tokens, i + @as(c_int, 1), json_chunk, @sizeOf(cgltf_primitive), @ptrCast(@alignCast(&out_mesh.*.primitives)), &out_mesh.*.primitives_count);
                if (i < @as(c_int, 0)) {
                    return i;
                }
                {
                    var prim_index: cgltf_size = 0;
                    _ = &prim_index;
                    while (prim_index < out_mesh.*.primitives_count) : (prim_index +%= 1) {
                        i = cgltf_parse_json_primitive(options, tokens, i, json_chunk, &out_mesh.*.primitives[@intCast(prim_index)]);
                        if (i < @as(c_int, 0)) {
                            return i;
                        }
                    }
                }
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "weights") == @as(c_int, 0)) {
                i = cgltf_parse_json_array(options, tokens, i + @as(c_int, 1), json_chunk, @sizeOf(cgltf_float), @ptrCast(@alignCast(&out_mesh.*.weights)), &out_mesh.*.weights_count);
                if (i < @as(c_int, 0)) {
                    return i;
                }
                i = cgltf_parse_json_float_array(tokens, i - @as(c_int, 1), json_chunk, out_mesh.*.weights, @bitCast(@as(c_uint, @truncate(out_mesh.*.weights_count))));
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "extras") == @as(c_int, 0)) {
                i += 1;
                out_mesh.*.extras.start_offset = @bitCast(@as(c_longlong, tokens[@bitCast(@as(isize, @intCast(i)))].start));
                out_mesh.*.extras.end_offset = @bitCast(@as(c_longlong, tokens[@bitCast(@as(isize, @intCast(i)))].end));
                if (tokens[@bitCast(@as(isize, @intCast(i)))].type == @as(jsmntype_t, JSMN_OBJECT)) {
                    var extras_size: c_int = tokens[@bitCast(@as(isize, @intCast(i)))].size;
                    _ = &extras_size;
                    i += 1;
                    {
                        var k: c_int = 0;
                        _ = &k;
                        while (k < extras_size) : (k += 1) {
                            if ((tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, JSMN_STRING)) or (tokens[@bitCast(@as(isize, @intCast(i)))].size == @as(c_int, 0))) {
                                return -@as(c_int, 1);
                            }
                            if ((cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "targetNames") == @as(c_int, 0)) and (tokens[@bitCast(@as(isize, @intCast(i + @as(c_int, 1))))].type == @as(jsmntype_t, JSMN_ARRAY))) {
                                i = cgltf_parse_json_string_array(options, tokens, i + @as(c_int, 1), json_chunk, &out_mesh.*.target_names, &out_mesh.*.target_names_count);
                            } else {
                                i = cgltf_skip_json(tokens, i + @as(c_int, 1));
                            }
                            if (i < @as(c_int, 0)) {
                                return i;
                            }
                        }
                    }
                } else {
                    i = cgltf_skip_json(tokens, i);
                }
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "extensions") == @as(c_int, 0)) {
                i = cgltf_parse_json_unprocessed_extensions(options, tokens, i, json_chunk, &out_mesh.*.extensions_count, &out_mesh.*.extensions);
            } else {
                i = cgltf_skip_json(tokens, i + @as(c_int, 1));
            }
            if (i < @as(c_int, 0)) {
                return i;
            }
        }
    }
    return i;
}
pub fn cgltf_parse_json_meshes(arg_options: [*c]cgltf_options, arg_tokens: [*c]const jsmntok_t, arg_i: c_int, arg_json_chunk: [*c]const u8, arg_out_data: [*c]cgltf_data) callconv(.c) c_int {
    var options = arg_options;
    _ = &options;
    var tokens = arg_tokens;
    _ = &tokens;
    var i = arg_i;
    _ = &i;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var out_data = arg_out_data;
    _ = &out_data;
    i = cgltf_parse_json_array(options, tokens, i, json_chunk, @sizeOf(cgltf_mesh), @ptrCast(@alignCast(&out_data.*.meshes)), &out_data.*.meshes_count);
    if (i < @as(c_int, 0)) {
        return i;
    }
    {
        var j: cgltf_size = 0;
        _ = &j;
        while (j < out_data.*.meshes_count) : (j +%= 1) {
            i = cgltf_parse_json_mesh(options, tokens, i, json_chunk, &out_data.*.meshes[@intCast(j)]);
            if (i < @as(c_int, 0)) {
                return i;
            }
        }
    }
    return i;
}
pub fn cgltf_json_to_component_type(arg_tok: [*c]const jsmntok_t, arg_json_chunk: [*c]const u8) callconv(.c) cgltf_component_type {
    var tok = arg_tok;
    _ = &tok;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var @"type": c_int = cgltf_json_to_int(tok, json_chunk);
    _ = &@"type";
    while (true) {
        switch (@"type") {
            @as(c_int, 5120) => {
                return cgltf_component_type_r_8;
            },
            @as(c_int, 5121) => {
                return cgltf_component_type_r_8u;
            },
            @as(c_int, 5122) => {
                return cgltf_component_type_r_16;
            },
            @as(c_int, 5123) => {
                return cgltf_component_type_r_16u;
            },
            @as(c_int, 5125) => {
                return cgltf_component_type_r_32u;
            },
            @as(c_int, 5126) => {
                return cgltf_component_type_r_32f;
            },
            else => {
                return cgltf_component_type_invalid;
            },
        }
        break;
    }
    return undefined;
}
pub fn cgltf_parse_json_accessor_sparse(arg_tokens: [*c]const jsmntok_t, arg_i: c_int, arg_json_chunk: [*c]const u8, arg_out_sparse: [*c]cgltf_accessor_sparse) callconv(.c) c_int {
    var tokens = arg_tokens;
    _ = &tokens;
    var i = arg_i;
    _ = &i;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var out_sparse = arg_out_sparse;
    _ = &out_sparse;
    if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_OBJECT))) {
        return -@as(c_int, 1);
    }
    var size: c_int = tokens[@bitCast(@as(isize, @intCast(i)))].size;
    _ = &size;
    i += 1;
    {
        var j: c_int = 0;
        _ = &j;
        while (j < size) : (j += 1) {
            if ((tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, JSMN_STRING)) or (tokens[@bitCast(@as(isize, @intCast(i)))].size == @as(c_int, 0))) {
                return -@as(c_int, 1);
            }
            if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "count") == @as(c_int, 0)) {
                i += 1;
                out_sparse.*.count = cgltf_json_to_size(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk);
                i += 1;
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "indices") == @as(c_int, 0)) {
                i += 1;
                if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_OBJECT))) {
                    return -@as(c_int, 1);
                }
                var indices_size: c_int = tokens[@bitCast(@as(isize, @intCast(i)))].size;
                _ = &indices_size;
                i += 1;
                {
                    var k: c_int = 0;
                    _ = &k;
                    while (k < indices_size) : (k += 1) {
                        if ((tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, JSMN_STRING)) or (tokens[@bitCast(@as(isize, @intCast(i)))].size == @as(c_int, 0))) {
                            return -@as(c_int, 1);
                        }
                        if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "bufferView") == @as(c_int, 0)) {
                            i += 1;
                            out_sparse.*.indices_buffer_view = @ptrFromInt(@as(cgltf_size, @bitCast(@as(c_longlong, cgltf_json_to_int(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk)))) +% @as(cgltf_size, 1));
                            i += 1;
                        } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "byteOffset") == @as(c_int, 0)) {
                            i += 1;
                            out_sparse.*.indices_byte_offset = cgltf_json_to_size(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk);
                            i += 1;
                        } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "componentType") == @as(c_int, 0)) {
                            i += 1;
                            out_sparse.*.indices_component_type = cgltf_json_to_component_type(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk);
                            i += 1;
                        } else {
                            i = cgltf_skip_json(tokens, i + @as(c_int, 1));
                        }
                        if (i < @as(c_int, 0)) {
                            return i;
                        }
                    }
                }
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "values") == @as(c_int, 0)) {
                i += 1;
                if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_OBJECT))) {
                    return -@as(c_int, 1);
                }
                var values_size: c_int = tokens[@bitCast(@as(isize, @intCast(i)))].size;
                _ = &values_size;
                i += 1;
                {
                    var k: c_int = 0;
                    _ = &k;
                    while (k < values_size) : (k += 1) {
                        if ((tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, JSMN_STRING)) or (tokens[@bitCast(@as(isize, @intCast(i)))].size == @as(c_int, 0))) {
                            return -@as(c_int, 1);
                        }
                        if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "bufferView") == @as(c_int, 0)) {
                            i += 1;
                            out_sparse.*.values_buffer_view = @ptrFromInt(@as(cgltf_size, @bitCast(@as(c_longlong, cgltf_json_to_int(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk)))) +% @as(cgltf_size, 1));
                            i += 1;
                        } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "byteOffset") == @as(c_int, 0)) {
                            i += 1;
                            out_sparse.*.values_byte_offset = cgltf_json_to_size(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk);
                            i += 1;
                        } else {
                            i = cgltf_skip_json(tokens, i + @as(c_int, 1));
                        }
                        if (i < @as(c_int, 0)) {
                            return i;
                        }
                    }
                }
            } else {
                i = cgltf_skip_json(tokens, i + @as(c_int, 1));
            }
            if (i < @as(c_int, 0)) {
                return i;
            }
        }
    }
    return i;
}
pub fn cgltf_parse_json_accessor(arg_options: [*c]cgltf_options, arg_tokens: [*c]const jsmntok_t, arg_i: c_int, arg_json_chunk: [*c]const u8, arg_out_accessor: [*c]cgltf_accessor) callconv(.c) c_int {
    var options = arg_options;
    _ = &options;
    var tokens = arg_tokens;
    _ = &tokens;
    var i = arg_i;
    _ = &i;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var out_accessor = arg_out_accessor;
    _ = &out_accessor;
    if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_OBJECT))) {
        return -@as(c_int, 1);
    }
    var size: c_int = tokens[@bitCast(@as(isize, @intCast(i)))].size;
    _ = &size;
    i += 1;
    {
        var j: c_int = 0;
        _ = &j;
        while (j < size) : (j += 1) {
            if ((tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, JSMN_STRING)) or (tokens[@bitCast(@as(isize, @intCast(i)))].size == @as(c_int, 0))) {
                return -@as(c_int, 1);
            }
            if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "name") == @as(c_int, 0)) {
                i = cgltf_parse_json_string(options, tokens, i + @as(c_int, 1), json_chunk, &out_accessor.*.name);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "bufferView") == @as(c_int, 0)) {
                i += 1;
                out_accessor.*.buffer_view = @ptrFromInt(@as(cgltf_size, @bitCast(@as(c_longlong, cgltf_json_to_int(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk)))) +% @as(cgltf_size, 1));
                i += 1;
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "byteOffset") == @as(c_int, 0)) {
                i += 1;
                out_accessor.*.offset = cgltf_json_to_size(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk);
                i += 1;
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "componentType") == @as(c_int, 0)) {
                i += 1;
                out_accessor.*.component_type = cgltf_json_to_component_type(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk);
                i += 1;
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "normalized") == @as(c_int, 0)) {
                i += 1;
                out_accessor.*.normalized = cgltf_json_to_bool(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk);
                i += 1;
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "count") == @as(c_int, 0)) {
                i += 1;
                out_accessor.*.count = cgltf_json_to_size(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk);
                i += 1;
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "type") == @as(c_int, 0)) {
                i += 1;
                if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "SCALAR") == @as(c_int, 0)) {
                    out_accessor.*.type = cgltf_type_scalar;
                } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "VEC2") == @as(c_int, 0)) {
                    out_accessor.*.type = cgltf_type_vec2;
                } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "VEC3") == @as(c_int, 0)) {
                    out_accessor.*.type = cgltf_type_vec3;
                } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "VEC4") == @as(c_int, 0)) {
                    out_accessor.*.type = cgltf_type_vec4;
                } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "MAT2") == @as(c_int, 0)) {
                    out_accessor.*.type = cgltf_type_mat2;
                } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "MAT3") == @as(c_int, 0)) {
                    out_accessor.*.type = cgltf_type_mat3;
                } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "MAT4") == @as(c_int, 0)) {
                    out_accessor.*.type = cgltf_type_mat4;
                }
                i += 1;
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "min") == @as(c_int, 0)) {
                i += 1;
                out_accessor.*.has_min = 1;
                var min_size: c_int = if (tokens[@bitCast(@as(isize, @intCast(i)))].size > @as(c_int, 16)) @as(c_int, 16) else tokens[@bitCast(@as(isize, @intCast(i)))].size;
                _ = &min_size;
                i = cgltf_parse_json_float_array(tokens, i, json_chunk, @ptrCast(@alignCast(&out_accessor.*.min)), min_size);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "max") == @as(c_int, 0)) {
                i += 1;
                out_accessor.*.has_max = 1;
                var max_size: c_int = if (tokens[@bitCast(@as(isize, @intCast(i)))].size > @as(c_int, 16)) @as(c_int, 16) else tokens[@bitCast(@as(isize, @intCast(i)))].size;
                _ = &max_size;
                i = cgltf_parse_json_float_array(tokens, i, json_chunk, @ptrCast(@alignCast(&out_accessor.*.max)), max_size);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "sparse") == @as(c_int, 0)) {
                out_accessor.*.is_sparse = 1;
                i = cgltf_parse_json_accessor_sparse(tokens, i + @as(c_int, 1), json_chunk, &out_accessor.*.sparse);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "extras") == @as(c_int, 0)) {
                i = cgltf_parse_json_extras(options, tokens, i + @as(c_int, 1), json_chunk, &out_accessor.*.extras);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "extensions") == @as(c_int, 0)) {
                i = cgltf_parse_json_unprocessed_extensions(options, tokens, i, json_chunk, &out_accessor.*.extensions_count, &out_accessor.*.extensions);
            } else {
                i = cgltf_skip_json(tokens, i + @as(c_int, 1));
            }
            if (i < @as(c_int, 0)) {
                return i;
            }
        }
    }
    return i;
}
pub fn cgltf_parse_json_texture_transform(arg_tokens: [*c]const jsmntok_t, arg_i: c_int, arg_json_chunk: [*c]const u8, arg_out_texture_transform: [*c]cgltf_texture_transform) callconv(.c) c_int {
    var tokens = arg_tokens;
    _ = &tokens;
    var i = arg_i;
    _ = &i;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var out_texture_transform = arg_out_texture_transform;
    _ = &out_texture_transform;
    if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_OBJECT))) {
        return -@as(c_int, 1);
    }
    var size: c_int = tokens[@bitCast(@as(isize, @intCast(i)))].size;
    _ = &size;
    i += 1;
    {
        var j: c_int = 0;
        _ = &j;
        while (j < size) : (j += 1) {
            if ((tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, JSMN_STRING)) or (tokens[@bitCast(@as(isize, @intCast(i)))].size == @as(c_int, 0))) {
                return -@as(c_int, 1);
            }
            if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "offset") == @as(c_int, 0)) {
                i = cgltf_parse_json_float_array(tokens, i + @as(c_int, 1), json_chunk, @ptrCast(@alignCast(&out_texture_transform.*.offset)), 2);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "rotation") == @as(c_int, 0)) {
                i += 1;
                out_texture_transform.*.rotation = cgltf_json_to_float(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk);
                i += 1;
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "scale") == @as(c_int, 0)) {
                i = cgltf_parse_json_float_array(tokens, i + @as(c_int, 1), json_chunk, @ptrCast(@alignCast(&out_texture_transform.*.scale)), 2);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "texCoord") == @as(c_int, 0)) {
                i += 1;
                out_texture_transform.*.has_texcoord = 1;
                out_texture_transform.*.texcoord = cgltf_json_to_int(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk);
                i += 1;
            } else {
                i = cgltf_skip_json(tokens, i + @as(c_int, 1));
            }
            if (i < @as(c_int, 0)) {
                return i;
            }
        }
    }
    return i;
}
pub fn cgltf_parse_json_texture_view(arg_options: [*c]cgltf_options, arg_tokens: [*c]const jsmntok_t, arg_i: c_int, arg_json_chunk: [*c]const u8, arg_out_texture_view: [*c]cgltf_texture_view) callconv(.c) c_int {
    var options = arg_options;
    _ = &options;
    var tokens = arg_tokens;
    _ = &tokens;
    var i = arg_i;
    _ = &i;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var out_texture_view = arg_out_texture_view;
    _ = &out_texture_view;
    _ = &options;
    if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_OBJECT))) {
        return -@as(c_int, 1);
    }
    out_texture_view.*.scale = 1.0;
    cgltf_fill_float_array(@ptrCast(@alignCast(&out_texture_view.*.transform.scale)), 2, 1.0);
    var size: c_int = tokens[@bitCast(@as(isize, @intCast(i)))].size;
    _ = &size;
    i += 1;
    {
        var j: c_int = 0;
        _ = &j;
        while (j < size) : (j += 1) {
            if ((tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, JSMN_STRING)) or (tokens[@bitCast(@as(isize, @intCast(i)))].size == @as(c_int, 0))) {
                return -@as(c_int, 1);
            }
            if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "index") == @as(c_int, 0)) {
                i += 1;
                out_texture_view.*.texture = @ptrFromInt(@as(cgltf_size, @bitCast(@as(c_longlong, cgltf_json_to_int(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk)))) +% @as(cgltf_size, 1));
                i += 1;
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "texCoord") == @as(c_int, 0)) {
                i += 1;
                out_texture_view.*.texcoord = cgltf_json_to_int(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk);
                i += 1;
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "scale") == @as(c_int, 0)) {
                i += 1;
                out_texture_view.*.scale = cgltf_json_to_float(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk);
                i += 1;
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "strength") == @as(c_int, 0)) {
                i += 1;
                out_texture_view.*.scale = cgltf_json_to_float(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk);
                i += 1;
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "extensions") == @as(c_int, 0)) {
                i += 1;
                if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_OBJECT))) {
                    return -@as(c_int, 1);
                }
                var extensions_size: c_int = tokens[@bitCast(@as(isize, @intCast(i)))].size;
                _ = &extensions_size;
                i += 1;
                {
                    var k: c_int = 0;
                    _ = &k;
                    while (k < extensions_size) : (k += 1) {
                        if ((tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, JSMN_STRING)) or (tokens[@bitCast(@as(isize, @intCast(i)))].size == @as(c_int, 0))) {
                            return -@as(c_int, 1);
                        }
                        if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "KHR_texture_transform") == @as(c_int, 0)) {
                            out_texture_view.*.has_transform = 1;
                            i = cgltf_parse_json_texture_transform(tokens, i + @as(c_int, 1), json_chunk, &out_texture_view.*.transform);
                        } else {
                            i = cgltf_skip_json(tokens, i + @as(c_int, 1));
                        }
                        if (i < @as(c_int, 0)) {
                            return i;
                        }
                    }
                }
            } else {
                i = cgltf_skip_json(tokens, i + @as(c_int, 1));
            }
            if (i < @as(c_int, 0)) {
                return i;
            }
        }
    }
    return i;
}
pub fn cgltf_parse_json_pbr_metallic_roughness(arg_options: [*c]cgltf_options, arg_tokens: [*c]const jsmntok_t, arg_i: c_int, arg_json_chunk: [*c]const u8, arg_out_pbr: [*c]cgltf_pbr_metallic_roughness) callconv(.c) c_int {
    var options = arg_options;
    _ = &options;
    var tokens = arg_tokens;
    _ = &tokens;
    var i = arg_i;
    _ = &i;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var out_pbr = arg_out_pbr;
    _ = &out_pbr;
    if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_OBJECT))) {
        return -@as(c_int, 1);
    }
    var size: c_int = tokens[@bitCast(@as(isize, @intCast(i)))].size;
    _ = &size;
    i += 1;
    {
        var j: c_int = 0;
        _ = &j;
        while (j < size) : (j += 1) {
            if ((tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, JSMN_STRING)) or (tokens[@bitCast(@as(isize, @intCast(i)))].size == @as(c_int, 0))) {
                return -@as(c_int, 1);
            }
            if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "metallicFactor") == @as(c_int, 0)) {
                i += 1;
                out_pbr.*.metallic_factor = cgltf_json_to_float(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk);
                i += 1;
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "roughnessFactor") == @as(c_int, 0)) {
                i += 1;
                out_pbr.*.roughness_factor = cgltf_json_to_float(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk);
                i += 1;
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "baseColorFactor") == @as(c_int, 0)) {
                i = cgltf_parse_json_float_array(tokens, i + @as(c_int, 1), json_chunk, @ptrCast(@alignCast(&out_pbr.*.base_color_factor)), 4);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "baseColorTexture") == @as(c_int, 0)) {
                i = cgltf_parse_json_texture_view(options, tokens, i + @as(c_int, 1), json_chunk, &out_pbr.*.base_color_texture);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "metallicRoughnessTexture") == @as(c_int, 0)) {
                i = cgltf_parse_json_texture_view(options, tokens, i + @as(c_int, 1), json_chunk, &out_pbr.*.metallic_roughness_texture);
            } else {
                i = cgltf_skip_json(tokens, i + @as(c_int, 1));
            }
            if (i < @as(c_int, 0)) {
                return i;
            }
        }
    }
    return i;
}
pub fn cgltf_parse_json_pbr_specular_glossiness(arg_options: [*c]cgltf_options, arg_tokens: [*c]const jsmntok_t, arg_i: c_int, arg_json_chunk: [*c]const u8, arg_out_pbr: [*c]cgltf_pbr_specular_glossiness) callconv(.c) c_int {
    var options = arg_options;
    _ = &options;
    var tokens = arg_tokens;
    _ = &tokens;
    var i = arg_i;
    _ = &i;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var out_pbr = arg_out_pbr;
    _ = &out_pbr;
    if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_OBJECT))) {
        return -@as(c_int, 1);
    }
    var size: c_int = tokens[@bitCast(@as(isize, @intCast(i)))].size;
    _ = &size;
    i += 1;
    {
        var j: c_int = 0;
        _ = &j;
        while (j < size) : (j += 1) {
            if ((tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, JSMN_STRING)) or (tokens[@bitCast(@as(isize, @intCast(i)))].size == @as(c_int, 0))) {
                return -@as(c_int, 1);
            }
            if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "diffuseFactor") == @as(c_int, 0)) {
                i = cgltf_parse_json_float_array(tokens, i + @as(c_int, 1), json_chunk, @ptrCast(@alignCast(&out_pbr.*.diffuse_factor)), 4);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "specularFactor") == @as(c_int, 0)) {
                i = cgltf_parse_json_float_array(tokens, i + @as(c_int, 1), json_chunk, @ptrCast(@alignCast(&out_pbr.*.specular_factor)), 3);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "glossinessFactor") == @as(c_int, 0)) {
                i += 1;
                out_pbr.*.glossiness_factor = cgltf_json_to_float(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk);
                i += 1;
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "diffuseTexture") == @as(c_int, 0)) {
                i = cgltf_parse_json_texture_view(options, tokens, i + @as(c_int, 1), json_chunk, &out_pbr.*.diffuse_texture);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "specularGlossinessTexture") == @as(c_int, 0)) {
                i = cgltf_parse_json_texture_view(options, tokens, i + @as(c_int, 1), json_chunk, &out_pbr.*.specular_glossiness_texture);
            } else {
                i = cgltf_skip_json(tokens, i + @as(c_int, 1));
            }
            if (i < @as(c_int, 0)) {
                return i;
            }
        }
    }
    return i;
}
pub fn cgltf_parse_json_clearcoat(arg_options: [*c]cgltf_options, arg_tokens: [*c]const jsmntok_t, arg_i: c_int, arg_json_chunk: [*c]const u8, arg_out_clearcoat: [*c]cgltf_clearcoat) callconv(.c) c_int {
    var options = arg_options;
    _ = &options;
    var tokens = arg_tokens;
    _ = &tokens;
    var i = arg_i;
    _ = &i;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var out_clearcoat = arg_out_clearcoat;
    _ = &out_clearcoat;
    if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_OBJECT))) {
        return -@as(c_int, 1);
    }
    var size: c_int = tokens[@bitCast(@as(isize, @intCast(i)))].size;
    _ = &size;
    i += 1;
    {
        var j: c_int = 0;
        _ = &j;
        while (j < size) : (j += 1) {
            if ((tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, JSMN_STRING)) or (tokens[@bitCast(@as(isize, @intCast(i)))].size == @as(c_int, 0))) {
                return -@as(c_int, 1);
            }
            if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "clearcoatFactor") == @as(c_int, 0)) {
                i += 1;
                out_clearcoat.*.clearcoat_factor = cgltf_json_to_float(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk);
                i += 1;
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "clearcoatRoughnessFactor") == @as(c_int, 0)) {
                i += 1;
                out_clearcoat.*.clearcoat_roughness_factor = cgltf_json_to_float(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk);
                i += 1;
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "clearcoatTexture") == @as(c_int, 0)) {
                i = cgltf_parse_json_texture_view(options, tokens, i + @as(c_int, 1), json_chunk, &out_clearcoat.*.clearcoat_texture);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "clearcoatRoughnessTexture") == @as(c_int, 0)) {
                i = cgltf_parse_json_texture_view(options, tokens, i + @as(c_int, 1), json_chunk, &out_clearcoat.*.clearcoat_roughness_texture);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "clearcoatNormalTexture") == @as(c_int, 0)) {
                i = cgltf_parse_json_texture_view(options, tokens, i + @as(c_int, 1), json_chunk, &out_clearcoat.*.clearcoat_normal_texture);
            } else {
                i = cgltf_skip_json(tokens, i + @as(c_int, 1));
            }
            if (i < @as(c_int, 0)) {
                return i;
            }
        }
    }
    return i;
}
pub fn cgltf_parse_json_ior(arg_tokens: [*c]const jsmntok_t, arg_i: c_int, arg_json_chunk: [*c]const u8, arg_out_ior: [*c]cgltf_ior) callconv(.c) c_int {
    var tokens = arg_tokens;
    _ = &tokens;
    var i = arg_i;
    _ = &i;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var out_ior = arg_out_ior;
    _ = &out_ior;
    if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_OBJECT))) {
        return -@as(c_int, 1);
    }
    var size: c_int = tokens[@bitCast(@as(isize, @intCast(i)))].size;
    _ = &size;
    i += 1;
    out_ior.*.ior = 1.5;
    {
        var j: c_int = 0;
        _ = &j;
        while (j < size) : (j += 1) {
            if ((tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, JSMN_STRING)) or (tokens[@bitCast(@as(isize, @intCast(i)))].size == @as(c_int, 0))) {
                return -@as(c_int, 1);
            }
            if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "ior") == @as(c_int, 0)) {
                i += 1;
                out_ior.*.ior = cgltf_json_to_float(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk);
                i += 1;
            } else {
                i = cgltf_skip_json(tokens, i + @as(c_int, 1));
            }
            if (i < @as(c_int, 0)) {
                return i;
            }
        }
    }
    return i;
}
pub fn cgltf_parse_json_specular(arg_options: [*c]cgltf_options, arg_tokens: [*c]const jsmntok_t, arg_i: c_int, arg_json_chunk: [*c]const u8, arg_out_specular: [*c]cgltf_specular) callconv(.c) c_int {
    var options = arg_options;
    _ = &options;
    var tokens = arg_tokens;
    _ = &tokens;
    var i = arg_i;
    _ = &i;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var out_specular = arg_out_specular;
    _ = &out_specular;
    if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_OBJECT))) {
        return -@as(c_int, 1);
    }
    var size: c_int = tokens[@bitCast(@as(isize, @intCast(i)))].size;
    _ = &size;
    i += 1;
    out_specular.*.specular_factor = 1.0;
    cgltf_fill_float_array(@ptrCast(@alignCast(&out_specular.*.specular_color_factor)), 3, 1.0);
    {
        var j: c_int = 0;
        _ = &j;
        while (j < size) : (j += 1) {
            if ((tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, JSMN_STRING)) or (tokens[@bitCast(@as(isize, @intCast(i)))].size == @as(c_int, 0))) {
                return -@as(c_int, 1);
            }
            if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "specularFactor") == @as(c_int, 0)) {
                i += 1;
                out_specular.*.specular_factor = cgltf_json_to_float(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk);
                i += 1;
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "specularColorFactor") == @as(c_int, 0)) {
                i = cgltf_parse_json_float_array(tokens, i + @as(c_int, 1), json_chunk, @ptrCast(@alignCast(&out_specular.*.specular_color_factor)), 3);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "specularTexture") == @as(c_int, 0)) {
                i = cgltf_parse_json_texture_view(options, tokens, i + @as(c_int, 1), json_chunk, &out_specular.*.specular_texture);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "specularColorTexture") == @as(c_int, 0)) {
                i = cgltf_parse_json_texture_view(options, tokens, i + @as(c_int, 1), json_chunk, &out_specular.*.specular_color_texture);
            } else {
                i = cgltf_skip_json(tokens, i + @as(c_int, 1));
            }
            if (i < @as(c_int, 0)) {
                return i;
            }
        }
    }
    return i;
}
pub fn cgltf_parse_json_transmission(arg_options: [*c]cgltf_options, arg_tokens: [*c]const jsmntok_t, arg_i: c_int, arg_json_chunk: [*c]const u8, arg_out_transmission: [*c]cgltf_transmission) callconv(.c) c_int {
    var options = arg_options;
    _ = &options;
    var tokens = arg_tokens;
    _ = &tokens;
    var i = arg_i;
    _ = &i;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var out_transmission = arg_out_transmission;
    _ = &out_transmission;
    if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_OBJECT))) {
        return -@as(c_int, 1);
    }
    var size: c_int = tokens[@bitCast(@as(isize, @intCast(i)))].size;
    _ = &size;
    i += 1;
    {
        var j: c_int = 0;
        _ = &j;
        while (j < size) : (j += 1) {
            if ((tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, JSMN_STRING)) or (tokens[@bitCast(@as(isize, @intCast(i)))].size == @as(c_int, 0))) {
                return -@as(c_int, 1);
            }
            if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "transmissionFactor") == @as(c_int, 0)) {
                i += 1;
                out_transmission.*.transmission_factor = cgltf_json_to_float(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk);
                i += 1;
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "transmissionTexture") == @as(c_int, 0)) {
                i = cgltf_parse_json_texture_view(options, tokens, i + @as(c_int, 1), json_chunk, &out_transmission.*.transmission_texture);
            } else {
                i = cgltf_skip_json(tokens, i + @as(c_int, 1));
            }
            if (i < @as(c_int, 0)) {
                return i;
            }
        }
    }
    return i;
}
pub fn cgltf_parse_json_volume(arg_options: [*c]cgltf_options, arg_tokens: [*c]const jsmntok_t, arg_i: c_int, arg_json_chunk: [*c]const u8, arg_out_volume: [*c]cgltf_volume) callconv(.c) c_int {
    var options = arg_options;
    _ = &options;
    var tokens = arg_tokens;
    _ = &tokens;
    var i = arg_i;
    _ = &i;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var out_volume = arg_out_volume;
    _ = &out_volume;
    if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_OBJECT))) {
        return -@as(c_int, 1);
    }
    var size: c_int = tokens[@bitCast(@as(isize, @intCast(i)))].size;
    _ = &size;
    i += 1;
    {
        var j: c_int = 0;
        _ = &j;
        while (j < size) : (j += 1) {
            if ((tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, JSMN_STRING)) or (tokens[@bitCast(@as(isize, @intCast(i)))].size == @as(c_int, 0))) {
                return -@as(c_int, 1);
            }
            if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "thicknessFactor") == @as(c_int, 0)) {
                i += 1;
                out_volume.*.thickness_factor = cgltf_json_to_float(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk);
                i += 1;
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "thicknessTexture") == @as(c_int, 0)) {
                i = cgltf_parse_json_texture_view(options, tokens, i + @as(c_int, 1), json_chunk, &out_volume.*.thickness_texture);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "attenuationColor") == @as(c_int, 0)) {
                i = cgltf_parse_json_float_array(tokens, i + @as(c_int, 1), json_chunk, @ptrCast(@alignCast(&out_volume.*.attenuation_color)), 3);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "attenuationDistance") == @as(c_int, 0)) {
                i += 1;
                out_volume.*.attenuation_distance = cgltf_json_to_float(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk);
                i += 1;
            } else {
                i = cgltf_skip_json(tokens, i + @as(c_int, 1));
            }
            if (i < @as(c_int, 0)) {
                return i;
            }
        }
    }
    return i;
}
pub fn cgltf_parse_json_sheen(arg_options: [*c]cgltf_options, arg_tokens: [*c]const jsmntok_t, arg_i: c_int, arg_json_chunk: [*c]const u8, arg_out_sheen: [*c]cgltf_sheen) callconv(.c) c_int {
    var options = arg_options;
    _ = &options;
    var tokens = arg_tokens;
    _ = &tokens;
    var i = arg_i;
    _ = &i;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var out_sheen = arg_out_sheen;
    _ = &out_sheen;
    if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_OBJECT))) {
        return -@as(c_int, 1);
    }
    var size: c_int = tokens[@bitCast(@as(isize, @intCast(i)))].size;
    _ = &size;
    i += 1;
    {
        var j: c_int = 0;
        _ = &j;
        while (j < size) : (j += 1) {
            if ((tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, JSMN_STRING)) or (tokens[@bitCast(@as(isize, @intCast(i)))].size == @as(c_int, 0))) {
                return -@as(c_int, 1);
            }
            if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "sheenColorFactor") == @as(c_int, 0)) {
                i = cgltf_parse_json_float_array(tokens, i + @as(c_int, 1), json_chunk, @ptrCast(@alignCast(&out_sheen.*.sheen_color_factor)), 3);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "sheenColorTexture") == @as(c_int, 0)) {
                i = cgltf_parse_json_texture_view(options, tokens, i + @as(c_int, 1), json_chunk, &out_sheen.*.sheen_color_texture);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "sheenRoughnessFactor") == @as(c_int, 0)) {
                i += 1;
                out_sheen.*.sheen_roughness_factor = cgltf_json_to_float(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk);
                i += 1;
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "sheenRoughnessTexture") == @as(c_int, 0)) {
                i = cgltf_parse_json_texture_view(options, tokens, i + @as(c_int, 1), json_chunk, &out_sheen.*.sheen_roughness_texture);
            } else {
                i = cgltf_skip_json(tokens, i + @as(c_int, 1));
            }
            if (i < @as(c_int, 0)) {
                return i;
            }
        }
    }
    return i;
}
pub fn cgltf_parse_json_emissive_strength(arg_tokens: [*c]const jsmntok_t, arg_i: c_int, arg_json_chunk: [*c]const u8, arg_out_emissive_strength: [*c]cgltf_emissive_strength) callconv(.c) c_int {
    var tokens = arg_tokens;
    _ = &tokens;
    var i = arg_i;
    _ = &i;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var out_emissive_strength = arg_out_emissive_strength;
    _ = &out_emissive_strength;
    if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_OBJECT))) {
        return -@as(c_int, 1);
    }
    var size: c_int = tokens[@bitCast(@as(isize, @intCast(i)))].size;
    _ = &size;
    i += 1;
    out_emissive_strength.*.emissive_strength = 1.0;
    {
        var j: c_int = 0;
        _ = &j;
        while (j < size) : (j += 1) {
            if ((tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, JSMN_STRING)) or (tokens[@bitCast(@as(isize, @intCast(i)))].size == @as(c_int, 0))) {
                return -@as(c_int, 1);
            }
            if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "emissiveStrength") == @as(c_int, 0)) {
                i += 1;
                out_emissive_strength.*.emissive_strength = cgltf_json_to_float(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk);
                i += 1;
            } else {
                i = cgltf_skip_json(tokens, i + @as(c_int, 1));
            }
            if (i < @as(c_int, 0)) {
                return i;
            }
        }
    }
    return i;
}
pub fn cgltf_parse_json_iridescence(arg_options: [*c]cgltf_options, arg_tokens: [*c]const jsmntok_t, arg_i: c_int, arg_json_chunk: [*c]const u8, arg_out_iridescence: [*c]cgltf_iridescence) callconv(.c) c_int {
    var options = arg_options;
    _ = &options;
    var tokens = arg_tokens;
    _ = &tokens;
    var i = arg_i;
    _ = &i;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var out_iridescence = arg_out_iridescence;
    _ = &out_iridescence;
    if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_OBJECT))) {
        return -@as(c_int, 1);
    }
    var size: c_int = tokens[@bitCast(@as(isize, @intCast(i)))].size;
    _ = &size;
    i += 1;
    out_iridescence.*.iridescence_ior = 1.3;
    out_iridescence.*.iridescence_thickness_min = 100.0;
    out_iridescence.*.iridescence_thickness_max = 400.0;
    {
        var j: c_int = 0;
        _ = &j;
        while (j < size) : (j += 1) {
            if ((tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, JSMN_STRING)) or (tokens[@bitCast(@as(isize, @intCast(i)))].size == @as(c_int, 0))) {
                return -@as(c_int, 1);
            }
            if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "iridescenceFactor") == @as(c_int, 0)) {
                i += 1;
                out_iridescence.*.iridescence_factor = cgltf_json_to_float(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk);
                i += 1;
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "iridescenceTexture") == @as(c_int, 0)) {
                i = cgltf_parse_json_texture_view(options, tokens, i + @as(c_int, 1), json_chunk, &out_iridescence.*.iridescence_texture);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "iridescenceIor") == @as(c_int, 0)) {
                i += 1;
                out_iridescence.*.iridescence_ior = cgltf_json_to_float(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk);
                i += 1;
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "iridescenceThicknessMinimum") == @as(c_int, 0)) {
                i += 1;
                out_iridescence.*.iridescence_thickness_min = cgltf_json_to_float(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk);
                i += 1;
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "iridescenceThicknessMaximum") == @as(c_int, 0)) {
                i += 1;
                out_iridescence.*.iridescence_thickness_max = cgltf_json_to_float(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk);
                i += 1;
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "iridescenceThicknessTexture") == @as(c_int, 0)) {
                i = cgltf_parse_json_texture_view(options, tokens, i + @as(c_int, 1), json_chunk, &out_iridescence.*.iridescence_thickness_texture);
            } else {
                i = cgltf_skip_json(tokens, i + @as(c_int, 1));
            }
            if (i < @as(c_int, 0)) {
                return i;
            }
        }
    }
    return i;
}
pub fn cgltf_parse_json_diffuse_transmission(arg_options: [*c]cgltf_options, arg_tokens: [*c]const jsmntok_t, arg_i: c_int, arg_json_chunk: [*c]const u8, arg_out_diff_transmission: [*c]cgltf_diffuse_transmission) callconv(.c) c_int {
    var options = arg_options;
    _ = &options;
    var tokens = arg_tokens;
    _ = &tokens;
    var i = arg_i;
    _ = &i;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var out_diff_transmission = arg_out_diff_transmission;
    _ = &out_diff_transmission;
    if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_OBJECT))) {
        return -@as(c_int, 1);
    }
    var size: c_int = tokens[@bitCast(@as(isize, @intCast(i)))].size;
    _ = &size;
    i += 1;
    cgltf_fill_float_array(@ptrCast(@alignCast(&out_diff_transmission.*.diffuse_transmission_color_factor)), 3, 1.0);
    out_diff_transmission.*.diffuse_transmission_factor = 0.0;
    {
        var j: c_int = 0;
        _ = &j;
        while (j < size) : (j += 1) {
            if ((tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, JSMN_STRING)) or (tokens[@bitCast(@as(isize, @intCast(i)))].size == @as(c_int, 0))) {
                return -@as(c_int, 1);
            }
            if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "diffuseTransmissionFactor") == @as(c_int, 0)) {
                i += 1;
                out_diff_transmission.*.diffuse_transmission_factor = cgltf_json_to_float(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk);
                i += 1;
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "diffuseTransmissionTexture") == @as(c_int, 0)) {
                i = cgltf_parse_json_texture_view(options, tokens, i + @as(c_int, 1), json_chunk, &out_diff_transmission.*.diffuse_transmission_texture);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "diffuseTransmissionColorFactor") == @as(c_int, 0)) {
                i = cgltf_parse_json_float_array(tokens, i + @as(c_int, 1), json_chunk, @ptrCast(@alignCast(&out_diff_transmission.*.diffuse_transmission_color_factor)), 3);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "diffuseTransmissionColorTexture") == @as(c_int, 0)) {
                i = cgltf_parse_json_texture_view(options, tokens, i + @as(c_int, 1), json_chunk, &out_diff_transmission.*.diffuse_transmission_color_texture);
            } else {
                i = cgltf_skip_json(tokens, i + @as(c_int, 1));
            }
            if (i < @as(c_int, 0)) {
                return i;
            }
        }
    }
    return i;
}
pub fn cgltf_parse_json_anisotropy(arg_options: [*c]cgltf_options, arg_tokens: [*c]const jsmntok_t, arg_i: c_int, arg_json_chunk: [*c]const u8, arg_out_anisotropy: [*c]cgltf_anisotropy) callconv(.c) c_int {
    var options = arg_options;
    _ = &options;
    var tokens = arg_tokens;
    _ = &tokens;
    var i = arg_i;
    _ = &i;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var out_anisotropy = arg_out_anisotropy;
    _ = &out_anisotropy;
    if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_OBJECT))) {
        return -@as(c_int, 1);
    }
    var size: c_int = tokens[@bitCast(@as(isize, @intCast(i)))].size;
    _ = &size;
    i += 1;
    {
        var j: c_int = 0;
        _ = &j;
        while (j < size) : (j += 1) {
            if ((tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, JSMN_STRING)) or (tokens[@bitCast(@as(isize, @intCast(i)))].size == @as(c_int, 0))) {
                return -@as(c_int, 1);
            }
            if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "anisotropyStrength") == @as(c_int, 0)) {
                i += 1;
                out_anisotropy.*.anisotropy_strength = cgltf_json_to_float(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk);
                i += 1;
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "anisotropyRotation") == @as(c_int, 0)) {
                i += 1;
                out_anisotropy.*.anisotropy_rotation = cgltf_json_to_float(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk);
                i += 1;
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "anisotropyTexture") == @as(c_int, 0)) {
                i = cgltf_parse_json_texture_view(options, tokens, i + @as(c_int, 1), json_chunk, &out_anisotropy.*.anisotropy_texture);
            } else {
                i = cgltf_skip_json(tokens, i + @as(c_int, 1));
            }
            if (i < @as(c_int, 0)) {
                return i;
            }
        }
    }
    return i;
}
pub fn cgltf_parse_json_dispersion(arg_tokens: [*c]const jsmntok_t, arg_i: c_int, arg_json_chunk: [*c]const u8, arg_out_dispersion: [*c]cgltf_dispersion) callconv(.c) c_int {
    var tokens = arg_tokens;
    _ = &tokens;
    var i = arg_i;
    _ = &i;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var out_dispersion = arg_out_dispersion;
    _ = &out_dispersion;
    if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_OBJECT))) {
        return -@as(c_int, 1);
    }
    var size: c_int = tokens[@bitCast(@as(isize, @intCast(i)))].size;
    _ = &size;
    i += 1;
    {
        var j: c_int = 0;
        _ = &j;
        while (j < size) : (j += 1) {
            if ((tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, JSMN_STRING)) or (tokens[@bitCast(@as(isize, @intCast(i)))].size == @as(c_int, 0))) {
                return -@as(c_int, 1);
            }
            if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "dispersion") == @as(c_int, 0)) {
                i += 1;
                out_dispersion.*.dispersion = cgltf_json_to_float(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk);
                i += 1;
            } else {
                i = cgltf_skip_json(tokens, i + @as(c_int, 1));
            }
            if (i < @as(c_int, 0)) {
                return i;
            }
        }
    }
    return i;
}
pub fn cgltf_parse_json_image(arg_options: [*c]cgltf_options, arg_tokens: [*c]const jsmntok_t, arg_i: c_int, arg_json_chunk: [*c]const u8, arg_out_image: [*c]cgltf_image) callconv(.c) c_int {
    var options = arg_options;
    _ = &options;
    var tokens = arg_tokens;
    _ = &tokens;
    var i = arg_i;
    _ = &i;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var out_image = arg_out_image;
    _ = &out_image;
    if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_OBJECT))) {
        return -@as(c_int, 1);
    }
    var size: c_int = tokens[@bitCast(@as(isize, @intCast(i)))].size;
    _ = &size;
    i += 1;
    {
        var j: c_int = 0;
        _ = &j;
        while (j < size) : (j += 1) {
            if ((tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, JSMN_STRING)) or (tokens[@bitCast(@as(isize, @intCast(i)))].size == @as(c_int, 0))) {
                return -@as(c_int, 1);
            }
            if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "uri") == @as(c_int, 0)) {
                i = cgltf_parse_json_string(options, tokens, i + @as(c_int, 1), json_chunk, &out_image.*.uri);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "bufferView") == @as(c_int, 0)) {
                i += 1;
                out_image.*.buffer_view = @ptrFromInt(@as(cgltf_size, @bitCast(@as(c_longlong, cgltf_json_to_int(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk)))) +% @as(cgltf_size, 1));
                i += 1;
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "mimeType") == @as(c_int, 0)) {
                i = cgltf_parse_json_string(options, tokens, i + @as(c_int, 1), json_chunk, &out_image.*.mime_type);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "name") == @as(c_int, 0)) {
                i = cgltf_parse_json_string(options, tokens, i + @as(c_int, 1), json_chunk, &out_image.*.name);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "extras") == @as(c_int, 0)) {
                i = cgltf_parse_json_extras(options, tokens, i + @as(c_int, 1), json_chunk, &out_image.*.extras);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "extensions") == @as(c_int, 0)) {
                i = cgltf_parse_json_unprocessed_extensions(options, tokens, i, json_chunk, &out_image.*.extensions_count, &out_image.*.extensions);
            } else {
                i = cgltf_skip_json(tokens, i + @as(c_int, 1));
            }
            if (i < @as(c_int, 0)) {
                return i;
            }
        }
    }
    return i;
}
pub fn cgltf_parse_json_sampler(arg_options: [*c]cgltf_options, arg_tokens: [*c]const jsmntok_t, arg_i: c_int, arg_json_chunk: [*c]const u8, arg_out_sampler: [*c]cgltf_sampler) callconv(.c) c_int {
    var options = arg_options;
    _ = &options;
    var tokens = arg_tokens;
    _ = &tokens;
    var i = arg_i;
    _ = &i;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var out_sampler = arg_out_sampler;
    _ = &out_sampler;
    _ = &options;
    if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_OBJECT))) {
        return -@as(c_int, 1);
    }
    out_sampler.*.wrap_s = cgltf_wrap_mode_repeat;
    out_sampler.*.wrap_t = cgltf_wrap_mode_repeat;
    var size: c_int = tokens[@bitCast(@as(isize, @intCast(i)))].size;
    _ = &size;
    i += 1;
    {
        var j: c_int = 0;
        _ = &j;
        while (j < size) : (j += 1) {
            if ((tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, JSMN_STRING)) or (tokens[@bitCast(@as(isize, @intCast(i)))].size == @as(c_int, 0))) {
                return -@as(c_int, 1);
            }
            if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "name") == @as(c_int, 0)) {
                i = cgltf_parse_json_string(options, tokens, i + @as(c_int, 1), json_chunk, &out_sampler.*.name);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "magFilter") == @as(c_int, 0)) {
                i += 1;
                out_sampler.*.mag_filter = @bitCast(cgltf_json_to_int(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk));
                i += 1;
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "minFilter") == @as(c_int, 0)) {
                i += 1;
                out_sampler.*.min_filter = @bitCast(cgltf_json_to_int(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk));
                i += 1;
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "wrapS") == @as(c_int, 0)) {
                i += 1;
                out_sampler.*.wrap_s = @bitCast(cgltf_json_to_int(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk));
                i += 1;
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "wrapT") == @as(c_int, 0)) {
                i += 1;
                out_sampler.*.wrap_t = @bitCast(cgltf_json_to_int(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk));
                i += 1;
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "extras") == @as(c_int, 0)) {
                i = cgltf_parse_json_extras(options, tokens, i + @as(c_int, 1), json_chunk, &out_sampler.*.extras);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "extensions") == @as(c_int, 0)) {
                i = cgltf_parse_json_unprocessed_extensions(options, tokens, i, json_chunk, &out_sampler.*.extensions_count, &out_sampler.*.extensions);
            } else {
                i = cgltf_skip_json(tokens, i + @as(c_int, 1));
            }
            if (i < @as(c_int, 0)) {
                return i;
            }
        }
    }
    return i;
}
pub fn cgltf_parse_json_texture(arg_options: [*c]cgltf_options, arg_tokens: [*c]const jsmntok_t, arg_i: c_int, arg_json_chunk: [*c]const u8, arg_out_texture: [*c]cgltf_texture) callconv(.c) c_int {
    var options = arg_options;
    _ = &options;
    var tokens = arg_tokens;
    _ = &tokens;
    var i = arg_i;
    _ = &i;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var out_texture = arg_out_texture;
    _ = &out_texture;
    if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_OBJECT))) {
        return -@as(c_int, 1);
    }
    var size: c_int = tokens[@bitCast(@as(isize, @intCast(i)))].size;
    _ = &size;
    i += 1;
    {
        var j: c_int = 0;
        _ = &j;
        while (j < size) : (j += 1) {
            if ((tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, JSMN_STRING)) or (tokens[@bitCast(@as(isize, @intCast(i)))].size == @as(c_int, 0))) {
                return -@as(c_int, 1);
            }
            if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "name") == @as(c_int, 0)) {
                i = cgltf_parse_json_string(options, tokens, i + @as(c_int, 1), json_chunk, &out_texture.*.name);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "sampler") == @as(c_int, 0)) {
                i += 1;
                out_texture.*.sampler = @ptrFromInt(@as(cgltf_size, @bitCast(@as(c_longlong, cgltf_json_to_int(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk)))) +% @as(cgltf_size, 1));
                i += 1;
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "source") == @as(c_int, 0)) {
                i += 1;
                out_texture.*.image = @ptrFromInt(@as(cgltf_size, @bitCast(@as(c_longlong, cgltf_json_to_int(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk)))) +% @as(cgltf_size, 1));
                i += 1;
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "extras") == @as(c_int, 0)) {
                i = cgltf_parse_json_extras(options, tokens, i + @as(c_int, 1), json_chunk, &out_texture.*.extras);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "extensions") == @as(c_int, 0)) {
                i += 1;
                if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_OBJECT))) {
                    return -@as(c_int, 1);
                }
                if (out_texture.*.extensions != null) {
                    return -@as(c_int, 1);
                }
                var extensions_size: c_int = tokens[@bitCast(@as(isize, @intCast(i)))].size;
                _ = &extensions_size;
                i += 1;
                out_texture.*.extensions = @ptrCast(@alignCast(cgltf_calloc(options, @sizeOf(cgltf_extension), @bitCast(@as(c_longlong, extensions_size)))));
                out_texture.*.extensions_count = 0;
                if (!(out_texture.*.extensions != null)) {
                    return -@as(c_int, 2);
                }
                {
                    var k: c_int = 0;
                    _ = &k;
                    while (k < extensions_size) : (k += 1) {
                        if ((tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, JSMN_STRING)) or (tokens[@bitCast(@as(isize, @intCast(i)))].size == @as(c_int, 0))) {
                            return -@as(c_int, 1);
                        }
                        if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "KHR_texture_basisu") == @as(c_int, 0)) {
                            out_texture.*.has_basisu = 1;
                            i += 1;
                            if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_OBJECT))) {
                                return -@as(c_int, 1);
                            }
                            var num_properties: c_int = tokens[@bitCast(@as(isize, @intCast(i)))].size;
                            _ = &num_properties;
                            i += 1;
                            {
                                var t: c_int = 0;
                                _ = &t;
                                while (t < num_properties) : (t += 1) {
                                    if ((tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, JSMN_STRING)) or (tokens[@bitCast(@as(isize, @intCast(i)))].size == @as(c_int, 0))) {
                                        return -@as(c_int, 1);
                                    }
                                    if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "source") == @as(c_int, 0)) {
                                        i += 1;
                                        out_texture.*.basisu_image = @ptrFromInt(@as(cgltf_size, @bitCast(@as(c_longlong, cgltf_json_to_int(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk)))) +% @as(cgltf_size, 1));
                                        i += 1;
                                    } else {
                                        i = cgltf_skip_json(tokens, i + @as(c_int, 1));
                                    }
                                    if (i < @as(c_int, 0)) {
                                        return i;
                                    }
                                }
                            }
                        } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "EXT_texture_webp") == @as(c_int, 0)) {
                            out_texture.*.has_webp = 1;
                            i += 1;
                            if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_OBJECT))) {
                                return -@as(c_int, 1);
                            }
                            var num_properties: c_int = tokens[@bitCast(@as(isize, @intCast(i)))].size;
                            _ = &num_properties;
                            i += 1;
                            {
                                var t: c_int = 0;
                                _ = &t;
                                while (t < num_properties) : (t += 1) {
                                    if ((tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, JSMN_STRING)) or (tokens[@bitCast(@as(isize, @intCast(i)))].size == @as(c_int, 0))) {
                                        return -@as(c_int, 1);
                                    }
                                    if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "source") == @as(c_int, 0)) {
                                        i += 1;
                                        out_texture.*.webp_image = @ptrFromInt(@as(cgltf_size, @bitCast(@as(c_longlong, cgltf_json_to_int(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk)))) +% @as(cgltf_size, 1));
                                        i += 1;
                                    } else {
                                        i = cgltf_skip_json(tokens, i + @as(c_int, 1));
                                    }
                                    if (i < @as(c_int, 0)) {
                                        return i;
                                    }
                                }
                            }
                        } else {
                            i = cgltf_parse_json_unprocessed_extension(options, tokens, i, json_chunk, &out_texture.*.extensions[
                                @intCast(blk: {
                                    const ref = &out_texture.*.extensions_count;
                                    const tmp = ref.*;
                                    ref.* +%= 1;
                                    break :blk tmp;
                                })
                            ]);
                        }
                        if (i < @as(c_int, 0)) {
                            return i;
                        }
                    }
                }
            } else {
                i = cgltf_skip_json(tokens, i + @as(c_int, 1));
            }
            if (i < @as(c_int, 0)) {
                return i;
            }
        }
    }
    return i;
}
pub fn cgltf_parse_json_material(arg_options: [*c]cgltf_options, arg_tokens: [*c]const jsmntok_t, arg_i: c_int, arg_json_chunk: [*c]const u8, arg_out_material: [*c]cgltf_material) callconv(.c) c_int {
    var options = arg_options;
    _ = &options;
    var tokens = arg_tokens;
    _ = &tokens;
    var i = arg_i;
    _ = &i;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var out_material = arg_out_material;
    _ = &out_material;
    if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_OBJECT))) {
        return -@as(c_int, 1);
    }
    cgltf_fill_float_array(@ptrCast(@alignCast(&out_material.*.pbr_metallic_roughness.base_color_factor)), 4, 1.0);
    out_material.*.pbr_metallic_roughness.metallic_factor = 1.0;
    out_material.*.pbr_metallic_roughness.roughness_factor = 1.0;
    cgltf_fill_float_array(@ptrCast(@alignCast(&out_material.*.pbr_specular_glossiness.diffuse_factor)), 4, 1.0);
    cgltf_fill_float_array(@ptrCast(@alignCast(&out_material.*.pbr_specular_glossiness.specular_factor)), 3, 1.0);
    out_material.*.pbr_specular_glossiness.glossiness_factor = 1.0;
    cgltf_fill_float_array(@ptrCast(@alignCast(&out_material.*.volume.attenuation_color)), 3, 1.0);
    out_material.*.volume.attenuation_distance = __FLT_MAX__;
    out_material.*.alpha_cutoff = 0.5;
    var size: c_int = tokens[@bitCast(@as(isize, @intCast(i)))].size;
    _ = &size;
    i += 1;
    {
        var j: c_int = 0;
        _ = &j;
        while (j < size) : (j += 1) {
            if ((tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, JSMN_STRING)) or (tokens[@bitCast(@as(isize, @intCast(i)))].size == @as(c_int, 0))) {
                return -@as(c_int, 1);
            }
            if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "name") == @as(c_int, 0)) {
                i = cgltf_parse_json_string(options, tokens, i + @as(c_int, 1), json_chunk, &out_material.*.name);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "pbrMetallicRoughness") == @as(c_int, 0)) {
                out_material.*.has_pbr_metallic_roughness = 1;
                i = cgltf_parse_json_pbr_metallic_roughness(options, tokens, i + @as(c_int, 1), json_chunk, &out_material.*.pbr_metallic_roughness);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "emissiveFactor") == @as(c_int, 0)) {
                i = cgltf_parse_json_float_array(tokens, i + @as(c_int, 1), json_chunk, @ptrCast(@alignCast(&out_material.*.emissive_factor)), 3);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "normalTexture") == @as(c_int, 0)) {
                i = cgltf_parse_json_texture_view(options, tokens, i + @as(c_int, 1), json_chunk, &out_material.*.normal_texture);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "occlusionTexture") == @as(c_int, 0)) {
                i = cgltf_parse_json_texture_view(options, tokens, i + @as(c_int, 1), json_chunk, &out_material.*.occlusion_texture);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "emissiveTexture") == @as(c_int, 0)) {
                i = cgltf_parse_json_texture_view(options, tokens, i + @as(c_int, 1), json_chunk, &out_material.*.emissive_texture);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "alphaMode") == @as(c_int, 0)) {
                i += 1;
                if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "OPAQUE") == @as(c_int, 0)) {
                    out_material.*.alpha_mode = cgltf_alpha_mode_opaque;
                } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "MASK") == @as(c_int, 0)) {
                    out_material.*.alpha_mode = cgltf_alpha_mode_mask;
                } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "BLEND") == @as(c_int, 0)) {
                    out_material.*.alpha_mode = cgltf_alpha_mode_blend;
                }
                i += 1;
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "alphaCutoff") == @as(c_int, 0)) {
                i += 1;
                out_material.*.alpha_cutoff = cgltf_json_to_float(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk);
                i += 1;
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "doubleSided") == @as(c_int, 0)) {
                i += 1;
                out_material.*.double_sided = cgltf_json_to_bool(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk);
                i += 1;
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "extras") == @as(c_int, 0)) {
                i = cgltf_parse_json_extras(options, tokens, i + @as(c_int, 1), json_chunk, &out_material.*.extras);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "extensions") == @as(c_int, 0)) {
                i += 1;
                if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_OBJECT))) {
                    return -@as(c_int, 1);
                }
                if (out_material.*.extensions != null) {
                    return -@as(c_int, 1);
                }
                var extensions_size: c_int = tokens[@bitCast(@as(isize, @intCast(i)))].size;
                _ = &extensions_size;
                i += 1;
                out_material.*.extensions = @ptrCast(@alignCast(cgltf_calloc(options, @sizeOf(cgltf_extension), @bitCast(@as(c_longlong, extensions_size)))));
                out_material.*.extensions_count = 0;
                if (!(out_material.*.extensions != null)) {
                    return -@as(c_int, 2);
                }
                {
                    var k: c_int = 0;
                    _ = &k;
                    while (k < extensions_size) : (k += 1) {
                        if ((tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, JSMN_STRING)) or (tokens[@bitCast(@as(isize, @intCast(i)))].size == @as(c_int, 0))) {
                            return -@as(c_int, 1);
                        }
                        if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "KHR_materials_pbrSpecularGlossiness") == @as(c_int, 0)) {
                            out_material.*.has_pbr_specular_glossiness = 1;
                            i = cgltf_parse_json_pbr_specular_glossiness(options, tokens, i + @as(c_int, 1), json_chunk, &out_material.*.pbr_specular_glossiness);
                        } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "KHR_materials_unlit") == @as(c_int, 0)) {
                            out_material.*.unlit = 1;
                            i = cgltf_skip_json(tokens, i + @as(c_int, 1));
                        } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "KHR_materials_clearcoat") == @as(c_int, 0)) {
                            out_material.*.has_clearcoat = 1;
                            i = cgltf_parse_json_clearcoat(options, tokens, i + @as(c_int, 1), json_chunk, &out_material.*.clearcoat);
                        } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "KHR_materials_ior") == @as(c_int, 0)) {
                            out_material.*.has_ior = 1;
                            i = cgltf_parse_json_ior(tokens, i + @as(c_int, 1), json_chunk, &out_material.*.ior);
                        } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "KHR_materials_specular") == @as(c_int, 0)) {
                            out_material.*.has_specular = 1;
                            i = cgltf_parse_json_specular(options, tokens, i + @as(c_int, 1), json_chunk, &out_material.*.specular);
                        } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "KHR_materials_transmission") == @as(c_int, 0)) {
                            out_material.*.has_transmission = 1;
                            i = cgltf_parse_json_transmission(options, tokens, i + @as(c_int, 1), json_chunk, &out_material.*.transmission);
                        } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "KHR_materials_volume") == @as(c_int, 0)) {
                            out_material.*.has_volume = 1;
                            i = cgltf_parse_json_volume(options, tokens, i + @as(c_int, 1), json_chunk, &out_material.*.volume);
                        } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "KHR_materials_sheen") == @as(c_int, 0)) {
                            out_material.*.has_sheen = 1;
                            i = cgltf_parse_json_sheen(options, tokens, i + @as(c_int, 1), json_chunk, &out_material.*.sheen);
                        } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "KHR_materials_emissive_strength") == @as(c_int, 0)) {
                            out_material.*.has_emissive_strength = 1;
                            i = cgltf_parse_json_emissive_strength(tokens, i + @as(c_int, 1), json_chunk, &out_material.*.emissive_strength);
                        } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "KHR_materials_iridescence") == @as(c_int, 0)) {
                            out_material.*.has_iridescence = 1;
                            i = cgltf_parse_json_iridescence(options, tokens, i + @as(c_int, 1), json_chunk, &out_material.*.iridescence);
                        } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "KHR_materials_diffuse_transmission") == @as(c_int, 0)) {
                            out_material.*.has_diffuse_transmission = 1;
                            i = cgltf_parse_json_diffuse_transmission(options, tokens, i + @as(c_int, 1), json_chunk, &out_material.*.diffuse_transmission);
                        } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "KHR_materials_anisotropy") == @as(c_int, 0)) {
                            out_material.*.has_anisotropy = 1;
                            i = cgltf_parse_json_anisotropy(options, tokens, i + @as(c_int, 1), json_chunk, &out_material.*.anisotropy);
                        } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "KHR_materials_dispersion") == @as(c_int, 0)) {
                            out_material.*.has_dispersion = 1;
                            i = cgltf_parse_json_dispersion(tokens, i + @as(c_int, 1), json_chunk, &out_material.*.dispersion);
                        } else {
                            i = cgltf_parse_json_unprocessed_extension(options, tokens, i, json_chunk, &out_material.*.extensions[
                                @intCast(blk: {
                                    const ref = &out_material.*.extensions_count;
                                    const tmp = ref.*;
                                    ref.* +%= 1;
                                    break :blk tmp;
                                })
                            ]);
                        }
                        if (i < @as(c_int, 0)) {
                            return i;
                        }
                    }
                }
            } else {
                i = cgltf_skip_json(tokens, i + @as(c_int, 1));
            }
            if (i < @as(c_int, 0)) {
                return i;
            }
        }
    }
    return i;
}
pub fn cgltf_parse_json_accessors(arg_options: [*c]cgltf_options, arg_tokens: [*c]const jsmntok_t, arg_i: c_int, arg_json_chunk: [*c]const u8, arg_out_data: [*c]cgltf_data) callconv(.c) c_int {
    var options = arg_options;
    _ = &options;
    var tokens = arg_tokens;
    _ = &tokens;
    var i = arg_i;
    _ = &i;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var out_data = arg_out_data;
    _ = &out_data;
    i = cgltf_parse_json_array(options, tokens, i, json_chunk, @sizeOf(cgltf_accessor), @ptrCast(@alignCast(&out_data.*.accessors)), &out_data.*.accessors_count);
    if (i < @as(c_int, 0)) {
        return i;
    }
    {
        var j: cgltf_size = 0;
        _ = &j;
        while (j < out_data.*.accessors_count) : (j +%= 1) {
            i = cgltf_parse_json_accessor(options, tokens, i, json_chunk, &out_data.*.accessors[@intCast(j)]);
            if (i < @as(c_int, 0)) {
                return i;
            }
        }
    }
    return i;
}
pub fn cgltf_parse_json_materials(arg_options: [*c]cgltf_options, arg_tokens: [*c]const jsmntok_t, arg_i: c_int, arg_json_chunk: [*c]const u8, arg_out_data: [*c]cgltf_data) callconv(.c) c_int {
    var options = arg_options;
    _ = &options;
    var tokens = arg_tokens;
    _ = &tokens;
    var i = arg_i;
    _ = &i;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var out_data = arg_out_data;
    _ = &out_data;
    i = cgltf_parse_json_array(options, tokens, i, json_chunk, @sizeOf(cgltf_material), @ptrCast(@alignCast(&out_data.*.materials)), &out_data.*.materials_count);
    if (i < @as(c_int, 0)) {
        return i;
    }
    {
        var j: cgltf_size = 0;
        _ = &j;
        while (j < out_data.*.materials_count) : (j +%= 1) {
            i = cgltf_parse_json_material(options, tokens, i, json_chunk, &out_data.*.materials[@intCast(j)]);
            if (i < @as(c_int, 0)) {
                return i;
            }
        }
    }
    return i;
}
pub fn cgltf_parse_json_images(arg_options: [*c]cgltf_options, arg_tokens: [*c]const jsmntok_t, arg_i: c_int, arg_json_chunk: [*c]const u8, arg_out_data: [*c]cgltf_data) callconv(.c) c_int {
    var options = arg_options;
    _ = &options;
    var tokens = arg_tokens;
    _ = &tokens;
    var i = arg_i;
    _ = &i;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var out_data = arg_out_data;
    _ = &out_data;
    i = cgltf_parse_json_array(options, tokens, i, json_chunk, @sizeOf(cgltf_image), @ptrCast(@alignCast(&out_data.*.images)), &out_data.*.images_count);
    if (i < @as(c_int, 0)) {
        return i;
    }
    {
        var j: cgltf_size = 0;
        _ = &j;
        while (j < out_data.*.images_count) : (j +%= 1) {
            i = cgltf_parse_json_image(options, tokens, i, json_chunk, &out_data.*.images[@intCast(j)]);
            if (i < @as(c_int, 0)) {
                return i;
            }
        }
    }
    return i;
}
pub fn cgltf_parse_json_textures(arg_options: [*c]cgltf_options, arg_tokens: [*c]const jsmntok_t, arg_i: c_int, arg_json_chunk: [*c]const u8, arg_out_data: [*c]cgltf_data) callconv(.c) c_int {
    var options = arg_options;
    _ = &options;
    var tokens = arg_tokens;
    _ = &tokens;
    var i = arg_i;
    _ = &i;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var out_data = arg_out_data;
    _ = &out_data;
    i = cgltf_parse_json_array(options, tokens, i, json_chunk, @sizeOf(cgltf_texture), @ptrCast(@alignCast(&out_data.*.textures)), &out_data.*.textures_count);
    if (i < @as(c_int, 0)) {
        return i;
    }
    {
        var j: cgltf_size = 0;
        _ = &j;
        while (j < out_data.*.textures_count) : (j +%= 1) {
            i = cgltf_parse_json_texture(options, tokens, i, json_chunk, &out_data.*.textures[@intCast(j)]);
            if (i < @as(c_int, 0)) {
                return i;
            }
        }
    }
    return i;
}
pub fn cgltf_parse_json_samplers(arg_options: [*c]cgltf_options, arg_tokens: [*c]const jsmntok_t, arg_i: c_int, arg_json_chunk: [*c]const u8, arg_out_data: [*c]cgltf_data) callconv(.c) c_int {
    var options = arg_options;
    _ = &options;
    var tokens = arg_tokens;
    _ = &tokens;
    var i = arg_i;
    _ = &i;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var out_data = arg_out_data;
    _ = &out_data;
    i = cgltf_parse_json_array(options, tokens, i, json_chunk, @sizeOf(cgltf_sampler), @ptrCast(@alignCast(&out_data.*.samplers)), &out_data.*.samplers_count);
    if (i < @as(c_int, 0)) {
        return i;
    }
    {
        var j: cgltf_size = 0;
        _ = &j;
        while (j < out_data.*.samplers_count) : (j +%= 1) {
            i = cgltf_parse_json_sampler(options, tokens, i, json_chunk, &out_data.*.samplers[@intCast(j)]);
            if (i < @as(c_int, 0)) {
                return i;
            }
        }
    }
    return i;
}
pub fn cgltf_parse_json_meshopt_compression(arg_options: [*c]cgltf_options, arg_tokens: [*c]const jsmntok_t, arg_i: c_int, arg_json_chunk: [*c]const u8, arg_out_meshopt_compression: [*c]cgltf_meshopt_compression) callconv(.c) c_int {
    var options = arg_options;
    _ = &options;
    var tokens = arg_tokens;
    _ = &tokens;
    var i = arg_i;
    _ = &i;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var out_meshopt_compression = arg_out_meshopt_compression;
    _ = &out_meshopt_compression;
    _ = &options;
    if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_OBJECT))) {
        return -@as(c_int, 1);
    }
    var size: c_int = tokens[@bitCast(@as(isize, @intCast(i)))].size;
    _ = &size;
    i += 1;
    {
        var j: c_int = 0;
        _ = &j;
        while (j < size) : (j += 1) {
            if ((tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, JSMN_STRING)) or (tokens[@bitCast(@as(isize, @intCast(i)))].size == @as(c_int, 0))) {
                return -@as(c_int, 1);
            }
            if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "buffer") == @as(c_int, 0)) {
                i += 1;
                out_meshopt_compression.*.buffer = @ptrFromInt(@as(cgltf_size, @bitCast(@as(c_longlong, cgltf_json_to_int(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk)))) +% @as(cgltf_size, 1));
                i += 1;
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "byteOffset") == @as(c_int, 0)) {
                i += 1;
                out_meshopt_compression.*.offset = cgltf_json_to_size(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk);
                i += 1;
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "byteLength") == @as(c_int, 0)) {
                i += 1;
                out_meshopt_compression.*.size = cgltf_json_to_size(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk);
                i += 1;
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "byteStride") == @as(c_int, 0)) {
                i += 1;
                out_meshopt_compression.*.stride = cgltf_json_to_size(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk);
                i += 1;
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "count") == @as(c_int, 0)) {
                i += 1;
                out_meshopt_compression.*.count = cgltf_json_to_size(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk);
                i += 1;
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "mode") == @as(c_int, 0)) {
                i += 1;
                if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "ATTRIBUTES") == @as(c_int, 0)) {
                    out_meshopt_compression.*.mode = cgltf_meshopt_compression_mode_attributes;
                } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "TRIANGLES") == @as(c_int, 0)) {
                    out_meshopt_compression.*.mode = cgltf_meshopt_compression_mode_triangles;
                } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "INDICES") == @as(c_int, 0)) {
                    out_meshopt_compression.*.mode = cgltf_meshopt_compression_mode_indices;
                }
                i += 1;
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "filter") == @as(c_int, 0)) {
                i += 1;
                if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "NONE") == @as(c_int, 0)) {
                    out_meshopt_compression.*.filter = cgltf_meshopt_compression_filter_none;
                } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "OCTAHEDRAL") == @as(c_int, 0)) {
                    out_meshopt_compression.*.filter = cgltf_meshopt_compression_filter_octahedral;
                } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "QUATERNION") == @as(c_int, 0)) {
                    out_meshopt_compression.*.filter = cgltf_meshopt_compression_filter_quaternion;
                } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "EXPONENTIAL") == @as(c_int, 0)) {
                    out_meshopt_compression.*.filter = cgltf_meshopt_compression_filter_exponential;
                } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "COLOR") == @as(c_int, 0)) {
                    out_meshopt_compression.*.filter = cgltf_meshopt_compression_filter_color;
                }
                i += 1;
            } else {
                i = cgltf_skip_json(tokens, i + @as(c_int, 1));
            }
            if (i < @as(c_int, 0)) {
                return i;
            }
        }
    }
    return i;
}
pub fn cgltf_parse_json_buffer_view(arg_options: [*c]cgltf_options, arg_tokens: [*c]const jsmntok_t, arg_i: c_int, arg_json_chunk: [*c]const u8, arg_out_buffer_view: [*c]cgltf_buffer_view) callconv(.c) c_int {
    var options = arg_options;
    _ = &options;
    var tokens = arg_tokens;
    _ = &tokens;
    var i = arg_i;
    _ = &i;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var out_buffer_view = arg_out_buffer_view;
    _ = &out_buffer_view;
    if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_OBJECT))) {
        return -@as(c_int, 1);
    }
    var size: c_int = tokens[@bitCast(@as(isize, @intCast(i)))].size;
    _ = &size;
    i += 1;
    {
        var j: c_int = 0;
        _ = &j;
        while (j < size) : (j += 1) {
            if ((tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, JSMN_STRING)) or (tokens[@bitCast(@as(isize, @intCast(i)))].size == @as(c_int, 0))) {
                return -@as(c_int, 1);
            }
            if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "name") == @as(c_int, 0)) {
                i = cgltf_parse_json_string(options, tokens, i + @as(c_int, 1), json_chunk, &out_buffer_view.*.name);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "buffer") == @as(c_int, 0)) {
                i += 1;
                out_buffer_view.*.buffer = @ptrFromInt(@as(cgltf_size, @bitCast(@as(c_longlong, cgltf_json_to_int(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk)))) +% @as(cgltf_size, 1));
                i += 1;
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "byteOffset") == @as(c_int, 0)) {
                i += 1;
                out_buffer_view.*.offset = cgltf_json_to_size(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk);
                i += 1;
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "byteLength") == @as(c_int, 0)) {
                i += 1;
                out_buffer_view.*.size = cgltf_json_to_size(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk);
                i += 1;
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "byteStride") == @as(c_int, 0)) {
                i += 1;
                out_buffer_view.*.stride = cgltf_json_to_size(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk);
                i += 1;
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "target") == @as(c_int, 0)) {
                i += 1;
                var @"type": c_int = cgltf_json_to_int(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk);
                _ = &@"type";
                while (true) {
                    switch (@"type") {
                        @as(c_int, 34962) => {
                            @"type" = cgltf_buffer_view_type_vertices;
                            break;
                        },
                        @as(c_int, 34963) => {
                            @"type" = cgltf_buffer_view_type_indices;
                            break;
                        },
                        else => {
                            @"type" = cgltf_buffer_view_type_invalid;
                            break;
                        },
                    }
                    break;
                }
                out_buffer_view.*.type = @bitCast(@"type");
                i += 1;
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "extras") == @as(c_int, 0)) {
                i = cgltf_parse_json_extras(options, tokens, i + @as(c_int, 1), json_chunk, &out_buffer_view.*.extras);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "extensions") == @as(c_int, 0)) {
                i += 1;
                if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_OBJECT))) {
                    return -@as(c_int, 1);
                }
                if (out_buffer_view.*.extensions != null) {
                    return -@as(c_int, 1);
                }
                var extensions_size: c_int = tokens[@bitCast(@as(isize, @intCast(i)))].size;
                _ = &extensions_size;
                out_buffer_view.*.extensions_count = 0;
                out_buffer_view.*.extensions = @ptrCast(@alignCast(cgltf_calloc(options, @sizeOf(cgltf_extension), @bitCast(@as(c_longlong, extensions_size)))));
                if (!(out_buffer_view.*.extensions != null)) {
                    return -@as(c_int, 2);
                }
                i += 1;
                {
                    var k: c_int = 0;
                    _ = &k;
                    while (k < extensions_size) : (k += 1) {
                        if ((tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, JSMN_STRING)) or (tokens[@bitCast(@as(isize, @intCast(i)))].size == @as(c_int, 0))) {
                            return -@as(c_int, 1);
                        }
                        if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "EXT_meshopt_compression") == @as(c_int, 0)) {
                            out_buffer_view.*.has_meshopt_compression = 1;
                            i = cgltf_parse_json_meshopt_compression(options, tokens, i + @as(c_int, 1), json_chunk, &out_buffer_view.*.meshopt_compression);
                        } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "KHR_meshopt_compression") == @as(c_int, 0)) {
                            out_buffer_view.*.has_meshopt_compression = 1;
                            out_buffer_view.*.meshopt_compression.is_khr = 1;
                            i = cgltf_parse_json_meshopt_compression(options, tokens, i + @as(c_int, 1), json_chunk, &out_buffer_view.*.meshopt_compression);
                        } else {
                            i = cgltf_parse_json_unprocessed_extension(options, tokens, i, json_chunk, &out_buffer_view.*.extensions[
                                @intCast(blk: {
                                    const ref = &out_buffer_view.*.extensions_count;
                                    const tmp = ref.*;
                                    ref.* +%= 1;
                                    break :blk tmp;
                                })
                            ]);
                        }
                        if (i < @as(c_int, 0)) {
                            return i;
                        }
                    }
                }
            } else {
                i = cgltf_skip_json(tokens, i + @as(c_int, 1));
            }
            if (i < @as(c_int, 0)) {
                return i;
            }
        }
    }
    return i;
}
pub fn cgltf_parse_json_buffer_views(arg_options: [*c]cgltf_options, arg_tokens: [*c]const jsmntok_t, arg_i: c_int, arg_json_chunk: [*c]const u8, arg_out_data: [*c]cgltf_data) callconv(.c) c_int {
    var options = arg_options;
    _ = &options;
    var tokens = arg_tokens;
    _ = &tokens;
    var i = arg_i;
    _ = &i;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var out_data = arg_out_data;
    _ = &out_data;
    i = cgltf_parse_json_array(options, tokens, i, json_chunk, @sizeOf(cgltf_buffer_view), @ptrCast(@alignCast(&out_data.*.buffer_views)), &out_data.*.buffer_views_count);
    if (i < @as(c_int, 0)) {
        return i;
    }
    {
        var j: cgltf_size = 0;
        _ = &j;
        while (j < out_data.*.buffer_views_count) : (j +%= 1) {
            i = cgltf_parse_json_buffer_view(options, tokens, i, json_chunk, &out_data.*.buffer_views[@intCast(j)]);
            if (i < @as(c_int, 0)) {
                return i;
            }
        }
    }
    return i;
}
pub fn cgltf_parse_json_buffer(arg_options: [*c]cgltf_options, arg_tokens: [*c]const jsmntok_t, arg_i: c_int, arg_json_chunk: [*c]const u8, arg_out_buffer: [*c]cgltf_buffer) callconv(.c) c_int {
    var options = arg_options;
    _ = &options;
    var tokens = arg_tokens;
    _ = &tokens;
    var i = arg_i;
    _ = &i;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var out_buffer = arg_out_buffer;
    _ = &out_buffer;
    if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_OBJECT))) {
        return -@as(c_int, 1);
    }
    var size: c_int = tokens[@bitCast(@as(isize, @intCast(i)))].size;
    _ = &size;
    i += 1;
    {
        var j: c_int = 0;
        _ = &j;
        while (j < size) : (j += 1) {
            if ((tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, JSMN_STRING)) or (tokens[@bitCast(@as(isize, @intCast(i)))].size == @as(c_int, 0))) {
                return -@as(c_int, 1);
            }
            if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "name") == @as(c_int, 0)) {
                i = cgltf_parse_json_string(options, tokens, i + @as(c_int, 1), json_chunk, &out_buffer.*.name);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "byteLength") == @as(c_int, 0)) {
                i += 1;
                out_buffer.*.size = cgltf_json_to_size(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk);
                i += 1;
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "uri") == @as(c_int, 0)) {
                i = cgltf_parse_json_string(options, tokens, i + @as(c_int, 1), json_chunk, &out_buffer.*.uri);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "extras") == @as(c_int, 0)) {
                i = cgltf_parse_json_extras(options, tokens, i + @as(c_int, 1), json_chunk, &out_buffer.*.extras);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "extensions") == @as(c_int, 0)) {
                i = cgltf_parse_json_unprocessed_extensions(options, tokens, i, json_chunk, &out_buffer.*.extensions_count, &out_buffer.*.extensions);
            } else {
                i = cgltf_skip_json(tokens, i + @as(c_int, 1));
            }
            if (i < @as(c_int, 0)) {
                return i;
            }
        }
    }
    return i;
}
pub fn cgltf_parse_json_buffers(arg_options: [*c]cgltf_options, arg_tokens: [*c]const jsmntok_t, arg_i: c_int, arg_json_chunk: [*c]const u8, arg_out_data: [*c]cgltf_data) callconv(.c) c_int {
    var options = arg_options;
    _ = &options;
    var tokens = arg_tokens;
    _ = &tokens;
    var i = arg_i;
    _ = &i;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var out_data = arg_out_data;
    _ = &out_data;
    i = cgltf_parse_json_array(options, tokens, i, json_chunk, @sizeOf(cgltf_buffer), @ptrCast(@alignCast(&out_data.*.buffers)), &out_data.*.buffers_count);
    if (i < @as(c_int, 0)) {
        return i;
    }
    {
        var j: cgltf_size = 0;
        _ = &j;
        while (j < out_data.*.buffers_count) : (j +%= 1) {
            i = cgltf_parse_json_buffer(options, tokens, i, json_chunk, &out_data.*.buffers[@intCast(j)]);
            if (i < @as(c_int, 0)) {
                return i;
            }
        }
    }
    return i;
}
pub fn cgltf_parse_json_skin(arg_options: [*c]cgltf_options, arg_tokens: [*c]const jsmntok_t, arg_i: c_int, arg_json_chunk: [*c]const u8, arg_out_skin: [*c]cgltf_skin) callconv(.c) c_int {
    var options = arg_options;
    _ = &options;
    var tokens = arg_tokens;
    _ = &tokens;
    var i = arg_i;
    _ = &i;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var out_skin = arg_out_skin;
    _ = &out_skin;
    if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_OBJECT))) {
        return -@as(c_int, 1);
    }
    var size: c_int = tokens[@bitCast(@as(isize, @intCast(i)))].size;
    _ = &size;
    i += 1;
    {
        var j: c_int = 0;
        _ = &j;
        while (j < size) : (j += 1) {
            if ((tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, JSMN_STRING)) or (tokens[@bitCast(@as(isize, @intCast(i)))].size == @as(c_int, 0))) {
                return -@as(c_int, 1);
            }
            if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "name") == @as(c_int, 0)) {
                i = cgltf_parse_json_string(options, tokens, i + @as(c_int, 1), json_chunk, &out_skin.*.name);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "joints") == @as(c_int, 0)) {
                i = cgltf_parse_json_array(options, tokens, i + @as(c_int, 1), json_chunk, @sizeOf([*c]cgltf_node), @ptrCast(@alignCast(&out_skin.*.joints)), &out_skin.*.joints_count);
                if (i < @as(c_int, 0)) {
                    return i;
                }
                {
                    var k: cgltf_size = 0;
                    _ = &k;
                    while (k < out_skin.*.joints_count) : (k +%= 1) {
                        out_skin.*.joints[@intCast(k)] = @ptrFromInt(@as(cgltf_size, @bitCast(@as(c_longlong, cgltf_json_to_int(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk)))) +% @as(cgltf_size, 1));
                        i += 1;
                    }
                }
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "skeleton") == @as(c_int, 0)) {
                i += 1;
                if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_PRIMITIVE))) {
                    return -@as(c_int, 1);
                }
                out_skin.*.skeleton = @ptrFromInt(@as(cgltf_size, @bitCast(@as(c_longlong, cgltf_json_to_int(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk)))) +% @as(cgltf_size, 1));
                i += 1;
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "inverseBindMatrices") == @as(c_int, 0)) {
                i += 1;
                if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_PRIMITIVE))) {
                    return -@as(c_int, 1);
                }
                out_skin.*.inverse_bind_matrices = @ptrFromInt(@as(cgltf_size, @bitCast(@as(c_longlong, cgltf_json_to_int(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk)))) +% @as(cgltf_size, 1));
                i += 1;
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "extras") == @as(c_int, 0)) {
                i = cgltf_parse_json_extras(options, tokens, i + @as(c_int, 1), json_chunk, &out_skin.*.extras);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "extensions") == @as(c_int, 0)) {
                i = cgltf_parse_json_unprocessed_extensions(options, tokens, i, json_chunk, &out_skin.*.extensions_count, &out_skin.*.extensions);
            } else {
                i = cgltf_skip_json(tokens, i + @as(c_int, 1));
            }
            if (i < @as(c_int, 0)) {
                return i;
            }
        }
    }
    return i;
}
pub fn cgltf_parse_json_skins(arg_options: [*c]cgltf_options, arg_tokens: [*c]const jsmntok_t, arg_i: c_int, arg_json_chunk: [*c]const u8, arg_out_data: [*c]cgltf_data) callconv(.c) c_int {
    var options = arg_options;
    _ = &options;
    var tokens = arg_tokens;
    _ = &tokens;
    var i = arg_i;
    _ = &i;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var out_data = arg_out_data;
    _ = &out_data;
    i = cgltf_parse_json_array(options, tokens, i, json_chunk, @sizeOf(cgltf_skin), @ptrCast(@alignCast(&out_data.*.skins)), &out_data.*.skins_count);
    if (i < @as(c_int, 0)) {
        return i;
    }
    {
        var j: cgltf_size = 0;
        _ = &j;
        while (j < out_data.*.skins_count) : (j +%= 1) {
            i = cgltf_parse_json_skin(options, tokens, i, json_chunk, &out_data.*.skins[@intCast(j)]);
            if (i < @as(c_int, 0)) {
                return i;
            }
        }
    }
    return i;
}
pub fn cgltf_parse_json_camera(arg_options: [*c]cgltf_options, arg_tokens: [*c]const jsmntok_t, arg_i: c_int, arg_json_chunk: [*c]const u8, arg_out_camera: [*c]cgltf_camera) callconv(.c) c_int {
    var options = arg_options;
    _ = &options;
    var tokens = arg_tokens;
    _ = &tokens;
    var i = arg_i;
    _ = &i;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var out_camera = arg_out_camera;
    _ = &out_camera;
    if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_OBJECT))) {
        return -@as(c_int, 1);
    }
    var size: c_int = tokens[@bitCast(@as(isize, @intCast(i)))].size;
    _ = &size;
    i += 1;
    {
        var j: c_int = 0;
        _ = &j;
        while (j < size) : (j += 1) {
            if ((tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, JSMN_STRING)) or (tokens[@bitCast(@as(isize, @intCast(i)))].size == @as(c_int, 0))) {
                return -@as(c_int, 1);
            }
            if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "name") == @as(c_int, 0)) {
                i = cgltf_parse_json_string(options, tokens, i + @as(c_int, 1), json_chunk, &out_camera.*.name);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "perspective") == @as(c_int, 0)) {
                i += 1;
                if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_OBJECT))) {
                    return -@as(c_int, 1);
                }
                var data_size: c_int = tokens[@bitCast(@as(isize, @intCast(i)))].size;
                _ = &data_size;
                i += 1;
                if (out_camera.*.type != @as(cgltf_camera_type, cgltf_camera_type_invalid)) {
                    return -@as(c_int, 1);
                }
                out_camera.*.type = cgltf_camera_type_perspective;
                {
                    var k: c_int = 0;
                    _ = &k;
                    while (k < data_size) : (k += 1) {
                        if ((tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, JSMN_STRING)) or (tokens[@bitCast(@as(isize, @intCast(i)))].size == @as(c_int, 0))) {
                            return -@as(c_int, 1);
                        }
                        if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "aspectRatio") == @as(c_int, 0)) {
                            i += 1;
                            out_camera.*.data.perspective.has_aspect_ratio = 1;
                            out_camera.*.data.perspective.aspect_ratio = cgltf_json_to_float(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk);
                            i += 1;
                        } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "yfov") == @as(c_int, 0)) {
                            i += 1;
                            out_camera.*.data.perspective.yfov = cgltf_json_to_float(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk);
                            i += 1;
                        } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "zfar") == @as(c_int, 0)) {
                            i += 1;
                            out_camera.*.data.perspective.has_zfar = 1;
                            out_camera.*.data.perspective.zfar = cgltf_json_to_float(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk);
                            i += 1;
                        } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "znear") == @as(c_int, 0)) {
                            i += 1;
                            out_camera.*.data.perspective.znear = cgltf_json_to_float(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk);
                            i += 1;
                        } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "extras") == @as(c_int, 0)) {
                            i = cgltf_parse_json_extras(options, tokens, i + @as(c_int, 1), json_chunk, &out_camera.*.data.perspective.extras);
                        } else {
                            i = cgltf_skip_json(tokens, i + @as(c_int, 1));
                        }
                        if (i < @as(c_int, 0)) {
                            return i;
                        }
                    }
                }
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "orthographic") == @as(c_int, 0)) {
                i += 1;
                if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_OBJECT))) {
                    return -@as(c_int, 1);
                }
                var data_size: c_int = tokens[@bitCast(@as(isize, @intCast(i)))].size;
                _ = &data_size;
                i += 1;
                if (out_camera.*.type != @as(cgltf_camera_type, cgltf_camera_type_invalid)) {
                    return -@as(c_int, 1);
                }
                out_camera.*.type = cgltf_camera_type_orthographic;
                {
                    var k: c_int = 0;
                    _ = &k;
                    while (k < data_size) : (k += 1) {
                        if ((tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, JSMN_STRING)) or (tokens[@bitCast(@as(isize, @intCast(i)))].size == @as(c_int, 0))) {
                            return -@as(c_int, 1);
                        }
                        if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "xmag") == @as(c_int, 0)) {
                            i += 1;
                            out_camera.*.data.orthographic.xmag = cgltf_json_to_float(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk);
                            i += 1;
                        } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "ymag") == @as(c_int, 0)) {
                            i += 1;
                            out_camera.*.data.orthographic.ymag = cgltf_json_to_float(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk);
                            i += 1;
                        } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "zfar") == @as(c_int, 0)) {
                            i += 1;
                            out_camera.*.data.orthographic.zfar = cgltf_json_to_float(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk);
                            i += 1;
                        } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "znear") == @as(c_int, 0)) {
                            i += 1;
                            out_camera.*.data.orthographic.znear = cgltf_json_to_float(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk);
                            i += 1;
                        } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "extras") == @as(c_int, 0)) {
                            i = cgltf_parse_json_extras(options, tokens, i + @as(c_int, 1), json_chunk, &out_camera.*.data.orthographic.extras);
                        } else {
                            i = cgltf_skip_json(tokens, i + @as(c_int, 1));
                        }
                        if (i < @as(c_int, 0)) {
                            return i;
                        }
                    }
                }
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "extras") == @as(c_int, 0)) {
                i = cgltf_parse_json_extras(options, tokens, i + @as(c_int, 1), json_chunk, &out_camera.*.extras);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "extensions") == @as(c_int, 0)) {
                i = cgltf_parse_json_unprocessed_extensions(options, tokens, i, json_chunk, &out_camera.*.extensions_count, &out_camera.*.extensions);
            } else {
                i = cgltf_skip_json(tokens, i + @as(c_int, 1));
            }
            if (i < @as(c_int, 0)) {
                return i;
            }
        }
    }
    return i;
}
pub fn cgltf_parse_json_cameras(arg_options: [*c]cgltf_options, arg_tokens: [*c]const jsmntok_t, arg_i: c_int, arg_json_chunk: [*c]const u8, arg_out_data: [*c]cgltf_data) callconv(.c) c_int {
    var options = arg_options;
    _ = &options;
    var tokens = arg_tokens;
    _ = &tokens;
    var i = arg_i;
    _ = &i;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var out_data = arg_out_data;
    _ = &out_data;
    i = cgltf_parse_json_array(options, tokens, i, json_chunk, @sizeOf(cgltf_camera), @ptrCast(@alignCast(&out_data.*.cameras)), &out_data.*.cameras_count);
    if (i < @as(c_int, 0)) {
        return i;
    }
    {
        var j: cgltf_size = 0;
        _ = &j;
        while (j < out_data.*.cameras_count) : (j +%= 1) {
            i = cgltf_parse_json_camera(options, tokens, i, json_chunk, &out_data.*.cameras[@intCast(j)]);
            if (i < @as(c_int, 0)) {
                return i;
            }
        }
    }
    return i;
}
pub fn cgltf_parse_json_light(arg_options: [*c]cgltf_options, arg_tokens: [*c]const jsmntok_t, arg_i: c_int, arg_json_chunk: [*c]const u8, arg_out_light: [*c]cgltf_light) callconv(.c) c_int {
    var options = arg_options;
    _ = &options;
    var tokens = arg_tokens;
    _ = &tokens;
    var i = arg_i;
    _ = &i;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var out_light = arg_out_light;
    _ = &out_light;
    if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_OBJECT))) {
        return -@as(c_int, 1);
    }
    out_light.*.color[@as(c_int, 0)] = 1.0;
    out_light.*.color[@as(c_int, 1)] = 1.0;
    out_light.*.color[@as(c_int, 2)] = 1.0;
    out_light.*.intensity = 1.0;
    out_light.*.spot_inner_cone_angle = 0.0;
    out_light.*.spot_outer_cone_angle = @as(f32, 3.141593) / @as(f32, 4.0);
    var size: c_int = tokens[@bitCast(@as(isize, @intCast(i)))].size;
    _ = &size;
    i += 1;
    {
        var j: c_int = 0;
        _ = &j;
        while (j < size) : (j += 1) {
            if ((tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, JSMN_STRING)) or (tokens[@bitCast(@as(isize, @intCast(i)))].size == @as(c_int, 0))) {
                return -@as(c_int, 1);
            }
            if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "name") == @as(c_int, 0)) {
                i = cgltf_parse_json_string(options, tokens, i + @as(c_int, 1), json_chunk, &out_light.*.name);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "color") == @as(c_int, 0)) {
                i = cgltf_parse_json_float_array(tokens, i + @as(c_int, 1), json_chunk, @ptrCast(@alignCast(&out_light.*.color)), 3);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "intensity") == @as(c_int, 0)) {
                i += 1;
                out_light.*.intensity = cgltf_json_to_float(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk);
                i += 1;
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "type") == @as(c_int, 0)) {
                i += 1;
                if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "directional") == @as(c_int, 0)) {
                    out_light.*.type = cgltf_light_type_directional;
                } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "point") == @as(c_int, 0)) {
                    out_light.*.type = cgltf_light_type_point;
                } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "spot") == @as(c_int, 0)) {
                    out_light.*.type = cgltf_light_type_spot;
                }
                i += 1;
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "range") == @as(c_int, 0)) {
                i += 1;
                out_light.*.range = cgltf_json_to_float(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk);
                i += 1;
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "spot") == @as(c_int, 0)) {
                i += 1;
                if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_OBJECT))) {
                    return -@as(c_int, 1);
                }
                var data_size: c_int = tokens[@bitCast(@as(isize, @intCast(i)))].size;
                _ = &data_size;
                i += 1;
                {
                    var k: c_int = 0;
                    _ = &k;
                    while (k < data_size) : (k += 1) {
                        if ((tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, JSMN_STRING)) or (tokens[@bitCast(@as(isize, @intCast(i)))].size == @as(c_int, 0))) {
                            return -@as(c_int, 1);
                        }
                        if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "innerConeAngle") == @as(c_int, 0)) {
                            i += 1;
                            out_light.*.spot_inner_cone_angle = cgltf_json_to_float(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk);
                            i += 1;
                        } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "outerConeAngle") == @as(c_int, 0)) {
                            i += 1;
                            out_light.*.spot_outer_cone_angle = cgltf_json_to_float(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk);
                            i += 1;
                        } else {
                            i = cgltf_skip_json(tokens, i + @as(c_int, 1));
                        }
                        if (i < @as(c_int, 0)) {
                            return i;
                        }
                    }
                }
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "extras") == @as(c_int, 0)) {
                i = cgltf_parse_json_extras(options, tokens, i + @as(c_int, 1), json_chunk, &out_light.*.extras);
            } else {
                i = cgltf_skip_json(tokens, i + @as(c_int, 1));
            }
            if (i < @as(c_int, 0)) {
                return i;
            }
        }
    }
    return i;
}
pub fn cgltf_parse_json_lights(arg_options: [*c]cgltf_options, arg_tokens: [*c]const jsmntok_t, arg_i: c_int, arg_json_chunk: [*c]const u8, arg_out_data: [*c]cgltf_data) callconv(.c) c_int {
    var options = arg_options;
    _ = &options;
    var tokens = arg_tokens;
    _ = &tokens;
    var i = arg_i;
    _ = &i;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var out_data = arg_out_data;
    _ = &out_data;
    i = cgltf_parse_json_array(options, tokens, i, json_chunk, @sizeOf(cgltf_light), @ptrCast(@alignCast(&out_data.*.lights)), &out_data.*.lights_count);
    if (i < @as(c_int, 0)) {
        return i;
    }
    {
        var j: cgltf_size = 0;
        _ = &j;
        while (j < out_data.*.lights_count) : (j +%= 1) {
            i = cgltf_parse_json_light(options, tokens, i, json_chunk, &out_data.*.lights[@intCast(j)]);
            if (i < @as(c_int, 0)) {
                return i;
            }
        }
    }
    return i;
}
pub fn cgltf_parse_json_node(arg_options: [*c]cgltf_options, arg_tokens: [*c]const jsmntok_t, arg_i: c_int, arg_json_chunk: [*c]const u8, arg_out_node: [*c]cgltf_node) callconv(.c) c_int {
    var options = arg_options;
    _ = &options;
    var tokens = arg_tokens;
    _ = &tokens;
    var i = arg_i;
    _ = &i;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var out_node = arg_out_node;
    _ = &out_node;
    if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_OBJECT))) {
        return -@as(c_int, 1);
    }
    out_node.*.rotation[@as(c_int, 3)] = 1.0;
    out_node.*.scale[@as(c_int, 0)] = 1.0;
    out_node.*.scale[@as(c_int, 1)] = 1.0;
    out_node.*.scale[@as(c_int, 2)] = 1.0;
    out_node.*.matrix[@as(c_int, 0)] = 1.0;
    out_node.*.matrix[@as(c_int, 5)] = 1.0;
    out_node.*.matrix[@as(c_int, 10)] = 1.0;
    out_node.*.matrix[@as(c_int, 15)] = 1.0;
    var size: c_int = tokens[@bitCast(@as(isize, @intCast(i)))].size;
    _ = &size;
    i += 1;
    {
        var j: c_int = 0;
        _ = &j;
        while (j < size) : (j += 1) {
            if ((tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, JSMN_STRING)) or (tokens[@bitCast(@as(isize, @intCast(i)))].size == @as(c_int, 0))) {
                return -@as(c_int, 1);
            }
            if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "name") == @as(c_int, 0)) {
                i = cgltf_parse_json_string(options, tokens, i + @as(c_int, 1), json_chunk, &out_node.*.name);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "children") == @as(c_int, 0)) {
                i = cgltf_parse_json_array(options, tokens, i + @as(c_int, 1), json_chunk, @sizeOf([*c]cgltf_node), @ptrCast(@alignCast(&out_node.*.children)), &out_node.*.children_count);
                if (i < @as(c_int, 0)) {
                    return i;
                }
                {
                    var k: cgltf_size = 0;
                    _ = &k;
                    while (k < out_node.*.children_count) : (k +%= 1) {
                        out_node.*.children[@intCast(k)] = @ptrFromInt(@as(cgltf_size, @bitCast(@as(c_longlong, cgltf_json_to_int(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk)))) +% @as(cgltf_size, 1));
                        i += 1;
                    }
                }
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "mesh") == @as(c_int, 0)) {
                i += 1;
                if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_PRIMITIVE))) {
                    return -@as(c_int, 1);
                }
                out_node.*.mesh = @ptrFromInt(@as(cgltf_size, @bitCast(@as(c_longlong, cgltf_json_to_int(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk)))) +% @as(cgltf_size, 1));
                i += 1;
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "skin") == @as(c_int, 0)) {
                i += 1;
                if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_PRIMITIVE))) {
                    return -@as(c_int, 1);
                }
                out_node.*.skin = @ptrFromInt(@as(cgltf_size, @bitCast(@as(c_longlong, cgltf_json_to_int(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk)))) +% @as(cgltf_size, 1));
                i += 1;
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "camera") == @as(c_int, 0)) {
                i += 1;
                if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_PRIMITIVE))) {
                    return -@as(c_int, 1);
                }
                out_node.*.camera = @ptrFromInt(@as(cgltf_size, @bitCast(@as(c_longlong, cgltf_json_to_int(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk)))) +% @as(cgltf_size, 1));
                i += 1;
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "translation") == @as(c_int, 0)) {
                out_node.*.has_translation = 1;
                i = cgltf_parse_json_float_array(tokens, i + @as(c_int, 1), json_chunk, @ptrCast(@alignCast(&out_node.*.translation)), 3);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "rotation") == @as(c_int, 0)) {
                out_node.*.has_rotation = 1;
                i = cgltf_parse_json_float_array(tokens, i + @as(c_int, 1), json_chunk, @ptrCast(@alignCast(&out_node.*.rotation)), 4);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "scale") == @as(c_int, 0)) {
                out_node.*.has_scale = 1;
                i = cgltf_parse_json_float_array(tokens, i + @as(c_int, 1), json_chunk, @ptrCast(@alignCast(&out_node.*.scale)), 3);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "matrix") == @as(c_int, 0)) {
                out_node.*.has_matrix = 1;
                i = cgltf_parse_json_float_array(tokens, i + @as(c_int, 1), json_chunk, @ptrCast(@alignCast(&out_node.*.matrix)), 16);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "weights") == @as(c_int, 0)) {
                i = cgltf_parse_json_array(options, tokens, i + @as(c_int, 1), json_chunk, @sizeOf(cgltf_float), @ptrCast(@alignCast(&out_node.*.weights)), &out_node.*.weights_count);
                if (i < @as(c_int, 0)) {
                    return i;
                }
                i = cgltf_parse_json_float_array(tokens, i - @as(c_int, 1), json_chunk, out_node.*.weights, @bitCast(@as(c_uint, @truncate(out_node.*.weights_count))));
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "extras") == @as(c_int, 0)) {
                i = cgltf_parse_json_extras(options, tokens, i + @as(c_int, 1), json_chunk, &out_node.*.extras);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "extensions") == @as(c_int, 0)) {
                i += 1;
                if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_OBJECT))) {
                    return -@as(c_int, 1);
                }
                if (out_node.*.extensions != null) {
                    return -@as(c_int, 1);
                }
                var extensions_size: c_int = tokens[@bitCast(@as(isize, @intCast(i)))].size;
                _ = &extensions_size;
                out_node.*.extensions_count = 0;
                out_node.*.extensions = @ptrCast(@alignCast(cgltf_calloc(options, @sizeOf(cgltf_extension), @bitCast(@as(c_longlong, extensions_size)))));
                if (!(out_node.*.extensions != null)) {
                    return -@as(c_int, 2);
                }
                i += 1;
                {
                    var k: c_int = 0;
                    _ = &k;
                    while (k < extensions_size) : (k += 1) {
                        if ((tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, JSMN_STRING)) or (tokens[@bitCast(@as(isize, @intCast(i)))].size == @as(c_int, 0))) {
                            return -@as(c_int, 1);
                        }
                        if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "KHR_lights_punctual") == @as(c_int, 0)) {
                            i += 1;
                            if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_OBJECT))) {
                                return -@as(c_int, 1);
                            }
                            var data_size: c_int = tokens[@bitCast(@as(isize, @intCast(i)))].size;
                            _ = &data_size;
                            i += 1;
                            {
                                var m: c_int = 0;
                                _ = &m;
                                while (m < data_size) : (m += 1) {
                                    if ((tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, JSMN_STRING)) or (tokens[@bitCast(@as(isize, @intCast(i)))].size == @as(c_int, 0))) {
                                        return -@as(c_int, 1);
                                    }
                                    if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "light") == @as(c_int, 0)) {
                                        i += 1;
                                        if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_PRIMITIVE))) {
                                            return -@as(c_int, 1);
                                        }
                                        out_node.*.light = @ptrFromInt(@as(cgltf_size, @bitCast(@as(c_longlong, cgltf_json_to_int(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk)))) +% @as(cgltf_size, 1));
                                        i += 1;
                                    } else {
                                        i = cgltf_skip_json(tokens, i + @as(c_int, 1));
                                    }
                                    if (i < @as(c_int, 0)) {
                                        return i;
                                    }
                                }
                            }
                        } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "EXT_mesh_gpu_instancing") == @as(c_int, 0)) {
                            out_node.*.has_mesh_gpu_instancing = 1;
                            i = cgltf_parse_json_mesh_gpu_instancing(options, tokens, i + @as(c_int, 1), json_chunk, &out_node.*.mesh_gpu_instancing);
                        } else {
                            i = cgltf_parse_json_unprocessed_extension(options, tokens, i, json_chunk, &out_node.*.extensions[
                                @intCast(blk: {
                                    const ref = &out_node.*.extensions_count;
                                    const tmp = ref.*;
                                    ref.* +%= 1;
                                    break :blk tmp;
                                })
                            ]);
                        }
                        if (i < @as(c_int, 0)) {
                            return i;
                        }
                    }
                }
            } else {
                i = cgltf_skip_json(tokens, i + @as(c_int, 1));
            }
            if (i < @as(c_int, 0)) {
                return i;
            }
        }
    }
    return i;
}
pub fn cgltf_parse_json_nodes(arg_options: [*c]cgltf_options, arg_tokens: [*c]const jsmntok_t, arg_i: c_int, arg_json_chunk: [*c]const u8, arg_out_data: [*c]cgltf_data) callconv(.c) c_int {
    var options = arg_options;
    _ = &options;
    var tokens = arg_tokens;
    _ = &tokens;
    var i = arg_i;
    _ = &i;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var out_data = arg_out_data;
    _ = &out_data;
    i = cgltf_parse_json_array(options, tokens, i, json_chunk, @sizeOf(cgltf_node), @ptrCast(@alignCast(&out_data.*.nodes)), &out_data.*.nodes_count);
    if (i < @as(c_int, 0)) {
        return i;
    }
    {
        var j: cgltf_size = 0;
        _ = &j;
        while (j < out_data.*.nodes_count) : (j +%= 1) {
            i = cgltf_parse_json_node(options, tokens, i, json_chunk, &out_data.*.nodes[@intCast(j)]);
            if (i < @as(c_int, 0)) {
                return i;
            }
        }
    }
    return i;
}
pub fn cgltf_parse_json_scene(arg_options: [*c]cgltf_options, arg_tokens: [*c]const jsmntok_t, arg_i: c_int, arg_json_chunk: [*c]const u8, arg_out_scene: [*c]cgltf_scene) callconv(.c) c_int {
    var options = arg_options;
    _ = &options;
    var tokens = arg_tokens;
    _ = &tokens;
    var i = arg_i;
    _ = &i;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var out_scene = arg_out_scene;
    _ = &out_scene;
    if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_OBJECT))) {
        return -@as(c_int, 1);
    }
    var size: c_int = tokens[@bitCast(@as(isize, @intCast(i)))].size;
    _ = &size;
    i += 1;
    {
        var j: c_int = 0;
        _ = &j;
        while (j < size) : (j += 1) {
            if ((tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, JSMN_STRING)) or (tokens[@bitCast(@as(isize, @intCast(i)))].size == @as(c_int, 0))) {
                return -@as(c_int, 1);
            }
            if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "name") == @as(c_int, 0)) {
                i = cgltf_parse_json_string(options, tokens, i + @as(c_int, 1), json_chunk, &out_scene.*.name);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "nodes") == @as(c_int, 0)) {
                i = cgltf_parse_json_array(options, tokens, i + @as(c_int, 1), json_chunk, @sizeOf([*c]cgltf_node), @ptrCast(@alignCast(&out_scene.*.nodes)), &out_scene.*.nodes_count);
                if (i < @as(c_int, 0)) {
                    return i;
                }
                {
                    var k: cgltf_size = 0;
                    _ = &k;
                    while (k < out_scene.*.nodes_count) : (k +%= 1) {
                        out_scene.*.nodes[@intCast(k)] = @ptrFromInt(@as(cgltf_size, @bitCast(@as(c_longlong, cgltf_json_to_int(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk)))) +% @as(cgltf_size, 1));
                        i += 1;
                    }
                }
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "extras") == @as(c_int, 0)) {
                i = cgltf_parse_json_extras(options, tokens, i + @as(c_int, 1), json_chunk, &out_scene.*.extras);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "extensions") == @as(c_int, 0)) {
                i = cgltf_parse_json_unprocessed_extensions(options, tokens, i, json_chunk, &out_scene.*.extensions_count, &out_scene.*.extensions);
            } else {
                i = cgltf_skip_json(tokens, i + @as(c_int, 1));
            }
            if (i < @as(c_int, 0)) {
                return i;
            }
        }
    }
    return i;
}
pub fn cgltf_parse_json_scenes(arg_options: [*c]cgltf_options, arg_tokens: [*c]const jsmntok_t, arg_i: c_int, arg_json_chunk: [*c]const u8, arg_out_data: [*c]cgltf_data) callconv(.c) c_int {
    var options = arg_options;
    _ = &options;
    var tokens = arg_tokens;
    _ = &tokens;
    var i = arg_i;
    _ = &i;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var out_data = arg_out_data;
    _ = &out_data;
    i = cgltf_parse_json_array(options, tokens, i, json_chunk, @sizeOf(cgltf_scene), @ptrCast(@alignCast(&out_data.*.scenes)), &out_data.*.scenes_count);
    if (i < @as(c_int, 0)) {
        return i;
    }
    {
        var j: cgltf_size = 0;
        _ = &j;
        while (j < out_data.*.scenes_count) : (j +%= 1) {
            i = cgltf_parse_json_scene(options, tokens, i, json_chunk, &out_data.*.scenes[@intCast(j)]);
            if (i < @as(c_int, 0)) {
                return i;
            }
        }
    }
    return i;
}
pub fn cgltf_parse_json_animation_sampler(arg_options: [*c]cgltf_options, arg_tokens: [*c]const jsmntok_t, arg_i: c_int, arg_json_chunk: [*c]const u8, arg_out_sampler: [*c]cgltf_animation_sampler) callconv(.c) c_int {
    var options = arg_options;
    _ = &options;
    var tokens = arg_tokens;
    _ = &tokens;
    var i = arg_i;
    _ = &i;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var out_sampler = arg_out_sampler;
    _ = &out_sampler;
    _ = &options;
    if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_OBJECT))) {
        return -@as(c_int, 1);
    }
    var size: c_int = tokens[@bitCast(@as(isize, @intCast(i)))].size;
    _ = &size;
    i += 1;
    {
        var j: c_int = 0;
        _ = &j;
        while (j < size) : (j += 1) {
            if ((tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, JSMN_STRING)) or (tokens[@bitCast(@as(isize, @intCast(i)))].size == @as(c_int, 0))) {
                return -@as(c_int, 1);
            }
            if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "input") == @as(c_int, 0)) {
                i += 1;
                out_sampler.*.input = @ptrFromInt(@as(cgltf_size, @bitCast(@as(c_longlong, cgltf_json_to_int(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk)))) +% @as(cgltf_size, 1));
                i += 1;
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "output") == @as(c_int, 0)) {
                i += 1;
                out_sampler.*.output = @ptrFromInt(@as(cgltf_size, @bitCast(@as(c_longlong, cgltf_json_to_int(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk)))) +% @as(cgltf_size, 1));
                i += 1;
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "interpolation") == @as(c_int, 0)) {
                i += 1;
                if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "LINEAR") == @as(c_int, 0)) {
                    out_sampler.*.interpolation = cgltf_interpolation_type_linear;
                } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "STEP") == @as(c_int, 0)) {
                    out_sampler.*.interpolation = cgltf_interpolation_type_step;
                } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "CUBICSPLINE") == @as(c_int, 0)) {
                    out_sampler.*.interpolation = cgltf_interpolation_type_cubic_spline;
                }
                i += 1;
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "extras") == @as(c_int, 0)) {
                i = cgltf_parse_json_extras(options, tokens, i + @as(c_int, 1), json_chunk, &out_sampler.*.extras);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "extensions") == @as(c_int, 0)) {
                i = cgltf_parse_json_unprocessed_extensions(options, tokens, i, json_chunk, &out_sampler.*.extensions_count, &out_sampler.*.extensions);
            } else {
                i = cgltf_skip_json(tokens, i + @as(c_int, 1));
            }
            if (i < @as(c_int, 0)) {
                return i;
            }
        }
    }
    return i;
}
pub fn cgltf_parse_json_animation_channel(arg_options: [*c]cgltf_options, arg_tokens: [*c]const jsmntok_t, arg_i: c_int, arg_json_chunk: [*c]const u8, arg_out_channel: [*c]cgltf_animation_channel) callconv(.c) c_int {
    var options = arg_options;
    _ = &options;
    var tokens = arg_tokens;
    _ = &tokens;
    var i = arg_i;
    _ = &i;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var out_channel = arg_out_channel;
    _ = &out_channel;
    _ = &options;
    if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_OBJECT))) {
        return -@as(c_int, 1);
    }
    var size: c_int = tokens[@bitCast(@as(isize, @intCast(i)))].size;
    _ = &size;
    i += 1;
    {
        var j: c_int = 0;
        _ = &j;
        while (j < size) : (j += 1) {
            if ((tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, JSMN_STRING)) or (tokens[@bitCast(@as(isize, @intCast(i)))].size == @as(c_int, 0))) {
                return -@as(c_int, 1);
            }
            if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "sampler") == @as(c_int, 0)) {
                i += 1;
                out_channel.*.sampler = @ptrFromInt(@as(cgltf_size, @bitCast(@as(c_longlong, cgltf_json_to_int(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk)))) +% @as(cgltf_size, 1));
                i += 1;
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "target") == @as(c_int, 0)) {
                i += 1;
                if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_OBJECT))) {
                    return -@as(c_int, 1);
                }
                var target_size: c_int = tokens[@bitCast(@as(isize, @intCast(i)))].size;
                _ = &target_size;
                i += 1;
                {
                    var k: c_int = 0;
                    _ = &k;
                    while (k < target_size) : (k += 1) {
                        if ((tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, JSMN_STRING)) or (tokens[@bitCast(@as(isize, @intCast(i)))].size == @as(c_int, 0))) {
                            return -@as(c_int, 1);
                        }
                        if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "node") == @as(c_int, 0)) {
                            i += 1;
                            out_channel.*.target_node = @ptrFromInt(@as(cgltf_size, @bitCast(@as(c_longlong, cgltf_json_to_int(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk)))) +% @as(cgltf_size, 1));
                            i += 1;
                        } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "path") == @as(c_int, 0)) {
                            i += 1;
                            if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "translation") == @as(c_int, 0)) {
                                out_channel.*.target_path = cgltf_animation_path_type_translation;
                            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "rotation") == @as(c_int, 0)) {
                                out_channel.*.target_path = cgltf_animation_path_type_rotation;
                            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "scale") == @as(c_int, 0)) {
                                out_channel.*.target_path = cgltf_animation_path_type_scale;
                            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "weights") == @as(c_int, 0)) {
                                out_channel.*.target_path = cgltf_animation_path_type_weights;
                            }
                            i += 1;
                        } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "extras") == @as(c_int, 0)) {
                            i = cgltf_parse_json_extras(options, tokens, i + @as(c_int, 1), json_chunk, &out_channel.*.extras);
                        } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "extensions") == @as(c_int, 0)) {
                            i = cgltf_parse_json_unprocessed_extensions(options, tokens, i, json_chunk, &out_channel.*.extensions_count, &out_channel.*.extensions);
                        } else {
                            i = cgltf_skip_json(tokens, i + @as(c_int, 1));
                        }
                        if (i < @as(c_int, 0)) {
                            return i;
                        }
                    }
                }
            } else {
                i = cgltf_skip_json(tokens, i + @as(c_int, 1));
            }
            if (i < @as(c_int, 0)) {
                return i;
            }
        }
    }
    return i;
}
pub fn cgltf_parse_json_animation(arg_options: [*c]cgltf_options, arg_tokens: [*c]const jsmntok_t, arg_i: c_int, arg_json_chunk: [*c]const u8, arg_out_animation: [*c]cgltf_animation) callconv(.c) c_int {
    var options = arg_options;
    _ = &options;
    var tokens = arg_tokens;
    _ = &tokens;
    var i = arg_i;
    _ = &i;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var out_animation = arg_out_animation;
    _ = &out_animation;
    if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_OBJECT))) {
        return -@as(c_int, 1);
    }
    var size: c_int = tokens[@bitCast(@as(isize, @intCast(i)))].size;
    _ = &size;
    i += 1;
    {
        var j: c_int = 0;
        _ = &j;
        while (j < size) : (j += 1) {
            if ((tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, JSMN_STRING)) or (tokens[@bitCast(@as(isize, @intCast(i)))].size == @as(c_int, 0))) {
                return -@as(c_int, 1);
            }
            if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "name") == @as(c_int, 0)) {
                i = cgltf_parse_json_string(options, tokens, i + @as(c_int, 1), json_chunk, &out_animation.*.name);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "samplers") == @as(c_int, 0)) {
                i = cgltf_parse_json_array(options, tokens, i + @as(c_int, 1), json_chunk, @sizeOf(cgltf_animation_sampler), @ptrCast(@alignCast(&out_animation.*.samplers)), &out_animation.*.samplers_count);
                if (i < @as(c_int, 0)) {
                    return i;
                }
                {
                    var k: cgltf_size = 0;
                    _ = &k;
                    while (k < out_animation.*.samplers_count) : (k +%= 1) {
                        i = cgltf_parse_json_animation_sampler(options, tokens, i, json_chunk, &out_animation.*.samplers[@intCast(k)]);
                        if (i < @as(c_int, 0)) {
                            return i;
                        }
                    }
                }
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "channels") == @as(c_int, 0)) {
                i = cgltf_parse_json_array(options, tokens, i + @as(c_int, 1), json_chunk, @sizeOf(cgltf_animation_channel), @ptrCast(@alignCast(&out_animation.*.channels)), &out_animation.*.channels_count);
                if (i < @as(c_int, 0)) {
                    return i;
                }
                {
                    var k: cgltf_size = 0;
                    _ = &k;
                    while (k < out_animation.*.channels_count) : (k +%= 1) {
                        i = cgltf_parse_json_animation_channel(options, tokens, i, json_chunk, &out_animation.*.channels[@intCast(k)]);
                        if (i < @as(c_int, 0)) {
                            return i;
                        }
                    }
                }
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "extras") == @as(c_int, 0)) {
                i = cgltf_parse_json_extras(options, tokens, i + @as(c_int, 1), json_chunk, &out_animation.*.extras);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "extensions") == @as(c_int, 0)) {
                i = cgltf_parse_json_unprocessed_extensions(options, tokens, i, json_chunk, &out_animation.*.extensions_count, &out_animation.*.extensions);
            } else {
                i = cgltf_skip_json(tokens, i + @as(c_int, 1));
            }
            if (i < @as(c_int, 0)) {
                return i;
            }
        }
    }
    return i;
}
pub fn cgltf_parse_json_animations(arg_options: [*c]cgltf_options, arg_tokens: [*c]const jsmntok_t, arg_i: c_int, arg_json_chunk: [*c]const u8, arg_out_data: [*c]cgltf_data) callconv(.c) c_int {
    var options = arg_options;
    _ = &options;
    var tokens = arg_tokens;
    _ = &tokens;
    var i = arg_i;
    _ = &i;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var out_data = arg_out_data;
    _ = &out_data;
    i = cgltf_parse_json_array(options, tokens, i, json_chunk, @sizeOf(cgltf_animation), @ptrCast(@alignCast(&out_data.*.animations)), &out_data.*.animations_count);
    if (i < @as(c_int, 0)) {
        return i;
    }
    {
        var j: cgltf_size = 0;
        _ = &j;
        while (j < out_data.*.animations_count) : (j +%= 1) {
            i = cgltf_parse_json_animation(options, tokens, i, json_chunk, &out_data.*.animations[@intCast(j)]);
            if (i < @as(c_int, 0)) {
                return i;
            }
        }
    }
    return i;
}
pub fn cgltf_parse_json_variant(arg_options: [*c]cgltf_options, arg_tokens: [*c]const jsmntok_t, arg_i: c_int, arg_json_chunk: [*c]const u8, arg_out_variant: [*c]cgltf_material_variant) callconv(.c) c_int {
    var options = arg_options;
    _ = &options;
    var tokens = arg_tokens;
    _ = &tokens;
    var i = arg_i;
    _ = &i;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var out_variant = arg_out_variant;
    _ = &out_variant;
    if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_OBJECT))) {
        return -@as(c_int, 1);
    }
    var size: c_int = tokens[@bitCast(@as(isize, @intCast(i)))].size;
    _ = &size;
    i += 1;
    {
        var j: c_int = 0;
        _ = &j;
        while (j < size) : (j += 1) {
            if ((tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, JSMN_STRING)) or (tokens[@bitCast(@as(isize, @intCast(i)))].size == @as(c_int, 0))) {
                return -@as(c_int, 1);
            }
            if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "name") == @as(c_int, 0)) {
                i = cgltf_parse_json_string(options, tokens, i + @as(c_int, 1), json_chunk, &out_variant.*.name);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "extras") == @as(c_int, 0)) {
                i = cgltf_parse_json_extras(options, tokens, i + @as(c_int, 1), json_chunk, &out_variant.*.extras);
            } else {
                i = cgltf_skip_json(tokens, i + @as(c_int, 1));
            }
            if (i < @as(c_int, 0)) {
                return i;
            }
        }
    }
    return i;
}
pub fn cgltf_parse_json_variants(arg_options: [*c]cgltf_options, arg_tokens: [*c]const jsmntok_t, arg_i: c_int, arg_json_chunk: [*c]const u8, arg_out_data: [*c]cgltf_data) callconv(.c) c_int {
    var options = arg_options;
    _ = &options;
    var tokens = arg_tokens;
    _ = &tokens;
    var i = arg_i;
    _ = &i;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var out_data = arg_out_data;
    _ = &out_data;
    i = cgltf_parse_json_array(options, tokens, i, json_chunk, @sizeOf(cgltf_material_variant), @ptrCast(@alignCast(&out_data.*.variants)), &out_data.*.variants_count);
    if (i < @as(c_int, 0)) {
        return i;
    }
    {
        var j: cgltf_size = 0;
        _ = &j;
        while (j < out_data.*.variants_count) : (j +%= 1) {
            i = cgltf_parse_json_variant(options, tokens, i, json_chunk, &out_data.*.variants[@intCast(j)]);
            if (i < @as(c_int, 0)) {
                return i;
            }
        }
    }
    return i;
}
pub fn cgltf_parse_json_asset(arg_options: [*c]cgltf_options, arg_tokens: [*c]const jsmntok_t, arg_i: c_int, arg_json_chunk: [*c]const u8, arg_out_asset: [*c]cgltf_asset) callconv(.c) c_int {
    var options = arg_options;
    _ = &options;
    var tokens = arg_tokens;
    _ = &tokens;
    var i = arg_i;
    _ = &i;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var out_asset = arg_out_asset;
    _ = &out_asset;
    if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_OBJECT))) {
        return -@as(c_int, 1);
    }
    var size: c_int = tokens[@bitCast(@as(isize, @intCast(i)))].size;
    _ = &size;
    i += 1;
    {
        var j: c_int = 0;
        _ = &j;
        while (j < size) : (j += 1) {
            if ((tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, JSMN_STRING)) or (tokens[@bitCast(@as(isize, @intCast(i)))].size == @as(c_int, 0))) {
                return -@as(c_int, 1);
            }
            if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "copyright") == @as(c_int, 0)) {
                i = cgltf_parse_json_string(options, tokens, i + @as(c_int, 1), json_chunk, &out_asset.*.copyright);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "generator") == @as(c_int, 0)) {
                i = cgltf_parse_json_string(options, tokens, i + @as(c_int, 1), json_chunk, &out_asset.*.generator);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "version") == @as(c_int, 0)) {
                i = cgltf_parse_json_string(options, tokens, i + @as(c_int, 1), json_chunk, &out_asset.*.version);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "minVersion") == @as(c_int, 0)) {
                i = cgltf_parse_json_string(options, tokens, i + @as(c_int, 1), json_chunk, &out_asset.*.min_version);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "extras") == @as(c_int, 0)) {
                i = cgltf_parse_json_extras(options, tokens, i + @as(c_int, 1), json_chunk, &out_asset.*.extras);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "extensions") == @as(c_int, 0)) {
                i = cgltf_parse_json_unprocessed_extensions(options, tokens, i, json_chunk, &out_asset.*.extensions_count, &out_asset.*.extensions);
            } else {
                i = cgltf_skip_json(tokens, i + @as(c_int, 1));
            }
            if (i < @as(c_int, 0)) {
                return i;
            }
        }
    }
    if ((out_asset.*.version != null) and (atof(out_asset.*.version) < @as(f64, @floatFromInt(@as(c_int, 2))))) {
        return -@as(c_int, 3);
    }
    return i;
}
pub fn cgltf_fixup_pointers(arg_data: [*c]cgltf_data) callconv(.c) c_int {
    var data = arg_data;
    _ = &data;
    {
        var i: cgltf_size = 0;
        _ = &i;
        while (i < data.*.meshes_count) : (i +%= 1) {
            {
                var j: cgltf_size = 0;
                _ = &j;
                while (j < data.*.meshes[@intCast(i)].primitives_count) : (j +%= 1) {
                    if (data.*.meshes[@intCast(i)].primitives[@intCast(j)].indices != null) {
                        if (@as(cgltf_size, @intCast(@intFromPtr(data.*.meshes[@intCast(i)].primitives[@intCast(j)].indices))) > data.*.accessors_count) {
                            return -@as(c_int, 1);
                        }
                        data.*.meshes[@intCast(i)].primitives[@intCast(j)].indices = &data.*.accessors[@intCast(@as(cgltf_size, @intCast(@intFromPtr(data.*.meshes[@intCast(i)].primitives[@intCast(j)].indices))) -% @as(cgltf_size, 1))];
                    }
                    if (data.*.meshes[@intCast(i)].primitives[@intCast(j)].material != null) {
                        if (@as(cgltf_size, @intCast(@intFromPtr(data.*.meshes[@intCast(i)].primitives[@intCast(j)].material))) > data.*.materials_count) {
                            return -@as(c_int, 1);
                        }
                        data.*.meshes[@intCast(i)].primitives[@intCast(j)].material = &data.*.materials[@intCast(@as(cgltf_size, @intCast(@intFromPtr(data.*.meshes[@intCast(i)].primitives[@intCast(j)].material))) -% @as(cgltf_size, 1))];
                    }
                    {
                        var k: cgltf_size = 0;
                        _ = &k;
                        while (k < data.*.meshes[@intCast(i)].primitives[@intCast(j)].attributes_count) : (k +%= 1) {
                            if (!(data.*.meshes[@intCast(i)].primitives[@intCast(j)].attributes[@intCast(k)].data != null) or (@as(cgltf_size, @intCast(@intFromPtr(data.*.meshes[@intCast(i)].primitives[@intCast(j)].attributes[@intCast(k)].data))) > data.*.accessors_count)) {
                                return -@as(c_int, 1);
                            }
                            data.*.meshes[@intCast(i)].primitives[@intCast(j)].attributes[@intCast(k)].data = &data.*.accessors[@intCast(@as(cgltf_size, @intCast(@intFromPtr(data.*.meshes[@intCast(i)].primitives[@intCast(j)].attributes[@intCast(k)].data))) -% @as(cgltf_size, 1))];
                        }
                    }
                    {
                        var k: cgltf_size = 0;
                        _ = &k;
                        while (k < data.*.meshes[@intCast(i)].primitives[@intCast(j)].targets_count) : (k +%= 1) {
                            {
                                var m: cgltf_size = 0;
                                _ = &m;
                                while (m < data.*.meshes[@intCast(i)].primitives[@intCast(j)].targets[@intCast(k)].attributes_count) : (m +%= 1) {
                                    if (!(data.*.meshes[@intCast(i)].primitives[@intCast(j)].targets[@intCast(k)].attributes[@intCast(m)].data != null) or (@as(cgltf_size, @intCast(@intFromPtr(data.*.meshes[@intCast(i)].primitives[@intCast(j)].targets[@intCast(k)].attributes[@intCast(m)].data))) > data.*.accessors_count)) {
                                        return -@as(c_int, 1);
                                    }
                                    data.*.meshes[@intCast(i)].primitives[@intCast(j)].targets[@intCast(k)].attributes[@intCast(m)].data = &data.*.accessors[@intCast(@as(cgltf_size, @intCast(@intFromPtr(data.*.meshes[@intCast(i)].primitives[@intCast(j)].targets[@intCast(k)].attributes[@intCast(m)].data))) -% @as(cgltf_size, 1))];
                                }
                            }
                        }
                    }
                    if (data.*.meshes[@intCast(i)].primitives[@intCast(j)].has_draco_mesh_compression != 0) {
                        if (!(data.*.meshes[@intCast(i)].primitives[@intCast(j)].draco_mesh_compression.buffer_view != null) or (@as(cgltf_size, @intCast(@intFromPtr(data.*.meshes[@intCast(i)].primitives[@intCast(j)].draco_mesh_compression.buffer_view))) > data.*.buffer_views_count)) {
                            return -@as(c_int, 1);
                        }
                        data.*.meshes[@intCast(i)].primitives[@intCast(j)].draco_mesh_compression.buffer_view = &data.*.buffer_views[@intCast(@as(cgltf_size, @intCast(@intFromPtr(data.*.meshes[@intCast(i)].primitives[@intCast(j)].draco_mesh_compression.buffer_view))) -% @as(cgltf_size, 1))];
                        {
                            var m: cgltf_size = 0;
                            _ = &m;
                            while (m < data.*.meshes[@intCast(i)].primitives[@intCast(j)].draco_mesh_compression.attributes_count) : (m +%= 1) {
                                if (!(data.*.meshes[@intCast(i)].primitives[@intCast(j)].draco_mesh_compression.attributes[@intCast(m)].data != null) or (@as(cgltf_size, @intCast(@intFromPtr(data.*.meshes[@intCast(i)].primitives[@intCast(j)].draco_mesh_compression.attributes[@intCast(m)].data))) > data.*.accessors_count)) {
                                    return -@as(c_int, 1);
                                }
                                data.*.meshes[@intCast(i)].primitives[@intCast(j)].draco_mesh_compression.attributes[@intCast(m)].data = &data.*.accessors[@intCast(@as(cgltf_size, @intCast(@intFromPtr(data.*.meshes[@intCast(i)].primitives[@intCast(j)].draco_mesh_compression.attributes[@intCast(m)].data))) -% @as(cgltf_size, 1))];
                            }
                        }
                    }
                    {
                        var k: cgltf_size = 0;
                        _ = &k;
                        while (k < data.*.meshes[@intCast(i)].primitives[@intCast(j)].mappings_count) : (k +%= 1) {
                            if (!(data.*.meshes[@intCast(i)].primitives[@intCast(j)].mappings[@intCast(k)].material != null) or (@as(cgltf_size, @intCast(@intFromPtr(data.*.meshes[@intCast(i)].primitives[@intCast(j)].mappings[@intCast(k)].material))) > data.*.materials_count)) {
                                return -@as(c_int, 1);
                            }
                            data.*.meshes[@intCast(i)].primitives[@intCast(j)].mappings[@intCast(k)].material = &data.*.materials[@intCast(@as(cgltf_size, @intCast(@intFromPtr(data.*.meshes[@intCast(i)].primitives[@intCast(j)].mappings[@intCast(k)].material))) -% @as(cgltf_size, 1))];
                        }
                    }
                }
            }
        }
    }
    {
        var i: cgltf_size = 0;
        _ = &i;
        while (i < data.*.accessors_count) : (i +%= 1) {
            if (data.*.accessors[@intCast(i)].buffer_view != null) {
                if (@as(cgltf_size, @intCast(@intFromPtr(data.*.accessors[@intCast(i)].buffer_view))) > data.*.buffer_views_count) {
                    return -@as(c_int, 1);
                }
                data.*.accessors[@intCast(i)].buffer_view = &data.*.buffer_views[@intCast(@as(cgltf_size, @intCast(@intFromPtr(data.*.accessors[@intCast(i)].buffer_view))) -% @as(cgltf_size, 1))];
            }
            if (data.*.accessors[@intCast(i)].is_sparse != 0) {
                if (!(data.*.accessors[@intCast(i)].sparse.indices_buffer_view != null) or (@as(cgltf_size, @intCast(@intFromPtr(data.*.accessors[@intCast(i)].sparse.indices_buffer_view))) > data.*.buffer_views_count)) {
                    return -@as(c_int, 1);
                }
                data.*.accessors[@intCast(i)].sparse.indices_buffer_view = &data.*.buffer_views[@intCast(@as(cgltf_size, @intCast(@intFromPtr(data.*.accessors[@intCast(i)].sparse.indices_buffer_view))) -% @as(cgltf_size, 1))];
                if (!(data.*.accessors[@intCast(i)].sparse.values_buffer_view != null) or (@as(cgltf_size, @intCast(@intFromPtr(data.*.accessors[@intCast(i)].sparse.values_buffer_view))) > data.*.buffer_views_count)) {
                    return -@as(c_int, 1);
                }
                data.*.accessors[@intCast(i)].sparse.values_buffer_view = &data.*.buffer_views[@intCast(@as(cgltf_size, @intCast(@intFromPtr(data.*.accessors[@intCast(i)].sparse.values_buffer_view))) -% @as(cgltf_size, 1))];
            }
            if (data.*.accessors[@intCast(i)].buffer_view != null) {
                data.*.accessors[@intCast(i)].stride = data.*.accessors[@intCast(i)].buffer_view.*.stride;
            }
            if (data.*.accessors[@intCast(i)].stride == @as(cgltf_size, 0)) {
                data.*.accessors[@intCast(i)].stride = cgltf_calc_size(data.*.accessors[@intCast(i)].type, data.*.accessors[@intCast(i)].component_type);
            }
        }
    }
    {
        var i: cgltf_size = 0;
        _ = &i;
        while (i < data.*.textures_count) : (i +%= 1) {
            if (data.*.textures[@intCast(i)].image != null) {
                if (@as(cgltf_size, @intCast(@intFromPtr(data.*.textures[@intCast(i)].image))) > data.*.images_count) {
                    return -@as(c_int, 1);
                }
                data.*.textures[@intCast(i)].image = &data.*.images[@intCast(@as(cgltf_size, @intCast(@intFromPtr(data.*.textures[@intCast(i)].image))) -% @as(cgltf_size, 1))];
            }
            if (data.*.textures[@intCast(i)].basisu_image != null) {
                if (@as(cgltf_size, @intCast(@intFromPtr(data.*.textures[@intCast(i)].basisu_image))) > data.*.images_count) {
                    return -@as(c_int, 1);
                }
                data.*.textures[@intCast(i)].basisu_image = &data.*.images[@intCast(@as(cgltf_size, @intCast(@intFromPtr(data.*.textures[@intCast(i)].basisu_image))) -% @as(cgltf_size, 1))];
            }
            if (data.*.textures[@intCast(i)].webp_image != null) {
                if (@as(cgltf_size, @intCast(@intFromPtr(data.*.textures[@intCast(i)].webp_image))) > data.*.images_count) {
                    return -@as(c_int, 1);
                }
                data.*.textures[@intCast(i)].webp_image = &data.*.images[@intCast(@as(cgltf_size, @intCast(@intFromPtr(data.*.textures[@intCast(i)].webp_image))) -% @as(cgltf_size, 1))];
            }
            if (data.*.textures[@intCast(i)].sampler != null) {
                if (@as(cgltf_size, @intCast(@intFromPtr(data.*.textures[@intCast(i)].sampler))) > data.*.samplers_count) {
                    return -@as(c_int, 1);
                }
                data.*.textures[@intCast(i)].sampler = &data.*.samplers[@intCast(@as(cgltf_size, @intCast(@intFromPtr(data.*.textures[@intCast(i)].sampler))) -% @as(cgltf_size, 1))];
            }
        }
    }
    {
        var i: cgltf_size = 0;
        _ = &i;
        while (i < data.*.images_count) : (i +%= 1) {
            if (data.*.images[@intCast(i)].buffer_view != null) {
                if (@as(cgltf_size, @intCast(@intFromPtr(data.*.images[@intCast(i)].buffer_view))) > data.*.buffer_views_count) {
                    return -@as(c_int, 1);
                }
                data.*.images[@intCast(i)].buffer_view = &data.*.buffer_views[@intCast(@as(cgltf_size, @intCast(@intFromPtr(data.*.images[@intCast(i)].buffer_view))) -% @as(cgltf_size, 1))];
            }
        }
    }
    {
        var i: cgltf_size = 0;
        _ = &i;
        while (i < data.*.materials_count) : (i +%= 1) {
            if (data.*.materials[@intCast(i)].normal_texture.texture != null) {
                if (@as(cgltf_size, @intCast(@intFromPtr(data.*.materials[@intCast(i)].normal_texture.texture))) > data.*.textures_count) {
                    return -@as(c_int, 1);
                }
                data.*.materials[@intCast(i)].normal_texture.texture = &data.*.textures[@intCast(@as(cgltf_size, @intCast(@intFromPtr(data.*.materials[@intCast(i)].normal_texture.texture))) -% @as(cgltf_size, 1))];
            }
            if (data.*.materials[@intCast(i)].emissive_texture.texture != null) {
                if (@as(cgltf_size, @intCast(@intFromPtr(data.*.materials[@intCast(i)].emissive_texture.texture))) > data.*.textures_count) {
                    return -@as(c_int, 1);
                }
                data.*.materials[@intCast(i)].emissive_texture.texture = &data.*.textures[@intCast(@as(cgltf_size, @intCast(@intFromPtr(data.*.materials[@intCast(i)].emissive_texture.texture))) -% @as(cgltf_size, 1))];
            }
            if (data.*.materials[@intCast(i)].occlusion_texture.texture != null) {
                if (@as(cgltf_size, @intCast(@intFromPtr(data.*.materials[@intCast(i)].occlusion_texture.texture))) > data.*.textures_count) {
                    return -@as(c_int, 1);
                }
                data.*.materials[@intCast(i)].occlusion_texture.texture = &data.*.textures[@intCast(@as(cgltf_size, @intCast(@intFromPtr(data.*.materials[@intCast(i)].occlusion_texture.texture))) -% @as(cgltf_size, 1))];
            }
            if (data.*.materials[@intCast(i)].pbr_metallic_roughness.base_color_texture.texture != null) {
                if (@as(cgltf_size, @intCast(@intFromPtr(data.*.materials[@intCast(i)].pbr_metallic_roughness.base_color_texture.texture))) > data.*.textures_count) {
                    return -@as(c_int, 1);
                }
                data.*.materials[@intCast(i)].pbr_metallic_roughness.base_color_texture.texture = &data.*.textures[@intCast(@as(cgltf_size, @intCast(@intFromPtr(data.*.materials[@intCast(i)].pbr_metallic_roughness.base_color_texture.texture))) -% @as(cgltf_size, 1))];
            }
            if (data.*.materials[@intCast(i)].pbr_metallic_roughness.metallic_roughness_texture.texture != null) {
                if (@as(cgltf_size, @intCast(@intFromPtr(data.*.materials[@intCast(i)].pbr_metallic_roughness.metallic_roughness_texture.texture))) > data.*.textures_count) {
                    return -@as(c_int, 1);
                }
                data.*.materials[@intCast(i)].pbr_metallic_roughness.metallic_roughness_texture.texture = &data.*.textures[@intCast(@as(cgltf_size, @intCast(@intFromPtr(data.*.materials[@intCast(i)].pbr_metallic_roughness.metallic_roughness_texture.texture))) -% @as(cgltf_size, 1))];
            }
            if (data.*.materials[@intCast(i)].pbr_specular_glossiness.diffuse_texture.texture != null) {
                if (@as(cgltf_size, @intCast(@intFromPtr(data.*.materials[@intCast(i)].pbr_specular_glossiness.diffuse_texture.texture))) > data.*.textures_count) {
                    return -@as(c_int, 1);
                }
                data.*.materials[@intCast(i)].pbr_specular_glossiness.diffuse_texture.texture = &data.*.textures[@intCast(@as(cgltf_size, @intCast(@intFromPtr(data.*.materials[@intCast(i)].pbr_specular_glossiness.diffuse_texture.texture))) -% @as(cgltf_size, 1))];
            }
            if (data.*.materials[@intCast(i)].pbr_specular_glossiness.specular_glossiness_texture.texture != null) {
                if (@as(cgltf_size, @intCast(@intFromPtr(data.*.materials[@intCast(i)].pbr_specular_glossiness.specular_glossiness_texture.texture))) > data.*.textures_count) {
                    return -@as(c_int, 1);
                }
                data.*.materials[@intCast(i)].pbr_specular_glossiness.specular_glossiness_texture.texture = &data.*.textures[@intCast(@as(cgltf_size, @intCast(@intFromPtr(data.*.materials[@intCast(i)].pbr_specular_glossiness.specular_glossiness_texture.texture))) -% @as(cgltf_size, 1))];
            }
            if (data.*.materials[@intCast(i)].clearcoat.clearcoat_texture.texture != null) {
                if (@as(cgltf_size, @intCast(@intFromPtr(data.*.materials[@intCast(i)].clearcoat.clearcoat_texture.texture))) > data.*.textures_count) {
                    return -@as(c_int, 1);
                }
                data.*.materials[@intCast(i)].clearcoat.clearcoat_texture.texture = &data.*.textures[@intCast(@as(cgltf_size, @intCast(@intFromPtr(data.*.materials[@intCast(i)].clearcoat.clearcoat_texture.texture))) -% @as(cgltf_size, 1))];
            }
            if (data.*.materials[@intCast(i)].clearcoat.clearcoat_roughness_texture.texture != null) {
                if (@as(cgltf_size, @intCast(@intFromPtr(data.*.materials[@intCast(i)].clearcoat.clearcoat_roughness_texture.texture))) > data.*.textures_count) {
                    return -@as(c_int, 1);
                }
                data.*.materials[@intCast(i)].clearcoat.clearcoat_roughness_texture.texture = &data.*.textures[@intCast(@as(cgltf_size, @intCast(@intFromPtr(data.*.materials[@intCast(i)].clearcoat.clearcoat_roughness_texture.texture))) -% @as(cgltf_size, 1))];
            }
            if (data.*.materials[@intCast(i)].clearcoat.clearcoat_normal_texture.texture != null) {
                if (@as(cgltf_size, @intCast(@intFromPtr(data.*.materials[@intCast(i)].clearcoat.clearcoat_normal_texture.texture))) > data.*.textures_count) {
                    return -@as(c_int, 1);
                }
                data.*.materials[@intCast(i)].clearcoat.clearcoat_normal_texture.texture = &data.*.textures[@intCast(@as(cgltf_size, @intCast(@intFromPtr(data.*.materials[@intCast(i)].clearcoat.clearcoat_normal_texture.texture))) -% @as(cgltf_size, 1))];
            }
            if (data.*.materials[@intCast(i)].specular.specular_texture.texture != null) {
                if (@as(cgltf_size, @intCast(@intFromPtr(data.*.materials[@intCast(i)].specular.specular_texture.texture))) > data.*.textures_count) {
                    return -@as(c_int, 1);
                }
                data.*.materials[@intCast(i)].specular.specular_texture.texture = &data.*.textures[@intCast(@as(cgltf_size, @intCast(@intFromPtr(data.*.materials[@intCast(i)].specular.specular_texture.texture))) -% @as(cgltf_size, 1))];
            }
            if (data.*.materials[@intCast(i)].specular.specular_color_texture.texture != null) {
                if (@as(cgltf_size, @intCast(@intFromPtr(data.*.materials[@intCast(i)].specular.specular_color_texture.texture))) > data.*.textures_count) {
                    return -@as(c_int, 1);
                }
                data.*.materials[@intCast(i)].specular.specular_color_texture.texture = &data.*.textures[@intCast(@as(cgltf_size, @intCast(@intFromPtr(data.*.materials[@intCast(i)].specular.specular_color_texture.texture))) -% @as(cgltf_size, 1))];
            }
            if (data.*.materials[@intCast(i)].transmission.transmission_texture.texture != null) {
                if (@as(cgltf_size, @intCast(@intFromPtr(data.*.materials[@intCast(i)].transmission.transmission_texture.texture))) > data.*.textures_count) {
                    return -@as(c_int, 1);
                }
                data.*.materials[@intCast(i)].transmission.transmission_texture.texture = &data.*.textures[@intCast(@as(cgltf_size, @intCast(@intFromPtr(data.*.materials[@intCast(i)].transmission.transmission_texture.texture))) -% @as(cgltf_size, 1))];
            }
            if (data.*.materials[@intCast(i)].volume.thickness_texture.texture != null) {
                if (@as(cgltf_size, @intCast(@intFromPtr(data.*.materials[@intCast(i)].volume.thickness_texture.texture))) > data.*.textures_count) {
                    return -@as(c_int, 1);
                }
                data.*.materials[@intCast(i)].volume.thickness_texture.texture = &data.*.textures[@intCast(@as(cgltf_size, @intCast(@intFromPtr(data.*.materials[@intCast(i)].volume.thickness_texture.texture))) -% @as(cgltf_size, 1))];
            }
            if (data.*.materials[@intCast(i)].sheen.sheen_color_texture.texture != null) {
                if (@as(cgltf_size, @intCast(@intFromPtr(data.*.materials[@intCast(i)].sheen.sheen_color_texture.texture))) > data.*.textures_count) {
                    return -@as(c_int, 1);
                }
                data.*.materials[@intCast(i)].sheen.sheen_color_texture.texture = &data.*.textures[@intCast(@as(cgltf_size, @intCast(@intFromPtr(data.*.materials[@intCast(i)].sheen.sheen_color_texture.texture))) -% @as(cgltf_size, 1))];
            }
            if (data.*.materials[@intCast(i)].sheen.sheen_roughness_texture.texture != null) {
                if (@as(cgltf_size, @intCast(@intFromPtr(data.*.materials[@intCast(i)].sheen.sheen_roughness_texture.texture))) > data.*.textures_count) {
                    return -@as(c_int, 1);
                }
                data.*.materials[@intCast(i)].sheen.sheen_roughness_texture.texture = &data.*.textures[@intCast(@as(cgltf_size, @intCast(@intFromPtr(data.*.materials[@intCast(i)].sheen.sheen_roughness_texture.texture))) -% @as(cgltf_size, 1))];
            }
            if (data.*.materials[@intCast(i)].iridescence.iridescence_texture.texture != null) {
                if (@as(cgltf_size, @intCast(@intFromPtr(data.*.materials[@intCast(i)].iridescence.iridescence_texture.texture))) > data.*.textures_count) {
                    return -@as(c_int, 1);
                }
                data.*.materials[@intCast(i)].iridescence.iridescence_texture.texture = &data.*.textures[@intCast(@as(cgltf_size, @intCast(@intFromPtr(data.*.materials[@intCast(i)].iridescence.iridescence_texture.texture))) -% @as(cgltf_size, 1))];
            }
            if (data.*.materials[@intCast(i)].iridescence.iridescence_thickness_texture.texture != null) {
                if (@as(cgltf_size, @intCast(@intFromPtr(data.*.materials[@intCast(i)].iridescence.iridescence_thickness_texture.texture))) > data.*.textures_count) {
                    return -@as(c_int, 1);
                }
                data.*.materials[@intCast(i)].iridescence.iridescence_thickness_texture.texture = &data.*.textures[@intCast(@as(cgltf_size, @intCast(@intFromPtr(data.*.materials[@intCast(i)].iridescence.iridescence_thickness_texture.texture))) -% @as(cgltf_size, 1))];
            }
            if (data.*.materials[@intCast(i)].diffuse_transmission.diffuse_transmission_texture.texture != null) {
                if (@as(cgltf_size, @intCast(@intFromPtr(data.*.materials[@intCast(i)].diffuse_transmission.diffuse_transmission_texture.texture))) > data.*.textures_count) {
                    return -@as(c_int, 1);
                }
                data.*.materials[@intCast(i)].diffuse_transmission.diffuse_transmission_texture.texture = &data.*.textures[@intCast(@as(cgltf_size, @intCast(@intFromPtr(data.*.materials[@intCast(i)].diffuse_transmission.diffuse_transmission_texture.texture))) -% @as(cgltf_size, 1))];
            }
            if (data.*.materials[@intCast(i)].diffuse_transmission.diffuse_transmission_color_texture.texture != null) {
                if (@as(cgltf_size, @intCast(@intFromPtr(data.*.materials[@intCast(i)].diffuse_transmission.diffuse_transmission_color_texture.texture))) > data.*.textures_count) {
                    return -@as(c_int, 1);
                }
                data.*.materials[@intCast(i)].diffuse_transmission.diffuse_transmission_color_texture.texture = &data.*.textures[@intCast(@as(cgltf_size, @intCast(@intFromPtr(data.*.materials[@intCast(i)].diffuse_transmission.diffuse_transmission_color_texture.texture))) -% @as(cgltf_size, 1))];
            }
            if (data.*.materials[@intCast(i)].anisotropy.anisotropy_texture.texture != null) {
                if (@as(cgltf_size, @intCast(@intFromPtr(data.*.materials[@intCast(i)].anisotropy.anisotropy_texture.texture))) > data.*.textures_count) {
                    return -@as(c_int, 1);
                }
                data.*.materials[@intCast(i)].anisotropy.anisotropy_texture.texture = &data.*.textures[@intCast(@as(cgltf_size, @intCast(@intFromPtr(data.*.materials[@intCast(i)].anisotropy.anisotropy_texture.texture))) -% @as(cgltf_size, 1))];
            }
        }
    }
    {
        var i: cgltf_size = 0;
        _ = &i;
        while (i < data.*.buffer_views_count) : (i +%= 1) {
            if (!(data.*.buffer_views[@intCast(i)].buffer != null) or (@as(cgltf_size, @intCast(@intFromPtr(data.*.buffer_views[@intCast(i)].buffer))) > data.*.buffers_count)) {
                return -@as(c_int, 1);
            }
            data.*.buffer_views[@intCast(i)].buffer = &data.*.buffers[@intCast(@as(cgltf_size, @intCast(@intFromPtr(data.*.buffer_views[@intCast(i)].buffer))) -% @as(cgltf_size, 1))];
            if (data.*.buffer_views[@intCast(i)].has_meshopt_compression != 0) {
                if (!(data.*.buffer_views[@intCast(i)].meshopt_compression.buffer != null) or (@as(cgltf_size, @intCast(@intFromPtr(data.*.buffer_views[@intCast(i)].meshopt_compression.buffer))) > data.*.buffers_count)) {
                    return -@as(c_int, 1);
                }
                data.*.buffer_views[@intCast(i)].meshopt_compression.buffer = &data.*.buffers[@intCast(@as(cgltf_size, @intCast(@intFromPtr(data.*.buffer_views[@intCast(i)].meshopt_compression.buffer))) -% @as(cgltf_size, 1))];
            }
        }
    }
    {
        var i: cgltf_size = 0;
        _ = &i;
        while (i < data.*.skins_count) : (i +%= 1) {
            {
                var j: cgltf_size = 0;
                _ = &j;
                while (j < data.*.skins[@intCast(i)].joints_count) : (j +%= 1) {
                    if (!(data.*.skins[@intCast(i)].joints[@intCast(j)] != null) or (@as(cgltf_size, @intCast(@intFromPtr(data.*.skins[@intCast(i)].joints[@intCast(j)]))) > data.*.nodes_count)) {
                        return -@as(c_int, 1);
                    }
                    data.*.skins[@intCast(i)].joints[@intCast(j)] = &data.*.nodes[@intCast(@as(cgltf_size, @intCast(@intFromPtr(data.*.skins[@intCast(i)].joints[@intCast(j)]))) -% @as(cgltf_size, 1))];
                }
            }
            if (data.*.skins[@intCast(i)].skeleton != null) {
                if (@as(cgltf_size, @intCast(@intFromPtr(data.*.skins[@intCast(i)].skeleton))) > data.*.nodes_count) {
                    return -@as(c_int, 1);
                }
                data.*.skins[@intCast(i)].skeleton = &data.*.nodes[@intCast(@as(cgltf_size, @intCast(@intFromPtr(data.*.skins[@intCast(i)].skeleton))) -% @as(cgltf_size, 1))];
            }
            if (data.*.skins[@intCast(i)].inverse_bind_matrices != null) {
                if (@as(cgltf_size, @intCast(@intFromPtr(data.*.skins[@intCast(i)].inverse_bind_matrices))) > data.*.accessors_count) {
                    return -@as(c_int, 1);
                }
                data.*.skins[@intCast(i)].inverse_bind_matrices = &data.*.accessors[@intCast(@as(cgltf_size, @intCast(@intFromPtr(data.*.skins[@intCast(i)].inverse_bind_matrices))) -% @as(cgltf_size, 1))];
            }
        }
    }
    {
        var i: cgltf_size = 0;
        _ = &i;
        while (i < data.*.nodes_count) : (i +%= 1) {
            {
                var j: cgltf_size = 0;
                _ = &j;
                while (j < data.*.nodes[@intCast(i)].children_count) : (j +%= 1) {
                    if (!(data.*.nodes[@intCast(i)].children[@intCast(j)] != null) or (@as(cgltf_size, @intCast(@intFromPtr(data.*.nodes[@intCast(i)].children[@intCast(j)]))) > data.*.nodes_count)) {
                        return -@as(c_int, 1);
                    }
                    data.*.nodes[@intCast(i)].children[@intCast(j)] = &data.*.nodes[@intCast(@as(cgltf_size, @intCast(@intFromPtr(data.*.nodes[@intCast(i)].children[@intCast(j)]))) -% @as(cgltf_size, 1))];
                    if (data.*.nodes[@intCast(i)].children[@intCast(j)].*.parent != null) {
                        return -@as(c_int, 1);
                    }
                    data.*.nodes[@intCast(i)].children[@intCast(j)].*.parent = &data.*.nodes[@intCast(i)];
                }
            }
            if (data.*.nodes[@intCast(i)].mesh != null) {
                if (@as(cgltf_size, @intCast(@intFromPtr(data.*.nodes[@intCast(i)].mesh))) > data.*.meshes_count) {
                    return -@as(c_int, 1);
                }
                data.*.nodes[@intCast(i)].mesh = &data.*.meshes[@intCast(@as(cgltf_size, @intCast(@intFromPtr(data.*.nodes[@intCast(i)].mesh))) -% @as(cgltf_size, 1))];
            }
            if (data.*.nodes[@intCast(i)].skin != null) {
                if (@as(cgltf_size, @intCast(@intFromPtr(data.*.nodes[@intCast(i)].skin))) > data.*.skins_count) {
                    return -@as(c_int, 1);
                }
                data.*.nodes[@intCast(i)].skin = &data.*.skins[@intCast(@as(cgltf_size, @intCast(@intFromPtr(data.*.nodes[@intCast(i)].skin))) -% @as(cgltf_size, 1))];
            }
            if (data.*.nodes[@intCast(i)].camera != null) {
                if (@as(cgltf_size, @intCast(@intFromPtr(data.*.nodes[@intCast(i)].camera))) > data.*.cameras_count) {
                    return -@as(c_int, 1);
                }
                data.*.nodes[@intCast(i)].camera = &data.*.cameras[@intCast(@as(cgltf_size, @intCast(@intFromPtr(data.*.nodes[@intCast(i)].camera))) -% @as(cgltf_size, 1))];
            }
            if (data.*.nodes[@intCast(i)].light != null) {
                if (@as(cgltf_size, @intCast(@intFromPtr(data.*.nodes[@intCast(i)].light))) > data.*.lights_count) {
                    return -@as(c_int, 1);
                }
                data.*.nodes[@intCast(i)].light = &data.*.lights[@intCast(@as(cgltf_size, @intCast(@intFromPtr(data.*.nodes[@intCast(i)].light))) -% @as(cgltf_size, 1))];
            }
            if (data.*.nodes[@intCast(i)].has_mesh_gpu_instancing != 0) {
                {
                    var m: cgltf_size = 0;
                    _ = &m;
                    while (m < data.*.nodes[@intCast(i)].mesh_gpu_instancing.attributes_count) : (m +%= 1) {
                        if (!(data.*.nodes[@intCast(i)].mesh_gpu_instancing.attributes[@intCast(m)].data != null) or (@as(cgltf_size, @intCast(@intFromPtr(data.*.nodes[@intCast(i)].mesh_gpu_instancing.attributes[@intCast(m)].data))) > data.*.accessors_count)) {
                            return -@as(c_int, 1);
                        }
                        data.*.nodes[@intCast(i)].mesh_gpu_instancing.attributes[@intCast(m)].data = &data.*.accessors[@intCast(@as(cgltf_size, @intCast(@intFromPtr(data.*.nodes[@intCast(i)].mesh_gpu_instancing.attributes[@intCast(m)].data))) -% @as(cgltf_size, 1))];
                    }
                }
            }
        }
    }
    {
        var i: cgltf_size = 0;
        _ = &i;
        while (i < data.*.scenes_count) : (i +%= 1) {
            {
                var j: cgltf_size = 0;
                _ = &j;
                while (j < data.*.scenes[@intCast(i)].nodes_count) : (j +%= 1) {
                    if (!(data.*.scenes[@intCast(i)].nodes[@intCast(j)] != null) or (@as(cgltf_size, @intCast(@intFromPtr(data.*.scenes[@intCast(i)].nodes[@intCast(j)]))) > data.*.nodes_count)) {
                        return -@as(c_int, 1);
                    }
                    data.*.scenes[@intCast(i)].nodes[@intCast(j)] = &data.*.nodes[@intCast(@as(cgltf_size, @intCast(@intFromPtr(data.*.scenes[@intCast(i)].nodes[@intCast(j)]))) -% @as(cgltf_size, 1))];
                    if (data.*.scenes[@intCast(i)].nodes[@intCast(j)].*.parent != null) {
                        return -@as(c_int, 1);
                    }
                }
            }
        }
    }
    if (data.*.scene != null) {
        if (@as(cgltf_size, @intCast(@intFromPtr(data.*.scene))) > data.*.scenes_count) {
            return -@as(c_int, 1);
        }
        data.*.scene = &data.*.scenes[@intCast(@as(cgltf_size, @intCast(@intFromPtr(data.*.scene))) -% @as(cgltf_size, 1))];
    }
    {
        var i: cgltf_size = 0;
        _ = &i;
        while (i < data.*.animations_count) : (i +%= 1) {
            {
                var j: cgltf_size = 0;
                _ = &j;
                while (j < data.*.animations[@intCast(i)].samplers_count) : (j +%= 1) {
                    if (!(data.*.animations[@intCast(i)].samplers[@intCast(j)].input != null) or (@as(cgltf_size, @intCast(@intFromPtr(data.*.animations[@intCast(i)].samplers[@intCast(j)].input))) > data.*.accessors_count)) {
                        return -@as(c_int, 1);
                    }
                    data.*.animations[@intCast(i)].samplers[@intCast(j)].input = &data.*.accessors[@intCast(@as(cgltf_size, @intCast(@intFromPtr(data.*.animations[@intCast(i)].samplers[@intCast(j)].input))) -% @as(cgltf_size, 1))];
                    if (!(data.*.animations[@intCast(i)].samplers[@intCast(j)].output != null) or (@as(cgltf_size, @intCast(@intFromPtr(data.*.animations[@intCast(i)].samplers[@intCast(j)].output))) > data.*.accessors_count)) {
                        return -@as(c_int, 1);
                    }
                    data.*.animations[@intCast(i)].samplers[@intCast(j)].output = &data.*.accessors[@intCast(@as(cgltf_size, @intCast(@intFromPtr(data.*.animations[@intCast(i)].samplers[@intCast(j)].output))) -% @as(cgltf_size, 1))];
                }
            }
            {
                var j: cgltf_size = 0;
                _ = &j;
                while (j < data.*.animations[@intCast(i)].channels_count) : (j +%= 1) {
                    if (!(data.*.animations[@intCast(i)].channels[@intCast(j)].sampler != null) or (@as(cgltf_size, @intCast(@intFromPtr(data.*.animations[@intCast(i)].channels[@intCast(j)].sampler))) > data.*.animations[@intCast(i)].samplers_count)) {
                        return -@as(c_int, 1);
                    }
                    data.*.animations[@intCast(i)].channels[@intCast(j)].sampler = &data.*.animations[@intCast(i)].samplers[@intCast(@as(cgltf_size, @intCast(@intFromPtr(data.*.animations[@intCast(i)].channels[@intCast(j)].sampler))) -% @as(cgltf_size, 1))];
                    if (data.*.animations[@intCast(i)].channels[@intCast(j)].target_node != null) {
                        if (@as(cgltf_size, @intCast(@intFromPtr(data.*.animations[@intCast(i)].channels[@intCast(j)].target_node))) > data.*.nodes_count) {
                            return -@as(c_int, 1);
                        }
                        data.*.animations[@intCast(i)].channels[@intCast(j)].target_node = &data.*.nodes[@intCast(@as(cgltf_size, @intCast(@intFromPtr(data.*.animations[@intCast(i)].channels[@intCast(j)].target_node))) -% @as(cgltf_size, 1))];
                    }
                }
            }
        }
    }
    return 0;
}
pub fn cgltf_parse_json_root(arg_options: [*c]cgltf_options, arg_tokens: [*c]const jsmntok_t, arg_i: c_int, arg_json_chunk: [*c]const u8, arg_out_data: [*c]cgltf_data) callconv(.c) c_int {
    var options = arg_options;
    _ = &options;
    var tokens = arg_tokens;
    _ = &tokens;
    var i = arg_i;
    _ = &i;
    var json_chunk = arg_json_chunk;
    _ = &json_chunk;
    var out_data = arg_out_data;
    _ = &out_data;
    if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_OBJECT))) {
        return -@as(c_int, 1);
    }
    var size: c_int = tokens[@bitCast(@as(isize, @intCast(i)))].size;
    _ = &size;
    i += 1;
    {
        var j: c_int = 0;
        _ = &j;
        while (j < size) : (j += 1) {
            if ((tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, JSMN_STRING)) or (tokens[@bitCast(@as(isize, @intCast(i)))].size == @as(c_int, 0))) {
                return -@as(c_int, 1);
            }
            if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "asset") == @as(c_int, 0)) {
                i = cgltf_parse_json_asset(options, tokens, i + @as(c_int, 1), json_chunk, &out_data.*.asset);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "meshes") == @as(c_int, 0)) {
                i = cgltf_parse_json_meshes(options, tokens, i + @as(c_int, 1), json_chunk, out_data);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "accessors") == @as(c_int, 0)) {
                i = cgltf_parse_json_accessors(options, tokens, i + @as(c_int, 1), json_chunk, out_data);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "bufferViews") == @as(c_int, 0)) {
                i = cgltf_parse_json_buffer_views(options, tokens, i + @as(c_int, 1), json_chunk, out_data);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "buffers") == @as(c_int, 0)) {
                i = cgltf_parse_json_buffers(options, tokens, i + @as(c_int, 1), json_chunk, out_data);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "materials") == @as(c_int, 0)) {
                i = cgltf_parse_json_materials(options, tokens, i + @as(c_int, 1), json_chunk, out_data);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "images") == @as(c_int, 0)) {
                i = cgltf_parse_json_images(options, tokens, i + @as(c_int, 1), json_chunk, out_data);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "textures") == @as(c_int, 0)) {
                i = cgltf_parse_json_textures(options, tokens, i + @as(c_int, 1), json_chunk, out_data);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "samplers") == @as(c_int, 0)) {
                i = cgltf_parse_json_samplers(options, tokens, i + @as(c_int, 1), json_chunk, out_data);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "skins") == @as(c_int, 0)) {
                i = cgltf_parse_json_skins(options, tokens, i + @as(c_int, 1), json_chunk, out_data);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "cameras") == @as(c_int, 0)) {
                i = cgltf_parse_json_cameras(options, tokens, i + @as(c_int, 1), json_chunk, out_data);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "nodes") == @as(c_int, 0)) {
                i = cgltf_parse_json_nodes(options, tokens, i + @as(c_int, 1), json_chunk, out_data);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "scenes") == @as(c_int, 0)) {
                i = cgltf_parse_json_scenes(options, tokens, i + @as(c_int, 1), json_chunk, out_data);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "scene") == @as(c_int, 0)) {
                i += 1;
                out_data.*.scene = @ptrFromInt(@as(cgltf_size, @bitCast(@as(c_longlong, cgltf_json_to_int(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk)))) +% @as(cgltf_size, 1));
                i += 1;
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "animations") == @as(c_int, 0)) {
                i = cgltf_parse_json_animations(options, tokens, i + @as(c_int, 1), json_chunk, out_data);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "extras") == @as(c_int, 0)) {
                i = cgltf_parse_json_extras(options, tokens, i + @as(c_int, 1), json_chunk, &out_data.*.extras);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "extensions") == @as(c_int, 0)) {
                i += 1;
                if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_OBJECT))) {
                    return -@as(c_int, 1);
                }
                if (out_data.*.data_extensions != null) {
                    return -@as(c_int, 1);
                }
                var extensions_size: c_int = tokens[@bitCast(@as(isize, @intCast(i)))].size;
                _ = &extensions_size;
                out_data.*.data_extensions_count = 0;
                out_data.*.data_extensions = @ptrCast(@alignCast(cgltf_calloc(options, @sizeOf(cgltf_extension), @bitCast(@as(c_longlong, extensions_size)))));
                if (!(out_data.*.data_extensions != null)) {
                    return -@as(c_int, 2);
                }
                i += 1;
                {
                    var k: c_int = 0;
                    _ = &k;
                    while (k < extensions_size) : (k += 1) {
                        if ((tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, JSMN_STRING)) or (tokens[@bitCast(@as(isize, @intCast(i)))].size == @as(c_int, 0))) {
                            return -@as(c_int, 1);
                        }
                        if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "KHR_lights_punctual") == @as(c_int, 0)) {
                            i += 1;
                            if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_OBJECT))) {
                                return -@as(c_int, 1);
                            }
                            var data_size: c_int = tokens[@bitCast(@as(isize, @intCast(i)))].size;
                            _ = &data_size;
                            i += 1;
                            {
                                var m: c_int = 0;
                                _ = &m;
                                while (m < data_size) : (m += 1) {
                                    if ((tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, JSMN_STRING)) or (tokens[@bitCast(@as(isize, @intCast(i)))].size == @as(c_int, 0))) {
                                        return -@as(c_int, 1);
                                    }
                                    if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "lights") == @as(c_int, 0)) {
                                        i = cgltf_parse_json_lights(options, tokens, i + @as(c_int, 1), json_chunk, out_data);
                                    } else {
                                        i = cgltf_skip_json(tokens, i + @as(c_int, 1));
                                    }
                                    if (i < @as(c_int, 0)) {
                                        return i;
                                    }
                                }
                            }
                        } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "KHR_materials_variants") == @as(c_int, 0)) {
                            i += 1;
                            if (tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, @bitCast(JSMN_OBJECT))) {
                                return -@as(c_int, 1);
                            }
                            var data_size: c_int = tokens[@bitCast(@as(isize, @intCast(i)))].size;
                            _ = &data_size;
                            i += 1;
                            {
                                var m: c_int = 0;
                                _ = &m;
                                while (m < data_size) : (m += 1) {
                                    if ((tokens[@bitCast(@as(isize, @intCast(i)))].type != @as(jsmntype_t, JSMN_STRING)) or (tokens[@bitCast(@as(isize, @intCast(i)))].size == @as(c_int, 0))) {
                                        return -@as(c_int, 1);
                                    }
                                    if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "variants") == @as(c_int, 0)) {
                                        i = cgltf_parse_json_variants(options, tokens, i + @as(c_int, 1), json_chunk, out_data);
                                    } else {
                                        i = cgltf_skip_json(tokens, i + @as(c_int, 1));
                                    }
                                    if (i < @as(c_int, 0)) {
                                        return i;
                                    }
                                }
                            }
                        } else {
                            i = cgltf_parse_json_unprocessed_extension(options, tokens, i, json_chunk, &out_data.*.data_extensions[
                                @intCast(blk: {
                                    const ref = &out_data.*.data_extensions_count;
                                    const tmp = ref.*;
                                    ref.* +%= 1;
                                    break :blk tmp;
                                })
                            ]);
                        }
                        if (i < @as(c_int, 0)) {
                            return i;
                        }
                    }
                }
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "extensionsUsed") == @as(c_int, 0)) {
                i = cgltf_parse_json_string_array(options, tokens, i + @as(c_int, 1), json_chunk, &out_data.*.extensions_used, &out_data.*.extensions_used_count);
            } else if (cgltf_json_strcmp(tokens + @as(usize, @bitCast(@as(isize, @intCast(i)))), json_chunk, "extensionsRequired") == @as(c_int, 0)) {
                i = cgltf_parse_json_string_array(options, tokens, i + @as(c_int, 1), json_chunk, &out_data.*.extensions_required, &out_data.*.extensions_required_count);
            } else {
                i = cgltf_skip_json(tokens, i + @as(c_int, 1));
            }
            if (i < @as(c_int, 0)) {
                return i;
            }
        }
    }
    return i;
}
pub fn jsmn_alloc_token(arg_parser: [*c]jsmn_parser, arg_tokens: [*c]jsmntok_t, arg_num_tokens: usize) callconv(.c) [*c]jsmntok_t {
    var parser = arg_parser;
    _ = &parser;
    var tokens = arg_tokens;
    _ = &tokens;
    var num_tokens = arg_num_tokens;
    _ = &num_tokens;
    var tok: [*c]jsmntok_t = undefined;
    _ = &tok;
    if (@as(usize, parser.*.toknext) >= num_tokens) {
        return null;
    }
    tok = &tokens[
        blk: {
            const ref = &parser.*.toknext;
            const tmp = ref.*;
            ref.* +%= 1;
            break :blk tmp;
        }
    ];
    tok.*.start = blk: {
        const tmp = @as(ptrdiff_t, -@as(c_int, 1));
        tok.*.end = tmp;
        break :blk tmp;
    };
    tok.*.size = 0;
    tok.*.parent = -@as(c_int, 1);
    return tok;
}
pub fn jsmn_fill_token(arg_token: [*c]jsmntok_t, arg_type: jsmntype_t, arg_start: ptrdiff_t, arg_end: ptrdiff_t) callconv(.c) void {
    var token = arg_token;
    _ = &token;
    var @"type" = arg_type;
    _ = &@"type";
    var start = arg_start;
    _ = &start;
    var end = arg_end;
    _ = &end;
    token.*.type = @"type";
    token.*.start = start;
    token.*.end = end;
    token.*.size = 0;
} // .\include\cgltf\cgltf.h:6949:9: warning: TODO goto
// .\include\cgltf\cgltf.h:6934:12: warning: unable to translate function, demoted to extern
pub extern fn jsmn_parse_primitive(arg_parser: [*c]jsmn_parser, arg_js: [*c]const u8, arg_len: usize, arg_tokens: [*c]jsmntok_t, arg_num_tokens: usize) callconv(.c) c_int;
pub fn jsmn_parse_string(arg_parser: [*c]jsmn_parser, arg_js: [*c]const u8, arg_len: usize, arg_tokens: [*c]jsmntok_t, arg_num_tokens: usize) callconv(.c) c_int {
    var parser = arg_parser;
    _ = &parser;
    var js = arg_js;
    _ = &js;
    var len = arg_len;
    _ = &len;
    var tokens = arg_tokens;
    _ = &tokens;
    var num_tokens = arg_num_tokens;
    _ = &num_tokens;
    var token: [*c]jsmntok_t = undefined;
    _ = &token;
    var start: ptrdiff_t = @bitCast(@as(c_ulonglong, @truncate(parser.*.pos)));
    _ = &start;
    parser.*.pos +%= 1;
    while ((parser.*.pos < len) and (@as(c_int, js[@intCast(parser.*.pos)]) != @as(c_int, '\x00'))) : (parser.*.pos +%= 1) {
        var c: u8 = js[@intCast(parser.*.pos)];
        _ = &c;
        if (@as(c_int, c) == @as(c_int, '"')) {
            if (@as(?*anyopaque, @ptrCast(@alignCast(tokens))) == @as(?*anyopaque, null)) {
                return 0;
            }
            token = jsmn_alloc_token(parser, tokens, num_tokens);
            if (@as(?*anyopaque, @ptrCast(@alignCast(token))) == @as(?*anyopaque, null)) {
                parser.*.pos = @bitCast(@as(c_longlong, start));
                return JSMN_ERROR_NOMEM;
            }
            jsmn_fill_token(token, JSMN_STRING, start + @as(ptrdiff_t, 1), @bitCast(@as(c_ulonglong, @truncate(parser.*.pos))));
            token.*.parent = parser.*.toksuper;
            return 0;
        }
        if ((@as(c_int, c) == @as(c_int, '\\')) and ((parser.*.pos +% @as(usize, 1)) < len)) {
            var i: c_int = undefined;
            _ = &i;
            parser.*.pos +%= 1;
            while (true) {
                switch (@as(c_int, js[@intCast(parser.*.pos)])) {
                    @as(c_int, '"'), @as(c_int, '/'), @as(c_int, '\\'), @as(c_int, 'b'), @as(c_int, 'f'), @as(c_int, 'r'), @as(c_int, 'n'), @as(c_int, 't') => {
                        break;
                    },
                    @as(c_int, 'u') => {
                        parser.*.pos +%= 1;
                        {
                            i = 0;
                            while (((i < @as(c_int, 4)) and (parser.*.pos < len)) and (@as(c_int, js[@intCast(parser.*.pos)]) != @as(c_int, '\x00'))) : (i += 1) {
                                if (!((((@as(c_int, js[@intCast(parser.*.pos)]) >= @as(c_int, 48)) and (@as(c_int, js[@intCast(parser.*.pos)]) <= @as(c_int, 57))) or ((@as(c_int, js[@intCast(parser.*.pos)]) >= @as(c_int, 65)) and (@as(c_int, js[@intCast(parser.*.pos)]) <= @as(c_int, 70)))) or ((@as(c_int, js[@intCast(parser.*.pos)]) >= @as(c_int, 97)) and (@as(c_int, js[@intCast(parser.*.pos)]) <= @as(c_int, 102))))) {
                                    parser.*.pos = @bitCast(@as(c_longlong, start));
                                    return JSMN_ERROR_INVAL;
                                }
                                parser.*.pos +%= 1;
                            }
                        }
                        parser.*.pos -%= 1;
                        break;
                    },
                    else => {
                        parser.*.pos = @bitCast(@as(c_longlong, start));
                        return JSMN_ERROR_INVAL;
                    },
                }
                break;
            }
        }
    }
    parser.*.pos = @bitCast(@as(c_longlong, start));
    return JSMN_ERROR_PART;
}

pub const __VERSION__ = "Aro aro-zig";
pub const __Aro__ = "";
pub const __STDC__ = @as(c_int, 1);
pub const __STDC_HOSTED__ = @as(c_int, 1);
pub const __STDC_UTF_16__ = @as(c_int, 1);
pub const __STDC_UTF_32__ = @as(c_int, 1);
pub const __STDC_EMBED_NOT_FOUND__ = @as(c_int, 0);
pub const __STDC_EMBED_FOUND__ = @as(c_int, 1);
pub const __STDC_EMBED_EMPTY__ = @as(c_int, 2);
pub const __STDC_VERSION__ = @as(c_long, 201710);
pub const __GNUC__ = @as(c_int, 7);
pub const __GNUC_MINOR__ = @as(c_int, 1);
pub const __GNUC_PATCHLEVEL__ = @as(c_int, 0);
pub const __ARO_EMULATE_NO__ = @as(c_int, 0);
pub const __ARO_EMULATE_CLANG__ = @as(c_int, 1);
pub const __ARO_EMULATE_GCC__ = @as(c_int, 2);
pub const __ARO_EMULATE_MSVC__ = @as(c_int, 3);
pub const __ARO_EMULATE__ = __ARO_EMULATE_GCC__;
pub inline fn __building_module(x: anytype) @TypeOf(@as(c_int, 0)) {
    _ = &x;
    return @as(c_int, 0);
}
pub const _WIN32 = @as(c_int, 1);
pub const _WIN64 = @as(c_int, 1);
pub const WIN32 = @as(c_int, 1);
pub const __WIN32 = @as(c_int, 1);
pub const __WIN32__ = @as(c_int, 1);
pub const WINNT = @as(c_int, 1);
pub const __WINNT = @as(c_int, 1);
pub const __WINNT__ = @as(c_int, 1);
pub const WIN64 = @as(c_int, 1);
pub const __WIN64 = @as(c_int, 1);
pub const __WIN64__ = @as(c_int, 1);
pub const __MINGW64__ = @as(c_int, 1);
pub const __MSVCRT__ = @as(c_int, 1);
pub const __MINGW32__ = @as(c_int, 1);
pub const __declspec = @compileError("unable to translate C expr: unexpected token '__attribute__'"); // <builtin>:34:9
pub const _cdecl = @compileError("unable to translate macro: undefined identifier `__cdecl__`"); // <builtin>:35:9
pub const __cdecl = @compileError("unable to translate macro: undefined identifier `__cdecl__`"); // <builtin>:36:9
pub const _stdcall = @compileError("unable to translate macro: undefined identifier `__stdcall__`"); // <builtin>:37:9
pub const __stdcall = @compileError("unable to translate macro: undefined identifier `__stdcall__`"); // <builtin>:38:9
pub const _fastcall = @compileError("unable to translate macro: undefined identifier `__fastcall__`"); // <builtin>:39:9
pub const __fastcall = @compileError("unable to translate macro: undefined identifier `__fastcall__`"); // <builtin>:40:9
pub const _thiscall = @compileError("unable to translate macro: undefined identifier `__thiscall__`"); // <builtin>:41:9
pub const __thiscall = @compileError("unable to translate macro: undefined identifier `__thiscall__`"); // <builtin>:42:9
pub const unix = @as(c_int, 1);
pub const __unix = @as(c_int, 1);
pub const __unix__ = @as(c_int, 1);
pub const __code_model_small__ = @as(c_int, 1);
pub const __amd64__ = @as(c_int, 1);
pub const __amd64 = @as(c_int, 1);
pub const __x86_64__ = @as(c_int, 1);
pub const __x86_64 = @as(c_int, 1);
pub const __SEG_GS = @as(c_int, 1);
pub const __SEG_FS = @as(c_int, 1);
pub const __seg_gs = @compileError("unable to translate macro: undefined identifier `address_space`"); // <builtin>:53:9
pub const __seg_fs = @compileError("unable to translate macro: undefined identifier `address_space`"); // <builtin>:54:9
pub const __LAHF_SAHF__ = @as(c_int, 1);
pub const __AES__ = @as(c_int, 1);
pub const __VAES__ = @as(c_int, 1);
pub const __PCLMUL__ = @as(c_int, 1);
pub const __VPCLMULQDQ__ = @as(c_int, 1);
pub const __LZCNT__ = @as(c_int, 1);
pub const __RDRND__ = @as(c_int, 1);
pub const __FSGSBASE__ = @as(c_int, 1);
pub const __BMI__ = @as(c_int, 1);
pub const __BMI2__ = @as(c_int, 1);
pub const __POPCNT__ = @as(c_int, 1);
pub const __PRFCHW__ = @as(c_int, 1);
pub const __RDSEED__ = @as(c_int, 1);
pub const __ADX__ = @as(c_int, 1);
pub const __MOVBE__ = @as(c_int, 1);
pub const __FMA__ = @as(c_int, 1);
pub const __F16C__ = @as(c_int, 1);
pub const __GFNI__ = @as(c_int, 1);
pub const __SHA__ = @as(c_int, 1);
pub const __FXSR__ = @as(c_int, 1);
pub const __XSAVE__ = @as(c_int, 1);
pub const __XSAVEOPT__ = @as(c_int, 1);
pub const __XSAVEC__ = @as(c_int, 1);
pub const __XSAVES__ = @as(c_int, 1);
pub const __CLFLUSHOPT__ = @as(c_int, 1);
pub const __CLWB__ = @as(c_int, 1);
pub const __SHSTK__ = @as(c_int, 1);
pub const __RDPID__ = @as(c_int, 1);
pub const __WAITPKG__ = @as(c_int, 1);
pub const __MOVDIRI__ = @as(c_int, 1);
pub const __MOVDIR64B__ = @as(c_int, 1);
pub const __PTWRITE__ = @as(c_int, 1);
pub const __INVPCID__ = @as(c_int, 1);
pub const __HRESET__ = @as(c_int, 1);
pub const __AVXVNNI__ = @as(c_int, 1);
pub const __SERIALIZE__ = @as(c_int, 1);
pub const __CRC32__ = @as(c_int, 1);
pub const __AVX2__ = @as(c_int, 1);
pub const __AVX__ = @as(c_int, 1);
pub const __SSE4_2__ = @as(c_int, 1);
pub const __SSE4_1__ = @as(c_int, 1);
pub const __SSSE3__ = @as(c_int, 1);
pub const __SSE3__ = @as(c_int, 1);
pub const __SSE2__ = @as(c_int, 1);
pub const __SSE__ = @as(c_int, 1);
pub const __SSE_MATH__ = @as(c_int, 1);
pub const __MMX__ = @as(c_int, 1);
pub const __GCC_HAVE_SYNC_COMPARE_AND_SWAP_8 = @as(c_int, 1);
pub const __ORDER_LITTLE_ENDIAN__ = @as(c_int, 1234);
pub const __ORDER_BIG_ENDIAN__ = @as(c_int, 4321);
pub const __ORDER_PDP_ENDIAN__ = @as(c_int, 3412);
pub const __BYTE_ORDER__ = __ORDER_LITTLE_ENDIAN__;
pub const __LITTLE_ENDIAN__ = @as(c_int, 1);
pub const __ATOMIC_RELAXED = @as(c_int, 0);
pub const __ATOMIC_CONSUME = @as(c_int, 1);
pub const __ATOMIC_ACQUIRE = @as(c_int, 2);
pub const __ATOMIC_RELEASE = @as(c_int, 3);
pub const __ATOMIC_ACQ_REL = @as(c_int, 4);
pub const __ATOMIC_SEQ_CST = @as(c_int, 5);
pub const __ATOMIC_BOOL_LOCK_FREE = @as(c_int, 1);
pub const __ATOMIC_CHAR_LOCK_FREE = @as(c_int, 1);
pub const __ATOMIC_CHAR16_T_LOCK_FREE = @as(c_int, 1);
pub const __ATOMIC_CHAR32_T_LOCK_FREE = @as(c_int, 1);
pub const __ATOMIC_WCHAR_T_LOCK_FREE = @as(c_int, 1);
pub const __ATOMIC_WINT_T_LOCK_FREE = @as(c_int, 1);
pub const __ATOMIC_SHORT_LOCK_FREE = @as(c_int, 1);
pub const __ATOMIC_INT_LOCK_FREE = @as(c_int, 1);
pub const __ATOMIC_LONG_LOCK_FREE = @as(c_int, 1);
pub const __ATOMIC_LLONG_LOCK_FREE = @as(c_int, 1);
pub const __ATOMIC_POINTER_LOCK_FREE = @as(c_int, 1);
pub const __WCHAR_UNSIGNED__ = @as(c_int, 1);
pub const __WINT_UNSIGNED__ = @as(c_int, 1);
pub const __CHAR_BIT__ = @as(c_int, 8);
pub const __BOOL_WIDTH__ = @as(c_int, 8);
pub const __SCHAR_MAX__ = @as(c_int, 127);
pub const __SCHAR_WIDTH__ = @as(c_int, 8);
pub const __SHRT_MAX__ = @as(c_int, 32767);
pub const __SHRT_WIDTH__ = @as(c_int, 16);
pub const __INT_MAX__ = __helpers.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __INT_WIDTH__ = @as(c_int, 32);
pub const __LONG_MAX__ = @as(c_long, 2147483647);
pub const __LONG_WIDTH__ = @as(c_int, 32);
pub const __LONG_LONG_MAX__ = @as(c_longlong, 9223372036854775807);
pub const __LONG_LONG_WIDTH__ = @as(c_int, 64);
pub const __WCHAR_MAX__ = __helpers.promoteIntLiteral(c_int, 65535, .decimal);
pub const __WCHAR_WIDTH__ = @as(c_int, 16);
pub const __WINT_MAX__ = __helpers.promoteIntLiteral(c_int, 65535, .decimal);
pub const __WINT_WIDTH__ = @as(c_int, 16);
pub const __INTMAX_MAX__ = @as(c_longlong, 9223372036854775807);
pub const __INTMAX_WIDTH__ = @as(c_int, 64);
pub const __SIZE_MAX__ = @as(c_ulonglong, 18446744073709551615);
pub const __SIZE_WIDTH__ = @as(c_int, 64);
pub const __UINTMAX_MAX__ = @as(c_ulonglong, 18446744073709551615);
pub const __UINTMAX_WIDTH__ = @as(c_int, 64);
pub const __PTRDIFF_MAX__ = @as(c_longlong, 9223372036854775807);
pub const __PTRDIFF_WIDTH__ = @as(c_int, 64);
pub const __INTPTR_MAX__ = @as(c_longlong, 9223372036854775807);
pub const __INTPTR_WIDTH__ = @as(c_int, 64);
pub const __UINTPTR_MAX__ = @as(c_ulonglong, 18446744073709551615);
pub const __UINTPTR_WIDTH__ = @as(c_int, 64);
pub const __SIG_ATOMIC_MAX__ = __helpers.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __SIG_ATOMIC_WIDTH__ = @as(c_int, 32);
pub const __BITINT_MAXWIDTH__ = __helpers.promoteIntLiteral(c_int, 65535, .decimal);
pub const __SIZEOF_FLOAT__ = @as(c_int, 4);
pub const __SIZEOF_DOUBLE__ = @as(c_int, 8);
pub const __SIZEOF_LONG_DOUBLE__ = @as(c_int, 10);
pub const __SIZEOF_SHORT__ = @as(c_int, 2);
pub const __SIZEOF_INT__ = @as(c_int, 4);
pub const __SIZEOF_LONG__ = @as(c_int, 4);
pub const __SIZEOF_LONG_LONG__ = @as(c_int, 8);
pub const __SIZEOF_POINTER__ = @as(c_int, 8);
pub const __SIZEOF_PTRDIFF_T__ = @as(c_int, 8);
pub const __SIZEOF_SIZE_T__ = @as(c_int, 8);
pub const __SIZEOF_WCHAR_T__ = @as(c_int, 2);
pub const __SIZEOF_WINT_T__ = @as(c_int, 2);
pub const __SIZEOF_INT128__ = @as(c_int, 16);
pub const __INTPTR_TYPE__ = c_longlong;
pub const __UINTPTR_TYPE__ = c_ulonglong;
pub const __INTMAX_TYPE__ = c_longlong;
pub const __INTMAX_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `LL`"); // <builtin>:175:9
pub const __INTMAX_C = __helpers.LL_SUFFIX;
pub const __UINTMAX_TYPE__ = c_ulonglong;
pub const __UINTMAX_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `ULL`"); // <builtin>:178:9
pub const __UINTMAX_C = __helpers.ULL_SUFFIX;
pub const __PTRDIFF_TYPE__ = c_longlong;
pub const __SIZE_TYPE__ = c_ulonglong;
pub const __WCHAR_TYPE__ = c_ushort;
pub const __WINT_TYPE__ = c_ushort;
pub const __CHAR16_TYPE__ = c_ushort;
pub const __CHAR32_TYPE__ = c_uint;
pub const __INT8_TYPE__ = i8;
pub const __INT8_FMTd__ = "hhd";
pub const __INT8_FMTi__ = "hhi";
pub const __INT8_C_SUFFIX__ = "";
pub inline fn __INT8_C(c: anytype) @TypeOf(c) {
    _ = &c;
    return c;
}
pub const __INT16_TYPE__ = c_short;
pub const __INT16_FMTd__ = "hd";
pub const __INT16_FMTi__ = "hi";
pub const __INT16_C_SUFFIX__ = "";
pub inline fn __INT16_C(c: anytype) @TypeOf(c) {
    _ = &c;
    return c;
}
pub const __INT32_TYPE__ = c_int;
pub const __INT32_FMTd__ = "d";
pub const __INT32_FMTi__ = "i";
pub const __INT32_C_SUFFIX__ = "";
pub inline fn __INT32_C(c: anytype) @TypeOf(c) {
    _ = &c;
    return c;
}
pub const __INT64_TYPE__ = c_longlong;
pub const __INT64_FMTd__ = "lld";
pub const __INT64_FMTi__ = "lli";
pub const __INT64_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `LL`"); // <builtin>:204:9
pub const __INT64_C = __helpers.LL_SUFFIX;
pub const __UINT8_TYPE__ = u8;
pub const __UINT8_FMTo__ = "hho";
pub const __UINT8_FMTu__ = "hhu";
pub const __UINT8_FMTx__ = "hhx";
pub const __UINT8_FMTX__ = "hhX";
pub const __UINT8_C_SUFFIX__ = "";
pub inline fn __UINT8_C(c: anytype) @TypeOf(c) {
    _ = &c;
    return c;
}
pub const __UINT8_MAX__ = @as(c_int, 255);
pub const __INT8_MAX__ = @as(c_int, 127);
pub const __UINT16_TYPE__ = c_ushort;
pub const __UINT16_FMTo__ = "ho";
pub const __UINT16_FMTu__ = "hu";
pub const __UINT16_FMTx__ = "hx";
pub const __UINT16_FMTX__ = "hX";
pub const __UINT16_C_SUFFIX__ = "";
pub inline fn __UINT16_C(c: anytype) @TypeOf(c) {
    _ = &c;
    return c;
}
pub const __UINT16_MAX__ = __helpers.promoteIntLiteral(c_int, 65535, .decimal);
pub const __INT16_MAX__ = @as(c_int, 32767);
pub const __UINT32_TYPE__ = c_uint;
pub const __UINT32_FMTo__ = "o";
pub const __UINT32_FMTu__ = "u";
pub const __UINT32_FMTx__ = "x";
pub const __UINT32_FMTX__ = "X";
pub const __UINT32_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `U`"); // <builtin>:229:9
pub const __UINT32_C = __helpers.U_SUFFIX;
pub const __UINT32_MAX__ = __helpers.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const __INT32_MAX__ = __helpers.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __UINT64_TYPE__ = c_ulonglong;
pub const __UINT64_FMTo__ = "llo";
pub const __UINT64_FMTu__ = "llu";
pub const __UINT64_FMTx__ = "llx";
pub const __UINT64_FMTX__ = "llX";
pub const __UINT64_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `ULL`"); // <builtin>:238:9
pub const __UINT64_C = __helpers.ULL_SUFFIX;
pub const __UINT64_MAX__ = @as(c_ulonglong, 18446744073709551615);
pub const __INT64_MAX__ = @as(c_longlong, 9223372036854775807);
pub const __INT_LEAST8_TYPE__ = i8;
pub const __INT_LEAST8_MAX__ = @as(c_int, 127);
pub const __INT_LEAST8_WIDTH__ = @as(c_int, 8);
pub const INT_LEAST8_FMTd__ = "hhd";
pub const INT_LEAST8_FMTi__ = "hhi";
pub const __UINT_LEAST8_TYPE__ = u8;
pub const __UINT_LEAST8_MAX__ = @as(c_int, 255);
pub const UINT_LEAST8_FMTo__ = "hho";
pub const UINT_LEAST8_FMTu__ = "hhu";
pub const UINT_LEAST8_FMTx__ = "hhx";
pub const UINT_LEAST8_FMTX__ = "hhX";
pub const __INT_FAST8_TYPE__ = i8;
pub const __INT_FAST8_MAX__ = @as(c_int, 127);
pub const __INT_FAST8_WIDTH__ = @as(c_int, 8);
pub const INT_FAST8_FMTd__ = "hhd";
pub const INT_FAST8_FMTi__ = "hhi";
pub const __UINT_FAST8_TYPE__ = u8;
pub const __UINT_FAST8_MAX__ = @as(c_int, 255);
pub const UINT_FAST8_FMTo__ = "hho";
pub const UINT_FAST8_FMTu__ = "hhu";
pub const UINT_FAST8_FMTx__ = "hhx";
pub const UINT_FAST8_FMTX__ = "hhX";
pub const __INT_LEAST16_TYPE__ = c_short;
pub const __INT_LEAST16_MAX__ = @as(c_int, 32767);
pub const __INT_LEAST16_WIDTH__ = @as(c_int, 16);
pub const INT_LEAST16_FMTd__ = "hd";
pub const INT_LEAST16_FMTi__ = "hi";
pub const __UINT_LEAST16_TYPE__ = c_ushort;
pub const __UINT_LEAST16_MAX__ = __helpers.promoteIntLiteral(c_int, 65535, .decimal);
pub const UINT_LEAST16_FMTo__ = "ho";
pub const UINT_LEAST16_FMTu__ = "hu";
pub const UINT_LEAST16_FMTx__ = "hx";
pub const UINT_LEAST16_FMTX__ = "hX";
pub const __INT_FAST16_TYPE__ = c_short;
pub const __INT_FAST16_MAX__ = @as(c_int, 32767);
pub const __INT_FAST16_WIDTH__ = @as(c_int, 16);
pub const INT_FAST16_FMTd__ = "hd";
pub const INT_FAST16_FMTi__ = "hi";
pub const __UINT_FAST16_TYPE__ = c_ushort;
pub const __UINT_FAST16_MAX__ = __helpers.promoteIntLiteral(c_int, 65535, .decimal);
pub const UINT_FAST16_FMTo__ = "ho";
pub const UINT_FAST16_FMTu__ = "hu";
pub const UINT_FAST16_FMTx__ = "hx";
pub const UINT_FAST16_FMTX__ = "hX";
pub const __INT_LEAST32_TYPE__ = c_int;
pub const __INT_LEAST32_MAX__ = __helpers.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __INT_LEAST32_WIDTH__ = @as(c_int, 32);
pub const INT_LEAST32_FMTd__ = "d";
pub const INT_LEAST32_FMTi__ = "i";
pub const __UINT_LEAST32_TYPE__ = c_uint;
pub const __UINT_LEAST32_MAX__ = __helpers.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const UINT_LEAST32_FMTo__ = "o";
pub const UINT_LEAST32_FMTu__ = "u";
pub const UINT_LEAST32_FMTx__ = "x";
pub const UINT_LEAST32_FMTX__ = "X";
pub const __INT_FAST32_TYPE__ = c_int;
pub const __INT_FAST32_MAX__ = __helpers.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __INT_FAST32_WIDTH__ = @as(c_int, 32);
pub const INT_FAST32_FMTd__ = "d";
pub const INT_FAST32_FMTi__ = "i";
pub const __UINT_FAST32_TYPE__ = c_uint;
pub const __UINT_FAST32_MAX__ = __helpers.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const UINT_FAST32_FMTo__ = "o";
pub const UINT_FAST32_FMTu__ = "u";
pub const UINT_FAST32_FMTx__ = "x";
pub const UINT_FAST32_FMTX__ = "X";
pub const __INT_LEAST64_TYPE__ = c_longlong;
pub const __INT_LEAST64_MAX__ = @as(c_longlong, 9223372036854775807);
pub const __INT_LEAST64_WIDTH__ = @as(c_int, 64);
pub const INT_LEAST64_FMTd__ = "lld";
pub const INT_LEAST64_FMTi__ = "lli";
pub const __UINT_LEAST64_TYPE__ = c_ulonglong;
pub const __UINT_LEAST64_MAX__ = @as(c_ulonglong, 18446744073709551615);
pub const UINT_LEAST64_FMTo__ = "llo";
pub const UINT_LEAST64_FMTu__ = "llu";
pub const UINT_LEAST64_FMTx__ = "llx";
pub const UINT_LEAST64_FMTX__ = "llX";
pub const __INT_FAST64_TYPE__ = c_longlong;
pub const __INT_FAST64_MAX__ = @as(c_longlong, 9223372036854775807);
pub const __INT_FAST64_WIDTH__ = @as(c_int, 64);
pub const INT_FAST64_FMTd__ = "lld";
pub const INT_FAST64_FMTi__ = "lli";
pub const __UINT_FAST64_TYPE__ = c_ulonglong;
pub const __UINT_FAST64_MAX__ = @as(c_ulonglong, 18446744073709551615);
pub const UINT_FAST64_FMTo__ = "llo";
pub const UINT_FAST64_FMTu__ = "llu";
pub const UINT_FAST64_FMTx__ = "llx";
pub const UINT_FAST64_FMTX__ = "llX";
pub const __FLT16_DENORM_MIN__ = @as(f16, 5.9604644775390625e-8);
pub const __FLT16_HAS_DENORM__ = "";
pub const __FLT16_DIG__ = @as(c_int, 3);
pub const __FLT16_DECIMAL_DIG__ = @as(c_int, 5);
pub const __FLT16_EPSILON__ = @as(f16, 9.765625e-4);
pub const __FLT16_HAS_INFINITY__ = "";
pub const __FLT16_HAS_QUIET_NAN__ = "";
pub const __FLT16_MANT_DIG__ = @as(c_int, 11);
pub const __FLT16_MAX_10_EXP__ = @as(c_int, 4);
pub const __FLT16_MAX_EXP__ = @as(c_int, 16);
pub const __FLT16_MAX__ = @as(f16, 6.5504e+4);
pub const __FLT16_MIN_10_EXP__ = -@as(c_int, 4);
pub const __FLT16_MIN_EXP__ = -@as(c_int, 13);
pub const __FLT16_MIN__ = @as(f16, 6.103515625e-5);
pub const __FLT_DENORM_MIN__ = @as(f32, 1.40129846e-45);
pub const __FLT_HAS_DENORM__ = "";
pub const __FLT_DIG__ = @as(c_int, 6);
pub const __FLT_DECIMAL_DIG__ = @as(c_int, 9);
pub const __FLT_EPSILON__ = @as(f32, 1.19209290e-7);
pub const __FLT_HAS_INFINITY__ = "";
pub const __FLT_HAS_QUIET_NAN__ = "";
pub const __FLT_MANT_DIG__ = @as(c_int, 24);
pub const __FLT_MAX_10_EXP__ = @as(c_int, 38);
pub const __FLT_MAX_EXP__ = @as(c_int, 128);
pub const __FLT_MAX__ = @as(f32, 3.40282347e+38);
pub const __FLT_MIN_10_EXP__ = -@as(c_int, 37);
pub const __FLT_MIN_EXP__ = -@as(c_int, 125);
pub const __FLT_MIN__ = @as(f32, 1.17549435e-38);
pub const __DBL_DENORM_MIN__ = @as(f64, 4.9406564584124654e-324);
pub const __DBL_HAS_DENORM__ = "";
pub const __DBL_DIG__ = @as(c_int, 15);
pub const __DBL_DECIMAL_DIG__ = @as(c_int, 17);
pub const __DBL_EPSILON__ = @as(f64, 2.2204460492503131e-16);
pub const __DBL_HAS_INFINITY__ = "";
pub const __DBL_HAS_QUIET_NAN__ = "";
pub const __DBL_MANT_DIG__ = @as(c_int, 53);
pub const __DBL_MAX_10_EXP__ = @as(c_int, 308);
pub const __DBL_MAX_EXP__ = @as(c_int, 1024);
pub const __DBL_MAX__ = @as(f64, 1.7976931348623157e+308);
pub const __DBL_MIN_10_EXP__ = -@as(c_int, 307);
pub const __DBL_MIN_EXP__ = -@as(c_int, 1021);
pub const __DBL_MIN__ = @as(f64, 2.2250738585072014e-308);
pub const __LDBL_DENORM_MIN__ = @as(c_longdouble, 3.64519953188247460253e-4951);
pub const __LDBL_HAS_DENORM__ = "";
pub const __LDBL_DIG__ = @as(c_int, 18);
pub const __LDBL_DECIMAL_DIG__ = @as(c_int, 21);
pub const __LDBL_EPSILON__ = @as(c_longdouble, 1.08420217248550443401e-19);
pub const __LDBL_HAS_INFINITY__ = "";
pub const __LDBL_HAS_QUIET_NAN__ = "";
pub const __LDBL_MANT_DIG__ = @as(c_int, 64);
pub const __LDBL_MAX_10_EXP__ = @as(c_int, 4932);
pub const __LDBL_MAX_EXP__ = @as(c_int, 16384);
pub const __LDBL_MAX__ = @as(c_longdouble, 1.18973149535723176502e+4932);
pub const __LDBL_MIN_10_EXP__ = -@as(c_int, 4931);
pub const __LDBL_MIN_EXP__ = -@as(c_int, 16381);
pub const __LDBL_MIN__ = @as(c_longdouble, 3.36210314311209350626e-4932);
pub const __FLT_EVAL_METHOD__ = @as(c_int, 0);
pub const __FLT_RADIX__ = @as(c_int, 2);
pub const __DECIMAL_DIG__ = __LDBL_DECIMAL_DIG__;
pub const __pic__ = @as(c_int, 2);
pub const __PIC__ = @as(c_int, 2);
pub const __MSVCRT_VERSION__ = @as(c_int, 0xE00);
pub const _WIN32_WINNT = @as(c_int, 0x0a00);
pub const CGLTF_IMPLEMENTATION = "";
pub const CGLTF_H_INCLUDED__ = "";
pub const __STDC_VERSION_STDDEF_H__ = @as(c_long, 202311);
pub const NULL = __helpers.cast(?*anyopaque, @as(c_int, 0));
pub const offsetof = @compileError("unable to translate macro: undefined identifier `__builtin_offsetof`"); // C:\D\zig\zig-x86_64-windows-0.16.0\lib\compiler\aro\include\stddef.h:18:9
pub const __CLANG_STDINT_H = "";
pub const _STDINT_H = "";
pub const _INC_CRTDEFS = "";
pub const _INC_CORECRT = "";
pub const _INC__MINGW_H = "";
pub const _INC_CRTDEFS_MACRO = "";
pub const __MINGW64_PASTE2 = @compileError("unable to translate C expr: unexpected token '##'"); // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\_mingw_mac.h:10:9
pub inline fn __MINGW64_PASTE(x: anytype, y: anytype) @TypeOf(__MINGW64_PASTE2(x, y)) {
    _ = &x;
    _ = &y;
    return __MINGW64_PASTE2(x, y);
}
pub const __STRINGIFY = @compileError("unable to translate C expr: unexpected token ''"); // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\_mingw_mac.h:13:9
pub inline fn __MINGW64_STRINGIFY(x: anytype) @TypeOf(__STRINGIFY(x)) {
    _ = &x;
    return __STRINGIFY(x);
}
pub const __MINGW64_VERSION_MAJOR = @as(c_int, 13);
pub const __MINGW64_VERSION_MINOR = @as(c_int, 0);
pub const __MINGW64_VERSION_BUGFIX = @as(c_int, 0);
pub const __MINGW64_VERSION_RC = @as(c_int, 0);
pub const __MINGW64_VERSION_STR = __MINGW64_STRINGIFY(__MINGW64_VERSION_MAJOR) ++ "." ++ __MINGW64_STRINGIFY(__MINGW64_VERSION_MINOR) ++ "." ++ __MINGW64_STRINGIFY(__MINGW64_VERSION_BUGFIX);
pub const __MINGW64_VERSION_STATE = "alpha";
pub const __MINGW32_MAJOR_VERSION = @as(c_int, 3);
pub const __MINGW32_MINOR_VERSION = @as(c_int, 11);
pub const _M_AMD64 = @as(c_int, 100);
pub const _M_X64 = @as(c_int, 100);
pub const __MINGW_USE_UNDERSCORE_PREFIX = @as(c_int, 0);
pub const __MINGW_IMP_SYMBOL = @compileError("unable to translate macro: undefined identifier `__imp_`"); // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\_mingw_mac.h:129:11
pub const __MINGW_IMP_LSYMBOL = @compileError("unable to translate macro: undefined identifier `__imp_`"); // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\_mingw_mac.h:130:11
pub inline fn __MINGW_USYMBOL(sym: anytype) @TypeOf(sym) {
    _ = &sym;
    return sym;
}
pub const __MINGW_LSYMBOL = @compileError("unable to translate macro: undefined identifier `_`"); // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\_mingw_mac.h:132:11
pub const __MINGW_ASM_CALL = @compileError("unable to translate C expr: unexpected token '__asm__'"); // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\_mingw_mac.h:140:9
pub const __MINGW_ASM_CRT_CALL = @compileError("unable to translate C expr: unexpected token '__asm__'"); // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\_mingw_mac.h:141:9
pub const __MINGW_EXTENSION = @compileError("unable to translate C expr: unexpected token '__extension__'"); // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\_mingw_mac.h:173:13
pub const __C89_NAMELESS = __MINGW_EXTENSION;
pub const __C89_NAMELESSSTRUCTNAME = "";
pub const __C89_NAMELESSSTRUCTNAME1 = "";
pub const __C89_NAMELESSSTRUCTNAME2 = "";
pub const __C89_NAMELESSSTRUCTNAME3 = "";
pub const __C89_NAMELESSSTRUCTNAME4 = "";
pub const __C89_NAMELESSSTRUCTNAME5 = "";
pub const __C89_NAMELESSUNIONNAME = "";
pub const __C89_NAMELESSUNIONNAME1 = "";
pub const __C89_NAMELESSUNIONNAME2 = "";
pub const __C89_NAMELESSUNIONNAME3 = "";
pub const __C89_NAMELESSUNIONNAME4 = "";
pub const __C89_NAMELESSUNIONNAME5 = "";
pub const __C89_NAMELESSUNIONNAME6 = "";
pub const __C89_NAMELESSUNIONNAME7 = "";
pub const __C89_NAMELESSUNIONNAME8 = "";
pub const __GNU_EXTENSION = __MINGW_EXTENSION;
pub const __MINGW_HAVE_ANSI_C99_PRINTF = @as(c_int, 1);
pub const __MINGW_HAVE_WIDE_C99_PRINTF = @as(c_int, 1);
pub const __MINGW_HAVE_ANSI_C99_SCANF = @as(c_int, 1);
pub const __MINGW_HAVE_WIDE_C99_SCANF = @as(c_int, 1);
pub const __MINGW_POISON_NAME = @compileError("unable to translate macro: undefined identifier `_layout_has_not_been_verified_and_its_declaration_is_most_likely_incorrect`"); // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\_mingw_mac.h:213:11
pub const __MSABI_LONG = __helpers.L_SUFFIX;
pub const __MINGW_GCC_VERSION = ((__GNUC__ * @as(c_int, 10000)) + (__GNUC_MINOR__ * @as(c_int, 100))) + __GNUC_PATCHLEVEL__;
pub inline fn __MINGW_GNUC_PREREQ(major: anytype, minor: anytype) @TypeOf((__GNUC__ > major) or ((__GNUC__ == major) and (__GNUC_MINOR__ >= minor))) {
    _ = &major;
    _ = &minor;
    return (__GNUC__ > major) or ((__GNUC__ == major) and (__GNUC_MINOR__ >= minor));
}
pub inline fn __MINGW_MSC_PREREQ(major: anytype, minor: anytype) @TypeOf(@as(c_int, 0)) {
    _ = &major;
    _ = &minor;
    return @as(c_int, 0);
}
pub inline fn __MINGW_ATTRIB_DEPRECATED_STR(X: anytype) void {
    _ = &X;
    return;
}
pub const __MINGW_SEC_WARN_STR = "This function or variable may be unsafe, use _CRT_SECURE_NO_WARNINGS to disable deprecation";
pub const __MINGW_MSVC2005_DEPREC_STR = "This POSIX function is deprecated beginning in Visual C++ 2005, use _CRT_NONSTDC_NO_DEPRECATE to disable deprecation";
pub const __MINGW_ATTRIB_DEPRECATED_MSVC2005 = __MINGW_ATTRIB_DEPRECATED_STR(__MINGW_MSVC2005_DEPREC_STR);
pub const __MINGW_ATTRIB_DEPRECATED_SEC_WARN = __MINGW_ATTRIB_DEPRECATED_STR(__MINGW_SEC_WARN_STR);
pub const __MINGW_MS_PRINTF = @compileError("unable to translate macro: undefined identifier `__format__`"); // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\_mingw_mac.h:293:9
pub const __MINGW_MS_SCANF = @compileError("unable to translate macro: undefined identifier `__format__`"); // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\_mingw_mac.h:296:9
pub const __MINGW_GNU_PRINTF = @compileError("unable to translate macro: undefined identifier `__format__`"); // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\_mingw_mac.h:299:9
pub const __MINGW_GNU_SCANF = @compileError("unable to translate macro: undefined identifier `__format__`"); // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\_mingw_mac.h:302:9
pub const __mingw_ovr = @compileError("unable to translate macro: undefined identifier `__unused__`"); // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\_mingw_mac.h:311:11
pub const __mingw_attribute_artificial = @compileError("unable to translate macro: undefined identifier `__artificial__`"); // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\_mingw_mac.h:318:11
pub const __MINGW_SELECTANY = @compileError("unable to translate macro: undefined identifier `__selectany__`"); // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\_mingw_mac.h:324:9
pub const __MINGW_FORTIFY_LEVEL = @as(c_int, 0);
pub const __mingw_bos_ovr = __mingw_ovr;
pub const __MINGW_FORTIFY_VA_ARG = @as(c_int, 0);
pub const _INC_MINGW_SECAPI = "";
pub const _CRT_SECURE_CPP_OVERLOAD_SECURE_NAMES = @as(c_int, 0);
pub const _CRT_SECURE_CPP_OVERLOAD_SECURE_NAMES_MEMORY = @as(c_int, 0);
pub const _CRT_SECURE_CPP_OVERLOAD_STANDARD_NAMES = @as(c_int, 0);
pub const _CRT_SECURE_CPP_OVERLOAD_STANDARD_NAMES_COUNT = @as(c_int, 0);
pub const _CRT_SECURE_CPP_OVERLOAD_STANDARD_NAMES_MEMORY = @as(c_int, 0);
pub const __MINGW_CRT_NAME_CONCAT2 = @compileError("unable to translate macro: undefined identifier `_s`"); // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\_mingw_secapi.h:41:9
pub const __CRT_SECURE_CPP_OVERLOAD_STANDARD_NAMES_MEMORY_0_3_ = @compileError("unable to translate C expr: unexpected token '__cdecl'"); // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\_mingw_secapi.h:69:9
pub const __LONG32 = c_long;
pub const __MINGW_IMPORT = @compileError("unable to translate macro: undefined identifier `__dllimport__`"); // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\_mingw.h:44:12
pub const __USE_CRTIMP = @as(c_int, 1);
pub const _CRTIMP = @compileError("unable to translate macro: undefined identifier `__dllimport__`"); // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\_mingw.h:52:15
pub const __DECLSPEC_SUPPORTED = "";
pub const USE___UUIDOF = @as(c_int, 0);
pub const _inline = @compileError("unable to translate C expr: unexpected token '__inline'"); // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\_mingw.h:74:9
pub const __CRT_INLINE = @compileError("unable to translate macro: undefined identifier `__gnu_inline__`"); // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\_mingw.h:83:11
pub const __MINGW_INTRIN_INLINE = @compileError("unable to translate macro: undefined identifier `__always_inline__`"); // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\_mingw.h:90:9
pub const __MINGW_CXX11_CONSTEXPR = "";
pub const __MINGW_CXX14_CONSTEXPR = "";
pub const __UNUSED_PARAM = @compileError("unable to translate macro: undefined identifier `__unused__`"); // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\_mingw.h:118:11
pub const __restrict_arr = @compileError("unable to translate C expr: unexpected token '__restrict'"); // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\_mingw.h:133:10
pub const __MINGW_ATTRIB_NORETURN = @compileError("unable to translate macro: undefined identifier `__noreturn__`"); // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\_mingw.h:149:9
pub const __MINGW_ATTRIB_CONST = @compileError("unable to translate C expr: unexpected token '__attribute__'"); // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\_mingw.h:150:9
pub const __MINGW_ATTRIB_MALLOC = @compileError("unable to translate macro: undefined identifier `__malloc__`"); // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\_mingw.h:160:9
pub const __MINGW_ATTRIB_PURE = @compileError("unable to translate macro: undefined identifier `__pure__`"); // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\_mingw.h:161:9
pub const __MINGW_ATTRIB_NONNULL = @compileError("unable to translate macro: undefined identifier `__nonnull__`"); // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\_mingw.h:174:9
pub const __MINGW_ATTRIB_UNUSED = @compileError("unable to translate macro: undefined identifier `__unused__`"); // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\_mingw.h:180:9
pub const __MINGW_ATTRIB_USED = @compileError("unable to translate macro: undefined identifier `__used__`"); // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\_mingw.h:186:9
pub const __MINGW_ATTRIB_DEPRECATED = @compileError("unable to translate macro: undefined identifier `__deprecated__`"); // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\_mingw.h:187:9
pub const __MINGW_ATTRIB_DEPRECATED_MSG = @compileError("unable to translate macro: undefined identifier `__deprecated__`"); // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\_mingw.h:189:9
pub const __MINGW_NOTHROW = @compileError("unable to translate macro: undefined identifier `__nothrow__`"); // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\_mingw.h:204:9
pub const __MINGW_ATTRIB_NO_OPTIMIZE = @compileError("unable to translate macro: undefined identifier `__optimize__`"); // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\_mingw.h:212:9
pub const __MINGW_PRAGMA_PARAM = @compileError("unable to translate macro: undefined identifier `_Pragma`"); // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\_mingw.h:218:9
pub const __MINGW_BROKEN_INTERFACE = @compileError("unable to translate macro: undefined identifier `message`"); // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\_mingw.h:225:9
pub const _UCRT = "";
pub inline fn __MINGW_UCRT_ASM_CALL(func: anytype) @TypeOf(__MINGW_ASM_CALL(func)) {
    _ = &func;
    return __MINGW_ASM_CALL(func);
}
pub const _INT128_DEFINED = "";
pub const __int8 = u8;
pub const __int16 = c_short;
pub const __int32 = c_int;
pub const __int64 = c_longlong;
pub const __ptr32 = "";
pub const __ptr64 = "";
pub const __unaligned = "";
pub const __w64 = "";
pub const __forceinline = @compileError("unable to translate macro: undefined identifier `__always_inline__`"); // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\_mingw.h:290:9
pub const __nothrow = "";
pub const _INC_VADEFS = "";
pub const MINGW_SDK_INIT = "";
pub const MINGW_HAS_SECURE_API = @as(c_int, 1);
pub const __STDC_SECURE_LIB__ = @as(c_long, 200411);
pub const __GOT_SECURE_LIB__ = __STDC_SECURE_LIB__;
pub const MINGW_DDK_H = "";
pub const MINGW_HAS_DDK_H = @as(c_int, 1);
pub const __GNUC_VA_LIST = "";
pub const _VA_LIST_DEFINED = "";
pub inline fn _ADDRESSOF(v: anytype) @TypeOf(&v) {
    _ = &v;
    return &v;
}
pub const _crt_va_start = @compileError("unable to translate macro: undefined identifier `__builtin_va_start`"); // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\vadefs.h:48:9
pub const _crt_va_arg = @compileError("unable to translate macro: undefined identifier `__builtin_va_arg`"); // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\vadefs.h:49:9
pub const _crt_va_end = @compileError("unable to translate macro: undefined identifier `__builtin_va_end`"); // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\vadefs.h:50:9
pub const _crt_va_copy = @compileError("unable to translate macro: undefined identifier `__builtin_va_copy`"); // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\vadefs.h:51:9
pub const __CRT_STRINGIZE = @compileError("unable to translate C expr: unexpected token ''"); // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\_mingw.h:309:9
pub inline fn _CRT_STRINGIZE(_Value: anytype) @TypeOf(__CRT_STRINGIZE(_Value)) {
    _ = &_Value;
    return __CRT_STRINGIZE(_Value);
}
pub const __CRT_WIDE = @compileError("unable to translate macro: undefined identifier `L`"); // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\_mingw.h:314:9
pub inline fn _CRT_WIDE(_String: anytype) @TypeOf(__CRT_WIDE(_String)) {
    _ = &_String;
    return __CRT_WIDE(_String);
}
pub const _W64 = "";
pub const _CRTIMP_NOIA64 = _CRTIMP;
pub const _CRTIMP2 = _CRTIMP;
pub const _CRTIMP_ALTERNATIVE = _CRTIMP;
pub const _CRT_ALTERNATIVE_IMPORTED = "";
pub const _MRTIMP2 = _CRTIMP;
pub const _DLL = "";
pub const _MT = "";
pub const _MCRTIMP = _CRTIMP;
pub const _CRTIMP_PURE = _CRTIMP;
pub const _PGLOBAL = "";
pub const _AGLOBAL = "";
pub const _SECURECRT_FILL_BUFFER_PATTERN = @as(c_int, 0xFD);
pub const _CRT_DEPRECATE_TEXT = @compileError("unable to translate macro: undefined identifier `deprecated`"); // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\_mingw.h:373:9
pub inline fn _CRT_INSECURE_DEPRECATE_MEMORY(_Replacement: anytype) void {
    _ = &_Replacement;
    return;
}
pub inline fn _CRT_INSECURE_DEPRECATE_GLOBALS(_Replacement: anytype) void {
    _ = &_Replacement;
    return;
}
pub const _CRT_MANAGED_HEAP_DEPRECATE = "";
pub inline fn _CRT_OBSOLETE(_NewItem: anytype) void {
    _ = &_NewItem;
    return;
}
pub const _CONST_RETURN = "";
pub const UNALIGNED = "";
pub const _CRT_ALIGN = @compileError("unable to translate macro: undefined identifier `__aligned__`"); // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\_mingw.h:415:9
pub const __CRTDECL = @compileError("unable to translate C expr: unexpected token '__cdecl'"); // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\_mingw.h:422:9
pub const _ARGMAX = @as(c_int, 100);
pub const _TRUNCATE = __helpers.cast(usize, -@as(c_int, 1));
pub inline fn _CRT_UNUSED(x: anytype) anyopaque {
    _ = &x;
    return __helpers.cast(anyopaque, x);
}
pub const __USE_MINGW_ANSI_STDIO = @as(c_int, 0);
pub const _CRT_glob = @compileError("unable to translate macro: undefined identifier `_dowildcard`"); // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\_mingw.h:479:9
pub const __ANONYMOUS_DEFINED = "";
pub const _ANONYMOUS_UNION = __MINGW_EXTENSION;
pub const _ANONYMOUS_STRUCT = __MINGW_EXTENSION;
pub inline fn _UNION_NAME(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn _STRUCT_NAME(x: anytype) void {
    _ = &x;
    return;
}
pub const DUMMYUNIONNAME = "";
pub const DUMMYUNIONNAME1 = "";
pub const DUMMYUNIONNAME2 = "";
pub const DUMMYUNIONNAME3 = "";
pub const DUMMYUNIONNAME4 = "";
pub const DUMMYUNIONNAME5 = "";
pub const DUMMYUNIONNAME6 = "";
pub const DUMMYUNIONNAME7 = "";
pub const DUMMYUNIONNAME8 = "";
pub const DUMMYUNIONNAME9 = "";
pub const DUMMYSTRUCTNAME = "";
pub const DUMMYSTRUCTNAME1 = "";
pub const DUMMYSTRUCTNAME2 = "";
pub const DUMMYSTRUCTNAME3 = "";
pub const DUMMYSTRUCTNAME4 = "";
pub const DUMMYSTRUCTNAME5 = "";
pub inline fn __CRT_UUID_DECL(@"type": anytype, l: anytype, w1: anytype, w2: anytype, b1: anytype, b2: anytype, b3: anytype, b4: anytype, b5: anytype, b6: anytype, b7: anytype, b8: anytype) void {
    _ = &@"type";
    _ = &l;
    _ = &w1;
    _ = &w2;
    _ = &b1;
    _ = &b2;
    _ = &b3;
    _ = &b4;
    _ = &b5;
    _ = &b6;
    _ = &b7;
    _ = &b8;
    return;
}
pub const __MINGW_DEBUGBREAK_IMPL = @compileError("unable to translate macro: undefined identifier `__debugbreak`"); // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\_mingw.h:599:9
pub const __MINGW_FASTFAIL_IMPL = @compileError("unable to translate macro: undefined identifier `__fastfail`"); // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\_mingw.h:620:9
pub const __MINGW_PREFETCH_IMPL = @compileError("unable to translate macro: undefined identifier `__prefetch`"); // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\_mingw.h:644:9
pub const _CRT_PACKING = @as(c_int, 8);
pub const _CRTNOALIAS = "";
pub const _CRTRESTRICT = "";
pub const _SIZE_T_DEFINED = "";
pub const _SSIZE_T_DEFINED = "";
pub const _RSIZE_T_DEFINED = "";
pub const _INTPTR_T_DEFINED = "";
pub const __intptr_t_defined = "";
pub const _UINTPTR_T_DEFINED = "";
pub const __uintptr_t_defined = "";
pub const _PTRDIFF_T_DEFINED = "";
pub const _PTRDIFF_T_ = "";
pub const _WCHAR_T_DEFINED = "";
pub const _WCTYPE_T_DEFINED = "";
pub const _WINT_T = "";
pub const _ERRCODE_DEFINED = "";
pub const _TIME32_T_DEFINED = "";
pub const _TIME64_T_DEFINED = "";
pub const _TIME_T_DEFINED = "";
pub const _CRT_SECURE_CPP_NOTHROW = @compileError("unable to translate macro: undefined identifier `throw`"); // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\corecrt.h:143:9
pub inline fn __DEFINE_CPP_OVERLOAD_SECURE_FUNC_0_0(__ret: anytype, __func: anytype, __dsttype: anytype, __dst: anytype) void {
    _ = &__ret;
    _ = &__func;
    _ = &__dsttype;
    _ = &__dst;
    return;
}
pub inline fn __DEFINE_CPP_OVERLOAD_SECURE_FUNC_0_1(__ret: anytype, __func: anytype, __dsttype: anytype, __dst: anytype, __type1: anytype, __arg1: anytype) void {
    _ = &__ret;
    _ = &__func;
    _ = &__dsttype;
    _ = &__dst;
    _ = &__type1;
    _ = &__arg1;
    return;
}
pub inline fn __DEFINE_CPP_OVERLOAD_SECURE_FUNC_0_2(__ret: anytype, __func: anytype, __dsttype: anytype, __dst: anytype, __type1: anytype, __arg1: anytype, __type2: anytype, __arg2: anytype) void {
    _ = &__ret;
    _ = &__func;
    _ = &__dsttype;
    _ = &__dst;
    _ = &__type1;
    _ = &__arg1;
    _ = &__type2;
    _ = &__arg2;
    return;
}
pub inline fn __DEFINE_CPP_OVERLOAD_SECURE_FUNC_0_3(__ret: anytype, __func: anytype, __dsttype: anytype, __dst: anytype, __type1: anytype, __arg1: anytype, __type2: anytype, __arg2: anytype, __type3: anytype, __arg3: anytype) void {
    _ = &__ret;
    _ = &__func;
    _ = &__dsttype;
    _ = &__dst;
    _ = &__type1;
    _ = &__arg1;
    _ = &__type2;
    _ = &__arg2;
    _ = &__type3;
    _ = &__arg3;
    return;
}
pub inline fn __DEFINE_CPP_OVERLOAD_SECURE_FUNC_0_4(__ret: anytype, __func: anytype, __dsttype: anytype, __dst: anytype, __type1: anytype, __arg1: anytype, __type2: anytype, __arg2: anytype, __type3: anytype, __arg3: anytype, __type4: anytype, __arg4: anytype) void {
    _ = &__ret;
    _ = &__func;
    _ = &__dsttype;
    _ = &__dst;
    _ = &__type1;
    _ = &__arg1;
    _ = &__type2;
    _ = &__arg2;
    _ = &__type3;
    _ = &__arg3;
    _ = &__type4;
    _ = &__arg4;
    return;
}
pub inline fn __DEFINE_CPP_OVERLOAD_SECURE_FUNC_1_1(__ret: anytype, __func: anytype, __type0: anytype, __arg0: anytype, __dsttype: anytype, __dst: anytype, __type1: anytype, __arg1: anytype) void {
    _ = &__ret;
    _ = &__func;
    _ = &__type0;
    _ = &__arg0;
    _ = &__dsttype;
    _ = &__dst;
    _ = &__type1;
    _ = &__arg1;
    return;
}
pub inline fn __DEFINE_CPP_OVERLOAD_SECURE_FUNC_1_2(__ret: anytype, __func: anytype, __type0: anytype, __arg0: anytype, __dsttype: anytype, __dst: anytype, __type1: anytype, __arg1: anytype, __type2: anytype, __arg2: anytype) void {
    _ = &__ret;
    _ = &__func;
    _ = &__type0;
    _ = &__arg0;
    _ = &__dsttype;
    _ = &__dst;
    _ = &__type1;
    _ = &__arg1;
    _ = &__type2;
    _ = &__arg2;
    return;
}
pub inline fn __DEFINE_CPP_OVERLOAD_SECURE_FUNC_1_3(__ret: anytype, __func: anytype, __type0: anytype, __arg0: anytype, __dsttype: anytype, __dst: anytype, __type1: anytype, __arg1: anytype, __type2: anytype, __arg2: anytype, __type3: anytype, __arg3: anytype) void {
    _ = &__ret;
    _ = &__func;
    _ = &__type0;
    _ = &__arg0;
    _ = &__dsttype;
    _ = &__dst;
    _ = &__type1;
    _ = &__arg1;
    _ = &__type2;
    _ = &__arg2;
    _ = &__type3;
    _ = &__arg3;
    return;
}
pub inline fn __DEFINE_CPP_OVERLOAD_SECURE_FUNC_2_0(__ret: anytype, __func: anytype, __type1: anytype, __arg1: anytype, __type2: anytype, __arg2: anytype, __dsttype: anytype, __dst: anytype) void {
    _ = &__ret;
    _ = &__func;
    _ = &__type1;
    _ = &__arg1;
    _ = &__type2;
    _ = &__arg2;
    _ = &__dsttype;
    _ = &__dst;
    return;
}
pub inline fn __DEFINE_CPP_OVERLOAD_SECURE_FUNC_0_1_ARGLIST(__ret: anytype, __func: anytype, __vfunc: anytype, __dsttype: anytype, __dst: anytype, __type1: anytype, __arg1: anytype) void {
    _ = &__ret;
    _ = &__func;
    _ = &__vfunc;
    _ = &__dsttype;
    _ = &__dst;
    _ = &__type1;
    _ = &__arg1;
    return;
}
pub inline fn __DEFINE_CPP_OVERLOAD_SECURE_FUNC_0_2_ARGLIST(__ret: anytype, __func: anytype, __vfunc: anytype, __dsttype: anytype, __dst: anytype, __type1: anytype, __arg1: anytype, __type2: anytype, __arg2: anytype) void {
    _ = &__ret;
    _ = &__func;
    _ = &__vfunc;
    _ = &__dsttype;
    _ = &__dst;
    _ = &__type1;
    _ = &__arg1;
    _ = &__type2;
    _ = &__arg2;
    return;
}
pub inline fn __DEFINE_CPP_OVERLOAD_SECURE_FUNC_SPLITPATH(__ret: anytype, __func: anytype, __dsttype: anytype, __src: anytype) void {
    _ = &__ret;
    _ = &__func;
    _ = &__dsttype;
    _ = &__src;
    return;
}
pub const __DEFINE_CPP_OVERLOAD_STANDARD_FUNC_0_0 = @compileError("unable to translate macro: undefined identifier `__func_name`"); // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\corecrt.h:277:9
pub const __DEFINE_CPP_OVERLOAD_STANDARD_FUNC_0_1 = @compileError("unable to translate macro: undefined identifier `__func_name`"); // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\corecrt.h:279:9
pub const __DEFINE_CPP_OVERLOAD_STANDARD_FUNC_0_2 = @compileError("unable to translate macro: undefined identifier `__func_name`"); // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\corecrt.h:281:9
pub const __DEFINE_CPP_OVERLOAD_STANDARD_FUNC_0_3 = @compileError("unable to translate macro: undefined identifier `__func_name`"); // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\corecrt.h:283:9
pub const __DEFINE_CPP_OVERLOAD_STANDARD_FUNC_0_4 = @compileError("unable to translate macro: undefined identifier `__func_name`"); // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\corecrt.h:285:9
pub inline fn __DEFINE_CPP_OVERLOAD_STANDARD_FUNC_0_0_EX(__ret_type: anytype, __ret_policy: anytype, __decl_spec: anytype, __name: anytype, __sec_name: anytype, __dst_attr: anytype, __dst_type: anytype, __dst: anytype) void {
    _ = &__ret_type;
    _ = &__ret_policy;
    _ = &__decl_spec;
    _ = &__name;
    _ = &__sec_name;
    _ = &__dst_attr;
    _ = &__dst_type;
    _ = &__dst;
    return;
}
pub inline fn __DEFINE_CPP_OVERLOAD_STANDARD_FUNC_0_1_EX(__ret_type: anytype, __ret_policy: anytype, __decl_spec: anytype, __name: anytype, __sec_name: anytype, __dst_attr: anytype, __dst_type: anytype, __dst: anytype, __arg1_type: anytype, __arg1: anytype) void {
    _ = &__ret_type;
    _ = &__ret_policy;
    _ = &__decl_spec;
    _ = &__name;
    _ = &__sec_name;
    _ = &__dst_attr;
    _ = &__dst_type;
    _ = &__dst;
    _ = &__arg1_type;
    _ = &__arg1;
    return;
}
pub inline fn __DEFINE_CPP_OVERLOAD_STANDARD_FUNC_0_2_EX(__ret_type: anytype, __ret_policy: anytype, __decl_spec: anytype, __name: anytype, __sec_name: anytype, __dst_attr: anytype, __dst_type: anytype, __dst: anytype, __arg1_type: anytype, __arg1: anytype, __arg2_type: anytype, __arg2: anytype) void {
    _ = &__ret_type;
    _ = &__ret_policy;
    _ = &__decl_spec;
    _ = &__name;
    _ = &__sec_name;
    _ = &__dst_attr;
    _ = &__dst_type;
    _ = &__dst;
    _ = &__arg1_type;
    _ = &__arg1;
    _ = &__arg2_type;
    _ = &__arg2;
    return;
}
pub inline fn __DEFINE_CPP_OVERLOAD_STANDARD_FUNC_0_3_EX(__ret_type: anytype, __ret_policy: anytype, __decl_spec: anytype, __name: anytype, __sec_name: anytype, __dst_attr: anytype, __dst_type: anytype, __dst: anytype, __arg1_type: anytype, __arg1: anytype, __arg2_type: anytype, __arg2: anytype, __arg3_type: anytype, __arg3: anytype) void {
    _ = &__ret_type;
    _ = &__ret_policy;
    _ = &__decl_spec;
    _ = &__name;
    _ = &__sec_name;
    _ = &__dst_attr;
    _ = &__dst_type;
    _ = &__dst;
    _ = &__arg1_type;
    _ = &__arg1;
    _ = &__arg2_type;
    _ = &__arg2;
    _ = &__arg3_type;
    _ = &__arg3;
    return;
}
pub inline fn __DEFINE_CPP_OVERLOAD_STANDARD_FUNC_0_4_EX(__ret_type: anytype, __ret_policy: anytype, __decl_spec: anytype, __name: anytype, __sec_name: anytype, __dst_attr: anytype, __dst_type: anytype, __dst: anytype, __arg1_type: anytype, __arg1: anytype, __arg2_type: anytype, __arg2: anytype, __arg3_type: anytype, __arg3: anytype, __arg4_type: anytype, __arg4: anytype) void {
    _ = &__ret_type;
    _ = &__ret_policy;
    _ = &__decl_spec;
    _ = &__name;
    _ = &__sec_name;
    _ = &__dst_attr;
    _ = &__dst_type;
    _ = &__dst;
    _ = &__arg1_type;
    _ = &__arg1;
    _ = &__arg2_type;
    _ = &__arg2;
    _ = &__arg3_type;
    _ = &__arg3;
    _ = &__arg4_type;
    _ = &__arg4;
    return;
}
pub const _TAGLC_ID_DEFINED = "";
pub const _THREADLOCALEINFO = "";
pub inline fn __crt_typefix(ctype: anytype) void {
    _ = &ctype;
    return;
}
pub const _CRT_USE_WINAPI_FAMILY_DESKTOP_APP = "";
pub const __need_wint_t = "";
pub const __need_wchar_t = "";
pub const INT8_MIN = -@as(c_int, 128);
pub const INT16_MIN = -__helpers.promoteIntLiteral(c_int, 32768, .decimal);
pub const INT32_MIN = -__helpers.promoteIntLiteral(c_int, 2147483647, .decimal) - @as(c_int, 1);
pub const INT64_MIN = -@as(c_longlong, 9223372036854775807) - @as(c_int, 1);
pub const INT8_MAX = @as(c_int, 127);
pub const INT16_MAX = @as(c_int, 32767);
pub const INT32_MAX = __helpers.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const INT64_MAX = @as(c_longlong, 9223372036854775807);
pub const UINT8_MAX = @as(c_int, 255);
pub const UINT16_MAX = __helpers.promoteIntLiteral(c_int, 65535, .decimal);
pub const UINT32_MAX = __helpers.promoteIntLiteral(c_uint, 0xffffffff, .hex);
pub const UINT64_MAX = @as(c_ulonglong, 0xffffffffffffffff);
pub const INT_LEAST8_MIN = INT8_MIN;
pub const INT_LEAST16_MIN = INT16_MIN;
pub const INT_LEAST32_MIN = INT32_MIN;
pub const INT_LEAST64_MIN = INT64_MIN;
pub const INT_LEAST8_MAX = INT8_MAX;
pub const INT_LEAST16_MAX = INT16_MAX;
pub const INT_LEAST32_MAX = INT32_MAX;
pub const INT_LEAST64_MAX = INT64_MAX;
pub const UINT_LEAST8_MAX = UINT8_MAX;
pub const UINT_LEAST16_MAX = UINT16_MAX;
pub const UINT_LEAST32_MAX = UINT32_MAX;
pub const UINT_LEAST64_MAX = UINT64_MAX;
pub const INT_FAST8_MIN = INT8_MIN;
pub const INT_FAST16_MIN = INT16_MIN;
pub const INT_FAST32_MIN = INT32_MIN;
pub const INT_FAST64_MIN = INT64_MIN;
pub const INT_FAST8_MAX = INT8_MAX;
pub const INT_FAST16_MAX = INT16_MAX;
pub const INT_FAST32_MAX = INT32_MAX;
pub const INT_FAST64_MAX = INT64_MAX;
pub const UINT_FAST8_MAX = UINT8_MAX;
pub const UINT_FAST16_MAX = UINT16_MAX;
pub const UINT_FAST32_MAX = UINT32_MAX;
pub const UINT_FAST64_MAX = UINT64_MAX;
pub const INTPTR_MIN = INT64_MIN;
pub const INTPTR_MAX = INT64_MAX;
pub const UINTPTR_MAX = UINT64_MAX;
pub const INTMAX_MIN = INT64_MIN;
pub const INTMAX_MAX = INT64_MAX;
pub const UINTMAX_MAX = UINT64_MAX;
pub const PTRDIFF_MIN = INT64_MIN;
pub const PTRDIFF_MAX = INT64_MAX;
pub const SIG_ATOMIC_MIN = INT32_MIN;
pub const SIG_ATOMIC_MAX = INT32_MAX;
pub const SIZE_MAX = UINT64_MAX;
pub const WCHAR_MIN = @as(c_uint, 0);
pub const WCHAR_MAX = @as(c_uint, 0xffff);
pub const WINT_MIN = @as(c_uint, 0);
pub const WINT_MAX = @as(c_uint, 0xffff);
pub inline fn INT8_C(val: anytype) @TypeOf((INT_LEAST8_MAX - INT_LEAST8_MAX) + val) {
    _ = &val;
    return (INT_LEAST8_MAX - INT_LEAST8_MAX) + val;
}
pub inline fn INT16_C(val: anytype) @TypeOf((INT_LEAST16_MAX - INT_LEAST16_MAX) + val) {
    _ = &val;
    return (INT_LEAST16_MAX - INT_LEAST16_MAX) + val;
}
pub inline fn INT32_C(val: anytype) @TypeOf((INT_LEAST32_MAX - INT_LEAST32_MAX) + val) {
    _ = &val;
    return (INT_LEAST32_MAX - INT_LEAST32_MAX) + val;
}
pub const INT64_C = __helpers.LL_SUFFIX;
pub inline fn UINT8_C(val: anytype) @TypeOf(val) {
    _ = &val;
    return val;
}
pub inline fn UINT16_C(val: anytype) @TypeOf(val) {
    _ = &val;
    return val;
}
pub const UINT32_C = __helpers.U_SUFFIX;
pub const UINT64_C = __helpers.ULL_SUFFIX;
pub const INTMAX_C = __helpers.LL_SUFFIX;
pub const UINTMAX_C = __helpers.ULL_SUFFIX;
pub const __ASSERT_H_ = "";
pub const static_assert = @compileError("unable to translate C expr: unexpected token '_Static_assert'"); // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\assert.h:38:9
pub const assert = @compileError("unable to translate macro: undefined identifier `__FILE__`"); // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\assert.h:50:9
pub const _INC_STRING = "";
pub const _SECIMP = @compileError("unable to translate macro: undefined identifier `dllimport`"); // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\string.h:16:9
pub const _NLSCMP_DEFINED = "";
pub const _NLSCMPERROR = __helpers.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const _WConst_return = "";
pub const _CRT_MEMORY_DEFINED = "";
pub const _WSTRING_DEFINED = "";
pub const wcswcs = wcsstr;
pub const _INC_STRING_S = "";
pub const _WSTRING_S_DEFINED = "";
pub const _INC_STDIO = "";
pub const _STDIO_CONFIG_DEFINED = "";
pub const _CRT_INTERNAL_PRINTF_LEGACY_VSPRINTF_NULL_TERMINATION = @as(c_ulonglong, 0x0001);
pub const _CRT_INTERNAL_PRINTF_STANDARD_SNPRINTF_BEHAVIOR = @as(c_ulonglong, 0x0002);
pub const _CRT_INTERNAL_PRINTF_LEGACY_WIDE_SPECIFIERS = @as(c_ulonglong, 0x0004);
pub const _CRT_INTERNAL_PRINTF_LEGACY_MSVCRT_COMPATIBILITY = @as(c_ulonglong, 0x0008);
pub const _CRT_INTERNAL_PRINTF_LEGACY_THREE_DIGIT_EXPONENTS = @as(c_ulonglong, 0x0010);
pub const _CRT_INTERNAL_PRINTF_STANDARD_ROUNDING = @as(c_ulonglong, 0x0020);
pub const _CRT_INTERNAL_SCANF_SECURECRT = @as(c_ulonglong, 0x0001);
pub const _CRT_INTERNAL_SCANF_LEGACY_WIDE_SPECIFIERS = @as(c_ulonglong, 0x0002);
pub const _CRT_INTERNAL_SCANF_LEGACY_MSVCRT_COMPATIBILITY = @as(c_ulonglong, 0x0004);
pub const _CRT_INTERNAL_LOCAL_PRINTF_OPTIONS = __local_stdio_printf_options().*;
pub const _CRT_INTERNAL_LOCAL_SCANF_OPTIONS = __local_stdio_scanf_options().*;
pub const BUFSIZ = @as(c_int, 512);
pub const _NFILE = _NSTREAM_;
pub const _NSTREAM_ = @as(c_int, 512);
pub const _IOB_ENTRIES = @as(c_int, 20);
pub const EOF = -@as(c_int, 1);
pub const _FILE_DEFINED = "";
pub const _P_tmpdir = "\\";
pub const _wP_tmpdir = "\\";
pub const L_tmpnam = @as(c_int, 260);
pub const SEEK_CUR = @as(c_int, 1);
pub const SEEK_END = @as(c_int, 2);
pub const SEEK_SET = @as(c_int, 0);
pub const STDIN_FILENO = @as(c_int, 0);
pub const STDOUT_FILENO = @as(c_int, 1);
pub const STDERR_FILENO = @as(c_int, 2);
pub const FILENAME_MAX = @as(c_int, 260);
pub const FOPEN_MAX = @as(c_int, 20);
pub const _SYS_OPEN = @as(c_int, 20);
pub const TMP_MAX = __helpers.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const _OFF_T_DEFINED = "";
pub const _OFF_T_ = "";
pub const _OFF64_T_DEFINED = "";
pub const _FILE_OFFSET_BITS_SET_OFFT = "";
pub const _iob = __iob_func();
pub const _FPOS_T_DEFINED = "";
pub inline fn _FPOSOFF(fp: anytype) c_long {
    _ = &fp;
    return __helpers.cast(c_long, fp);
}
pub const _STDSTREAM_DEFINED = "";
pub const stdin = __acrt_iob_func(@as(c_int, 0));
pub const stdout = __acrt_iob_func(@as(c_int, 1));
pub const stderr = __acrt_iob_func(@as(c_int, 2));
pub const _IOFBF = @as(c_int, 0x0000);
pub const _IOLBF = @as(c_int, 0x0040);
pub const _IONBF = @as(c_int, 0x0004);
pub const __MINGW_PRINTF_FORMAT = @compileError("unable to translate macro: undefined identifier `__gnu_printf__`"); // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\stdio.h:280:9
pub const __MINGW_SCANF_FORMAT = @compileError("unable to translate macro: undefined identifier `__gnu_scanf__`"); // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\stdio.h:281:9
pub const _FILE_OFFSET_BITS_SET_FSEEKO = "";
pub const _FILE_OFFSET_BITS_SET_FTELLO = "";
pub const _CRT_PERROR_DEFINED = "";
pub const popen = _popen;
pub const pclose = _pclose;
pub const _CRT_DIRECTORY_DEFINED = "";
pub const _WSTDIO_DEFINED = "";
pub const WEOF = __helpers.cast(wint_t, __helpers.promoteIntLiteral(c_int, 0xFFFF, .hex));
pub const _INC_SWPRINTF_INL = "";
pub const _CRT_WPERROR_DEFINED = "";
pub const wpopen = _wpopen;
pub inline fn _putwc_nolock(_c: anytype, _stm: anytype) @TypeOf(_fputwc_nolock(_c, _stm)) {
    _ = &_c;
    _ = &_stm;
    return _fputwc_nolock(_c, _stm);
}
pub inline fn _getwc_nolock(_c: anytype) @TypeOf(_fgetwc_nolock(_c)) {
    _ = &_c;
    return _fgetwc_nolock(_c);
}
pub const _STDIO_DEFINED = "";
pub inline fn _getchar_nolock() @TypeOf(_getc_nolock(stdin)) {
    return _getc_nolock(stdin);
}
pub inline fn _putchar_nolock(_c: anytype) @TypeOf(_putc_nolock(_c, stdout)) {
    _ = &_c;
    return _putc_nolock(_c, stdout);
}
pub inline fn _getwchar_nolock() @TypeOf(_getwc_nolock(stdin)) {
    return _getwc_nolock(stdin);
}
pub inline fn _putwchar_nolock(_c: anytype) @TypeOf(_putwc_nolock(_c, stdout)) {
    _ = &_c;
    return _putwc_nolock(_c, stdout);
}
pub const P_tmpdir = _P_tmpdir;
pub const SYS_OPEN = _SYS_OPEN;
pub const __MINGW_MBWC_CONVERT_DEFINED = "";
pub const _WSPAWN_DEFINED = "";
pub const _P_WAIT = @as(c_int, 0);
pub const _P_NOWAIT = @as(c_int, 1);
pub const _OLD_P_OVERLAY = @as(c_int, 2);
pub const _P_NOWAITO = @as(c_int, 3);
pub const _P_DETACH = @as(c_int, 4);
pub const _P_OVERLAY = @as(c_int, 2);
pub const _WAIT_CHILD = @as(c_int, 0);
pub const _WAIT_GRANDCHILD = @as(c_int, 1);
pub const _SPAWNV_DEFINED = "";
pub const _INC_STDIO_S = "";
pub const _STDIO_S_DEFINED = "";
pub const L_tmpnam_s = L_tmpnam;
pub const TMP_MAX_S = TMP_MAX;
pub const _WSTDIO_S_DEFINED = "";
pub const _GCC_LIMITS_H_ = "";
pub const __CLANG_LIMITS_H = "";
pub const _INC_LIMITS = "";
pub const PATH_MAX = @as(c_int, 260);
pub const MB_LEN_MAX = @as(c_int, 5);
pub const _I8_MIN = -@as(c_int, 127) - @as(c_int, 1);
pub const _I8_MAX = @as(c_int, 127);
pub const _UI8_MAX = @as(c_uint, 0xff);
pub const _I16_MIN = -@as(c_int, 32767) - @as(c_int, 1);
pub const _I16_MAX = @as(c_int, 32767);
pub const _UI16_MAX = @as(c_uint, 0xffff);
pub const _I32_MIN = -__helpers.promoteIntLiteral(c_int, 2147483647, .decimal) - @as(c_int, 1);
pub const _I32_MAX = __helpers.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const _UI32_MAX = __helpers.promoteIntLiteral(c_uint, 0xffffffff, .hex);
pub const _I64_MIN = -@as(c_longlong, 9223372036854775807) - @as(c_int, 1);
pub const _I64_MAX = @as(c_longlong, 9223372036854775807);
pub const _UI64_MAX = @as(c_ulonglong, 0xffffffffffffffff);
pub const SSIZE_MAX = _I64_MAX;
pub const LONG_LONG_MAX = __LONG_LONG_MAX__;
pub const LONG_LONG_MIN = -__LONG_LONG_MAX__ - @as(c_longlong, 1);
pub const ULONG_LONG_MAX = (__LONG_LONG_MAX__ * @as(c_ulonglong, 2)) + @as(c_ulonglong, 1);
pub const SCHAR_MAX = __SCHAR_MAX__;
pub const SHRT_MAX = __SHRT_MAX__;
pub const INT_MAX = __INT_MAX__;
pub const LONG_MAX = __LONG_MAX__;
pub const SCHAR_MIN = -__SCHAR_MAX__ - @as(c_int, 1);
pub const SHRT_MIN = -__SHRT_MAX__ - @as(c_int, 1);
pub const INT_MIN = -__INT_MAX__ - @as(c_int, 1);
pub const LONG_MIN = -__LONG_MAX__ - @as(c_long, 1);
pub const UCHAR_MAX = (__SCHAR_MAX__ * @as(c_int, 2)) + @as(c_int, 1);
pub const USHRT_MAX = (__SHRT_MAX__ * @as(c_int, 2)) + @as(c_int, 1);
pub const UINT_MAX = (__INT_MAX__ * @as(c_uint, 2)) + @as(c_uint, 1);
pub const ULONG_MAX = (__LONG_MAX__ * @as(c_ulong, 2)) + @as(c_ulong, 1);
pub const CHAR_BIT = __CHAR_BIT__;
pub const CHAR_MIN = SCHAR_MIN;
pub const CHAR_MAX = __SCHAR_MAX__;
pub const LLONG_MIN = -__LONG_LONG_MAX__ - @as(c_longlong, 1);
pub const LLONG_MAX = __LONG_LONG_MAX__;
pub const ULLONG_MAX = (__LONG_LONG_MAX__ * @as(c_ulonglong, 2)) + @as(c_ulonglong, 1);
pub const FLT_RADIX = __FLT_RADIX__;
pub const FLT_MANT_DIG = __FLT_MANT_DIG__;
pub const DBL_MANT_DIG = __DBL_MANT_DIG__;
pub const LDBL_MANT_DIG = __LDBL_MANT_DIG__;
pub const FLT_EVAL_METHOD = __FLT_EVAL_METHOD__;
pub const DECIMAL_DIG = __DECIMAL_DIG__;
pub const FLT_DIG = __FLT_DIG__;
pub const DBL_DIG = __DBL_DIG__;
pub const LDBL_DIG = __LDBL_DIG__;
pub const FLT_MIN_EXP = __FLT_MIN_EXP__;
pub const DBL_MIN_EXP = __DBL_MIN_EXP__;
pub const LDBL_MIN_EXP = __LDBL_MIN_EXP__;
pub const FLT_MIN_10_EXP = __FLT_MIN_10_EXP__;
pub const DBL_MIN_10_EXP = __DBL_MIN_10_EXP__;
pub const LDBL_MIN_10_EXP = __LDBL_MIN_10_EXP__;
pub const FLT_MAX_EXP = __FLT_MAX_EXP__;
pub const DBL_MAX_EXP = __DBL_MAX_EXP__;
pub const LDBL_MAX_EXP = __LDBL_MAX_EXP__;
pub const FLT_MAX_10_EXP = __FLT_MAX_10_EXP__;
pub const DBL_MAX_10_EXP = __DBL_MAX_10_EXP__;
pub const LDBL_MAX_10_EXP = __LDBL_MAX_10_EXP__;
pub const FLT_MAX = __FLT_MAX__;
pub const DBL_MAX = __DBL_MAX__;
pub const LDBL_MAX = __LDBL_MAX__;
pub const FLT_EPSILON = __FLT_EPSILON__;
pub const DBL_EPSILON = __DBL_EPSILON__;
pub const LDBL_EPSILON = __LDBL_EPSILON__;
pub const FLT_MIN = __FLT_MIN__;
pub const DBL_MIN = __DBL_MIN__;
pub const LDBL_MIN = __LDBL_MIN__;
pub const FLT_TRUE_MIN = __FLT_DENORM_MIN__;
pub const DBL_TRUE_MIN = __DBL_DENORM_MIN__;
pub const LDBL_TRUE_MIN = __LDBL_DENORM_MIN__;
pub const FLT_DECIMAL_DIG = __FLT_DECIMAL_DIG__;
pub const DBL_DECIMAL_DIG = __DBL_DECIMAL_DIG__;
pub const LDBL_DECIMAL_DIG = __LDBL_DECIMAL_DIG__;
pub const FLT_HAS_SUBNORM = "";
pub const DBL_HAS_SUBNORM = "";
pub const LDBL_HAS_SUBNORM = "";
pub const _INC_STDLIB = "";
pub const _INC_CORECRT_WSTDLIB = "";
pub const EXIT_SUCCESS = @as(c_int, 0);
pub const EXIT_FAILURE = @as(c_int, 1);
pub const _ONEXIT_T_DEFINED = "";
pub const onexit_t = _onexit_t;
pub const _DIV_T_DEFINED = "";
pub const _CRT_DOUBLE_DEC = "";
pub inline fn _PTR_LD(x: anytype) [*c]u8 {
    _ = &x;
    return __helpers.cast([*c]u8, &x.*.ld);
}
pub const RAND_MAX = @as(c_int, 0x7fff);
pub const MB_CUR_MAX = ___mb_cur_max_func();
pub const __mb_cur_max = ___mb_cur_max_func();
pub inline fn __max(a: anytype, b: anytype) @TypeOf(if (__helpers.cast(bool, a > b)) a else b) {
    _ = &a;
    _ = &b;
    return if (__helpers.cast(bool, a > b)) a else b;
}
pub inline fn __min(a: anytype, b: anytype) @TypeOf(if (__helpers.cast(bool, a < b)) a else b) {
    _ = &a;
    _ = &b;
    return if (__helpers.cast(bool, a < b)) a else b;
}
pub const _MAX_PATH = @as(c_int, 260);
pub const _MAX_DRIVE = @as(c_int, 3);
pub const _MAX_DIR = @as(c_int, 256);
pub const _MAX_FNAME = @as(c_int, 256);
pub const _MAX_EXT = @as(c_int, 256);
pub const _OUT_TO_DEFAULT = @as(c_int, 0);
pub const _OUT_TO_STDERR = @as(c_int, 1);
pub const _OUT_TO_MSGBOX = @as(c_int, 2);
pub const _REPORT_ERRMODE = @as(c_int, 3);
pub const _WRITE_ABORT_MSG = @as(c_int, 0x1);
pub const _CALL_REPORTFAULT = @as(c_int, 0x2);
pub const _MAX_ENV = @as(c_int, 32767);
pub const _CRT_ERRNO_DEFINED = "";
pub const errno = _errno().*;
pub const _doserrno = __doserrno().*;
pub const _sys_nerr = __sys_nerr().*;
pub const _sys_errlist = __sys_errlist();
pub const _fmode = __p__fmode().*;
pub const __argc = __p___argc().*;
pub const __argv = __p___argv().*;
pub const __wargv = __p___wargv().*;
pub const _pgmptr = __p__pgmptr().*;
pub const _wpgmptr = __p__wpgmptr().*;
pub const _environ = __p__environ().*;
pub const _wenviron = __p__wenviron().*;
pub const _osplatform = __p__osplatform().*;
pub const _osver = __p__osver().*;
pub const _winver = __p__winver().*;
pub const _winmajor = __p__winmajor().*;
pub const _winminor = __p__winminor().*;
pub inline fn _countof(_Array: anytype) @TypeOf(__helpers.div(__helpers.sizeof(_Array), __helpers.sizeof(_Array[@as(usize, @intCast(@as(c_int, 0)))]))) {
    _ = &_Array;
    return __helpers.div(__helpers.sizeof(_Array), __helpers.sizeof(_Array[@as(usize, @intCast(@as(c_int, 0)))]));
}
pub const _CRT_TERMINATE_DEFINED = "";
pub const _CRT_ABS_DEFINED = "";
pub const _CRT_ATOF_DEFINED = "";
pub const _CRT_ALGO_DEFINED = "";
pub const _CRT_SYSTEM_DEFINED = "";
pub const _CRT_ALLOCATION_DEFINED = "";
pub const _WSTDLIB_DEFINED = "";
pub const _CRT_WSYSTEM_DEFINED = "";
pub const _CVTBUFSIZE = @as(c_int, 309) + @as(c_int, 40);
pub const _WSTDLIBP_DEFINED = "";
pub const sys_errlist = _sys_errlist;
pub const sys_nerr = _sys_nerr;
pub const environ = _environ;
pub const _CRT_SWAB_DEFINED = "";
pub const _INC_STDLIB_S = "";
pub const _QSORT_S_DEFINED = "";
pub const _MALLOC_H_ = "";
pub const _HEAP_MAXREQ = __helpers.promoteIntLiteral(c_int, 0xFFFFFFFFFFFFFFE0, .hex);
pub const _STATIC_ASSERT = @compileError("unable to translate C expr: unexpected token '_Static_assert'"); // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\malloc.h:29:9
pub const _HEAPEMPTY = -@as(c_int, 1);
pub const _HEAPOK = -@as(c_int, 2);
pub const _HEAPBADBEGIN = -@as(c_int, 3);
pub const _HEAPBADNODE = -@as(c_int, 4);
pub const _HEAPEND = -@as(c_int, 5);
pub const _HEAPBADPTR = -@as(c_int, 6);
pub const _FREEENTRY = @as(c_int, 0);
pub const _USEDENTRY = @as(c_int, 1);
pub const _HEAPINFO_DEFINED = "";
pub const _amblksiz = __p__amblksiz().*;
pub const __MM_MALLOC_H = "";
pub const _MAX_WAIT_MALLOC_CRT = __helpers.promoteIntLiteral(c_int, 60000, .decimal);
pub const _alloca = @compileError("unable to translate macro: undefined identifier `__builtin_alloca`"); // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\malloc.h:163:9
pub const _ALLOCA_S_THRESHOLD = @as(c_int, 1024);
pub const _ALLOCA_S_STACK_MARKER = __helpers.promoteIntLiteral(c_int, 0xCCCC, .hex);
pub const _ALLOCA_S_HEAP_MARKER = __helpers.promoteIntLiteral(c_int, 0xDDDD, .hex);
pub const _ALLOCA_S_MARKER_SIZE = @as(c_int, 16);
pub inline fn _malloca(size: anytype) @TypeOf(if (__helpers.cast(bool, (size + _ALLOCA_S_MARKER_SIZE) <= _ALLOCA_S_THRESHOLD)) _MarkAllocaS(_alloca(size + _ALLOCA_S_MARKER_SIZE), _ALLOCA_S_STACK_MARKER) else _MarkAllocaS(malloc(size + _ALLOCA_S_MARKER_SIZE), _ALLOCA_S_HEAP_MARKER)) {
    _ = &size;
    return if (__helpers.cast(bool, (size + _ALLOCA_S_MARKER_SIZE) <= _ALLOCA_S_THRESHOLD)) _MarkAllocaS(_alloca(size + _ALLOCA_S_MARKER_SIZE), _ALLOCA_S_STACK_MARKER) else _MarkAllocaS(malloc(size + _ALLOCA_S_MARKER_SIZE), _ALLOCA_S_HEAP_MARKER);
}
pub const _FREEA_INLINE = "";
pub const alloca = @compileError("unable to translate macro: undefined identifier `__builtin_alloca`"); // C:\D\zig\zig-x86_64-windows-0.16.0\lib\libc\include\any-windows-any\malloc.h:238:9
pub const JSMN_PARENT_LINKS = "";
pub const JSMN_STRICT = "";
pub const GlbHeaderSize = @as(c_int, 12);
pub const GlbChunkHeaderSize = @as(c_int, 8);
pub const CGLTF_CONSTS = "";
pub inline fn CGLTF_MALLOC(size: anytype) @TypeOf(malloc(size)) {
    _ = &size;
    return malloc(size);
}
pub inline fn CGLTF_FREE(ptr: anytype) @TypeOf(free(ptr)) {
    _ = &ptr;
    return free(ptr);
}
pub inline fn CGLTF_ATOI(str: anytype) @TypeOf(atoi(str)) {
    _ = &str;
    return atoi(str);
}
pub inline fn CGLTF_ATOF(str: anytype) @TypeOf(atof(str)) {
    _ = &str;
    return atof(str);
}
pub inline fn CGLTF_ATOLL(str: anytype) @TypeOf(atoll(str)) {
    _ = &str;
    return atoll(str);
}
pub const CGLTF_VALIDATE_ENABLE_ASSERTS = @as(c_int, 0);
pub const CGLTF_ASSERT_IF = @compileError("unable to translate C expr: unexpected token 'if'"); // .\include\cgltf\cgltf.h:1594:9
pub const CGLTF_ERROR_JSON = -@as(c_int, 1);
pub const CGLTF_ERROR_NOMEM = -@as(c_int, 2);
pub const CGLTF_ERROR_LEGACY = -@as(c_int, 3);
pub const CGLTF_CHECK_TOKTYPE = @compileError("unable to translate C expr: unexpected token 'if'"); // .\include\cgltf\cgltf.h:2750:9
pub const CGLTF_CHECK_TOKTYPE_RET = @compileError("unable to translate C expr: unexpected token 'if'"); // .\include\cgltf\cgltf.h:2751:9
pub const CGLTF_CHECK_KEY = @compileError("unable to translate C expr: unexpected token 'if'"); // .\include\cgltf\cgltf.h:2752:9
pub inline fn CGLTF_PTRINDEX(@"type": anytype, idx: anytype) @TypeOf([*c]@"type"(__helpers.cast(cgltf_size, idx) + @as(c_int, 1))) {
    _ = &@"type";
    _ = &idx;
    return [*c]@"type"(__helpers.cast(cgltf_size, idx) + @as(c_int, 1));
}
pub const CGLTF_PTRFIXUP = @compileError("unable to translate C expr: unexpected token 'if'"); // .\include\cgltf\cgltf.h:2755:9
pub const CGLTF_PTRFIXUP_REQ = @compileError("unable to translate C expr: unexpected token 'if'"); // .\include\cgltf\cgltf.h:2756:9
pub const threadlocaleinfostruct = struct_threadlocaleinfostruct;
pub const threadmbcinfostruct = struct_threadmbcinfostruct;
pub const __lc_time_data = struct___lc_time_data;
pub const localeinfo_struct = struct_localeinfo_struct;
pub const tagLC_ID = struct_tagLC_ID;
pub const _iobuf = struct__iobuf;
pub const _div_t = struct__div_t;
pub const _ldiv_t = struct__ldiv_t;
pub const _heapinfo = struct__heapinfo;
pub const jsmnerr = enum_jsmnerr;
