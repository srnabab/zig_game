## Agent 自我更新规范 (Core Directive)

- **核心要求**：作为 AI Agent，每当你根据用户要求完成了新功能的开发、重构了代码逻辑、调整了目录结构、引入了新的库，或者更改了项目构建/测试命令后，**你必须主动且自动地编辑并更新本 `AGENTS.md` 文件**。
- 请将最新的项目认知（如新增的文件模块、新的常用命令、新确立的代码规范）就地更新（Improve in place）到此文件中，以确保下一个会话能够准确继承这些最新成果。
- 如果某次改动不涉及架构或规范层面的变化，则无需更新。
- 调用一个未记录的函数后记录一次这个函数的调用方法

## Important
请将所有逻辑写在同一个函数内，除非逻辑极其复杂，否则不要拆分出子函数，也不要进行额外包装。
- **验证职责**：Zig 相关的编译/运行/测试验证（`zig build`、`zig build run`、`zig build test` 等）一律由用户自行进行，AI Agent 不要执行 zig 命令做验证——LLM 训练语料缺少 Zig 0.16 相关内容，执行验证既不可靠又耗时耗 token。

## Build

- `zig build` — compile (Zig >= 0.16.0)
- `zig build run` — build + run (kills running game.exe first, Windows-only)
- `zig build test` — unit tests on `exe_mod` (transitive tests from `monsoon/main.zig`)
- `zig build -Dtracy_enable=true` — enable Tracy; `-Dtracy_callstack=N` (default 10)
- Default target ABI is forced to `.gnu` (`build.zig:7`)
- `genFileNameIdHashMap` auto-runs as a build dep → regenerates `monsoon/fileSystem/fileNameID.zig`. Do not edit by hand.
- 自定义结构体(`src/customStruct`)的 module 创建/接线已收敛到 `src/build/`，根 `build.zig` 只需构造 `Config` 调 `customBuild.build(cfg)`（详见 Architecture）

## u8pack Str / HashMap (迁移已完成)

`monsoon/u8pack.zig`(唯一引用方模块 `u8pack`)现状：

- `Str = struct { id: u32, name: (Debug/ReleaseSafe 才保留的 []const u8, ReleaseFast 为 void) }`；`format` 仅在 debug 分支打印。
- `u8pack.HashMap(V) = std.HashMap(Str, V, HashMapContext, 80)`（已取代旧的 `StrAutoHashMap`，后者已删除/注释）。`HashMapContext` 在 debug 下按 `name` 串 hash/eql，在 release 下按 `id` hash/eql。
- **名字注册表**：`str_maps` 的类型由 `@Struct(.auto, null, <"belongMap" ++ totalMaps>, <StrMap × n>, &@splat(.{}))` 在 comptime 拼出来（`StrMap = std.StaticStringMap(u32)`），字段 = `belongMap` + `totalMaps` 里每个表名，所以新增表不用改字段声明。三组表来源：`ctxMaps = {buffers, passes}`（comptime 造 `var ctx = CTX{ .buffers = &.{}, .passes = &.{} }` → `setPass.setting(&ctx)` 填名 → `deduplicateStrings` → `StaticStringMap`，id = 去重后下标）、`files`（直接复用 `file.fileNameID.FileNameIdHashMap`，由 `Content.db` 生成）、`constructMaps = strConstruct.maps`（u8pack 对每张表调 `@field(construct, <name>)()`，见下）。最后把所有表的 key 拼成 `belongMap`（name → `totalMaps` 下标）。
- **`src/strConstruct.zig`（手写名字表插件）**：`pub const maps = [_][]const u8{"rdatas"}` + 每张表一个 `pub fn <name>() std.StaticStringMap(u32)`。u8pack 在 comptime 把 `maps` 里的名字加进 `totalMaps`/`belongMap` 并逐个调 `@field(construct, name)()`；目前只有 `rdatas()`（手写 `sprite`/`feather` 两个 rdata item 名，id = 表内下标）。新增/改名 rdata item 必须同步这里，否则运行期 `ID2` 查不到。
- **id 命名空间不唯一（注意）**：id 是“各表内部下标”，`belongMap` 也不查重，所以 (1) ReleaseFast 下 `HashMapContext`/`eql` 只比 id，`Str` 只能在同一张表内比较/做 HashMap key；(2) 名字跨表重名(pass/buffer/file/rdata)会静默命中先排序的表 → `ID` 编译期报错 / `ID2` 运行期 `unknownName`。renderData.map 属于后者（只装 rdatas 表的 Str）。
- API：
  - `ID(comptime str: []const u8) u32`——comptime 查表，找不到编译期报错。
  - `toStr(comptime str) Str`——comptime 版，等价 `.{ .name = str, .id = ID(str) }`。
  - `Str2 = if (debug) []const u8 else u32`；`ID2(str: Str2) Error!u32`——运行时查表。
  - `toStr2(str: Str2) Str`——运行时版。debug 下在 `belongMap` 里查表(`inline for (totalMaps)` + `@field(str_maps, …).getIndex(str)`)，**返回静态表里那份 key** 当 `.name`（避免调用方临时切片存进 HashMap 后悬垂），查不到则 log 并返回 `.name = 调用方切片, id = maxInt(u32)`；ReleaseFast 下 `Str2` 就是 id，直接 `.{ .name = void{}, .id = str }`（所以 debug 里能直接 `toStr2(运行时名字切片)`，ReleaseFast 下得先自己 `ID2(name)` 拿 id —— 目前代码只在 debug 下跑，见 TODO(release) 注释）。
  - `dupe(gpa, Str)` / `free(gpa, Str)` / `eql(a, b)` 已实现（按 debug 分支处理 name）。
- 调用范式：`setPass.setting(null)` 在 `monsoon/main.zig` 运行时调用；`setPass.setting(&ctx)` 在 `u8pack.zig` comptime 调用。所有 `renderFlow.*` 注册函数(见下)都加了 `comptime ctx: ?*u8pack.CTX` 首参：ctx != null 时只把名字 append 进 ctx 并返回 dummy/undefined，ctx == null 时才真正建 runtime map/array。
- 已完成类型替换：`monsoon/pass/Pass.zig` 的 `Buffer.name/parentName`、`Pass.name`、`Pipeline.name` 均为 `Str`；`monsoon/pass/renderFlow.zig` 的 `passMap/buffers/pipelines` 与 `PassImp.zig` 的 `passMap`、局部 `bufferMap`(initFromRenderFlow) 均为 `u8pack.HashMap(...)`；`monsoon/video/vkStruct/buffer.zig` 的 `bufferMap` 为 `u8pack.HashMap(Buffer_t)`；`src/customStruct/passGroupMapping.zig` 的 `updates: ArrayList(Str)`、`passCommandsMap/uploadTargets: HashMap(...)`。
- loadmap 已迁移：`monsoon/loadmap/loadmap.zig` 用 `toStr2(i.name)` / `toStr2(bi)`，`Item.name: []u8`、`Item.bufferName: [][]u8`（不再是旧泛型），已可正常编译。
- build.zig：给涉事模块(`u8pack_mod/renderFlow_mod/pass_mod/video_mod/resource_mod/setPass_mod/loadmap_mod/resourceProcess_mod` 等)补 `addImport("u8pack")`；`u8pack_mod` 自己 `addImport("strConstruct", strConstruct_mod)`(模块 `src/strConstruct.zig`)。

