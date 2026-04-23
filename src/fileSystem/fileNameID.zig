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
.{ "direct.frag.spv", 38 },
.{ "empty.frag.spv", 39 },
.{ "flat2d.frag.spv", 40 },
.{ "flat2d.vert.spv", 41 },
.{ "model.mesh.spv", 42 },
.{ "model3d.frag.spv", 43 },
.{ "model3d.vert.spv", 44 },
.{ "modelBottom.frag.spv", 45 },
.{ "particle.comp.spv", 46 },
.{ "particle.frag.spv", 47 },
.{ "particle.vert.spv", 48 },
.{ "shader2.comp.spv", 49 },
.{ "shadow.vert.spv", 50 },
.{ "shape.frag.spv", 51 },
.{ "shape.vert.spv", 52 },
.{ "sixVertices.vert.spv", 53 },
.{ "spirv_reflect.exe", 54 },
.{ "SSGI.comp.spv", 55 },
.{ "triangle.frag.spv", 56 },
.{ "triangle.vert.spv", 57 },
.{ "Texts", 58 },
.{ "text.txt", 59 },
.{ "Textures", 60 },
.{ "circle.png", 61 },
.{ "emoji.png", 62 },
.{ "icon.png", 63 },
.{ "loading1", 64 },
.{ "loading1.png", 65 },
.{ "mainBackground.png", 66 },
.{ "mainFont.png", 67 },
.{ "non_exist.png", 68 },
.{ "StartMenu", 69 },
.{ "exit.png", 70 },
.{ "load.png", 71 },
.{ "setting.png", 72 },
.{ "start.png", 73 },
.{ "temp.aseprite", 74 },
.{ "textRectangle1.png", 75 },
.{ "tileSet1.png", 76 },
.{ "Tilemap", 77 },
.{ "tileMap1.tsdI", 78 },
.{ "tileSet1.tsd", 79 },
};

break: map std.StaticStringMap(i32).initComptime(list);
};
 


pub fn comptimeGetID(comptime fileName: []const u8) i32 {
comptime {
return FileNameIdHashMap.get(fileName) orelse @compileError("not found");
}
}

pub fn getID(fileName: []const u8) i32 {    return FileNameIdHashMap.get(fileName) orelse std.debug.panic("ilegal name", .{}); }