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
.{ "box.obj", 12 },
.{ "box.png", 13 },
.{ "voxel.mtl", 14 },
.{ "voxel.obj", 15 },
.{ "voxel.png", 16 },
.{ "Pipeline", 17 },
.{ "flat2d.pipeb", 19 },
.{ "model3d.pipeb", 20 },
.{ "Shaders", 23 },
.{ "2d.vert.spv", 24 },
.{ "combine.frag.spv", 25 },
.{ "combine2d.frag.spv", 27 },
.{ "empty.frag.spv", 29 },
.{ "flat2d.frag.spv", 30 },
.{ "flat2d.vert.spv", 31 },
.{ "model3d.frag.spv", 32 },
.{ "model3d.vert.spv", 33 },
.{ "modelBottom.frag.spv", 34 },
.{ "particle.comp.spv", 35 },
.{ "particle.frag.spv", 36 },
.{ "particle.vert.spv", 37 },
.{ "shader2.comp.spv", 38 },
.{ "shadow.vert.spv", 39 },
.{ "shape.frag.spv", 40 },
.{ "shape.vert.spv", 41 },
.{ "spirv_reflect.exe", 43 },
.{ "SSGI.comp.spv", 44 },
.{ "triangle.frag.spv", 45 },
.{ "triangle.vert.spv", 46 },
.{ "Texts", 47 },
.{ "text.txt", 48 },
.{ "Textures", 49 },
.{ "circle.png", 50 },
.{ "emoji.png", 51 },
.{ "icon.png", 52 },
.{ "loading1", 53 },
.{ "loading1.png", 54 },
.{ "mainBackground.png", 55 },
.{ "mainFont.png", 56 },
.{ "non_exist.png", 57 },
.{ "StartMenu", 58 },
.{ "exit.png", 59 },
.{ "load.png", 60 },
.{ "setting.png", 61 },
.{ "start.png", 62 },
.{ "temp.aseprite", 63 },
.{ "textRectangle1.png", 64 },
.{ "tileSet1.png", 65 },
.{ "Tilemap", 66 },
.{ "tileMap1.tsdI", 67 },
.{ "tileSet1.tsd", 68 },
.{ "Sampler", 21 },
.{ "pixel2dSampler.sampler", 22 },
.{ "direct.frag.spv", 28 },
.{ "directOut.pipeb", 18 },
.{ "sixVertices.vert.spv", 42 },
};

break: map std.StaticStringMap(i32).initComptime(list);
};
 


pub fn comptimeGetID(comptime fileName: []const u8) i32 {
comptime {
return FileNameIdHashMap.get(fileName) orelse @compileError("not found");
}
}

pub fn getID(fileName: []const u8) i32 {    return FileNameIdHashMap.get(fileName) orelse std.debug.panic("ilegal name", .{}); }