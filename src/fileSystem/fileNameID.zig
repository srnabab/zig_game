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
.{ "monkey.glb", 20 },
.{ "Suzanne_0.vtx", 21 },
.{ "voxel.mtl", 22 },
.{ "voxel.obj", 23 },
.{ "voxel.png", 24 },
.{ "Pipeline", 25 },
.{ "directOut.pipeb", 26 },
.{ "flat2d.pipeb", 27 },
.{ "model.pipeb", 28 },
.{ "model3d.pipeb", 29 },
.{ "Sampler", 30 },
.{ "pixel2dSampler.sampler", 31 },
.{ "Scenes.json", 32 },
.{ "Shaders", 33 },
.{ "2d.vert.spv", 34 },
.{ "combine.frag.spv", 35 },
.{ "combine.vert.spv", 36 },
.{ "combine2d.frag.spv", 37 },
.{ "flat2d.vert.spv", 38 },
.{ "particle.frag.spv", 39 },
.{ "model.mesh.spv", 40 },
.{ "model3d.frag.spv", 41 },
.{ "model3d.vert.spv", 42 },
.{ "modelBottom.frag.spv", 43 },
.{ "particle.comp.spv", 44 },
.{ "flat2d.frag.spv", 45 },
.{ "particle.vert.spv", 46 },
.{ "shader2.comp.spv", 47 },
.{ "shadow.vert.spv", 48 },
.{ "shape.frag.spv", 49 },
.{ "shape.vert.spv", 50 },
.{ "sixVertices.vert.spv", 51 },
.{ "spirv_reflect.exe", 52 },
.{ "SSGI.comp.spv", 53 },
.{ "triangle.frag.spv", 54 },
.{ "triangle.vert.spv", 55 },
.{ "Texts", 56 },
.{ "text.txt", 57 },
.{ "Textures", 58 },
.{ "circle.png", 59 },
.{ "emoji.png", 60 },
.{ "icon.png", 61 },
.{ "loading1", 62 },
.{ "loading1.png", 63 },
.{ "mainBackground.png", 64 },
.{ "mainFont.png", 65 },
.{ "non_exist.png", 66 },
.{ "StartMenu", 67 },
.{ "exit.png", 68 },
.{ "load.png", 69 },
.{ "setting.png", 70 },
.{ "start.png", 71 },
.{ "temp.aseprite", 72 },
.{ "textRectangle1.png", 73 },
.{ "tileSet1.png", 74 },
.{ "Tilemap", 75 },
.{ "tileMap1.tsdI", 76 },
.{ "tileSet1.tsd", 77 },
.{ "empty.frag.spv", 78 },
.{ "direct.frag.spv", 79 },
};

break: map std.StaticStringMap(i32).initComptime(list);
};
 


pub fn comptimeGetID(comptime fileName: []const u8) i32 {
comptime {
return FileNameIdHashMap.get(fileName) orelse @compileError("not found");
}
}

pub fn getID(fileName: []const u8) i32 {    return FileNameIdHashMap.get(fileName) orelse std.debug.panic("ilegal name", .{}); }