## Zig 0.16.0 使用笔记 (参考 monsoon/loadmap/loadmap.zig)

- `@ptrCast(slice)`：`std.mem.readInt` 参数是 `*const [4]u8`，把 `[]u8` 切片用 `@ptrCast` 转换：`std.mem.readInt(u32, @ptrCast(mem[offset .. offset + 4]), .native)`
- `@alignCast` + `bytesAsSlice`：`gpa.alignedAlloc(u8, .of(T), n)` 返回 `[]align(N) u8`（0.16 新 `Alignment` 类型，`null` 表示 T 的自然对齐）；`std.mem.bytesAsSlice` 保留指针对齐属性，需 `@alignCast` 降为自然对齐的类型化切片：
  ```zig
  const memory = try gpa.alignedAlloc(u8, .of(GridLayer), totalLen);
  const layers: []GridLayer = @alignCast(std.mem.bytesAsSlice(GridLayer, layersBytes));
  ```
- `std.mem.readInt` 直接返回 `T`（非 error union），不需要 `try`；`alignedAlloc` 才需要 `try`
- grid 在层数组中的定位：`GridLayer.getGridIndex(x, y)` 用 `cglm.abs(x - layer.leftUp[0])` 取差、`@intCast` 到 `u32` 再除 `gridLength`，商作切片索引（`u32` 索引合法）：
  ```zig
  const gx = @as(u32, @intCast(cglm.abs(x - self.leftUp[0]))) / self.gridLength;
  const gy = @as(u32, @intCast(cglm.abs(y - self.leftUp[1]))) / self.gridLength;
  ```

## Content pipeline (tools/srcs/ watcher + cooker)

内容管线由三个独立 Zig 包协作（都在 `tools/srcs/`，各自有 `build.zig`/`build.zig.zon`）：

- **watcher** (`tools/srcs/watcher/`)：Windows IOCP `ReadDirectoryChangesW` 监听，负责调度，不直接做内容处理。
- **cooker** (`tools/srcs/cooker/`)：实际内容处理进程，由 watcher spawn；通过 stdin 收命令、按 `?` 分隔初次握手、按 `\n` 收后续事件。
- **loadmapConverter** (`tools/srcs/loadmapConverter/`)：`.loadmap` JSON → `.lMap` 二进制；由 cooker 通过 `std.process.run` 调用。

工作流：

- `cd tools/srcs/watcher && zig build run`：
  - 先 build 自身 + 依赖包 cooker/loadmapConverter，把 `watcher.exe`/`cooker.exe`/`loadmapConverter.exe` 安装到 `tools/`（`dest_dir.override.custom = "../../../"`，相对包目录），再启动 watcher。
  - watcher 的参数(由 build.zig 固定注入)：`--f <root> --d <Content.db 绝对路径> <Content 目录绝对路径> --c <cooker.exe> <tools/srcs/cooker/> -force`。**默认始终带 `-force`**，即启动时 cooker 会 `processFolder` 全量重扫。
- `.watching`（watcher 启动目录下）逐行列出要监听的目录；当前内容：
  `Assets\Shaders`、`Assets\Sampler`、`Assets\pipeline`、`Assets\loadMap`、`Assets\rdata`、`Assets\layout`、`zig-out\bin\Content`、`tools\srcs\cooker`。改动 `.watching` 本身会热更新监听集合。
- watcher 把文件事件按 `<action>?<name>?<fullPath>?<type>\n` 协议写给 cooker；`action>1000` 表示"该文件在 Content/ 内"。cooker 侧按 `ProcessType` 分派到 `src/resourceProcess/*.zig` 里对应的 `*_Cooker`（`Enable` 为 true 才执行）：
  - `.comp/.vert/.frag/.mesh/.task` → `Shader_Cooker.preProcess2`：**外部调用 `glslc --target-env=vulkan1.4 -g -o <spv> <src>`**（不再用内嵌 shaderc），并写 `ShaderPipelineGraphNode/Edge` 表。
  - `.pipe` → `Pipeline_Cooker.preProcess2`：解析 JSON 写 `Content/Pipeline/<name>.pipeb`，回填 shader-pipeline 图。
  - `.samp` → `Sampler_Cooker.preProcess2`：写 `Content/Sampler/<name>.sampler`。
  - `.loadmap` → `LoadMap_Cooker.preProcess2`：调 `loadmapConverter.exe` 生成 `Content/LoadMap/<name>.lMap`。
  - `.rdata` → `RData_Cooker.preProcess2`：用 `pwsh Copy-Item` 复制到 `Content/Rdata/`。
  - `.layout` → `Layout_Cooker.preProcess2`：用 `pwsh Copy-Item` 复制到 `Content/Layout/`。
  - 无 cooker 的 type 走 `Example_Cooker`（空实现）。
  - 全量扫描/DB 更新由 cooker 内部 `db.processFolder` / `iterateFolder.processFile` 完成。
- `Content.db`(SQLite) 由 cooker 维护；表定义见 `src/tables.zig`(`ContentPath`、`ImageLoadParameter`、`ModelLoadParameter`、`ShaderPipelineGraphNode`、`ShaderPipelineGraphEdge`)，触发器见 `src/triggers.zig`。运行时引擎只读。
- Ctrl+C → watcher 让 cooker 退出；Ctrl+Break → 让 cooker 保存(commit)后继续。
- cooker 的 `shared_b` 是指向 `../../../src` 的符号链接，因此 cooker 直接复用引擎的 `src/resourceProcess.zig`、`src/tables.zig`、`src/setPass.zig` 等源码；cooker build 依赖 blake3/meshoptimizer/cglm，`shaderc` 依赖已在 cooker `build.zig.zon` 中移除。
- `-force` 语义：`db.iterateFolder.forceUpdata = true`。

