const std = @import("std");

const FileNameIdHashMap = map: {
const KV = struct {
[]const u8,i64,
};
const list = [_]KV{
.{ "Content", 0 },
.{ "Audio", 1 },
.{ "MainBackgroundMusic1.wav", 2 },
.{ "test.wav", 3 },
.{ "Fonts", 4 },
.{ "EmojiHashTable", 5 },
.{ "MainFontHashTable", 6 },
.{ "OpenMoji-color-glyf_colr_0.ttf", 7 },
.{ "SourceHanSansSC-VF.ttf", 8 },
.{ "Model", 9 },
.{ "bottom.obj", 10 },
.{ "bottom.png", 11 },
.{ "box.bin", 12 },
.{ "box.glb", 13 },
.{ "box.gltf", 14 },
.{ "box.obj", 15 },
.{ "box.png", 16 },
.{ "voxel.mtl", 17 },
.{ "voxel.obj", 18 },
.{ "voxel.png", 19 },
.{ "Pipeline", 20 },
.{ "directOut.pipeb", 21 },
.{ "flat2d.pipeb", 22 },
.{ "model3d.pipeb", 23 },
.{ "Sampler", 24 },
.{ "pixel2dSampler.sampler", 25 },
.{ "Shaders", 26 },
.{ "2d.vert.spv", 27 },
.{ "combine.frag.spv", 28 },
.{ "combine2d.frag.spv", 30 },
.{ "direct.frag.spv", 31 },
.{ "empty.frag.spv", 32 },
.{ "flat2d.frag.spv", 33 },
.{ "flat2d.vert.spv", 34 },
.{ "model3d.frag.spv", 35 },
.{ "model3d.vert.spv", 36 },
.{ "modelBottom.frag.spv", 37 },
.{ "particle.comp.spv", 38 },
.{ "particle.frag.spv", 39 },
.{ "particle.vert.spv", 40 },
.{ "shader2.comp.spv", 41 },
.{ "shadow.vert.spv", 42 },
.{ "shape.frag.spv", 43 },
.{ "shape.vert.spv", 44 },
.{ "spirv_reflect.exe", 46 },
.{ "SSGI.comp.spv", 47 },
.{ "triangle.frag.spv", 48 },
.{ "triangle.vert.spv", 49 },
.{ "Texts", 50 },
.{ "text.txt", 51 },
.{ "Textures", 52 },
.{ "circle.png", 53 },
.{ "emoji.png", 54 },
.{ "icon.png", 55 },
.{ "loading1", 56 },
.{ "loading1.png", 57 },
.{ "mainBackground.png", 58 },
.{ "mainFont.png", 59 },
.{ "non_exist.png", 60 },
.{ "StartMenu", 61 },
.{ "exit.png", 62 },
.{ "load.png", 63 },
.{ "setting.png", 64 },
.{ "start.png", 65 },
.{ "temp.aseprite", 66 },
.{ "textRectangle1.png", 67 },
.{ "tileSet1.png", 68 },
.{ "Tilemap", 69 },
.{ "tileMap1.tsdI", 70 },
.{ "tileSet1.tsd", 71 },
.{ "sixVertices.vert.spv", 45 },
};

break: map std.StaticStringMap(i32).initComptime(list);
};
 


pub fn comptimeGetID(comptime fileName: []const u8) i32 {
comptime {
return FileNameIdHashMap.get(fileName) orelse @compileError("not found");
}
}

pub fn getID(fileName: []const u8) i32 {    return FileNameIdHashMap.get(fileName) orelse std.debug.panic("ilegal name", .{}); }