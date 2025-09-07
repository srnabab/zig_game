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
.{ "box.obj", 12 },
.{ "box.png", 13 },
.{ "voxel.mtl", 14 },
.{ "voxel.obj", 15 },
.{ "voxel.png", 16 },
.{ "Pipeline", 17 },
.{ "model3d.pipeb", 18 },
.{ "Shaders", 19 },
.{ "2d.vert.spv", 20 },
.{ "combine.frag.spv", 21 },
.{ "combine.vert.spv", 22 },
.{ "combine2d.frag.spv", 23 },
.{ "empty.frag.spv", 24 },
.{ "model3d.frag.spv", 25 },
.{ "model3d.vert.spv", 26 },
.{ "modelBottom.frag.spv", 27 },
.{ "particle.comp.spv", 28 },
.{ "particle.frag.spv", 29 },
.{ "particle.vert.spv", 30 },
.{ "shader2.comp.spv", 31 },
.{ "shadow.vert.spv", 32 },
.{ "shape.frag.spv", 33 },
.{ "shape.vert.spv", 34 },
.{ "spirv_reflect.exe", 35 },
.{ "SSGI.comp.spv", 36 },
.{ "triangle.frag.spv", 37 },
.{ "triangle.vert.spv", 38 },
.{ "Texts", 39 },
.{ "text.txt", 40 },
.{ "Textures", 41 },
.{ "circle.png", 42 },
.{ "emoji.png", 43 },
.{ "icon.png", 44 },
.{ "loading1", 45 },
.{ "loading1.png", 46 },
.{ "mainBackground.png", 47 },
.{ "mainFont.png", 48 },
.{ "non_exist.png", 49 },
.{ "StartMenu", 50 },
.{ "exit.png", 51 },
.{ "load.png", 52 },
.{ "setting.png", 53 },
.{ "start.png", 54 },
.{ "temp.aseprite", 55 },
.{ "textRectangle1.png", 56 },
.{ "tileSet1.png", 57 },
.{ "Tilemap", 58 },
.{ "tileMap1.tsdI", 59 },
.{ "tileSet1.tsd", 60 },
.{ "bottom.png", 11 },
};

break: map std.StaticStringMap(i64).initComptime(list);
};
 


pub fn comptimeGetID(comptime fileName: []const u8) i64 {return comptime FileNameIdHashMap.get(fileName) orelse std.debug.panic("ilegal name", .{{}});}

pub fn getID(fileName: []const u8) i64 {    return FileNameIdHashMap.get(fileName) orelse std.debug.panic("ilegal name", .{{}}); }