`build_script/` 下是**手动 fallback**（需要 PATH 上有 `glslc.exe`，并靠 `monsoon/selectModifiedFileToTxt` + `cache.json` 生成改动文件列表）：`shaderCompile.bat`、`pipelineParse.bat`、`samplerParse.bat`；另有 `pipelineConfig.py`、`samplerJson.py`、`feather_lut.py`、`showDag.py`。

## External prerequisites

- **Vulkan SDK** — headers in `include/vulkan/`，`lib/vulkan-1.lib` 已内置，运行时仍需 SDK
- **Steam SDK** — `lib/steam_api64.lib` 与 DLL，头文件 `include/steam/`
- **glslc** — cooker/watcher 编译 shader 需要 PATH 上可执行的 `glslc.exe`（来自 Vulkan SDK / shaderc）；`shared/shaderc/shaderc.zig` 仍在但当前未被 cooker 使用
- **Python** — `build_script/pipelineConfig.py`、`feather_lut.py`、`samplerJson.py`、`showDag.py` 需要
- SDL3、cglm、Tracy、meshoptimizer、blake3 均从 `dependencies/` 源码构建
- `tools/srcs/cooker` 还用到 `include/UUID`、`include/cgltf`、`include/meshoptimizer.h`

## Architecture

- **Entrypoint**: `monsoon/main.zig` spawns update + render threads, inits SDL3 + Vulkan + Tracy
- **Module convention**: Each significant source file is its own Zig module in `build.zig`. Import by module name (e.g. `@import("video")`, `@import("fileSystem")`), not file path
- **Custom structs + src/build pipeline**: `vertices`/`meshInstance`/`mesh`/`passGroupMapping`/`renderData` 五个自定义结构体已从 `monsoon/video/`(及 indirect2D/) 拆到 `src/customStruct/*.zig`。模块名与文件名一致：`src/customStruct/meshInstance.zig`(原名 instance.zig)，模块名 `"meshInstance"`；`src/customStruct/passGroupMapping.zig`(原名 `monsoon/video/pass/pass.zig`，模块名不变)；`src/customStruct/renderData.zig`(模块名 `"renderData"`，上游需 `pass`，故 `Config` 新增了 `pass` 字段，`build.zig` 构造 Config 时 `.pass = pass_mod`)。它们的 module 创建与接线全部收敛到 `src/build/`：`config.zig` 定义 `Config`(上游 = 结构体源码 @import 的引擎模块 video/processRender/vertexStruct/global/handle/u8pack/pass；下游 = 引擎中回填注册的消费者 exe/resource/resourceProcess)；每结构体一个构建文件(`vertices.zig`/`meshInstance.zig`/`mesh.zig`/`passGroupMapping.zig`/`renderData.zig`，导出 `name` + `build(cfg)`，内部完成 createModule + 上游 addImport + 对下游消费者 addImport)；`out.zig` 导出 `build(cfg)`，里面**逐个显式**调用各 build 函数（`list`/`Modules` 仍在文件里但当前未被 build() 使用——属预留的自动遍历结构）。根 `build.zig` 构造 `Config` 并 `_ = customBuild.build(cfg)`。新增自定义结构体：加文件 + 在 out.zig 里加一行 `build(cfg)` 调用（list 可顺手加，但不影响构建）。
- **每帧上传管线**: `src/renderUpload.zig` 的 `upload(io, vulkan, passes, pTextureSet, uctx, commands: *processRender.commands)` 是 render 线程每帧入口（render.zig 在 `waitEndFence/startCommand/addCachedCommand` 前调用），依次 `uctx.vertices.uploadInstance(io, vulkan, commands)`、`uctx.instances1.upload(io, vulkan, commands)`、`uctx.passGroupMapping.upload(io, vulkan, commands)`、`uctx.meshes.upload(commands)`，均通过 `commands.cacheCommand(.copyBuffer)` 录命令。
  - `vertices`/`meshInstance` 的上传目标 buffer 由 `resourceProcess.UserContext.initUserContext` 从 passMap 取出后在 init 时内置：`vertices2D.init(indirect2D buffer[2]/[0]/[1], gpa, externalCommands)`、`meshInstance.init(gpa, handles, i_feather buffer[9]=IF.instance3D)`。
  - `mesh.init(gpa, vulkan, handles, [5]Buffer_t)` 接收 i_feather buffer[2]/[3]/[4]/[5](featherMeshlet/featherVertices/featherMeshletVertices/featherMeshletTriangles)+[10](meshes)，字段化保存 4 个 mesh 数据区 buffer + `meshesBuffer`，并以四组 `TotalAndCount{total,count}` 在 init 按 `getBufferContent(buf).size / buf.stride` 算 total、`addMesh` 累计 count 得 offsets。**`mesh` 内部没有 mutex**：`mesh.addMesh(meshletSize, verticesSize, meshletVerticesSize, meshletTrianglesSize, verticeStride) !u32`(无 fileID/io) 与 `mesh.upload(commands) !void`(无 io) 都是裸调用；`meshMap: AutoHashMap(u32, Mesh_t)` 仍在结构体里但当前 addMesh 不写它。`mesh.init` 的一次性命令(fillBuffer)仍走 `externalCommands.externalCommand`(init 参数类型为 `*externalCommands`)。
  - `vertices`/`meshInstance`/`passGroupMapping` 内部都有 `mutex: std.Io.Mutex`，`add`/`upload` 均 `lock(io)`/`unlock(io)`(add 在 update 线程、upload 在 render 线程，互斥对齐)。
  - `monsoon/instances/instances.zig`(模块 `instance2`/`instances2`，含 `instance` 结构/`add`/`load`) **已删除**：实例的生成全部搬到 render.zig 的 updateEvent 分支（见下条 `UpdateEvent`），`UserContext.instances2` 字段与 `Config.instances2` 亦一并移除。
