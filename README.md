# zig_game

## struct
<img width="2723" height="1841" alt="image" src="https://github.com/user-attachments/assets/22ab9706-3125-4f4e-975d-22cb6ac29424" />

## feather preview
<img width="808" height="641" alt="image" src="https://github.com/user-attachments/assets/054cf704-a1cd-4aa2-96e2-27b452156439" />
<img width="640" height="480" alt="2026-08-11 11-07-00" src="https://github.com/user-attachments/assets/476cf985-7d77-42f0-9bed-4266f41af59e" />

### build

sometimes build may failed at first time, retry a few times will success

```bash
git clone https://github.com/srnabab/zig_game.git
cd zig_game
git lfs pull
cd tools/srcs/cooker
zig build
cd ..
cd watcher
zig build run 
# until success run then terminate it or wahtever.
cd ../../../
zig build run
```

### file struct

```
.
├── AGENTS.md # agent self-update rules
├── LICENSE
├── README.md
├── .watching # dirs watched by watcher
├── Assets # asset source files
    ├── loadMap # loadmap source files
    ├── pipeline # pipeline config json
    ├── Sampler # sampler config json
    ├── schema # pipeline/sampler/loadmap json schema
    └── Shaders # shader source file
├── build.zig 
├── build.zig.zon
├── build_script 
    ├── feather_lut.py # generate feather BRDF omega_h lut
    ├── pipelineConfig.py # generate example for pipeline json config
    ├── pipelineParse.bat # pack pipeline config json and shader spv to binary (deprecate)
    ├── samplerJson.py # generate example for sampler json config
    ├── samplerParse.bat # pack sampler json
    ├── shaderCompile.bat # compile shader to spv (deprecate)
    └── showDag.py # draw a graph from render graph dot file debug info
├── dependencies
├── include
├── lib # dll and lib
├── monsoon # engine code (migrated from src)
├── shared # zig file across watcher and game
├── src # game code
├── tools
    ├── srcs
    │   ├── cooker # resource preprocessor, child process of watcher
    │   │   ├── build.zig
    │   │   └── src
    │   ├── loadmapConverter # loadmap preprocessor
    │   │   └── src
    │   └── watcher
    │       ├── build.zig
    │       ├── build.zig.zon
    │       └── src # watcher src
    └── *.exe # built tool binaries (cooker / loadmapConverter / watcher)
├── zig-out
    └── bin
        ├── Content
            ├── Audio
            ├── Fonts
            ├── LoadMap
            ├── Model
            ├── Pipeline # pipeline binary with spv shader
            ├── Sampler # sampler pack
            ├── Scenes.json # model transform based on scene
            ├── Shaders # spv shader file
            ├── Texts
            ├── Textures
            └── Tilemap (deprecate)
        └── Content.db
```

### to see the example
press D -> press B -> press C -> press E -> press E ->press Q
