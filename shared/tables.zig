const sqlDB = @import("sqlDb");

pub const ContentPath = sqlDB.Table(
    "CREATE TABLE IF NOT EXISTS ContentPath (ID INTEGER PRIMARY KEY, UUID TEXT UNIQUE, ParentUUID TEXT, RelativePath TEXT NOT NULL UNIQUE, FileName TEXT,  TYPE INTEGER" ++
        ", FileSize INTEGER, ContentHash BLOB, ModifiedTime INTEGER, LastSeenTime INTEGER, FileType INTEGER);",
    "ContentPath",
    false,
);
pub const ImageLoadParameter = sqlDB.Table(
    "CREATE TABLE IF NOT EXISTS ImageLoadParameter (ID INTEGER PRIMARY KEY, FileName TEXT, ContentHash BLOB UNIQUE, RelativePath TEXT UNIQUE, Format INTEGER" ++
        ", Tiling INTEGER, Usage INTEGER, Properties INTEGER, FileUUID TEXT, FOREIGN KEY(FileUUID) REFERENCES ContentPath(UUID) ON DELETE SET NULL ON UPDATE CASCADE);",
    "ImageLoadParameter",
    false,
);
pub const ModelLoadParameter = sqlDB.Table(
    "CREATE TABLE IF NOT EXISTS ModelLoadParameter (ID INTEGER PRIMARY KEY, FileName TEXT, ContentHash BLOB UNIQUE, RelativePath TEXT UNIQUE" ++
        ", VertexType INTEGER, VerticesSize INTEGER, MeshletsSize INTEGER, MeshletVerticesSize INTEGER, MeshletTrianglesSize INTEGER" ++
        ", ParentModelFile TEXT, FileUUID TEXT, FOREIGN KEY(FileUUID) REFERENCES ContentPath(UUID)" ++
        ", FOREIGN KEY(ParentModelFile) REFERENCES ContentPath(UUID) ON DELETE SET NULL ON UPDATE CASCADE);",
    "ModelLoadParameter",
    false,
);
pub const ShaderPipelineGraphNode = sqlDB.Table(
    "CREATE TABLE IF NOT EXISTS ShaderPipelineGraphNode (ID INTEGER PRIMARY KEY AUTOINCREMENT, Name TEXT UNIQUE, Type INTEGER);",
    "ShaderPipelineGraphNode",
    true,
);
pub const ShaderPipelineGraphEdge = sqlDB.Table(
    "CREATE TABLE IF NOT EXISTS ShaderPipelineGraphEdge (FromNodeID INTEGER, ToNodeID INTEGER, PRIMARY KEY (FromNodeID, ToNodeID));",
    "ShaderPipelineGraphEdge",
    false,
);
// pub const ShaderLoadParameter = sqlDB.Table(
//     "CREATE TABLE IF NOT EXISTS ShaderLoadParameter (FileName TEXT PRIMARY KEY, ContentHash BLOB UNIQUE, RelativePath TEXT UNIQUE, FileSize INTEGER" ++
//         ", EntryName TEXT, Stage INTEGER, SetCount INTEGER, BindingCount INTEGER, Bindings BLOB, PushConstantSize INTEGER" ++
//         ", FileID TEXT, FOREIGN KEY(FileID) REFERENCES ContentPath(ID) ON DELETE SET NULL ON UPDATE CASCADE);",
//     "ShaderLoadParameter",
//     false,
// );