- **UpdateEvent (update→render)**: `monsoon/event.zig` 的 `UpdateEventType = { createTest2d, createTest3d }`，`UpdateEvent` 两个成员 `test2d`/`test3d` 字段相同：`{ pos, scale, rotation, rdata: u8pack.Str, handle }`。**事件由 render 线程自己生产**：主要由 `Layout_Reader.renderLoad`(渲染线程) 经 `updateEventQueue.pushLastC(...)` 推进消费者自己的队列(同帧后面就被 drain)，过渡期用 pass 名比对分支(`indirect2D`→`createTest2d`、`i_feather`→`createTest3d`)。render.zig 每帧消费 `updateEventQueue` 时按分支处理(先 `while (popFirst())` 消费，循环之后才 `swap()`)：
  - `.createTest2d`：`args.uctx.renderData.get(c.rdata)` 取 `rData` → `pass.useTexture(rdata.textures[0], gpa)` + `pTextureSet.getTextureCotent/getDescriptorSetIndex` → `vertices.addInstance(io, pos[0], pos[1], scale*source_size, pos[2], descIdx)` → 写 `pass.userdata`(`ViewBoundsAndTotalSpriteCount.totalSpriteCount`) → `handles.setIndex(...)`。
  - `.createTest3d`：同样先取 `rData`，然后 `instances1.add(io, null, pos, scale, rotation, null)` → `Handles.getIndex(ins)` 得 instanceID、`Handles.getIndex(rdata.model.?)` 得 meshID → `passGroupMapping.add(io, rdata.pass.name, .{instanceID, meshID})` 回写 `pass.userdata`(drawCount u32) → `rdata.pass.setPushConstants(2, toBytes(descIdx), 64)`。
  - **PassGroupMapping**(src/customStruct/passGroupMapping.zig)：`uploadTargets: HashMap(Target{indirectBuffer, mappingBuffer})`(passName→目标 buffer，由 `addUploadTarget(passName, indirectBuffer, mappingBuffer)` 在 initUserContext 里注册 i_feather 的 buffer[6]/buffer[8])与 `mutex`；`add(io, passName, mapping: GroupMapping) !u32` 返回 drawCount，`upload(io, vulkan, commands: *commands)` pop `updates` 后按 name 查表取 buffer、录 `cacheCommand(.copyBuffer)`、查不到则 `continue`(不中断队列其余 name)。
- **Vulkan core**: `monsoon/video/VkStruct.zig` (~1870 lines) — device/swapchain/descriptors/gfx pipeline. `monsoon/video/processRender.zig` — per-frame rendering
- **Render graph**: DAG-based pass system in `monsoon/pass/` (`PassImp.zig`, `renderFlow.zig`). DAG debug flags in `monsoon/global.zig` (`printDagToDot`, `stopNodeDagPrint`, `nodeChildrenAppendBreakPoint`)
- **Dynamic UBO offset (`uboOffset`)**: `drawCommand.zig` 的 `Compute/ComputeIndirect/Draw2D/DrawIndirect/DrawMesh/DrawMeshIndirect/Present` 各有一个 `uboOffset: ?*u32`(指向外部 u32，非拥有)。`processRender.addCommand` 的 compute(含 indirect) 分支直接把它写进 `bindDescriptorSetsInfo`(`dynamicOffsetCount = if (uboOffset != null) 1 else 0`，`pDynamicOffsets = uboOffset`)；draw/present 分支则把它作为新参数传给 `resPackNodeProcess(..., pushConstants, uboOffset, commandType, ...)`。`resPackNodeProcess` 内 3 处建 descriptor set 时先取 `const stageFlags = self.getDescriptorSetsShaderStage(descriptorSets)`，再 `dynamicOffsetCount = if ((stageFlags & (COMPUTE|VERTEX|MESH_EXT)) != 0) 1 else 0`(+ `pDynamicOffsets = uboOffset`)——即含 compute/vertex/mesh 的集合传偏移，纯 frag 集合不传(`pDynamicOffsets` 字段类型 `[*c]const u32`，直接由 `?*u32` 赋值)。注意 resPack 的 hash 不含 uboOffset，仅 offset 不同的 draw 会命中同一缓存链。
- **Viewport / Scissor（Phase 1：去句柄 / 去资源链）**: `Commands`(processRender) 改为值语义字段 `viewports: [2]vk.VkViewport = undefined` + `currentViewportIndex: u32 = 0`、`scissors: [2]vk.VkRect2D = undefined` + `currentScissorIndex: u32 = 0`（目前只用索引 0，槽 1 预留）。调用方法：`commands.setViewport(vk.VkViewport)` / `commands.setScissor(vk.VkRect2D)`（只写 `[currentXxxIndex]`，没有 handle、没有锁）。`monsoon/video/vkStruct/viewport.zig` / `scissor.zig` 已删除，`VkStruct` 不再有 `viewports/scissors` 字段与 `Viewport_t/Scissor_t`（`VkStruct.zig` 里 pipeline 创建用的 `viewportInfo` 是 `.pipe` 静态状态，保留不动；`handle.zig` 的 `ResourceType.viewport/scissor` 故意留着没删）。**已从 resource pack 移除**：`getRenderingResPack` 不再收 viewport/scissor 参数，resPack 布局 = `[vertexBuffers…, descriptorSets…, pipeline, indexBuffer?]`；`resPackNodeProcess` 尾段上界 `vAndDeLen + 2`，`tempNode` 改为 `?*QueueNode` 并在连接前用 `if (tempNode) |t| { if (linkNodeEnd == null) … }` 判空（防 undefined 指针进 DAG）。`addCommand2` 的 `.setScissor/.setViewport` 分支（`drawC.comm2` 里是值类型 `vk.VkRect2D`/`vk.VkViewport`）与录制侧 `vkCmdSetViewport/vkCmdSetScissor` 保留待用。**发射点已在 `addCommand` 的 graphics draw 分支**（`resPackNodeProcess` 之后）：每帧每 draw 先 `const viewportNode = try self.addCommand2(.{ .setViewport = self.viewports[self.currentViewportIndex] }, std.meta.activeTag(command), ID)`、再 `scissorNode = addCommand2(.{ .setScissor = self.scissors[self.currentScissorIndex] }, …)`（`addCommand2(command: drawC.comm2, enterCommandType: drawC.CommandType, enterID: u32) !twoQueueNode`，取 `.a.?` 得 `*QueueNode`），然后 `nodeConnect(viewportNode.a.?, scissorNode.a.?)` → `nodeConnect(scissorNode.a.?, node)`，并把 **viewport 的节点**作为 `node` 实参传给 `lastNodeLinkNodeRenderingNodeConnect(lastNode, linkNode, viewportNode.a.?, renderingNode)` —— 即 order = `render链 → viewport → scissor → draw记录节点`，且 previous draw 的子节点会被 reparent 到 viewport 节点（若发现后续依赖顺序不对，优先查这里）。**尚未做**：每个 pass 手动 `commands.setViewport/setScissor`（目前只有 `render.zig` 启动时写一次全窗口值到槽 0，所以全局同一套 viewport/scissor）；`render.zig` 每帧兜底与 resize 修正。
- **Pass pipeline 声明/运行时模型**: schema 层 `monsoon/pass/Pass.zig` `Pass.Pass.pipeline: ?[]Pipeline`(nullable 列表，每条含 `{name: Str, isMesh}`；`null` = 未声明管线，`PassImp.initFromRenderFlow` 会跳过该 pass 不进 runtime)。`renderFlow` 所有注册函数签名统一为 `fn(comptime ctx: ?*u8pack.CTX, comptime name/passName: []const u8, ...)`：
  - `createBuffer(ctx, name, initSize, stride, usage, isVirtualBlock, parentName)`、`createPass(ctx, name)`、`addPipeline(ctx, name, isMesh)`、`addBufferToPass(ctx, passName, buffer)`、`addPipelineToPass(ctx, passName, pipeline)`、`addVTableToPass(ctx, passName, vtable)`、`setPushConstant(ctx, passName, stage, size)`、`appendPass(ctx, passName)`。
  - ctx != null 时只登记到 `ctx.passes`/`ctx.buffers` 并直接 return（供 u8pack comptime 建表）；ctx == null 时才是真正的运行时构建。
  - `addPipelineToPass` 把单条 pipeline **追加**到列表(arena realloc)；`createPass` 初始为 `null`。
  运行时层 `PassImp.Pass.pipeline: []Pipeline_t`，在 `initFromRenderFlow` 中按声明列表逐条 `vulkan.readPipelineFileAndAdd(io, file.getID(p.name.name), sqlite, p.isMesh)`(deinit 需 `gpa.free`)；各 vtable 的 addCommand 通过 `pass.pipeline[i]` 按索引绑定(c_commandPrefixSum→ic_task→iv_feather 三索引，其余 pass 目前 1 条取 `[0]`)。push constant 同构：schema `Pass.Pass.pushConstant: []PushConstantPack`，每次 `renderFlow.setPushConstant` **追加**一条 range(arena realloc)；`initFromRenderFlow` 为每个元素单独 `gpa.alignedAlloc(u8, .@"8", size)` 填 `pValues`(deinit 逐元素 free 后 free 数组)；`PassImp.Pass.setPushConstants(index: u32, mem: []u8, offset: u16)` 按索引写 pack 的 `pValues`(数组空时 panic，offset > size 时 panic)。
