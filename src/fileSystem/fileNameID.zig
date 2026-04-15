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
.{ "dragon.glb", 14 },
.{ "box.gltf", 15 },
.{ "box.obj", 16 },
.{ "box.png", 17 },
.{ "Cube_0.vtx", 18 },
.{ "voxel.mtl", 19 },
.{ "dragon_0.vtx", 20 },
.{ "voxel.obj", 21 },
.{ "voxel.png", 22 },
.{ "Pipeline", 23 },
.{ "directOut.pipeb", 24 },
.{ "flat2d.pipeb", 25 },
.{ "model.pipeb", 26 },
.{ "model3d.pipeb", 27 },
.{ "Sampler", 28 },
.{ "pixel2dSampler.sampler", 29 },
.{ "loading1", 31 },
.{ "loading1.png", 32 },
.{ "mainBackground.png", 33 },
.{ "mainFont.png", 34 },
.{ "non_exist.png", 35 },
.{ "StartMenu", 36 },
.{ "exit.png", 37 },
.{ "load.png", 38 },
.{ "setting.png", 39 },
.{ "start.png", 40 },
.{ "temp.aseprite", 41 },
.{ "textRectangle1.png", 42 },
.{ "tileSet1.png", 43 },
.{ "Tilemap", 44 },
.{ "tileMap1.tsdI", 45 },
.{ "tileSet1.tsd", 46 },
.{ "Scenes.json", 47 },
.{ "Shaders", 48 },
.{ "2d.vert.spv", 49 },
.{ "combine.frag.spv", 50 },
.{ "combine.vert.spv", 51 },
.{ "combine2d.frag.spv", 52 },
.{ "direct.frag.spv", 53 },
.{ "empty.frag.spv", 54 },
.{ "flat2d.frag.spv", 55 },
.{ "flat2d.vert.spv", 56 },
.{ "model.mesh.spv", 57 },
.{ "model3d.frag.spv", 58 },
.{ "model3d.vert.spv", 59 },
.{ "modelBottom.frag.spv", 60 },
.{ "particle.comp.spv", 61 },
.{ "particle.frag.spv", 62 },
.{ "particle.vert.spv", 63 },
.{ "shader2.comp.spv", 64 },
.{ "shadow.vert.spv", 65 },
.{ "shape.frag.spv", 66 },
.{ "shape.vert.spv", 67 },
.{ "sixVertices.vert.spv", 68 },
.{ "spirv_reflect.exe", 69 },
.{ "SSGI.comp.spv", 70 },
.{ "triangle.frag.spv", 71 },
.{ "triangle.vert.spv", 72 },
.{ "Texts", 73 },
.{ "text.txt", 74 },
.{ "Textures", 75 },
.{ "circle.png", 76 },
.{ "emoji.png", 77 },
.{ "icon.png", 78 },
};

break: map std.StaticStringMap(i32).initComptime(list);
};
 


pub fn comptimeGetID(comptime fileName: []const u8) i32 {
comptime {
return FileNameIdHashMap.get(fileName) orelse @compileError("not found");
}
}

pub fn getID(fileName: []const u8) i32 {    return FileNameIdHashMap.get(fileName) orelse std.debug.panic("ilegal name", .{}); }