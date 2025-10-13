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
.{ "Shaders", 20 },
.{ "2d.vert.spv", 21 },
.{ "combine.frag.spv", 22 },
.{ "combine.vert.spv", 23 },
.{ "combine2d.frag.spv", 24 },
.{ "empty.frag.spv", 25 },
.{ "flat2d.frag.spv", 26 },
.{ "flat2d.vert.spv", 27 },
.{ "model3d.frag.spv", 28 },
.{ "model3d.vert.spv", 29 },
.{ "modelBottom.frag.spv", 30 },
.{ "particle.comp.spv", 31 },
.{ "particle.frag.spv", 32 },
.{ "particle.vert.spv", 33 },
.{ "shader2.comp.spv", 34 },
.{ "shadow.vert.spv", 35 },
.{ "shape.frag.spv", 36 },
.{ "shape.vert.spv", 37 },
.{ "spirv_reflect.exe", 38 },
.{ "SSGI.comp.spv", 39 },
.{ "triangle.frag.spv", 40 },
.{ "triangle.vert.spv", 41 },
.{ "Texts", 42 },
.{ "text.txt", 43 },
.{ "Textures", 44 },
.{ "circle.png", 45 },
.{ "emoji.png", 46 },
.{ "icon.png", 47 },
.{ "loading1", 48 },
.{ "loading1.png", 49 },
.{ "mainBackground.png", 50 },
.{ "mainFont.png", 51 },
.{ "non_exist.png", 52 },
.{ "StartMenu", 53 },
.{ "exit.png", 54 },
.{ "load.png", 55 },
.{ "setting.png", 56 },
.{ "start.png", 57 },
.{ "temp.aseprite", 58 },
.{ "textRectangle1.png", 59 },
.{ "tileSet1.png", 60 },
.{ "Tilemap", 61 },
.{ "tileMap1.tsdI", 62 },
.{ "tileSet1.tsd", 63 },
};

break: map std.StaticStringMap(i32).initComptime(list);
};
 


pub fn comptimeGetID(comptime fileName: []const u8) i32 {
comptime {
return FileNameIdHashMap.get(fileName) orelse @compileError("not found");
}
}

pub fn getID(fileName: []const u8) i32 {    return FileNameIdHashMap.get(fileName) orelse std.debug.panic("ilegal name", .{{}}); }