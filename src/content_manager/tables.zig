const sqlDB = @import("sqlDb");

pub const ContentPath = sqlDB.Table(
    "CREATE TABLE IF NOT EXISTS ContentPath (ID TEXT PRIMARY KEY,  ParentID TEXT,  RelativePath TEXT NOT NULL UNIQUE,  FileName TEXT,  TYPE INTEGER, FileSize INTEGER, ContentHash BLOB, ModifiedTime INTEGER, LastSeenTime INTEGER, FileType INTEGER);",
    "ContentPath",
    false,
);
pub const ImageLoadParameter = sqlDB.Table(
    "CREATE TABLE IF NOT EXISTS ImageLoadParameter (FileName TEXT PRIMARY KEY, ContentHash BLOB UNIQUE, RelativePath TEXT UNIQUE, FileID TEXT, FOREIGN KEY(FileID) REFERENCES ContentPath(ID) ON DELETE SET NULL ON UPDATE CASCADE);",
    "ImageLoadParameter",
    false,
);
pub const ShaderLoadParameter = sqlDB.Table(
    "CREATE TABLE IF NOT EXISTS ShaderLoadParameter (FileName TEXT PRIMARY KEY, ContentHash BLOB UNIQUE, RelativePath TEXT UNIQUE, FileSize INTEGER" ++
        ", EntryName TEXT, Stage INTEGER, SetCount INTEGER, BindingCount INTEGER, Bindings BLOB, PushConstantSize INTEGER" ++
        ", FileID TEXT, FOREIGN KEY(FileID) REFERENCES ContentPath(ID) ON DELETE SET NULL ON UPDATE CASCADE);",
    "ShaderLoadParameter",
    false,
);