- **Merged pass `i_feather`(src/setPass/i_feather.zig)**: 将原 `c_command_prefix_sum`→`ic_task`→`iv_feather` 三段流水合并为单一运行时 pass "i_feather"，顺序 fill+compute(前缀和)→ fill+computeIndirect → drawIndirect；三条 pipeline/pushConstant 按索引区分(0=c_commandPrefixSum.pipeb compute 16B、1=ic_task.pipeb compute 52B、2=iv_feather.pipeb vertex @sizeOf(Iv_feather_PushConstant)=72B)。buffer 索引表见 `const IF`(drawCommands=0、meshStorage=1、meshlet=2、vertices=3、meshletVertices=4、meshletTriangles=5、featherCommands=6、dispatchCommands=7、groupMappings=8、instance3D=9、meshes=10、payloads=11、params=12)。init 直写 `pass.pushConstant[1]/[2].pValues`，`setPushConstants(0,…)` 写 pack0，并用 `externalCommand(.fillBuffer)` 初始化 dispatch/draw 命令。描述符集用**超集** `[globalTextureDescriptorSet, global3dMVPMatrixDescriptorSet]`，compute 命令绑 `pass.descriptorSet[0..1]`、draw 绑全量。addCommand 内每帧：pack0(前缀和) → 清零 dispatch → `setPushConstants(1, drawCountPtr, 48)` 写 ic_task.drawCount → 清零 draw → computeIndirect → drawIndirect。外部引用：`resourceProcess.UserContext.initUserContext` 用 `passes.passMap.get(toStr2("i_feather")).?.buffer` 取 buffer[2..5]/[9]/[10] 初始化 mesh/instances1、取 buffer[6]/[8] 作 passGroupMapping 上传目标；instances.zig 里的 3D 处理已搬到 render.zig 的 `.createTest3d` 分支，每帧 `rdata.pass.setPushConstants(2, toBytes(tidx), 64)` 写 iv 段纹理索引。render.zig 自身只 `passes.passMap.get(toStr("indirect2D"))`（createTest2d 事件）。注意 `ic_Task_PushConstant` 是 extern struct(注册 52B，sizeof 56B，沿用旧行为)，`Iv_feather_PushConstant` 注册用 `@sizeOf`(72B)。
- **setPass 拆分为模块**: `src/setPass.zig` 只留 present + 废弃 im_feather 旧代码 + `pub const ViewBoundsAndTotalSpriteCount` + `pub fn setting(comptime ctx: ?*u8pack.CTX)`(依次 `indirect2D.addIndirect2DPass(ctx)`、`i_feather.addI_FeatherPass(ctx)`、`addPresentPass(ctx)`；im_feather 调用已注释)。每个合并 pass 是独立文件 `src/setPass/*.zig`(经 `@import("setPass/xxx.zig")` 引用，内部 `@import("../setPass.zig")` 取共享类型/结构体)。`u8pack.zig` 在 comptime 调 `setPass.setting(&ctx)` 建注册表；`monsoon/main.zig` 调 `setPass.setting(null)` 建运行时对象。**VTable.init 契约**: `init(userdata: *?*anyopaque, pass, vulkan, commands: *ExternalCommands, gpa)` —— 各 pass 在 init 内自行 `gpa.create` 用户数据对象并 `userdata.* = …`(PassImp.init 传入 `&self.userdata`)；`addCommand(userdata: ?*anyopaque, …)` 收到同一指针。渲染帧每 pass `enabled>0` 才执行；`instances2.load`(render 线程)直接经 `item.pass.userdata` 写每帧计数(2D totalSpriteCount、i_feather drawCount)。
- **Merged pass `indirect2D`(src/setPass/indirect2D.zig)**: 原 `indirectCompute`+`indirect2D` 两 pass 合并，顺序 compute(填 indirect 计数/裁剪)→ drawIndirect 绘制；pipeline/pushConstant [0]=indirectDrawCompute.pipeb compute 48B、[1]=indirectDraw.pipeb vertex 16B；buffer `[0]=indirectDrawCommand、[1]=instance2D、[2]=instanceID2D`(名字/顺序不变 → main.zig vertices2D.init 引用不变)。pass userdata = heap `ViewBoundsAndTotalSpriteCount`(init 时建)。init 直写 pack0(`IndirectComputePushConstant`)与 pack1(`indirectPushConstant`)。compute addCommand 每帧重写 `userdata.viewBounds = {-300,300,-400,400}` 并 `setPushConstants(0, src, 24)`(写 viewBounds+totalSpriteCount)，按 `(totalSpriteCount+31)/32` 求 groupCount；draw 用 `pass.buffer[1..]` 作 usedBuffers。描述符超集 `[globalTextureDescriptorSet, globalFixed2dMVPMatrixDescriptorSet]`，compute 绑 `[0..1]`。pass 的启用由 loadmap 驱动：`monsoon/loadmap/loadmap.zig` 在 grid 加载完成后 `ctx.passes.enablePass(toStr2(name))`；render.zig 每帧只对 `value.enabled > 0` 的 pass 调 addCommand。当前 loadmap `passes` 列表为 `["indirect2D","i_feather","present"]`。
- **ECS**: 代码在 `monsoon/ecs/`(`compent.zig`/`ecs.zig`/`entity.zig`)，`monsoon/ms_std/ecs.zig` 亦 `@import("ECS")`；但根 `build.zig` **当前未创建 `ECS` 模块**，`monsoon/update.zig` 里的 `@import("ECS")`/`DrawableC` 未被使用，靠 Zig 惰性分析暂不报错。要启用需在 build.zig 建 `ECS` module 并接线。
- **Content DB**: SQLite database (`Content.db`)，dev 期由 `tools/srcs/cooker` 维护，运行时由引擎只读；表/触发器定义在 `src/tables.zig` / `src/triggers.zig`
- **Handle system**: `monsoon/handle/handle.zig` — `Handles(1024, .Once)`(`global.HandlesType`)，`Handle = *Context`，`Invalid = maxInt(u32)`、`WaitFill = maxInt(u32)-1`；`getIndex(handle) ?u32`、`setIndex(handle, index)`、`handleIsValid(handle)`、`createHandle`、`destroyHandle`
- **Resource readers & cookers**: `src/resourceProcess/*.zig` 每个文件同时提供(或只提供其一)：
  - **`*_Cooker`**(编译期/工具期，供 `tools/srcs/cooker` 调用)：`pub const TableName`、`pub const Enable`、`preProcess(io, gpa, dir, parmas: *PreProcessParm, Table: *TableType)`、`preProcess2(io, gpa, contentFolderPath, fileName, content, fullPath, database: *db)`、`judgeFileType2(content, fType) ProcessType`。有 cooker 的：PNG/GLTF/VTX/Sampler/Shader/Pipeline/LoadMap/RData/Layout(在 `src/resourceProcess.zig` 中以 `pub const X_Cooker = file.X_Cooker` 重导出)。
  - **`*_Reader`**(运行时)：`read`(旧名 `processResource`) + 可选 `updateLoad`/`renderLoad`。当前 readers：`KTX2_Reader`/`VTX_Reader`/`PNG_Reader`/`LMap_Reader`/`Binary_Reader`/`RData_Reader`/`Layout_Reader`(均在 `src/resourceProcess.zig` 重导出；`Layout_Reader` 为空壳 stub，`read` 只打日志并返回 `.update`，无 `updateLoad`)。`Shader`/`Pipeline`/`Sampler`/`GLTF`/`LoadMap`/`DIR`/... 等没有 reader，走 `Example_Reader`(由 `TypeUseExample` + `useExample(comptime fType)` 判定；`Example_Reader.read` 内 `unreachable`)。
  - **`read` 统一签名**：`fn read(comptime fType: ProcessType, ctx: *const resource.ResourceCtx, sqlite: sqlite3, fileID: u32, buffers: ?[]Buffer_t, commands: *ExternalCommands, child: *Child) resource.ResourceError!resource.ReaderReturnType`。旧签名里的 `handle`/`uctx` 已移除；`sqlite` 是显式参数(per-worker 池化连接，线程安全)。`ReaderReturnType = { rType: ReaderQueueEnum(update/render) }`(**只有 rType**)。
  - **`Child` 契约**：`pub const Child = struct { pub const Parent = <ReaderName>; ...; pub fn free(self: *Child, gpa: Allocator) void }`；`ReaderUnion` 由 `resourceProcess` 里所有 `*_Reader` decl 自动生成(跳过 `Example_Reader`)，union 字段类型为 `*struct { count: std.atomic.Value(u32), child: Child }`，用 `Child.Parent` 指回 reader 本体。当前 `free`：`RData_Reader` 会逐 item `gpa.free(name)`/`gpa.free(textures)` 再 `gpa.free(items)`，其余为 stub。
  - **CPU/GPU 两阶段**：`read` 只做 CPU 侧工作(读文件/解码/建 staging buffer + image + imageView + regions)，把 GPU 资源写进**调用方传入的** `child`(`child` 由 dispatch 分配，reader 不再 `gpa.create`)，返回 `.{ .rType = .render }`，再由 render 线程的 `renderLoad(io, gpa, vulkan, commands, uctx: *Ctx, handle, pointer: *Child) !u32` 调 `uctx.pTextureSet.createTextureFromResource(...)`。`PNG_Reader`/`KTX2_Reader` 为样板。
  - **`Ctx` 契约**：每个 reader 定义 `pub const Ctx = struct { <字段名>: *<UserContext 里同名字段的类型>, ... }`。消费端(render/update 线程)在拿到队列项后，用 `@typeInfo(field.Ctx)` 遍历字段名，把 `&@field(args.uctx, f.name)` 逐个填进临时 `Ctx` 再传给 load 函数——即 `Ctx` 字段名必须与 `UserContext` 字段名严格一致。例：PNG/KTX2 `{ pTextureSet }`、VTX `{ meshes }`、LMap `{ loadmaps }`、RData `{ renderData, pTextureSet }`。
  - **错误约定**：`read` 内 `std.log.err` 后返回 `ResourceError.Invalid`/`Unavaliable`(不向 dispatch 之外传播)；`updateLoad`/`renderLoad` 失败时返回 `Handles.WaitFill`/`Handles.Invalid` 之类的 u32 而非 error。
  - `src/resourceProcess.zig` 还导出：`ProcessType`(含 `.LoadMap/.LMap/.Binary/.RData/.Layout` 等)、`list`(扩展名→ProcessType，`.rdata`/`.layout`)、`Mappings`(ProcessType→`Handles.ResourceType`，用于 `readResource` 建 handle；`.RData`/`.Layout` 未登记 → 默认 `.others`)、`CustomTables`/`CustomTablePack`(ContentPath/ImageLoadParameter/ModelLoadParameter)、`Triggers`(建库触发器 SQL)、`judgeFileTypeByContent`、`preProcessInit(io, gpa, content)`(cooker 启动调：`sceneJsonInit`(读/建 `Content/Scenes.json` → `SceneJson: ?[]cgltf.Scene` + `SceneNameStringMap`/`SceneNodeNames`) + `gltf.saveSceneJson`，`SceneFileName = "Scenes.json"`)。
