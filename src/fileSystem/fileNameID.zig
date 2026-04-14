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
.{ "Cube_0.vtx", 14 },
.{ "box.gltf", 15 },
.{ "box.obj", 16 },
.{ "box.png", 17 },
.{ "dragon.glb", 18 },
.{ "dragon_0.vtx", 19 },
.{ "voxel.mtl", 20 },
.{ "voxel.obj", 21 },
.{ "voxel.png", 22 },
.{ "Pipeline", 23 },
.{ "directOut.pipeb", 24 },
.{ "flat2d.pipeb", 25 },
.{ "model3d.pipeb", 26 },
.{ "Sampler", 27 },
.{ "pixel2dSampler.sampler", 28 },
.{ "Scenes.json", 29 },
.{ "Shaders", 30 },
.{ "2d.vert.spv", 31 },
.{ "combine.frag.spv", 32 },
.{ "combine2d.frag.spv", 34 },
.{ "direct.frag.spv", 35 },
.{ "empty.frag.spv", 36 },
.{ "flat2d.frag.spv", 37 },
.{ "flat2d.vert.spv", 38 },
.{ "model3d.frag.spv", 39 },
.{ "model3d.vert.spv", 40 },
.{ "modelBottom.frag.spv", 41 },
.{ "particle.comp.spv", 42 },
.{ "particle.frag.spv", 43 },
.{ "particle.vert.spv", 44 },
.{ "shader2.comp.spv", 45 },
.{ "shadow.vert.spv", 46 },
.{ "shape.frag.spv", 47 },
.{ "shape.vert.spv", 48 },
.{ "sixVertices.vert.spv", 49 },
.{ "spirv_reflect.exe", 50 },
.{ "SSGI.comp.spv", 51 },
.{ "triangle.frag.spv", 52 },
.{ "triangle.vert.spv", 53 },
.{ "Texts", 54 },
.{ "text.txt", 55 },
.{ "Textures", 56 },
.{ "circle.png", 57 },
.{ "emoji.png", 58 },
.{ "icon.png", 59 },
.{ "loading1", 60 },
.{ "loading1.png", 61 },
.{ "mainBackground.png", 62 },
.{ "mainFont.png", 63 },
.{ "non_exist.png", 64 },
.{ "StartMenu", 65 },
.{ "exit.png", 66 },
.{ "load.png", 67 },
.{ "setting.png", 68 },
.{ "start.png", 69 },
.{ "temp.aseprite", 70 },
.{ "textRectangle1.png", 71 },
.{ "tileSet1.png", 72 },
.{ "Tilemap", 73 },
.{ "tileMap1.tsdI", 74 },
.{ "tileSet1.tsd", 75 },
};

break: map std.StaticStringMap(i32).initComptime(list);
};
 


pub fn comptimeGetID(comptime fileName: []const u8) i32 {
comptime {
return FileNameIdHashMap.get(fileName) orelse @compileError("not found");
}
}

pub fn getID(fileName: []const u8) i32 {    return FileNameIdHashMap.get(fileName) orelse std.debug.panic("ilegal name", .{}); }