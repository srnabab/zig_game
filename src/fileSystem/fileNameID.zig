const std = @import("std");

const FileNameIdHashMap = map: {
const KV = struct {
[]const u8,i64,
};
const list = [_]KV{
.{ "OpenMoji-color-glyf_colr_0.ttf", 0 },
.{ "SourceHanSansSC-VF.ttf", 1 },
.{ "Model", 2 },
.{ "bottom.obj", 3 },
.{ "bottom.png", 4 },
.{ "box.bin", 5 },
.{ "box.glb", 6 },
.{ "box.gltf", 7 },
.{ "box.obj", 8 },
.{ "box.png", 9 },
.{ "Cube_0.vtx", 10 },
.{ "dragon.glb", 11 },
.{ "dragon_0.vtx", 12 },
.{ "voxel.mtl", 13 },
.{ "flat2d.pipeb", 14 },
.{ "voxel.obj", 15 },
.{ "voxel.png", 16 },
.{ "Pipeline", 17 },
.{ "directOut.pipeb", 18 },
.{ "model3d.pipeb", 19 },
.{ "model.pipeb", 20 },
.{ "Sampler", 21 },
.{ "pixel2dSampler.sampler", 22 },
.{ "Content", 24 },
.{ "Audio", 25 },
.{ "MainBackgroundMusic1.wav", 26 },
.{ "test.wav", 27 },
.{ "Fonts", 28 },
.{ "EmojiHashTable", 29 },
.{ "MainFontHashTable", 30 },
.{ "load.png", 31 },
.{ "setting.png", 32 },
.{ "start.png", 33 },
.{ "temp.aseprite", 34 },
.{ "textRectangle1.png", 35 },
.{ "tileSet1.png", 36 },
.{ "Tilemap", 37 },
.{ "tileMap1.tsdI", 38 },
.{ "tileSet1.tsd", 39 },
.{ "Scenes.json", 40 },
.{ "Shaders", 41 },
.{ "2d.vert.spv", 42 },
.{ "combine.frag.spv", 43 },
.{ "combine.vert.spv", 44 },
.{ "combine2d.frag.spv", 45 },
.{ "direct.frag.spv", 46 },
.{ "empty.frag.spv", 47 },
.{ "flat2d.frag.spv", 48 },
.{ "flat2d.vert.spv", 49 },
.{ "model.mesh.spv", 50 },
.{ "model3d.frag.spv", 51 },
.{ "model3d.vert.spv", 52 },
.{ "modelBottom.frag.spv", 53 },
.{ "particle.comp.spv", 54 },
.{ "particle.frag.spv", 55 },
.{ "particle.vert.spv", 56 },
.{ "shader2.comp.spv", 57 },
.{ "shadow.vert.spv", 58 },
.{ "shape.frag.spv", 59 },
.{ "shape.vert.spv", 60 },
.{ "sixVertices.vert.spv", 61 },
.{ "spirv_reflect.exe", 62 },
.{ "SSGI.comp.spv", 63 },
.{ "triangle.frag.spv", 64 },
.{ "triangle.vert.spv", 65 },
.{ "Texts", 66 },
.{ "text.txt", 67 },
.{ "Textures", 68 },
.{ "circle.png", 69 },
.{ "emoji.png", 70 },
.{ "icon.png", 71 },
.{ "loading1", 72 },
.{ "loading1.png", 73 },
.{ "mainBackground.png", 74 },
.{ "mainFont.png", 75 },
.{ "non_exist.png", 76 },
.{ "StartMenu", 77 },
.{ "exit.png", 78 },
};

break: map std.StaticStringMap(i32).initComptime(list);
};
 


pub fn comptimeGetID(comptime fileName: []const u8) i32 {
comptime {
return FileNameIdHashMap.get(fileName) orelse @compileError("not found");
}
}

pub fn getID(fileName: []const u8) i32 {    return FileNameIdHashMap.get(fileName) orelse std.debug.panic("ilegal name", .{}); }