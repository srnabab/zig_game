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
.{ "flat2d.pipeb", 18 },
.{ "model3d.pipeb", 19 },
.{ "Shaders", 22 },
.{ "2d.vert.spv", 23 },
.{ "combine.frag.spv", 24 },
.{ "combine.vert.spv", 25 },
.{ "combine2d.frag.spv", 26 },
.{ "empty.frag.spv", 27 },
.{ "flat2d.frag.spv", 28 },
.{ "flat2d.vert.spv", 29 },
.{ "model3d.frag.spv", 30 },
.{ "model3d.vert.spv", 31 },
.{ "modelBottom.frag.spv", 32 },
.{ "particle.comp.spv", 33 },
.{ "particle.frag.spv", 34 },
.{ "particle.vert.spv", 35 },
.{ "shader2.comp.spv", 36 },
.{ "shadow.vert.spv", 37 },
.{ "shape.frag.spv", 38 },
.{ "shape.vert.spv", 39 },
.{ "spirv_reflect.exe", 40 },
.{ "SSGI.comp.spv", 41 },
.{ "triangle.frag.spv", 42 },
.{ "triangle.vert.spv", 43 },
.{ "Texts", 44 },
.{ "text.txt", 45 },
.{ "Textures", 46 },
.{ "circle.png", 47 },
.{ "emoji.png", 48 },
.{ "icon.png", 49 },
.{ "loading1", 50 },
.{ "loading1.png", 51 },
.{ "mainBackground.png", 52 },
.{ "mainFont.png", 53 },
.{ "non_exist.png", 54 },
.{ "StartMenu", 55 },
.{ "exit.png", 56 },
.{ "load.png", 57 },
.{ "setting.png", 58 },
.{ "start.png", 59 },
.{ "temp.aseprite", 60 },
.{ "textRectangle1.png", 61 },
.{ "tileSet1.png", 62 },
.{ "Tilemap", 63 },
.{ "tileMap1.tsdI", 64 },
.{ "tileSet1.tsd", 65 },
.{ "Sampler", 20 },
.{ "pixel2dSampler.sampler", 21 },
};

break: map std.StaticStringMap(i32).initComptime(list);
};
 


pub fn comptimeGetID(comptime fileName: []const u8) i32 {
comptime {
return FileNameIdHashMap.get(fileName) orelse @compileError("not found");
}
}

pub fn getID(fileName: []const u8) i32 {    return FileNameIdHashMap.get(fileName) orelse std.debug.panic("ilegal name", .{{}}); }