- **Resource reader queues**: `monsoon/resource.zig` 定义 `Pointer_Handle = struct { handle: Handle, pointer: resourceProcess.ReaderUnion }`、`ReaderQueue = mstd.Queue(Pointer_Handle)`，以及 `ReaderQueueEnum`/`ReaderReturnType`。`ResourceCtx` 新增 `render: *ReaderQueue` / `update: *ReaderQueue`。两个队列在 `monsoon/main.zig` 中 `resource.ReaderQueue.init(allocator_t.*, io)` 初始化并 defer deinit，`render` 经 `.renderQueue` 单独传给 `render.Args`，`render`+`update` 经 `update.Args.renderQueue/updateQueue` 传给 update 线程，由其构造的 `resourceCtx` 持有。
  - worker `resource.processResource`：从 `nameArray` 取 `pack`，按 `ProcessType` tag 拼 `"<T>_Reader"` / `"<T>_Child"`，`gpa.create(@FieldType(ReaderUnion, childName).pointer.child)` 得到 `*struct{count, child}`，调 `field.read(t, ctx, sqlite, pack.id, pack.buffers, externalCommands, &ptr.child)`，按 `index.rType` 入 `ctx.update`/`ctx.render` 并置 `ptr.count = 1`；无 reader 时走 `Example_Reader`(否则 comptime 报 "no reader for T")。
  - 消费端(update.zig/render.zig)：`while (queue.popFirst()) |v|` → `switch (v.pointer) { inline else => |pt| { defer if (pt.count.fetchSub(1, .seq_cst) == 1) { @TypeOf(pt.child).free(&pt.child, gpa); gpa.destroy(pt); } ... } }`，构造 `Ctx` 后调 `field.updateLoad/renderLoad(io, gpa, vulkan, <commands|undefined>, &uctx, v.handle, &pt.child)`(**`renderLoad` 还要多传一个 `args.updateEventQueue`**)，拿返回值 `handles.setIndex(v.handle, index)`；没有对应 load 函数时 `setIndex(v.handle, WaitFill)`。
