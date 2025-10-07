const ecs = @import("ECS");
const std = @import("std");

var entity: []ecs.Entity = undefined;

pub fn init(allocator: std.mem.Allocator) std.mem.Allocator.Error!void {
    entity = try allocator.alignedAlloc(ecs.Entity, @alignOf(ecs.Entity), 2);
}

pub fn createEntity(allocator: std.mem.Allocator) std.mem.Allocator.Error!void {
    const en = ecs.Entity.createEntity();

    if (@as(usize, @intCast(en.id)) > entity.len) {
        entity = try allocator.realloc(entity, entity.len * 2);
    }

    entity[en.id] = en;
}

pub fn haveEntity(en: ecs.Entity) bool {
    return if (en.id < entity.len) en.id == entity[en.id].id else false;
}

pub fn deinit(allocator: std.mem.Allocator) void {
    allocator.free(entity);
}