- **Event queues (update↔render, 无锁双缓冲)**: `monsoon/ms_std/doubleBufferQueue.zig` 的 `doubleBufferQueue(T)`（`ms_std` 导出为 `DoubleBufferQueue`，`global.UpdateEventQueueType`/`RenderEventQueueType = mstd.DoubleBufferQueue(event.UpdateEvent/RenderEvent)`，`main.zig` 各 `try .init(allocator_t.*, io)`/`deinit()`）。两块 `std.Deque(T)`(O(1) 双端, 消费者侧 FIFO)，归属由原子 `state` 的 generation 奇偶决定（`prodIdx = (state >> 1) & 1`，消费者 `consumerIdx = 1 - prodIdx`），无 `Io.Mutex`：
  - API：`pushLastP(data) !void`（**生产者线程**，`pushBack` 进生产者那块）、`pushLastC(data) !void`（消费者 `pushBack` 进自己那块）、`popFirst() ?T`（**消费者线程**，`popFront` 自己那块，FIFO）、`swap()`（消费者，交换归属）、`len()`。
  - swap 协议：`state` bit0=1 表示 swap 进行中；生产者 `pushLastP` 读 `state`(odd 则重试) → `writers += 1` → 复读 `state` 校验(变了就撤回重试) → append → `writers -= 1`；`swap` 先 `state += 1`(odd，挡住新生产者) → 自旋等 `writers == 0`(等在途 push 结束) → 翻转 `consumerIdx` → 再 `state += 1`(even，generation+1)。全程 `seq_cst`，只需单生产者 + 单消费者。
  - `swap` **不清空**任何一块：消费者没 drain 完的条目(或自己 `pushLastC` 塞的)会随该块一起交给生产者，下一轮 swap 回来再消费。消费者调 `swap` 时不得操作队列。
  - 调用点：`monsoon/render.zig` 每帧 `while (args.updateEventQueue.popFirst()) |event|` 消费完这批后调 `args.updateEventQueue.swap()`(swap 点在该循环之后，因此 swap 时消费者确实没在操作队列)；`monsoon/update.zig` 用 `eventQueue.pushLastP(...)`。`renderEventQueue`(render→update) 目前只声明未消费，将来消费同样需先 `swap()`。
- **RData / Layout reader**（`src/resourceProcess/rdata.zig` / `layout.zig`；由 `src/resourceProcess/instance.zig` 拆分而来，原 `Instance_Reader`/`Instance_Cooker` 已删除）：
  - `RData_Reader.read` 解析 `.rdata` JSON(`Assets/schema/rdata.schema.json`)：根对象 `{ $schema?: string, items: [...] }`(含可选 `"$schema"`，无 `ignore_unknown_fields`)；item = `{name: string, pass: string, textures: []string, model?: string}`，**不再含 pos/scale/rotation**(transform 移到 layout 文件；`instance2.instance` 结构体仍带 pos/scale/rotation/name，本步未动)。`Child.items: []RData_Reader.Item`(`Item = { name: []u8, model: ?Handle, textures: []Handle, pass: *pass.Pass }`)，`read` 用 `ctx.gpa` 分配 name(`gpa.dupe`)与 textures 数组，并用 `filled` 计数器 `errdefer` 逐个回滚；不再 `createHandle`。逐 item：`pass` 用 `ctx.passes.passMap.get(toStr2(item.pass))`(否则 `Invalid`)，textures 用 `resource.getResourceHandle(file.getID(name))` + `Handles.handleIsValid`(否则 `Unavaliable`)，`model` 同 `getResourceHandle`；返回 **`.{ .rType = .render }`**(不再 `.update`)。
  - `RData_Reader.renderLoad(io, gpa, vulkan, commands, uctx: *Ctx, handle, pointer: *Child) !u32`(render 线程)：逐 item 用 `u8pack.toStr2(item.name)` 拿 Str(debug 下查 `strConstruct.rdatas` 静态表，`.id == maxInt(u32)` 就 log + 返回 `Handles.Invalid`；ReleaseFast 下要改 `ID2`，见 TODO(release))，再 `uctx.renderData.add(gpa, name, .{ .model, .textures, .pass })`；`add` 内部 `gpa.dupe` textures，故 `Child.free` 依旧负责原始数组。
  - `Layout_Reader`(layout.zig)：`Ctx = { renderData }`。`read` 解析 layout JSON(`Assets/schema/layout.schema.json`)：根对象 `{ $schema?: string, items: [{name, pos/scale/rotation: number[3]}] }`，根 `pos/scale/rotation` 长度必须 3(否则 `Invalid`)，每个 item 用 `ctx.handles.createHandle(Handles.Invalid, .others)` 建一个**实例 handle**，存入 `Child.items: []Layout_Reader.Item`(`{ name: []u8, pos, scale, rotation: vec3, handle }`)，返回 `.render`。`renderLoad(..., updateEventQueue: *global.UpdateEventQueueType)` 逐 item：`const name = u8pack.toStr2(item.name)`(查不到就 log + `continue`) → `uctx.renderData.get(name)` 取 `rData`(取不到就 `continue`) → 按 `rdata.pass.name` 比对(`toStr("indirect2D")` / `toStr("i_feather")`) → `updateEventQueue.pushLastC(.{ .createTest2d/createTest3d = .{ pos, scale, rotation, rdata = name, handle = item.handle } })`；返回 `Handles.WaitFill`。即 **layout 的 name→rdata 合并就在这里完成**(过渡方案，将来可能换成更直接的 dispatch)。
- **RData / Layout schema**: `Assets/schema/rdata.schema.json` — 根对象 `{ $schema?, items: [{name, pass, textures, model?}] }`(`additionalProperties: false`，required `name/pass/textures`，`items` 必需)；`Assets/schema/layout.schema.json` — 根对象 `{ $schema?, items: [{name, pos, scale, rotation}] }`(全 required，pos/scale/rotation 为 3 个 number)。示例 `Assets/rdata/test.rdata` + `Assets/layout/test.layout`(由旧 `Assets/instance/test.instance` 拆分；旧 `instance.schema.json`/`Assets/instance/` 已删除，`Assets/loadMap/test.loadmap` 的 item 名已改为 `test.rdata`/`test.layout`)。
- **renderData**(`src/customStruct/renderData.zig`，模块名 `renderData`，接入 `src/build/renderData.zig` + `Config.pass`)：`pub const rData = struct { model: ?Handle = null, textures: []Handle = &.{}, pass: *pass.Pass }`；容器就一个 `map: u8pack.HashMap(rData)`(Str→rData，**只在 render 线程访问，无 mutex**)。key 的 name/id 来自 `strConstruct.rdatas` 静态表(经 `u8pack.toStr/toStr2`)，所以 renderData **不拥有任何字符串**(原来的 `stringMap`/`nextId`/`toStr` 已删除)，`deinit` 只释放每个 `value.textures`。API：`init(gpa)`、`deinit()`、`add(self, gpa, name: Str, data: rData) !void`(**重复 name 直接 return 忽略**；内部 `gpa.dupe` textures)、`get(self, name: Str) ?*rData`。已在 `UserContext` 里加 `renderData: renderData` 字段(init/deinitUserContext 已接线)，使用者为 `RData_Reader.renderLoad` 与 `Layout_Reader.renderLoad`；用途是把 rdata 解析出的 model/textures/pass 按 name 暂存，再由 layout 读取时按 name 取回并分发成 updateEvent。
- **Pipeline schema**: `Assets/schema/pipeline.schema.json` (JSON Schema draft-2020-12) documents the `.pipe` format；enums unconstrained (plain strings)，unknown fields allowed
- **Sampler schema**: `Assets/schema/sampler.schema.json` (JSON Schema draft-2020-12) documents the `.samp` format (flat VkSamplerCreateInfo, integer enums)；same permissive policy
- **Layout → rdata 合并**: 由 `Layout_Reader.renderLoad` 用 `u8pack.toStr2(item.name)` + `renderData.get(name)` 完成，然后按 pass 名分发成 `UpdateEvent`(见上)；`rData`/`event.test2d/test3d` 里都没有单独的 `name` 字段，name 只以 `u8pack.Str`(静态表 key)形式随事件传递。
- **LoadMap schema**: `Assets/schema/loadmap.schema.json` (JSON Schema draft-2020-12) documents recursive grid loadmap format；`gridLength` required everywhere，`leftUp` required in grids，`items` entries are `{name, isGpu, bufferName(optional string array)}` objects (`name`/`isGpu` required)，`passes` string array in root and grids，`depth` 是解析上限用的非负 int，unknown fields 拒绝(`additionalProperties: false`)。示例 `Assets/loadMap/test.loadmap`(JSON)，运行时读取的是 cooker 经 `loadmapConverter.exe` 转出的 `.lMap` 二进制。

## lMap binary format

```
| magic | depth | totals (5) | offsets[] | layer0 | layer1 | ... |
```

- `magic` 4B: ASCII `"lMap"`
- `depth` 4B: grid layer count — file contains `depth + 1` layers (root layer included)
- `totalGridCount` 4B u32 — Σ per-layer `row × col` (spatial grid slots, NOT written grids); reader uses it to size the grids memory region without traversal
- `totalItemCount` 4B u32 — number of items
- `totalPassCount` 4B u32 — number of passes
- `totalU8Count` 4B u32 — number of u8
- `totalBufferNameCount` 4B u32 — total number of bufferName strings across all items
- `offsets`: `(depth + 1) * 4B` — file offset where each grid layer starts (header is 28B + offsets)
- **Grid layer** (all grids of the same depth stored together):
  - `gridRow` 4B — grid row of this layer
  - `gridCol` 4B — grid col of this layer
  - `leftUp` 8B — layer min (x, y) across its grids (written after the loop, like row/col)
  - `gridLength` 4B — grid size of this layer
  - `gridCount` 4B u32 — number of **non-blank** grids written for this layer; the layer's in-memory spatial array is `row × col`, blank slots keep struct defaults
  - Grid × `gridCount`:
    - `leftUp` 8B — (x, y) coordinates; locates the grid's slot in the layer array: `idx = (y - layerLeftUp.y) / gridLength * col + (x - layerLeftUp.x) / gridLength`
    - `itemCount` 4B
    - Item × `itemCount`:
      - `nameLen` 4B, then `name` bytes
      - `isGpu` 1B
      - `bufferNameCount` 4B, then per name: `bufferNameLen` 4B, then `bufferName` bytes
    - `passCount` 4B
    - Pass × `passCount`: `passLen` 4B, then `pass` bytes

## Ignored / special directories

- `.watching` — watcher 监听的目录清单(每行一个)，见 Content pipeline
- `testFeature/` — gitignored; ad-hoc test programs, NOT part of `zig build test`
- `cache.json` — root level, content hash cache for `selectModifiedFileToTxt`
- `path.txt` — `pushToCenter.ps1`(把本仓库按 path.txt 列表导出并推到中心仓库的辅助脚本)的目录清单
- `config/` — gitignored(当前代码已无引用，疑为遗留)
- `tools/` — 由 watcher 构建安装的 `watcher.exe`/`cooker.exe`/`loadmapConverter.exe` 及源码 `tools/srcs/`；`tools/srcs/cooker/shared_b` 是指向 `src/` 的符号链接
- `.vscode/`、`opencode.json`、`.opencode/` — 编辑器 / AI agent 配置
- `.zig-cache/`, `zig-out/`, `zig-pkg/` — build artifacts
